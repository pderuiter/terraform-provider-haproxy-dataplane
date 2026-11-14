#!/usr/bin/env sh
# Mirror the default branch, or one release tag, from GitLab (the source of
# truth) to the public GitHub repository the Terraform Registry reads.
#
#   scripts/github-mirror.sh branch      push $CI_DEFAULT_BRANCH (fast-forward only)
#   scripts/github-mirror.sh tag <tag>   push one tag (no-op if GitHub has it at the same commit)
#
# Needs GITHUB_TOKEN (contents: write on GITHUB_REPOSITORY) and a full clone.
# Never force-pushes: a commit made directly on GitHub makes the mirror fail
# loudly instead of being overwritten.
set -eu

: "${GITHUB_TOKEN:?GITHUB_TOKEN is not set}"
GITHUB_REPOSITORY="${GITHUB_REPOSITORY:-pderuiter/terraform-provider-haproxy-dataplane}"
remote="https://x-access-token:${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git"

git config --global --add safe.directory "$(pwd)" 2>/dev/null || true

case "${1:-}" in
  branch)
    branch="${CI_DEFAULT_BRANCH:-main}"
    sha="$(git rev-parse HEAD)"
    git push "${remote}" "${sha}:refs/heads/${branch}"
    echo "Mirrored ${branch} at ${sha} to github.com/${GITHUB_REPOSITORY}"
    ;;
  tag)
    tag="${2:?usage: $0 tag <tag>}"
    local_sha="$(git rev-parse "refs/tags/${tag}^{commit}")"
    # Peeled (^{}) line for annotated tags, plain line for lightweight ones.
    remote_sha="$(git ls-remote "${remote}" "refs/tags/${tag}^{}" "refs/tags/${tag}" | sort -r | awk 'NR==1{print $1}')"
    if [ -n "${remote_sha}" ]; then
      if [ "${remote_sha}" = "${local_sha}" ] || [ "$(git rev-parse "refs/tags/${tag}")" = "${remote_sha}" ]; then
        echo "Tag ${tag} already on GitHub at the same commit."
        exit 0
      fi
      echo "ERROR: tag ${tag} exists on GitHub at ${remote_sha}, not ${local_sha}. Released versions are immutable." >&2
      exit 1
    fi
    git push "${remote}" "refs/tags/${tag}:refs/tags/${tag}"
    echo "Mirrored tag ${tag} (${local_sha}) to github.com/${GITHUB_REPOSITORY}"
    ;;
  *)
    echo "usage: $0 branch | tag <tag>" >&2
    exit 2
    ;;
esac
