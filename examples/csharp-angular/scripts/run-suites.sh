#!/usr/bin/env bash
# Runs every suite in .codeo/config.json, build then test, in order, from the project root, and stops at
# the first failure. Prints "suite: <name> ok" or "suite: <name> FAIL" per suite; exits 0 only when all pass.
# Each command runs under bash -c, so spaces and "--" in a command behave as they do in a terminal. The
# suites are read on fd 3 and each command's stdin is /dev/null, so no command can swallow the list.
#
#   run-suites.sh
set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
[[ -f $PWD/.codeo/config.json ]] && root=$PWD
config="$root/.codeo/config.json"
[[ -f $config ]] || { echo "run-suites: no $config" >&2; exit 1; }
cd "$root"

# Read the list first, so invalid JSON or a missing .suites fails here and not silently.
list=$(jq -r '.suites[] | [.name, (.build // ""), (.test // "")] | join("\u001f")' "$config" 2>/dev/null) ||
    { echo "run-suites: cannot read .suites from $config" >&2; exit 1; }
[[ -n $list ]] || { echo "run-suites: no suites in $config" >&2; exit 1; }

ran=0
# A unit separator, not a tab, so an empty build field is not collapsed by read.
while IFS=$'\x1f' read -r -u 3 name build test; do
    [[ -n $name ]] || continue
    for cmd in "$build" "$test"; do
        [[ -n $cmd ]] || continue
        if ! bash -c "$cmd" </dev/null; then
            echo "suite: $name FAIL"
            exit 1
        fi
    done
    echo "suite: $name ok"
    ran=$((ran + 1))
done 3<<<"$list"
[[ $ran -gt 0 ]] || { echo "run-suites: no suite ran" >&2; exit 1; }
