#!/usr/bin/env bash
PLUGIN_DIR=/home/dev/.config/nvim/pack/vendor/start

plugin_loads() {
  local module=$1 name=$2
  in_container "nvim --headless -c \"lua if not pcall(require, '$module') then vim.cmd('cquit 1') end\" -c 'qa!'" >/dev/null 2>&1 \
    || { echo "$name did not load from $PLUGIN_DIR" >&2; return 1; }
}

plugin_pinned() {
  local var=$1 name=$2
  grep -qE "^ARG ${var}=[0-9a-f]{40}$" Dockerfile \
    || { echo "$name is not pinned to a full commit in Dockerfile (ARG $var)" >&2; return 1; }
}

check_plenary_loads() { plugin_loads plenary.path plenary.nvim; }
check_plenary_is_pinned() { plugin_pinned PLENARY_REV plenary.nvim; }

check_lspconfig_loads() { plugin_loads lspconfig nvim-lspconfig; }
check_lspconfig_is_pinned() { plugin_pinned LSPCONFIG_REV nvim-lspconfig; }

check_cmp_loads() { plugin_loads cmp nvim-cmp; }
check_cmp_is_pinned() { plugin_pinned CMP_REV nvim-cmp; }

check_treesitter_loads() { plugin_loads nvim-treesitter nvim-treesitter; }
check_treesitter_is_pinned() { plugin_pinned TREESITTER_REV nvim-treesitter; }

check_telescope_loads() { plugin_loads telescope telescope.nvim; }
check_telescope_is_pinned() { plugin_pinned TELESCOPE_REV telescope.nvim; }

check_gitsigns_loads() { plugin_loads gitsigns gitsigns.nvim; }
check_gitsigns_is_pinned() { plugin_pinned GITSIGNS_REV gitsigns.nvim; }

check_git_is_installed_for_gitsigns() {
  in_container 'command -v git' >/dev/null 2>&1 \
    || { echo "git is not on PATH; gitsigns aborts setup without it" >&2; return 1; }
}

check_gitsigns_setup_is_silent_at_startup() {
  local out
  out=$(in_container "nvim --headless -c 'qa!' 2>&1") || { echo "nvim failed at startup" >&2; return 1; }
  [[ -z "$out" ]] || { echo "startup printed errors: $out" >&2; return 1; }
}

check_only_the_six_plugins_are_vendored() {
  local expected actual
  expected=$(printf '%s\n' gitsigns.nvim nvim-cmp nvim-lspconfig nvim-treesitter plenary.nvim telescope.nvim | sort)
  actual=$(in_container "ls $PLUGIN_DIR" | sort)
  [[ "$actual" == "$expected" ]] \
    || { echo "vendored plugins differ from the reviewed six:" >&2; echo "$actual" >&2; return 1; }
}

check_no_plugin_manager_runs_at_startup() {
  in_container "nvim --headless -c \"lua if package.loaded['lazy'] or package.loaded['packer'] then vim.cmd('cquit 1') end\" -c 'qa!'" >/dev/null 2>&1 \
    || { echo "a plugin manager was loaded at startup" >&2; return 1; }
}
