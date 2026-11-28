#!/usr/bin/env bash
# shellcheck disable=SC2016 # fixture check bodies are intentionally single-quoted
# Tests for tests/run.sh. Each test runs the harness against a fixture image and fixture checks.
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1

failures=0
fixture=$(mktemp -d)
trap 'rm -rf "$fixture"' EXIT

mkdir -p "$fixture/context"
printf 'FROM debian:bookworm-slim\n' > "$fixture/context/Dockerfile"

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
  NVIM_TEST_CONTEXT="$fixture/context" NVIM_TEST_CHECKS_DIR="$1" tests/run.sh
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

test_checks_run_against_temporary_image() {
  local dir out status ok=no
  dir=$(new_checks image 'check_image_is_temporary() { [[ "$TEST_IMAGE" == nvim-container:test-* ]] && docker image inspect "$TEST_IMAGE" >/dev/null; }')
  out=$(run_harness "$dir" 2>&1); status=$?
  [[ $status -eq 0 && "$out" == *"PASS: check_image_is_temporary"* ]] && ok=yes
  report "checks run against a temporary image" "$ok"
}

test_image_and_network_removed_after_run() {
  local dir out status ok=no marker="$fixture/names"
  dir=$(new_checks cleanup "check_records_names() { echo \"\$TEST_IMAGE \$NETWORK\" > '$marker'; }")
  out=$(run_harness "$dir" 2>&1); status=$?
  if [[ $status -eq 0 && -s "$marker" ]]; then
    read -r image network < "$marker"
    if [[ -z "$(docker images -q "$image")" && -z "$(docker network ls -q -f "name=^${network}$")" ]]; then
      ok=yes
    fi
  fi
  report "temporary image and network are removed after run" "$ok"
}

test_passing_check_exits_zero
test_failing_check_exits_nonzero_and_is_named
test_checks_run_on_internal_network
test_checks_run_against_temporary_image
test_image_and_network_removed_after_run

exit "$failures"
