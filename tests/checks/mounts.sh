#!/usr/bin/env bash
check_work_is_writable() {
  in_container 'touch /work/probe' >/dev/null 2>&1 \
    || { echo "/work is not writable by the container user" >&2; return 1; }
}
