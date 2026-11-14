#!/usr/bin/env sh
# Detached GPG signature over dist/*_SHA256SUMS with the Terraform Registry
# signing key from Vault (job sign:gpg, alpine image, tag pipelines).
#
# The key is checked against scripts/terraform-registry-signing-key.asc, the
# public key registered for the pderuiter namespace: a different key in Vault
# would produce releases the Registry rejects, so it fails here instead.
set -eu

: "${VAULT_SECRET_BASE:?}"
apk add --no-cache gnupg curl jq >/dev/null

sums="$(ls dist/*_SHA256SUMS)"
[ "$(printf '%s\n' "${sums}" | wc -l)" -eq 1 ] || { echo "ERROR: expected one SHA256SUMS in dist/" >&2; exit 1; }

GNUPGHOME="$(mktemp -d)"
export GNUPGHOME
trap 'gpgconf --kill gpg-agent 2>/dev/null || true; rm -rf "${GNUPGHOME}"' EXIT
printf 'allow-loopback-pinentry\n' >"${GNUPGHOME}/gpg-agent.conf"

expected="$(gpg --batch --with-colons --show-keys scripts/terraform-registry-signing-key.asc | awk -F: '$1=="fpr"{print $10; exit}')"

# shellcheck source=scripts/vault.sh
. scripts/vault.sh
vault_login
vault_kv "${VAULT_SECRET_BASE}/gpg" private_key | gpg --batch --quiet --import
passphrase="$(vault_kv "${VAULT_SECRET_BASE}/gpg" passphrase 2>/dev/null || true)"

if ! gpg --batch --list-secret-keys "${expected}" >/dev/null 2>&1; then
  echo "ERROR: the key in Vault is not ${expected}, the key registered with the Terraform Registry" >&2
  exit 1
fi

printf '%s' "${passphrase}" | gpg --batch --yes --pinentry-mode loopback --passphrase-fd 0 \
  --local-user "${expected}" --output "${sums}.sig" --detach-sign "${sums}"
unset passphrase

# Verify with the public key only, in a clean keyring, as the Registry does.
verify_home="$(mktemp -d)"
GNUPGHOME="${verify_home}" gpg --batch --quiet --import scripts/terraform-registry-signing-key.asc
GNUPGHOME="${verify_home}" gpg --batch --verify "${sums}.sig" "${sums}"
rm -rf "${verify_home}"
echo "Signed ${sums} with ${expected}"
