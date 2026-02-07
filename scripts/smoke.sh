#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BIN_DIR="$ROOT_DIR/bin"
EXAMPLE_DIR="$ROOT_DIR/examples/smoke"

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
go build -o "$BIN_DIR/terraform-provider-haproxy-dataplane" "$ROOT_DIR"

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

echo "Initializing terraform..."
terraform init -plugin-dir "$BIN_DIR"

echo "Applying smoke config..."
terraform apply -auto-approve

echo "Destroying smoke config..."
terraform destroy -auto-approve

popd >/dev/null

echo "Smoke test complete."
