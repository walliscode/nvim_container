#!/usr/bin/env bash
check_internet_is_unreachable() {
  if in_container 'curl -sS -m 5 https://example.com >/dev/null 2>&1'; then
    echo "container reached the internet" >&2
    return 1
  fi
}
