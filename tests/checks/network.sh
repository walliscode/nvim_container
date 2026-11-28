#!/usr/bin/env bash
check_internet_is_unreachable() {
  if docker run --rm --network "$NETWORK" --entrypoint bash "$TEST_IMAGE" \
    -c 'timeout 5 bash -c "exec 3<>/dev/tcp/1.1.1.1/443"' >/dev/null 2>&1; then
    echo "container reached the internet" >&2
    return 1
  fi
}
