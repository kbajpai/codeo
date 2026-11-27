#!/usr/bin/env bash
# Runs every tests/*.test.sh whose name contains the optional pattern (all by default), printing
# the output of each failing file and exiting non-zero if any failed.
#
#   run.sh [pattern]
#
# CODEO_GOLDEN_DIR is unset first, so the suite stays hermetic: tests/replay.test.sh replays only
# its synthetic directory here, whatever the caller's environment holds. To replay a project's
# golden data, run CODEO_GOLDEN_DIR=<dir> bash tests/replay.test.sh directly.
set -euo pipefail
unset CODEO_GOLDEN_DIR

dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
pattern="${1:-}"

# Files run in parallel (CODEO_TEST_JOBS workers, default one per CPU). Each file's output goes to
# its own log, so a passing file stays quiet and a failing one is replayed below.
jobs="${CODEO_TEST_JOBS:-$(nproc 2>/dev/null || echo 2)}"
logs=$(mktemp -d)
trap 'rm -rf "$logs"' EXIT

files=()
for file in "$dir"/*.test.sh; do
    [[ -e "$file" ]] || continue
    name=$(basename "$file")
    [[ "$name" == *"$pattern"* ]] || continue
    files+=("$file")
done
ran="${#files[@]}"

run_one() {
    local name
    name=$(basename "$1")
    bash "$1" >"$2/$name.log" 2>&1 || : >"$2/$name.failed"
}
export -f run_one

if [[ "$ran" -gt 0 ]]; then
    printf '%s\0' "${files[@]}" | xargs -0 -P "$jobs" -I{} bash -c 'run_one "$1" "$2"' _ {} "$logs"
fi

failed=()
for file in "${files[@]}"; do
    name=$(basename "$file")
    if [[ -e "$logs/$name.failed" ]]; then
        failed+=("$name")
        printf '=== FAIL: %s\n%s\n' "$name" "$(cat "$logs/$name.log")"
    fi
done

# A pattern that matches nothing is a mistake, not a pass.
if [[ "$ran" -eq 0 ]]; then
    echo "no tests matched '$pattern'" >&2
    exit 1
fi

if [[ "${#failed[@]}" -gt 0 ]]; then
    echo "failed: ${failed[*]}" >&2
    exit 1
fi
echo "all cases passed"
