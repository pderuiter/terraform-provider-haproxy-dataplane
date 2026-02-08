#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EXAMPLE_DIR="$ROOT_DIR/examples/smoke"
COMPOSE_FILE="$ROOT_DIR/docker-compose.integration.yml"
WORK_DIR="$(mktemp -d)"
HAPROXY_CONFIG_DIR="$WORK_DIR/haproxy-config"
NETWORK_NAME=""
TF_CONTAINER_NAME=""

if ! command -v docker >/dev/null 2>&1; then
  echo "docker is required on PATH" >&2
  exit 1
fi

compose() {
  docker compose -f "$COMPOSE_FILE" "$@"
}

detect_network_name() {
  local haproxy_id
  haproxy_id="$(compose ps -q haproxy)"
  if [ -z "$haproxy_id" ]; then
    echo "Failed to find haproxy container ID from docker compose while detecting network" >&2
    compose ps >&2 || true
    compose logs --tail=200 haproxy >&2 || true
    return 1
  fi

  NETWORK_NAME="$(docker inspect -f '{{range $name, $cfg := .NetworkSettings.Networks}}{{println $name}}{{end}}' "$haproxy_id" | head -n1 | tr -d '[:space:]')"
  if [ -z "$NETWORK_NAME" ]; then
    echo "Failed to detect docker network for haproxy container" >&2
    return 1
  fi
}

configure_haproxy_container() {
  local haproxy_id
  haproxy_id="$(compose ps -q haproxy)"
  if [ -z "$haproxy_id" ]; then
    echo "Failed to find haproxy container ID from docker compose" >&2
    return 1
  fi

  docker exec "$haproxy_id" sh -lc \
    "mkdir -p /usr/local/etc/haproxy/transactions /usr/local/etc/haproxy/backups /usr/local/etc/haproxy/maps /usr/local/etc/haproxy/ssl /usr/local/etc/haproxy/general /usr/local/etc/haproxy/dataplane /usr/local/etc/haproxy/spoe" >/dev/null
  docker cp "$HAPROXY_CONFIG_DIR/." "$haproxy_id:/usr/local/etc/haproxy/"
  docker restart "$haproxy_id" >/dev/null
}

wait_http() {
  local url="$1"
  local userpass="${2:-}"
  local tries=0
  until {
    if [ -n "$userpass" ]; then
      docker run --rm --network "$NETWORK_NAME" curlimages/curl:8.10.1 -fsS -u "$userpass" "$url" >/dev/null 2>&1
    else
      docker run --rm --network "$NETWORK_NAME" curlimages/curl:8.10.1 -fsS "$url" >/dev/null 2>&1
    fi
  }; do
    tries=$((tries + 1))
    if [ "$tries" -ge 120 ]; then
      echo "Timed out waiting for ${url}" >&2
      compose ps >&2 || true
      compose logs --tail=200 haproxy >&2 || true
      return 1
    fi
    sleep 2
  done
}

start_terraform_container() {
  TF_CONTAINER_NAME="tf-smoke-$(date +%s)-$$"
  docker run -d --rm \
    --network "$NETWORK_NAME" \
    --name "$TF_CONTAINER_NAME" \
    --entrypoint sh \
    hashicorp/terraform:1.11.0 -c 'sleep infinity' >/dev/null
  docker exec "$TF_CONTAINER_NAME" mkdir -p /workspace >/dev/null
  docker cp "$EXAMPLE_DIR/." "$TF_CONTAINER_NAME:/workspace/"
  docker exec "$TF_CONTAINER_NAME" sh -lc "rm -rf /workspace/.terraform /workspace/.terraform.lock.hcl /workspace/terraform.tfstate /workspace/terraform.tfstate.backup" >/dev/null
}

terraform_cmd() {
  docker exec \
    -e TF_VAR_haproxy_admin_password \
    -e TF_VAR_dataplane_endpoint \
    "$TF_CONTAINER_NAME" terraform -chdir=/workspace "$@"
}

cleanup() {
  set +e
  terraform_cmd destroy -auto-approve >/dev/null 2>&1
  if [ -n "$TF_CONTAINER_NAME" ]; then
    docker rm -f "$TF_CONTAINER_NAME" >/dev/null 2>&1 || true
  fi
  compose down >/dev/null 2>&1
  rm -rf "$WORK_DIR"
}
trap cleanup EXIT

mkdir -p "$HAPROXY_CONFIG_DIR"
cp -R "$ROOT_DIR/dev/haproxy/." "$HAPROXY_CONFIG_DIR/"
if [ -f "$HAPROXY_CONFIG_DIR/dataplaneapi.yml" ]; then
  sed 's#/var/run/haproxy/master.sock#/var/run/haproxy-master.sock#g' \
    "$HAPROXY_CONFIG_DIR/dataplaneapi.yml" > "$HAPROXY_CONFIG_DIR/dataplaneapi.yml.tmp"
  mv "$HAPROXY_CONFIG_DIR/dataplaneapi.yml.tmp" "$HAPROXY_CONFIG_DIR/dataplaneapi.yml"
fi

echo "Starting HAProxy smoke stack..."
compose down --remove-orphans >/dev/null 2>&1 || true
compose up -d haproxy
configure_haproxy_container
detect_network_name
start_terraform_container

HAPROXY_CONTAINER_ID="$(compose ps -q haproxy)"
PASSWORD_LINE="$(docker exec "$HAPROXY_CONTAINER_ID" awk '/user admin insecure-password/ {print $0; exit}' /usr/local/etc/haproxy/haproxy.cfg || true)"
if [ -z "$PASSWORD_LINE" ]; then
  echo "Failed to read admin password from container haproxy.cfg" >&2
  exit 1
fi
HAPROXY_ADMIN_PASSWORD=$(echo "$PASSWORD_LINE" | awk '{print $4}')
if [ -z "$HAPROXY_ADMIN_PASSWORD" ]; then
  echo "Failed to parse admin password" >&2
  exit 1
fi

export TF_VAR_haproxy_admin_password="$HAPROXY_ADMIN_PASSWORD"
export TF_VAR_dataplane_endpoint="http://haproxy:5555"
wait_http "http://haproxy:5555/v3/info" "admin:${HAPROXY_ADMIN_PASSWORD}"

echo "Initializing smoke terraform..."
terraform_cmd init

echo "Applying smoke config..."
terraform_cmd apply -auto-approve

echo "Verifying smoke state..."
terraform_cmd state list | grep -q "haproxy-dataplane_backend.smoke"
terraform_cmd state list | grep -q "haproxy-dataplane_frontend.smoke"

echo "Destroying smoke config..."
terraform_cmd destroy -auto-approve

echo "Smoke test complete."
