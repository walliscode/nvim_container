#!/usr/bin/env bash
# Builds the image and checks that Neovim starts on an internal-only network
# with no route to the internet.
set -euo pipefail

IMAGE="${IMAGE:-nvim-container:latest}"
NVIM_VERSION="0.12.6"
cd "$(dirname "$0")/.."

NETWORK="nvim-container-test-$$"

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

cleanup() {
  docker network rm "$NETWORK" >/dev/null 2>&1 || true
}
trap cleanup EXIT

docker build -t "$IMAGE" . || fail "image build"

docker network create --internal "$NETWORK" >/dev/null || fail "could not create internal network"

version=$(docker run --rm --network "$NETWORK" "$IMAGE" \
  nvim --headless -c "lua local v = vim.version(); io.write(v.major .. '.' .. v.minor .. '.' .. v.patch)" -c 'qa!' 2>&1) \
  || fail "nvim did not start on the internal network: $version"

[[ "$version" == "$NVIM_VERSION" ]] \
  || fail "expected Neovim v$NVIM_VERSION, got: $version"

no_plugins=$(docker run --rm --network "$NETWORK" --entrypoint sh "$IMAGE" \
  -c 'test ! -e /home/dev/.config/nvim/pack && echo yes') \
  || fail "could not inspect image"

[[ "$no_plugins" == "yes" ]] || fail "expected no vendored plugins in ticket 01"

docker run --rm --network "$NETWORK" --entrypoint sh "$IMAGE" \
  -c 'touch /work/probe' >/dev/null 2>&1 \
  || fail "/work is not writable by the container user"

if docker run --rm --network "$NETWORK" --entrypoint sh "$IMAGE" \
  -c 'curl -sS -m 5 https://example.com >/dev/null 2>&1'; then
  fail "container reached the internet"
fi

echo "PASS: Neovim v$NVIM_VERSION starts on the internal network with no internet route"
