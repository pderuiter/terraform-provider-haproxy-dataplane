#!/usr/bin/env sh
# Markdown release notes for tag $1 from the Conventional Commits since the
# previous release tag. Same grouping as the toolkit's version bump rules.
#
#   scripts/release-notes.sh v0.2.0 > notes.md
set -eu

tag="${1:?usage: $0 <tag>}"
prev="$(git describe --tags --abbrev=0 --match 'v[0-9]*.[0-9]*.[0-9]*' "${tag}^" 2>/dev/null || true)"
range="${prev:+${prev}..}${tag}"

section() {
  title="$1"
  pattern="$2"
  lines="$(git log --no-merges --format='%s (%h)' "${range}" | grep -E "${pattern}" || true)"
  if [ -n "${lines}" ]; then
    printf '### %s\n\n' "${title}"
    printf '%s\n' "${lines}" | sed 's/^/- /'
    printf '\n'
  fi
}

section "Breaking changes" '^[a-zA-Z]+(\([^)]*\))?!:'
section "Features" '^feat(\([^)]*\))?:'
section "Bug fixes" '^fix(\([^)]*\))?:'
section "Other changes" '^(docs|refactor|perf|test|build|ci|chore\([^d][^)]*\)|chore)(\([^)]*\))?:'

if [ -n "${prev}" ]; then
  printf 'Full diff: %s...%s\n' "${prev}" "${tag}"
fi
