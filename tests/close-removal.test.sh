#!/usr/bin/env bash
# Checks that /codeo:close prints the host commands that remove its container: the overlay's
# host-workflow section carries the removal command, the role-guard section is still there, and
# the skill's generic host: container default says the commands run on the host, with no
# container-engine command in it.
#
#   close-removal.test.sh
#       Exits non-zero and names the first failing case; prints "all cases passed" otherwise.
set -euo pipefail

plugin_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$plugin_root"

fail() { echo "FAIL: $1" >&2; exit 1; }

rc=0
out=$(bash scripts/overlay.sh close host-workflow 2>/dev/null) || rc=$?
[[ "$rc" -eq 0 ]] || fail "overlay.sh close host-workflow exited $rc"
for needle in 'docker rm -f <volume>; docker volume rm <volume>' '^codeo-[0-9]+$' 'unknown' 'docker ps' \
    'on the host' 'PowerShell'; do
    [[ "$out" == *"$needle"* ]] || fail "overlay output lacks: $needle"
done

rc=0
bash scripts/overlay.sh close role-guard >/dev/null 2>&1 || rc=$?
[[ "$rc" -eq 0 ]] || fail "overlay.sh close role-guard exited $rc"

skill=skills/close/SKILL.md
bullet=$(awk '/^    - \*\*`host: container`\*\*/ {on=1; print; next} on && /^    - \*\*/ {exit} on {print}' "$skill")
[[ -n "$bullet" ]] || fail "no host: container bullet in $skill"
for needle in 'on the host' 'git status' 'volume:'; do
    [[ "$bullet" == *"$needle"* ]] || fail "host: container bullet lacks: $needle"
done
grep -qi 'docker' "$skill" && fail "$skill names a container engine"

echo "all cases passed"
