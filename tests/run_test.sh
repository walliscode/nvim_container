#!/usr/bin/env bash
# shellcheck disable=SC2016 # fixture check bodies are intentionally single-quoted
# Tests for tests/run.sh and tests/build-and-test.sh. Each test runs against fixture images and fixture checks.
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1

failures=0
fixture=$(mktemp -d)
FIXTURE_IMAGE="nvim-container-fixture-$$"
BT_BASE="nvim-container-bt-$$"
# shellcheck disable=SC2329 # invoked by the EXIT trap
cleanup() {
  rm -rf "$fixture"
  docker image rm -f "$FIXTURE_IMAGE" >/dev/null 2>&1
  docker image ls -q --filter "reference=$BT_BASE*" | xargs -r docker image rm -f >/dev/null 2>&1
}
trap cleanup EXIT

mkdir -p "$fixture/context"
printf 'FROM debian:bookworm-slim\n' > "$fixture/context/Dockerfile"
docker build -q -t "$FIXTURE_IMAGE" "$fixture/context" >/dev/null || { echo "FAIL: could not build fixture image" >&2; exit 1; }

mkdir -p "$fixture/broken"
printf 'FROM debian:bookworm-slim\nRUN false\n' > "$fixture/broken/Dockerfile"

if [[ -n "$(git status --porcelain)" ]]; then
  echo "FAIL: commit or stash changes before running tests (build-and-test needs a clean tree)" >&2
  exit 1
fi

new_checks() {
  local dir="$fixture/checks-$1"
  mkdir -p "$dir"
  cat > "$dir/checks.sh" <<EOF
#!/usr/bin/env bash
$2
EOF
  echo "$dir"
}

run_harness() {
  NVIM_TEST_IMAGE="$FIXTURE_IMAGE" NVIM_TEST_CHECKS_DIR="$1" tests/run.sh
}

build_and_test() {
  NVIM_IMAGE_NAME="$1" NVIM_TEST_CONTEXT="$2" NVIM_TEST_CHECKS_DIR="$3" tests/build-and-test.sh
}

report() {
  local name=$1 ok=$2
  if [[ "$ok" == yes ]]; then
    echo "PASS: $name"
  else
    echo "FAIL: $name" >&2
    failures=$((failures + 1))
  fi
}

test_passing_check_exits_zero() {
  local dir out status ok=no
  dir=$(new_checks pass 'check_always_passes() { return 0; }')
  out=$(run_harness "$dir" 2>&1); status=$?
  [[ $status -eq 0 && "$out" == *"PASS: check_always_passes"* ]] && ok=yes
  report "passing check exits zero and is reported" "$ok"
}

test_failing_check_exits_nonzero_and_is_named() {
  local dir out status ok=no
  dir=$(new_checks fail 'check_always_fails() { return 1; }')
  out=$(run_harness "$dir" 2>&1); status=$?
  [[ $status -ne 0 && "$out" == *"FAIL: check_always_fails"* ]] && ok=yes
  report "failing check exits non-zero and is named" "$ok"
}

test_checks_run_on_internal_network() {
  local dir out status ok=no
  dir=$(new_checks internal 'check_network_is_internal() { [[ "$(docker network inspect "$NETWORK" --format "{{.Internal}}")" == true ]]; }')
  out=$(run_harness "$dir" 2>&1); status=$?
  [[ $status -eq 0 && "$out" == *"PASS: check_network_is_internal"* ]] && ok=yes
  report "checks run on an internal network" "$ok"
}

test_checks_run_against_given_image() {
  local dir out status ok=no
  dir=$(new_checks image "check_runs_given_image() { [[ \"\$TEST_IMAGE\" == '$FIXTURE_IMAGE' ]]; }")
  out=$(run_harness "$dir" 2>&1); status=$?
  [[ $status -eq 0 && "$out" == *"PASS: check_runs_given_image"* ]] && ok=yes
  report "checks run against the image they are given" "$ok"
}

test_run_requires_an_image() {
  local dir status ok=no
  dir=$(new_checks noimage 'check_always_passes() { return 0; }')
  env -u NVIM_TEST_IMAGE NVIM_TEST_CHECKS_DIR="$dir" tests/run.sh >/dev/null 2>&1; status=$?
  [[ $status -ne 0 ]] && ok=yes
  report "run exits non-zero without an image" "$ok"
}

test_network_removed_and_image_kept_after_run() {
  local dir out status ok=no marker="$fixture/names"
  dir=$(new_checks cleanup "check_records_network() { echo \"\$NETWORK\" > '$marker'; }")
  out=$(run_harness "$dir" 2>&1); status=$?
  if [[ $status -eq 0 && -s "$marker" ]]; then
    read -r network < "$marker"
    if [[ -z "$(docker network ls -q -f "name=^${network}$")" && -n "$(docker images -q "$FIXTURE_IMAGE")" ]]; then
      ok=yes
    fi
  fi
  report "network is removed and the given image is kept after run" "$ok"
}

test_build_and_test_keeps_tags_on_pass() {
  local name="$BT_BASE-pass" dir out status ok=no versioned
  dir=$(new_checks bt-pass 'check_always_passes() { return 0; }')
  out=$(build_and_test "$name" "$fixture/context" "$dir" 2>&1); status=$?
  versioned=$(docker image ls --format '{{.Tag}}' "$name" | grep -c '^0\.12\.6-')
  if [[ $status -eq 0 \
     && -n "$(docker image ls -q "$name:latest")" \
     && $versioned -ge 1 \
     && -z "$(docker image ls -q "$name:candidate")" \
     && "$out" == *"Total image size:"* ]]; then
    ok=yes
  fi
  report "build-and-test keeps latest and versioned tags on pass, removes candidate, prints size" "$ok"
}

test_build_and_test_removes_image_on_failing_check() {
  local name="$BT_BASE-fail" dir out status ok=no
  dir=$(new_checks bt-fail 'check_always_fails() { return 1; }')
  out=$(build_and_test "$name" "$fixture/context" "$dir" 2>&1); status=$?
  if [[ $status -ne 0 \
     && -z "$(docker image ls -q "$name")" ]]; then
    ok=yes
  fi
  report "build-and-test removes every tag and exits non-zero on a failing check" "$ok"
}

test_build_and_test_removes_image_on_failing_build() {
  local name="$BT_BASE-broken" dir out status ok=no
  dir=$(new_checks bt-broken 'check_always_passes() { return 0; }')
  out=$(build_and_test "$name" "$fixture/broken" "$dir" 2>&1); status=$?
  if [[ $status -ne 0 && -z "$(docker image ls -q "$name")" ]]; then
    ok=yes
  fi
  report "build-and-test writes no tags and exits non-zero when the build fails" "$ok"
}

test_build_and_test_refuses_dirty_tree() {
  local name="$BT_BASE-dirty" dir out status ok=no probe="tests/.dirty-probe-$$"
  dir=$(new_checks bt-dirty 'check_always_passes() { return 0; }')
  : > "$probe"
  out=$(build_and_test "$name" "$fixture/context" "$dir" 2>&1); status=$?
  rm -f "$probe"
  if [[ $status -ne 0 && "$out" == *"uncommitted"* && -z "$(docker image ls -q "$name")" ]]; then
    ok=yes
  fi
  report "build-and-test refuses to tag a build from an uncommitted tree" "$ok"
}

test_passing_check_exits_zero
test_failing_check_exits_nonzero_and_is_named
test_checks_run_on_internal_network
test_checks_run_against_given_image
test_run_requires_an_image
test_network_removed_and_image_kept_after_run
test_build_and_test_keeps_tags_on_pass
test_build_and_test_removes_image_on_failing_check
test_build_and_test_removes_image_on_failing_build
test_build_and_test_refuses_dirty_tree

exit "$failures"
