#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

readonly PROJECT_MODULE=github.com/lqshow/multi-arch-build
readonly SOURCE_DATE_EPOCH=$(git show -s --format=format:%ct HEAD)

source "${PROJECT_ROOT}/hack/lib/version.sh"