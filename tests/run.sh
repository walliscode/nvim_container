#!/usr/bin/env bash
# Builds a temporary image, runs every check in tests/checks/ against it, then removes the image and network.
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1

CONTEXT="${NVIM_TEST_CONTEXT:-.}"
CHECKS_DIR="${NVIM_TEST_CHECKS_DIR:-tests/checks}"
TEST_IMAGE="nvim-container:test-$$"
NETWORK="nvim-container-test-$$"
export TEST_IMAGE NETWORK

# shellcheck source=/dev/null
source tests/lib.sh

# shellcheck disable=SC2329
cleanup() {
  docker network rm "$NETWORK" >/dev/null 2>&1 || true
  docker image rm "$TEST_IMAGE" >/dev/null 2>&1 || true
}
trap cleanup EXIT

docker build -t "$TEST_IMAGE" "$CONTEXT" || { echo "FAIL: image build" >&2; exit 1; }
docker network create --internal "$NETWORK" >/dev/null || { echo "FAIL: could not create internal network" >&2; exit 1; }

failed=0
for file in "$CHECKS_DIR"/*.sh; do
  # shellcheck source=/dev/null
  source "$file"
  for check in $(declare -F | awk '{print $3}' | grep '^check_'); do
    if "$check"; then
      echo "PASS: $check"
    else
      echo "FAIL: $check" >&2
      failed=1
    fi
    unset -f "$check"
  done
done

exit "$failed"
