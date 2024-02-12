#!/usr/bin/env bash

set -euo pipefail

cd "${0%/*}" || exit # go to script dir

source ../../build-vars.sh

docker buildx build \
  --build-arg="MATURIN_VERSION=${MATURIN_VERSION}" \
  --build-arg="PYTHON_VERSION=3.${PYTHON3_VERSION}" \
  -t "$(build_image_pyduckling_for_python3_version $PYTHON3_VERSION)" .

if [[ ${PUSH_IMAGES} ]]; then
  docker push "$(build_image_pyduckling_for_python3_version $PYTHON3_VERSION)"
fi
