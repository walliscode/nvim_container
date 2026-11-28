#!/usr/bin/env bash
check_no_vendored_plugins() {
  [[ "$(in_container 'test ! -e /home/dev/.config/nvim/pack && echo yes')" == "yes" ]] \
    || { echo "expected no vendored plugins" >&2; return 1; }
}
