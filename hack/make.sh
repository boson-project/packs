#!/usr/bin/env bash

set -euo pipefail
set -o xtrace

VERSION="${2-tip}"
REPOSITORY="ghcr.io/boson-project"
PACK_CMD=${PACK_CMD:-pack}

BUILDPACKS=(go)
BUILDERS=(go)

buildpack_to_img() { echo "${REPOSITORY}/${1}-function-buildpack:${2}"; }
builder_to_img() { echo "${REPOSITORY}/${1}-function-builder:${2}"; }

make_buildpacks() {
  for BUILDPACK in "${BUILDPACKS[@]}"; do
    local BP_PATH="./buildpacks/${BUILDPACK}/"
    $PACK_CMD buildpack package "$(buildpack_to_img "${BUILDPACK}" "${VERSION}")" \
    --pull-policy if-not-present \
    --path "${BP_PATH}"
  done
}

make_builders() {
  for BUILDER in "${BUILDERS[@]}"; do
    $PACK_CMD builder create "$(builder_to_img "${BUILDER}" "${VERSION}")" --config "./builders/${BUILDER}/builder.toml"
  done
}

make_publish() {
  local TO_PUSH=()

  for BUILDPACK in "${BUILDPACKS[@]}"; do
    TO_PUSH+=("$(buildpack_to_img "${BUILDPACK}" "${VERSION}")")
  done

  for BUILDER in "${BUILDERS[@]}"; do
    TO_PUSH+=("$(builder_to_img "${BUILDER}" "${VERSION}")")
  done

  for IMG in "${TO_PUSH[@]}"; do
    docker push "${IMG}"
  done
}

case $1 in
  "buildpacks")
    make_buildpacks
    ;;
  "builders")
    make_builders
    ;;
  "publish")
  make_publish
  ;;
  *)
    echo "invalid command"
    exit 1
    ;;
esac
