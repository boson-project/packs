#!/usr/bin/env bash

set -euo pipefail
set -o xtrace

VERSION="${2-tip}"
REPOSITORY="ghcr.io/boson-project"
PACK_CMD=${PACK_CMD:-pack}

BUILDPACKS=(boson go)

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

make_test() {
  # Try building in a directory known not to have a func.yaml and look for "Knative Function project not detected"
  local OUT=`$PACK_CMD build boson-func-test --pull-policy if-not-present --buildpack ghcr.io/boson-project/boson-function-buildpack:tip  -v --trust-builder --builder gcr.io/paketo-buildpacks/builder:base --path ./test/testdata`
  echo $OUT | grep "Knative Function project not detected"

  # Try building in a directory with a func.yaml and expect no errors
  mkdir -p ./test/testdata/func && touch ./test/testdata/func/func.yaml
	$PACK_CMD build boson-func-test --pull-policy if-not-present --buildpack ghcr.io/boson-project/boson-function-buildpack:tip  -v --trust-builder --builder gcr.io/paketo-buildpacks/builder:base --path ./test/testdata/func
}

case $1 in
  "buildpacks")
    make_buildpacks
    ;;
  "publish")
    make_publish
    ;;
  "test")
    make_test
    ;;
  *)
    echo "invalid command"
    exit 1
    ;;
esac
