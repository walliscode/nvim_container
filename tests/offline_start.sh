#!/usr/bin/env bash
# Builds the image and checks that Neovim starts with no network.
set -euo pipefail

IMAGE="${IMAGE:-nvim-container:test}"
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

plugins=$(docker run --rm --network none --entrypoint sh "$IMAGE" \
  -c 'ls /home/dev/.config/nvim/pack 2>/dev/null | wc -l') \
  || fail "could not inspect image"

[[ "$plugins" -eq 0 ]] || fail "expected no vendored plugins in ticket 01"

echo "PASS: Neovim v$NVIM_VERSION starts offline"
