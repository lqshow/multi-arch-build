#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

readonly PROJECT_ROOT=$(dirname "${BASH_SOURCE[0]}")/../..
source "${PROJECT_ROOT}/hack/lib/init.sh"

VERBOSE=${VERBOSE:-"0"}
# V=""
if [[ "${VERBOSE}" == "1" ]];then
    # V="-x"
    set -x
fi

OUTPUT_DIR=bin
BUILDPATH=./${1:?"path to build"}
OUT=${OUTPUT_DIR}/${1:?"output path"}

BUILD_GOOS=${GOOS:-$(go env GOOS)}
BUILD_GOARCH=${GOARCH:-$(go env GOARCH)}
GOBINARY=${GOBINARY:-go}
LDFLAGS=$(version::ldflags)

if [ $# -ge 2 ] && [ -n $2 ]; then
  BUILD_GOOS=$2
fi

if [ $# -ge 3 ] && [ -n $3 ]; then
  GOARCH=$3
fi

# forgoing -i (incremental build) because it will be deprecated by tool chain.
GOOS=${BUILD_GOOS} CGO_ENABLED=0 GOARCH=${BUILD_GOARCH} ${GOBINARY} build \
        -ldflags="${LDFLAGS}" \
        -o "${OUT}" \
        "${BUILDPATH}"
