#!/usr/bin/env sh
# Publish release $CI_COMMIT_TAG on GitHub, which is where the Terraform
# Registry ingests it (job publish:github, alpine image, tag pipelines).
#
# Nothing is built here. The files come from Nexus (publish:nexus stored them
# there), are verified -- SHA256SUMS against the zips and manifest, the GPG
# signature against scripts/terraform-registry-signing-key.asc -- and only
# then copied to GitHub:
#
#  1. mirror the tag (and so its commit) to GitHub;
#  2. create the release as a DRAFT and upload the Registry asset set;
#  3. publish the draft: only a published release is visible to the Registry,
#     so it never sees a half-uploaded one;
#  4. create the GitLab release, linking Nexus, GitHub and the Registry.
#
# Idempotent: a published GitHub release is left alone (only checked); a
# leftover draft from an aborted run is deleted and redone.
set -eu

: "${CI_COMMIT_TAG:?tag pipelines only}"
: "${GITHUB_REPOSITORY:?}" "${VAULT_GITHUB_PATH:?}" "${VAULT_NEXUS_PATH:?}"
: "${NEXUS_URL:?}" "${NEXUS_RAW_REPO:?}"
apk add --no-cache git gnupg curl jq >/dev/null
git config --global --add safe.directory "$(pwd)"

tag="${CI_COMMIT_TAG}"
version="${tag#v}"
prefix="terraform-provider-haproxy-dataplane_${version}"
nexus_base="${NEXUS_URL}/repository/${NEXUS_RAW_REPO}/pderuiter/haproxy-dataplane/${version}"
api="https://api.github.com/repos/${GITHUB_REPOSITORY}"
work="$(mktemp -d)"
trap 'rm -rf "${work}"' EXIT

# shellcheck source=scripts/vault.sh
. scripts/vault.sh
vault_login
GITHUB_TOKEN="$(vault_kv "${VAULT_GITHUB_PATH}" token)"
export GITHUB_TOKEN
host="$(printf '%s' "${NEXUS_URL}" | sed -E 's#^https?://([^/:]+).*#\1#')"
printf 'machine %s login %s password %s\n' "${host}" \
  "$(vault_kv "${VAULT_NEXUS_PATH}" username)" "$(vault_kv "${VAULT_NEXUS_PATH}" password)" >"${work}/netrc"

gh_api() {
  curl -sS -H "Authorization: Bearer ${GITHUB_TOKEN}" -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: 2022-11-28" "$@"
}

# --- fetch from Nexus and verify ---------------------------------------------
mkdir -p "${work}/assets"
curl -sS --fail --netrc-file "${work}/netrc" -o "${work}/assets/${prefix}_SHA256SUMS" "${nexus_base}/${prefix}_SHA256SUMS"
curl -sS --fail --netrc-file "${work}/netrc" -o "${work}/assets/${prefix}_SHA256SUMS.sig" "${nexus_base}/${prefix}_SHA256SUMS.sig"
awk '{print $2}' "${work}/assets/${prefix}_SHA256SUMS" | while read -r name; do
  curl -sS --fail --netrc-file "${work}/netrc" -o "${work}/assets/${name}" "${nexus_base}/${name}"
done
(cd "${work}/assets" && sha256sum -c "${prefix}_SHA256SUMS")
grep -q "  ${prefix}_manifest.json\$" "${work}/assets/${prefix}_SHA256SUMS" \
  || { echo "ERROR: SHA256SUMS does not cover the manifest" >&2; exit 1; }

GNUPGHOME="${work}/gnupg"
export GNUPGHOME
mkdir -m 700 "${GNUPGHOME}"
gpg --batch --quiet --import scripts/terraform-registry-signing-key.asc
gpg --batch --verify "${work}/assets/${prefix}_SHA256SUMS.sig" "${work}/assets/${prefix}_SHA256SUMS"
gpgconf --kill gpg-agent 2>/dev/null || true
echo "Verified $(ls "${work}/assets" | wc -l) files from ${nexus_base}/"

# --- 1. tag -------------------------------------------------------------------
scripts/github-mirror.sh tag "${tag}"

# --- 2./3. GitHub release -----------------------------------------------------
release="$(gh_api "${api}/releases/tags/${tag}")"
if [ "$(printf '%s' "${release}" | jq -r '.draft // empty')" = "false" ]; then
  # Published already: check it carries what Nexus holds, never change it.
  missing=""
  for f in "${work}"/assets/*; do
    n="$(basename "${f}")"
    printf '%s' "${release}" | jq -e --arg n "${n}" '.assets[] | select(.name == $n)' >/dev/null || missing="${missing} ${n}"
  done
  if [ -n "${missing}" ]; then
    echo "ERROR: published GitHub release ${tag} lacks:${missing}. Published releases are not edited; fix by hand after checking why." >&2
    exit 1
  fi
  echo "GitHub release ${tag} is already published with every asset."
else
  # Drafts are not visible through releases/tags/<tag>; find leftovers by name.
  gh_api "${api}/releases?per_page=50" | jq -r --arg t "${tag}" '.[] | select(.draft and .tag_name == $t) | .id' |
    while read -r id; do
      echo "Deleting leftover draft release ${id}"
      gh_api -X DELETE "${api}/releases/${id}" >/dev/null
    done

  prerelease=false
  case "${version}" in *-*) prerelease=true ;; esac
  scripts/release-notes.sh "${tag}" >"${work}/notes.md"
  printf '\nBuilt and signed on GitLab CI (%s); also stored in Nexus.\n' "${CI_PIPELINE_URL:-}" >>"${work}/notes.md"
  jq -n --arg tag "${tag}" --rawfile body "${work}/notes.md" --argjson pre "${prerelease}" \
    '{tag_name: $tag, name: $tag, body: $body, draft: true, prerelease: $pre}' >"${work}/release.json"
  created="$(gh_api -X POST --fail-with-body --data @"${work}/release.json" "${api}/releases")"
  id="$(printf '%s' "${created}" | jq -r .id)"
  upload="https://uploads.github.com/repos/${GITHUB_REPOSITORY}/releases/${id}/assets"
  for f in "${work}"/assets/*; do
    n="$(basename "${f}")"
    case "${n}" in
      *.zip) ctype=application/zip ;;
      *.json) ctype=application/json ;;
      *.sig) ctype=application/pgp-signature ;;
      *) ctype=text/plain ;;
    esac
    gh_api -X POST --fail-with-body -H "Content-Type: ${ctype}" --data-binary @"${f}" \
      "${upload}?name=${n}" >/dev/null
    echo "uploaded ${n}"
  done
  gh_api -X PATCH --fail-with-body --data '{"draft": false}' "${api}/releases/${id}" >/dev/null
  echo "Published GitHub release ${tag}"
fi

# --- 4. GitLab release --------------------------------------------------------
gl_status=$(curl -sS -o /dev/null -w '%{http_code}' -H "JOB-TOKEN: ${CI_JOB_TOKEN}" \
  "${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/releases/${tag}")
if [ "${gl_status}" != "200" ]; then
  gh_url="https://github.com/${GITHUB_REPOSITORY}/releases/tag/${tag}"
  reg_url="https://registry.terraform.io/providers/pderuiter/haproxy-dataplane/${version}"
  scripts/release-notes.sh "${tag}" >"${work}/notes.md"
  jq -n --arg tag "${tag}" --rawfile notes "${work}/notes.md" \
    --arg nexus "${nexus_base}/" --arg gh "${gh_url}" --arg reg "${reg_url}" '{
    name: $tag, tag_name: $tag, description: $notes,
    assets: {links: [
      {name: "Nexus (copy of record)", url: $nexus, link_type: "package"},
      {name: "GitHub release", url: $gh, link_type: "other"},
      {name: "Terraform Registry", url: $reg, link_type: "other"}
    ]}
  }' >"${work}/gitlab-release.json"
  curl -sS --fail-with-body -X POST -H "JOB-TOKEN: ${CI_JOB_TOKEN}" -H "Content-Type: application/json" \
    --data @"${work}/gitlab-release.json" "${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/releases" >/dev/null
  echo "GitLab release ${tag} created."
fi
