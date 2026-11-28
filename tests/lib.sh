#!/usr/bin/env bash
export NVIM_VERSION="0.12.6"

in_container() {
  docker run --rm --network "$NETWORK" --entrypoint sh "$TEST_IMAGE" -c "$1"
}
