#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EXAMPLE_DIR="$ROOT_DIR/examples/registry-integration"
COMPOSE_FILE="$ROOT_DIR/docker-compose.integration.yml"
WORK_DIR="$(mktemp -d)"
HAPROXY_CONFIG_DIR="$WORK_DIR/haproxy-config"

if ! command -v docker >/dev/null 2>&1; then
  echo "docker is required on PATH" >&2
  exit 1
fi

compose() {
  docker compose -f "$COMPOSE_FILE" "$@"
}

NETWORK_NAME=""
TF_CONTAINER_NAME=""

detect_network_name() {
  local haproxy_id
  haproxy_id="$(compose ps -q haproxy)"
  if [ -z "$haproxy_id" ]; then
    echo "Failed to find haproxy container ID from docker compose while detecting network" >&2
    dump_compose_logs
    return 1
  fi

  NETWORK_NAME="$(docker inspect -f '{{range $name, $cfg := .NetworkSettings.Networks}}{{println $name}}{{end}}' "$haproxy_id" | head -n 1 | tr -d '[:space:]')"
  if [ -z "$NETWORK_NAME" ]; then
    echo "Failed to detect docker network for haproxy container" >&2
    dump_compose_logs
    return 1
  fi
}

curl_via_network() {
  docker run --rm --network "$NETWORK_NAME" curlimages/curl:8.10.1 "$@"
}

terraform_cmd() {
  docker exec \
    -e TF_VAR_haproxy_admin_password \
    -e TF_VAR_name_suffix \
    -e TF_VAR_dataplane_endpoint \
    "$TF_CONTAINER_NAME" terraform -chdir=/workspace "$@"
}

start_terraform_container() {
  TF_CONTAINER_NAME="tf-integration-$(date +%s)-$$"
  docker run -d --rm \
    --network "$NETWORK_NAME" \
    --name "$TF_CONTAINER_NAME" \
    --entrypoint sh \
    hashicorp/terraform:1.11.0 -c 'sleep infinity' >/dev/null
  docker exec "$TF_CONTAINER_NAME" mkdir -p /workspace >/dev/null
  docker cp "$EXAMPLE_DIR/." "$TF_CONTAINER_NAME:/workspace/"
}

stop_terraform_container() {
  if [ -n "$TF_CONTAINER_NAME" ]; then
    docker rm -f "$TF_CONTAINER_NAME" >/dev/null 2>&1 || true
  fi
}

dump_compose_logs() {
  echo "---- docker compose ps ----" >&2
  compose ps >&2 || true
  echo "---- haproxy logs ----" >&2
  compose logs --tail=200 haproxy >&2 || true
  echo "---- consul logs ----" >&2
  compose logs --tail=200 consul >&2 || true
}

configure_haproxy_container() {
  local haproxy_id
  haproxy_id="$(compose ps -q haproxy)"
  if [ -z "$haproxy_id" ]; then
    echo "Failed to find haproxy container ID from docker compose" >&2
    dump_compose_logs
    return 1
  fi

  docker exec "$haproxy_id" sh -lc \
    "mkdir -p /usr/local/etc/haproxy/transactions /usr/local/etc/haproxy/backups /usr/local/etc/haproxy/maps /usr/local/etc/haproxy/ssl /usr/local/etc/haproxy/general /usr/local/etc/haproxy/dataplane /usr/local/etc/haproxy/spoe" >/dev/null
  docker cp "$HAPROXY_CONFIG_DIR/." "$haproxy_id:/usr/local/etc/haproxy/"
  docker restart "$haproxy_id" >/dev/null
}

wait_http() {
  local url="$1"
  local name="$2"
  local userpass="${3:-}"
  local tries=0
  until {
    if [ -n "$userpass" ]; then
      curl_via_network -fsS -u "$userpass" "$url" >/dev/null 2>&1
    else
      curl_via_network -fsS "$url" >/dev/null 2>&1
    fi
  }; do
    tries=$((tries + 1))
    if [ "$tries" -ge 120 ]; then
      echo "Timed out waiting for $name ($url)" >&2
      dump_compose_logs
      return 1
    fi
    sleep 2
  done
}

wait_body_contains() {
  local url="$1"
  local name="$2"
  local expected="$3"
  local tries=0
  while true; do
    local body
    body="$(curl_via_network -sS --max-time 5 "$url" || true)"
    if [[ "$body" == *"$expected"* ]]; then
      return 0
    fi
    tries=$((tries + 1))
    if [ "$tries" -ge 120 ]; then
      echo "Timed out waiting for expected body on $name ($url). Last body: $body" >&2
      dump_compose_logs
      return 1
    fi
    sleep 2
  done
}

mkdir -p "$HAPROXY_CONFIG_DIR"
cp -R "$ROOT_DIR/dev/haproxy/." "$HAPROXY_CONFIG_DIR/"

# ACME support in HAProxy requires enabling experimental directives globally.
if ! grep -q "expose-experimental-directives" "$HAPROXY_CONFIG_DIR/haproxy.cfg"; then
  awk '
    /^global$/ { print; print "  expose-experimental-directives"; next }
    { print }
  ' "$HAPROXY_CONFIG_DIR/haproxy.cfg" > "$HAPROXY_CONFIG_DIR/haproxy.cfg.tmp"
  mv "$HAPROXY_CONFIG_DIR/haproxy.cfg.tmp" "$HAPROXY_CONFIG_DIR/haproxy.cfg"
fi

# The official HAProxy image starts with a master socket at /var/run/haproxy-master.sock.
# Ensure dataplaneapi points at the same path so config reloads succeed.
if [ -f "$HAPROXY_CONFIG_DIR/dataplaneapi.yml" ]; then
  sed 's#/var/run/haproxy/master.sock#/var/run/haproxy-master.sock#g' \
    "$HAPROXY_CONFIG_DIR/dataplaneapi.yml" > "$HAPROXY_CONFIG_DIR/dataplaneapi.yml.tmp"
  mv "$HAPROXY_CONFIG_DIR/dataplaneapi.yml.tmp" "$HAPROXY_CONFIG_DIR/dataplaneapi.yml"
fi

echo "Starting integration containers..."
compose up -d
configure_haproxy_container
detect_network_name
start_terraform_container

cleanup() {
  set +e
  echo "Cleaning up terraform state and containers..."
  terraform_cmd destroy -auto-approve -parallelism=1 >/dev/null 2>&1
  stop_terraform_container
  compose down >/dev/null 2>&1
  rm -rf "$WORK_DIR"
}
trap cleanup EXIT

HAPROXY_CONTAINER_ID="$(compose ps -q haproxy)"
if [ -z "$HAPROXY_CONTAINER_ID" ]; then
  echo "Failed to find haproxy container ID from docker compose" >&2
  dump_compose_logs
  exit 1
fi

PASSWORD_LINE="$(docker exec "$HAPROXY_CONTAINER_ID" awk '/user admin insecure-password/ {print $0; exit}' /usr/local/etc/haproxy/haproxy.cfg || true)"
if [ -z "$PASSWORD_LINE" ]; then
  echo "Failed to read admin password from container haproxy.cfg" >&2
  dump_compose_logs
  exit 1
fi
HAPROXY_ADMIN_PASSWORD=$(echo "$PASSWORD_LINE" | awk '{print $4}')
if [ -z "$HAPROXY_ADMIN_PASSWORD" ]; then
  echo "Failed to parse admin password" >&2
  exit 1
fi
export TF_VAR_haproxy_admin_password="$HAPROXY_ADMIN_PASSWORD"
export TF_VAR_name_suffix="itest$(date +%s)"
export TF_VAR_dataplane_endpoint="http://haproxy:5555"

wait_http "http://haproxy:5555/v3/info" "HAProxy Data Plane API" "admin:${HAPROXY_ADMIN_PASSWORD}"
wait_http "http://consul:8500/v1/status/leader" "Consul"

echo "Registering test service in Consul..."
ECHO_CONTAINER_ID="$(compose ps -q echo)"
if [ -z "$ECHO_CONTAINER_ID" ]; then
  echo "Failed to find echo container ID from docker compose" >&2
  dump_compose_logs
  exit 1
fi
ECHO_IP=$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$ECHO_CONTAINER_ID")
if [ -z "$ECHO_IP" ]; then
  echo "Failed to determine echo container IP for Consul registration" >&2
  dump_compose_logs
  exit 1
fi
curl_via_network -fsS -X PUT http://consul:8500/v1/agent/service/register \
  -H 'Content-Type: application/json' \
  -d "{\"Name\":\"echo\",\"ID\":\"echo-1\",\"Address\":\"${ECHO_IP}\",\"Port\":5678}" >/dev/null

pushd "$EXAMPLE_DIR" >/dev/null
rm -rf .terraform .terraform.lock.hcl terraform.tfstate* 

echo "Initializing terraform..."
terraform_cmd init

echo "Applying integration module..."
terraform_cmd apply -auto-approve -parallelism=1

# Main static backend/frontend path test
wait_body_contains "http://haproxy:18081" "Main frontend" "hello-from-consul"

# Service discovery path test (backend server + consul resolver)
wait_body_contains "http://haproxy:18082" "Service discovery frontend" "hello-from-consul"

# ACME config existence check
curl_via_network -fsS -u "admin:${HAPROXY_ADMIN_PASSWORD}" \
  "http://haproxy:5555/v3/services/haproxy/configuration/acme/letsencrypt_${TF_VAR_name_suffix}" \
  | grep -q '"directory"' || {
    echo "ACME configuration not found through Data Plane API" >&2
    exit 1
  }

# Additional typed resource CRUD checks (state IDs after create)
terraform_cmd state show haproxy-dataplane_userlist.itest | grep -q "id   = \"itest_userlist_${TF_VAR_name_suffix}\"" || {
  echo "Userlist state check failed" >&2
  exit 1
}

terraform_cmd state show haproxy-dataplane_group.ops | grep -q "name     = \"ops_${TF_VAR_name_suffix}\"" || {
  echo "Group state check failed" >&2
  exit 1
}

terraform_cmd state show haproxy-dataplane_cache.itest | grep -q "id   = \"cache_${TF_VAR_name_suffix}\"" || {
  echo "Cache state check failed" >&2
  exit 1
}

terraform_cmd state show haproxy-dataplane_log_profile.itest | grep -q "id   = \"log_profile_${TF_VAR_name_suffix}\"" || {
  echo "Log profile state check failed" >&2
  exit 1
}

echo "Integration test passed: traffic, service discovery, acme, and additional typed resource CRUD checks succeeded."

terraform_cmd destroy -auto-approve -parallelism=1
popd >/dev/null

echo "Integration test complete."
