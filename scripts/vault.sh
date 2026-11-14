# shellcheck shell=sh
# Vault access for release jobs, sourced: `. scripts/vault.sh`.
#
# Same approach as the ci-cd-toolkit's .vault_tf_state: one JWT login with
# the job's VAULT_ID_TOKEN, then KV v2 reads with curl + jq (the release
# image has no vault CLI).
#
# Needs: VAULT_ADDR, VAULT_ID_TOKEN (id_tokens in the job), RELEASE_VAULT_ROLE.
# TLS: Vault is verified against VAULT_CACERT_PEM: PEM content, or a path
# (default scripts/wbyc-root-ca.pem, the WBYC root CA, copied from the
# ci-cd-toolkit cosign template). There is deliberately no skip-verify
# switch: this connection hands out the release signing key.
#
#   vault_login
#   key=$(vault_kv wbyc/prd/infra/terraform-registry/gpg private_key)

_vault_fail() {
  echo "ERROR: $*" >&2
  exit 1
}

vault_login() {
  : "${VAULT_ADDR:?VAULT_ADDR is not set}"
  : "${VAULT_ID_TOKEN:?VAULT_ID_TOKEN is not set (id_tokens missing on the job?)}"
  : "${RELEASE_VAULT_ROLE:?RELEASE_VAULT_ROLE is not set}"

  _vault_ca="${VAULT_CACERT_PEM:-scripts/wbyc-root-ca.pem}"
  # Accept both GitLab variable types: a File variable expands to a path.
  case "${_vault_ca}" in
    *"BEGIN CERTIFICATE"*)
      printf '%s\n' "${_vault_ca}" >/tmp/vault-ca.pem
      _vault_ca=/tmp/vault-ca.pem
      ;;
  esac
  [ -r "${_vault_ca}" ] || _vault_fail "Vault CA ${_vault_ca} is not readable"
  _vault_curl="curl -sS --cacert ${_vault_ca}"

  _login=$(${_vault_curl} --data "{\"role\":\"${RELEASE_VAULT_ROLE}\",\"jwt\":\"${VAULT_ID_TOKEN}\"}" \
    "${VAULT_ADDR}/v1/auth/${VAULT_AUTH_PATH:-jwt}/login") || _vault_fail "could not reach Vault at ${VAULT_ADDR}"
  VAULT_TOKEN=$(printf '%s' "${_login}" | jq -r '.auth.client_token // empty')
  [ -n "${VAULT_TOKEN}" ] || _vault_fail "Vault JWT login as ${RELEASE_VAULT_ROLE} rejected: $(printf '%s' "${_login}" | jq -c '.errors')"
  unset _login
}

# vault_kv <path under secret/> <field>
vault_kv() {
  _resp=$(${_vault_curl} -H "X-Vault-Token: ${VAULT_TOKEN}" "${VAULT_ADDR}/v1/secret/data/$1") \
    || _vault_fail "could not read secret/$1"
  _val=$(printf '%s' "${_resp}" | jq -r --arg f "$2" '.data.data[$f] // empty')
  # A missing field and a missing grant look alike from here.
  [ -n "${_val}" ] || _vault_fail "field '$2' missing at secret/$1 (or no read grant: $(printf '%s' "${_resp}" | jq -c '.errors // empty'))"
  printf '%s' "${_val}"
  unset _resp _val
}
