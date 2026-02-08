#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EXAMPLE_DIR="$ROOT_DIR/examples/registry-runtime-integration"
COMPOSE_FILE="$ROOT_DIR/docker-compose.integration.yml"
WORK_DIR="$(mktemp -d)"
HAPROXY_CONFIG_DIR="$WORK_DIR/haproxy-config"

if ! command -v terraform >/dev/null 2>&1; then
  echo "terraform is required on PATH" >&2
  exit 1
fi

if ! command -v docker >/dev/null 2>&1; then
  echo "docker is required on PATH" >&2
  exit 1
fi

if ! command -v go >/dev/null 2>&1; then
  echo "go is required on PATH" >&2
  exit 1
fi

compose() {
  docker compose -f "$COMPOSE_FILE" "$@"
}

NETWORK_NAME=""

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

mkdir -p "$HAPROXY_CONFIG_DIR"
cp -R "$ROOT_DIR/dev/haproxy/." "$HAPROXY_CONFIG_DIR/"

if ! grep -q "expose-experimental-directives" "$HAPROXY_CONFIG_DIR/haproxy.cfg"; then
  awk '
    /^global$/ { print; print "  expose-experimental-directives"; next }
    { print }
  ' "$HAPROXY_CONFIG_DIR/haproxy.cfg" > "$HAPROXY_CONFIG_DIR/haproxy.cfg.tmp"
  mv "$HAPROXY_CONFIG_DIR/haproxy.cfg.tmp" "$HAPROXY_CONFIG_DIR/haproxy.cfg"
fi

if [ -f "$HAPROXY_CONFIG_DIR/dataplaneapi.yml" ]; then
  sed 's#/var/run/haproxy/master.sock#/var/run/haproxy-master.sock#g' \
    "$HAPROXY_CONFIG_DIR/dataplaneapi.yml" > "$HAPROXY_CONFIG_DIR/dataplaneapi.yml.tmp"
  mv "$HAPROXY_CONFIG_DIR/dataplaneapi.yml.tmp" "$HAPROXY_CONFIG_DIR/dataplaneapi.yml"
fi

echo "Starting integration containers for runtime scenario..."
compose up -d
configure_haproxy_container
detect_network_name

cleanup() {
  set +e
  echo "Cleaning up runtime terraform state and containers..."
  (cd "$EXAMPLE_DIR" && terraform destroy -auto-approve -parallelism=1 >/dev/null 2>&1)
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
export TF_VAR_name_suffix="rtime$(date +%s)"

wait_http "http://haproxy:5555/v3/info" "HAProxy Data Plane API" "admin:${HAPROXY_ADMIN_PASSWORD}"
wait_http "http://consul:8500/v1/status/leader" "Consul"

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

mkdir -p /tmp/tf-dev-provider-runtime
go build -o /tmp/tf-dev-provider-runtime/terraform-provider-haproxy-dataplane "$ROOT_DIR"
cat > /tmp/tf-dev-runtime.tfrc <<'EOF'
provider_installation {
  dev_overrides {
    "pderuiter/haproxy-dataplane" = "/tmp/tf-dev-provider-runtime"
  }
  direct {}
}
EOF
export TF_CLI_CONFIG_FILE=/tmp/tf-dev-runtime.tfrc

pushd "$EXAMPLE_DIR" >/dev/null
rm -rf .terraform .terraform.lock.hcl terraform.tfstate*

echo "Initializing terraform for runtime scenario..."
terraform init

echo "Applying runtime integration module..."
terraform apply -auto-approve -parallelism=1

RUNTIME_BACKEND="be_http"
RUNTIME_SERVER="runtime-${TF_VAR_name_suffix}"

curl_via_network -fsS -u "admin:${HAPROXY_ADMIN_PASSWORD}" \
  "http://haproxy:5555/v3/services/haproxy/runtime/backends/${RUNTIME_BACKEND}/servers/${RUNTIME_SERVER}" \
  | grep -q "${RUNTIME_SERVER}" || {
    echo "Runtime backend server not found" >&2
    exit 1
  }

echo "Runtime integration test passed: runtime backend_server checks succeeded."

terraform destroy -auto-approve -parallelism=1
popd >/dev/null

echo "Runtime integration test complete."
