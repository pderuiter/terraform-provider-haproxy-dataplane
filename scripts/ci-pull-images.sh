#!/usr/bin/env sh
# CI only: pull the images the integration scripts run through the Nexus
# Docker Hub proxy and tag them with the Docker Hub names those scripts and
# docker-compose.integration.yml use. The runner host's docker daemon has no
# registry mirror, so without this it would pull from Docker Hub directly.
# The names stay plain Docker Hub names in the files, so Renovate keeps
# updating them.
#
#   NEXUS_DOCKERHUB=nexus.bsdserver.nl:443/docker-hub scripts/ci-pull-images.sh
set -eu

: "${NEXUS_DOCKERHUB:?}"
cd "$(dirname "$0")/.."

{
  docker compose -f docker-compose.integration.yml config --images
  grep -ho '\(curlimages/curl\|hashicorp/terraform\):[^ ]*' scripts/registry_integration.sh scripts/registry_runtime_integration.sh
} | sort -u | while read -r image; do
  case "${image}" in
    */*) path="${image}" ;;
    *) path="library/${image}" ;;
  esac
  docker pull --quiet "${NEXUS_DOCKERHUB}/${path}"
  docker tag "${NEXUS_DOCKERHUB}/${path}" "${image}"
  echo "${image} <- ${NEXUS_DOCKERHUB}/${path}"
done
