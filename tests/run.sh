#!/usr/bin/env bash
# Runs every tests/*.test.sh whose name contains the optional pattern (all by default), printing
# the output of each failing file and exiting non-zero if any failed.
#
#   run.sh [pattern]
set -euo pipefail

dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
pattern="${1:-}"

failed=()
ran=0
for file in "$dir"/*.test.sh; do
    [[ -e "$file" ]] || continue
    name=$(basename "$file")
    [[ "$name" == *"$pattern"* ]] || continue
    ran=$((ran + 1))
    # Output is captured so a passing file stays quiet; a failing one is replayed below.
    if ! output=$(bash "$file" 2>&1); then
        failed+=("$name")
        printf '=== FAIL: %s\n%s\n' "$name" "$output"
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
