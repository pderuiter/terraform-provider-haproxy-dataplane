#!/usr/bin/env bash
# End-to-end check of a published release: wait until the Terraform Registry
# lists the version, then `terraform init` it, which downloads the zip and
# verifies SHA256SUMS and its GPG signature against the key registered in
# the Registry -- the exact path every user takes.
#
#   VERSION=0.1.0 TERRAFORM=/path/to/terraform scripts/verify-registry.sh
set -euo pipefail

: "${VERSION:?set VERSION, e.g. 0.1.0}"
TERRAFORM="${TERRAFORM:-terraform}"
PROVIDER="${PROVIDER:-pderuiter/haproxy-dataplane}"
WAIT_SECONDS="${WAIT_SECONDS:-900}"

url="https://registry.terraform.io/v1/providers/${PROVIDER}/versions"
deadline=$(( $(date +%s) + WAIT_SECONDS ))
until curl -fsS "${url}" | grep -q "\"version\":\"${VERSION}\""; do
  if [ "$(date +%s)" -ge "${deadline}" ]; then
    echo "ERROR: ${PROVIDER} ${VERSION} not on the Registry after ${WAIT_SECONDS}s." >&2
    echo "Check that the GitHub release is published with every asset, then use" >&2
    echo "Resync on the provider's settings page in the Registry." >&2
    exit 1
  fi
  echo "Waiting for the Registry to ingest ${PROVIDER} ${VERSION}..."
  sleep 30
done

dir="$(mktemp -d)"
trap 'rm -rf "${dir}"' EXIT
cat >"${dir}/main.tf" <<EOF
terraform {
  required_providers {
    haproxy-dataplane = {
      source  = "${PROVIDER}"
      version = "= ${VERSION}"
    }
  }
}
EOF
# A clean CLI config: no dev_overrides or mirrors may short-circuit the check.
TF_CLI_CONFIG_FILE=/dev/null "${TERRAFORM}" -chdir="${dir}" init -input=false -no-color
"${TERRAFORM}" -chdir="${dir}" version
echo "Registry serves ${PROVIDER} ${VERSION} with a valid signature."
