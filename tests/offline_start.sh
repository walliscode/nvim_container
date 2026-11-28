#!/usr/bin/env bash
# Builds the image and checks that Neovim starts with no network.
set -euo pipefail

IMAGE="${IMAGE:-nvim-container:latest}"
NVIM_VERSION="0.12.6"
cd "$(dirname "$0")/.."

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

docker build -t "$IMAGE" . || fail "image build"

version=$(docker run --rm --network none "$IMAGE" \
  nvim --headless -c "lua local v = vim.version(); io.write(v.major .. '.' .. v.minor .. '.' .. v.patch)" -c 'qa!' 2>&1) \
  || fail "nvim did not start with --network none: $version"

[[ "$version" == "$NVIM_VERSION" ]] \
  || fail "expected Neovim v$NVIM_VERSION, got: $version"

no_plugins=$(docker run --rm --network none --entrypoint sh "$IMAGE" \
  -c 'test ! -e /home/dev/.config/nvim/pack && echo yes') \
  || fail "could not inspect image"

[[ "$no_plugins" == "yes" ]] || fail "expected no vendored plugins in ticket 01"

docker run --rm --network none --entrypoint sh "$IMAGE" \
  -c 'touch /work/probe' >/dev/null 2>&1 \
  || fail "/work is not writable by the container user"

echo "PASS: Neovim v$NVIM_VERSION starts offline"
