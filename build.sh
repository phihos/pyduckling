#!/usr/bin/env bash

set -euo pipefail

cd "${0%/*}" || exit # go to script dir

# load common vars
source build-vars.sh

export USER_HOME_CACHE_PATH="$(pwd)"/.cache/userhome
export STATIC_LIB_CONTAINER_NAME="pyduckling-build-static-lib"
export PYDUCKLING_CONTAINER_NAME="pyduckling-build-wheel"

if ! command -v docker &> /dev/null
then
    echo "docker could not be found"
    exit 1
fi

function cleanup {
  docker rm -f "${STATIC_LIB_CONTAINER_NAME}" > /dev/null 2>&1 || true
  for python3_version in $$PYTHON3_VERSION_RANGE; do
    CONTAINER_NAME="${PYDUCKLING_CONTAINER_NAME}-${python3_version}"
    docker rm -f "${CONTAINER_NAME}" > /dev/null 2>&1 || true
  done
}
trap cleanup EXIT

function build_or_pull_pyduckling_build_image {
  python3_version=$1
  BUILD_IMAGE=$(build_image_pyduckling_for_python3_version "$python3_version")
  if docker manifest inspect "${BUILD_IMAGE}" > /dev/null 2>&1; then
    echo "Image \"${BUILD_IMAGE}\" already available. Skipping build..."
  else
    echo "Building \"${BUILD_IMAGE}\"..."
    export PYTHON3_VERSION=$python3_version
    containers/pyduckling/build.sh
  fi
}
export -f build_or_pull_pyduckling_build_image

function build_python_package() {
  python3_version=$1
  BUILD_IMAGE=$(build_image_pyduckling_for_python3_version "$python3_version")
  CONTAINER_NAME="${PYDUCKLING_CONTAINER_NAME}-${python3_version}"
  VENV_NAME="venv-3.${python3_version}"
  docker run \
    --mount type=bind,source="$(pwd)",target=/repo \
    --mount type=bind,source="${USER_HOME_CACHE_PATH}",target=/userhome \
    --user "$(id -u):$(id -g)" \
    --name "${CONTAINER_NAME}" \
    -e GHC_VERSION \
    -e HOME=/userhome \
    -e VENV="/userhome/${VENV_NAME}" \
    --detach \
    "${BUILD_IMAGE}" \
    sleep infinity
  docker exec "${CONTAINER_NAME}" bash -c 'if [[ ! -d "$HOME/venv" ]]; then python3 -m venv "$VENV"; fi'
  docker exec "${CONTAINER_NAME}" bash -c 'source "$VENV/bin/activate" && pip install pytest pendulum'
  docker exec "${CONTAINER_NAME}" bash -c 'source "$VENV/bin/activate" && cd /repo && maturin develop'
  docker exec "${CONTAINER_NAME}" bash -c 'source "$VENV/bin/activate" && cd /repo && pytest -v duckling/tests'
  docker exec "${CONTAINER_NAME}" bash -c 'source "$VENV/bin/activate" && cd /repo && maturin build -r --sdist'
  docker rm -f "${CONTAINER_NAME}" > /dev/null 2>&1 || true
}
export -f build_python_package

if docker manifest inspect "${BUILD_IMAGE_DUCKLING_FFI}" > /dev/null 2>&1; then
  echo "Image \"${BUILD_IMAGE_DUCKLING_FFI}\" already available. Skipping build..."
else
  echo "Building \"${BUILD_IMAGE_DUCKLING_FFI}\"..."
  containers/duckling-ffi/build.sh
fi

echo -n $PYTHON3_VERSION_RANGE | parallel -j0 --halt now,fail=1  -d ' ' 'build_or_pull_pyduckling_build_image {}'

mkdir -p "${USER_HOME_CACHE_PATH}"

echo "Building statically linked \"libducklingffi.a\"..."
docker run \
  --mount type=bind,source="$(pwd)"/duckling-ffi,target=/duckling-ffi \
  --mount type=bind,source="${USER_HOME_CACHE_PATH}",target=/userhome \
  --user "$(id -u):$(id -g)" \
  --name "${STATIC_LIB_CONTAINER_NAME}" \
  -e HOME=/userhome \
  --detach \
  "${BUILD_IMAGE_DUCKLING_FFI}" \
  sleep infinity
docker exec "${STATIC_LIB_CONTAINER_NAME}" bash -c 'cd /duckling-ffi && stack build --no-install-ghc --system-ghc --allow-different-user'
docker cp "${STATIC_LIB_CONTAINER_NAME}:/duckling-ffi/libducklingffi.a" ext_lib/libducklingffi.a
docker rm -f "${STATIC_LIB_CONTAINER_NAME}" > /dev/null 2>&1 || true

echo "Building wheel for all python versions..."
echo -n $PYTHON3_VERSION_RANGE | parallel -j0 --halt now,fail=1  -d ' ' 'build_python_package {}'