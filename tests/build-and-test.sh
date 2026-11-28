#!/usr/bin/env bash
# Builds the image as a candidate, runs every check against it, then tags it as latest and <nvim-version>-<git-sha> on pass, or removes it on fail.
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1

NAME="${NVIM_IMAGE_NAME:-nvim-container}"
CONTEXT="${NVIM_TEST_CONTEXT:-.}"
CHECKS_DIR="${NVIM_TEST_CHECKS_DIR:-tests/checks}"
CANDIDATE="$NAME:candidate"

VERSION=$(sed -n 's/^ARG NVIM_VERSION=//p' Dockerfile | head -n 1)
SHA=$(git rev-parse --short HEAD) || { echo "FAIL: not a git repository" >&2; exit 1; }
[[ -n "$(git status --porcelain)" ]] && SHA="$SHA-dirty"
VERSIONED="$NAME:$VERSION-$SHA"

remove_candidate() {
  docker image rm "$CANDIDATE" >/dev/null 2>&1 || true
}

docker build -t "$CANDIDATE" "$CONTEXT" || { echo "FAIL: image build" >&2; remove_candidate; exit 1; }

if NVIM_TEST_IMAGE="$CANDIDATE" NVIM_TEST_CHECKS_DIR="$CHECKS_DIR" tests/run.sh; then
  docker tag "$CANDIDATE" "$NAME:latest"
  docker tag "$CANDIDATE" "$VERSIONED"
  remove_candidate
  echo "Tagged $NAME:latest and $VERSIONED"
  echo "Total image size: $(docker image ls --format '{{.Size}}' "$NAME:latest" | head -n 1)"
  echo "Layer sizes:"
  docker history --format '  {{.Size}}\t{{.CreatedBy}}' "$NAME:latest" | cut -c1-120
else
  echo "FAIL: checks failed, removing candidate image" >&2
  remove_candidate
  exit 1
fi
