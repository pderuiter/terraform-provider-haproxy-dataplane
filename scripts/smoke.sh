#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BIN_DIR="$ROOT_DIR/bin"
EXAMPLE_DIR="$ROOT_DIR/examples/smoke"
PROVIDER_SOURCE="pderuiter/haproxy-dataplane"
PROVIDER_VERSION="0.1.0"

if ! command -v terraform >/dev/null 2>&1; then
  echo "terraform is required on PATH" >&2
  exit 1
fi

if ! command -v docker >/dev/null 2>&1; then
  echo "docker is required on PATH" >&2
  exit 1
fi

mkdir -p "$BIN_DIR"

echo "Building provider..."
GOOS="$(go env GOOS)"
GOARCH="$(go env GOARCH)"
MIRROR_DIR="$BIN_DIR/terraform-mirror"
PLUGIN_DIR="$MIRROR_DIR/registry.terraform.io/$PROVIDER_SOURCE/$PROVIDER_VERSION/${GOOS}_${GOARCH}"
PLUGIN_BIN="$PLUGIN_DIR/terraform-provider-haproxy-dataplane_v$PROVIDER_VERSION"
mkdir -p "$PLUGIN_DIR"
go build -o "$PLUGIN_BIN" "$ROOT_DIR"
chmod +x "$PLUGIN_BIN"

CLI_CONFIG="$(mktemp)"
trap 'rm -f "$CLI_CONFIG"' EXIT
cat > "$CLI_CONFIG" <<EOF
provider_installation {
  filesystem_mirror {
    path    = "$MIRROR_DIR"
    include = ["$PROVIDER_SOURCE"]
  }
  direct {}
}
EOF
export TF_CLI_CONFIG_FILE="$CLI_CONFIG"

echo "Starting HAProxy container..."
( cd "$ROOT_DIR" && docker compose up -d )

PASSWORD_LINE=$(awk '/user admin insecure-password/ {print $0; exit}' "$ROOT_DIR/dev/haproxy/haproxy.cfg")
if [ -z "$PASSWORD_LINE" ]; then
  echo "Failed to read admin password from dev/haproxy/haproxy.cfg" >&2
  exit 1
fi

HAPROXY_ADMIN_PASSWORD=$(echo "$PASSWORD_LINE" | awk '{print $4}')
if [ -z "$HAPROXY_ADMIN_PASSWORD" ]; then
  echo "Failed to parse admin password" >&2
  exit 1
fi

export TF_VAR_haproxy_admin_password="$HAPROXY_ADMIN_PASSWORD"

pushd "$EXAMPLE_DIR" >/dev/null

rm -rf .terraform .terraform.lock.hcl

echo "Initializing terraform..."
terraform init

echo "Applying smoke config..."
terraform apply -auto-approve

echo "Destroying smoke config..."
terraform destroy -auto-approve

popd >/dev/null

echo "Smoke test complete."
