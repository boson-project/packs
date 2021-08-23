#!/usr/bin/env bash

set -euo pipefail
set -o xtrace

VERSION="${2-tip}"
REPOSITORY="ghcr.io/boson-project"
PACK_CMD=${PACK_CMD:-pack}

BUILDPACKS=(go typescript)

buildpack_to_img() { echo "${REPOSITORY}/${1}-function-buildpack:${2}"; }

make_buildpacks() {
  for BUILDPACK in "${BUILDPACKS[@]}"; do
    local BP_PATH="./buildpacks/${BUILDPACK}/"
    $PACK_CMD buildpack package "$(buildpack_to_img "${BUILDPACK}" "${VERSION}")" \
    --pull-policy never \
    --path "${BP_PATH}"
  done
}

make_publish() {
  local TO_PUSH=()

  for BUILDPACK in "${BUILDPACKS[@]}"; do
    TO_PUSH+=("$(buildpack_to_img "${BUILDPACK}" "${VERSION}")")
  done

  for IMG in "${TO_PUSH[@]}"; do
    docker push "${IMG}"
  done
}

case $1 in
  "buildpacks")
    make_buildpacks
    ;;
  "publish")
  make_publish
  ;;
  *)
    echo "invalid command"
    exit 1
    ;;
esac
