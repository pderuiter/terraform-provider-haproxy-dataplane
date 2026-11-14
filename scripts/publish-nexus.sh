#!/usr/bin/env sh
# Store the signed release (dist/) in Nexus: the estate's copy of record.
#   ${NEXUS_URL}/repository/${NEXUS_RAW_REPO}/pderuiter/haproxy-dataplane/<version>/<file>
#
# The repository is ALLOW_ONCE, so a stored version cannot be replaced. A
# re-run uploads only what is missing and fails when a stored file differs
# from the one built now (a rebuild must never silently change a release).
set -eu

: "${CI_COMMIT_TAG:?tag pipelines only}"
: "${NEXUS_URL:?}" "${NEXUS_RAW_REPO:?}" "${VAULT_NEXUS_PATH:?}"
apk add --no-cache curl jq >/dev/null

version="${CI_COMMIT_TAG#v}"
base="${NEXUS_URL}/repository/${NEXUS_RAW_REPO}/pderuiter/haproxy-dataplane/${version}"

# shellcheck source=scripts/vault.sh
. scripts/vault.sh
vault_login
NEXUS_USER="$(vault_kv "${VAULT_NEXUS_PATH}" username)"
NEXUS_PASSWORD="$(vault_kv "${VAULT_NEXUS_PATH}" password)"
netrc="$(mktemp)"
trap 'rm -f "${netrc}"' EXIT
host="$(printf '%s' "${NEXUS_URL}" | sed -E 's#^https?://([^/:]+).*#\1#')"
printf 'machine %s login %s password %s\n' "${host}" "${NEXUS_USER}" "${NEXUS_PASSWORD}" >"${netrc}"
unset NEXUS_PASSWORD

uploaded=0
for f in dist/*.zip dist/*_SHA256SUMS dist/*_SHA256SUMS.sig dist/*_manifest.json dist/*.sigstore.json; do
  [ -f "${f}" ] || { echo "ERROR: missing ${f}" >&2; exit 1; }
  name="$(basename "${f}")"
  local_sum="$(sha256sum "${f}" | awk '{print $1}')"
  code="$(curl -sS --netrc-file "${netrc}" -o /tmp/remote -w '%{http_code}' "${base}/${name}")"
  if [ "${code}" = "200" ]; then
    if [ "$(sha256sum /tmp/remote | awk '{print $1}')" = "${local_sum}" ]; then
      echo "present  ${name}"
      continue
    fi
    echo "ERROR: ${base}/${name} exists with different content; a released version is immutable." >&2
    exit 1
  fi
  curl -sS --fail-with-body --netrc-file "${netrc}" --upload-file "${f}" "${base}/${name}" >/dev/null
  echo "uploaded ${name}"
  uploaded=$((uploaded + 1))
done
rm -f /tmp/remote
echo "Release ${version} in Nexus: ${base}/ (${uploaded} new files)"
