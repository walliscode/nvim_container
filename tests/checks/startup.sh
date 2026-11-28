#!/usr/bin/env bash
check_nvim_starts_on_internal_network() {
  local version
  version=$(docker run --rm --network "$NETWORK" "$TEST_IMAGE" \
    nvim --headless -c "lua local v = vim.version(); io.write(v.major .. '.' .. v.minor .. '.' .. v.patch)" -c 'qa!' 2>&1) \
    || { echo "nvim did not start: $version" >&2; return 1; }
  [[ "$version" == "$NVIM_VERSION" ]] \
    || { echo "expected Neovim v$NVIM_VERSION, got: $version" >&2; return 1; }
}
