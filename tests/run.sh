#!/usr/bin/env bash
# Runs every check in tests/checks/ against the image in NVIM_TEST_IMAGE on a temporary internal network. Removes the network afterwards. Never builds or deletes an image.
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1

CHECKS_DIR="${NVIM_TEST_CHECKS_DIR:-tests/checks}"
TEST_IMAGE="${NVIM_TEST_IMAGE:?set NVIM_TEST_IMAGE to the image to test}"
NETWORK="nvim-container-test-$$"
export TEST_IMAGE NETWORK

# shellcheck source=/dev/null
source tests/lib.sh

# shellcheck disable=SC2329
cleanup() {
  docker network rm "$NETWORK" >/dev/null 2>&1 || true
}
trap cleanup EXIT

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
