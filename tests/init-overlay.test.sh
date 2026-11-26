#!/usr/bin/env bash
# Checks this repo's own init overlay: the host-workflow section is fetched and carries the
# home-container hand-off, and the registry still rejects an unknown point.
#
#   init-overlay.test.sh
#       Exits non-zero and names the first failing case; prints "all cases passed" otherwise.
set -euo pipefail

plugin_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$plugin_root"

fail() { echo "FAIL: $1" >&2; exit 1; }

rc=0
out=$(bash scripts/overlay.sh init host-workflow 2>/dev/null) || rc=$?
[[ "$rc" -eq 0 ]] || fail "overlay.sh init host-workflow exited $rc"

for needle in 'home checkout' 'the host clone named `codeo-home`' 'This skill does not write `.codeo/active`' 'Clone Repository in Named Container Volume' \
    'https://github.com/kbajpai/codeo/tree/' 'codeo-<N>' 'git worktree remove' 'git branch -D' \
    '/codeo:plan' 'lock: took the lock for #<N>' \
    'bash .devcontainer/codeo-container.sh issue <N> <branch>' 'bash .devcontainer/codeo-container.sh shell <N>' 'codeo issue <N> <branch> --sandbox' 'outside the project clone' 'bash codeo-sandbox.sh issue <N> <branch>' 'command line' 'codeo rm <N>' \
    'bash .devcontainer/codeo-track.sh add <N> branch <branch>' 'track:' 'changes nothing'; do
    [[ "$out" == *"$needle"* ]] || fail "overlay output lacks: $needle"
done
[[ "$out" != *'docker volume rm'* ]] || fail "overlay output still names docker volume rm"
[[ "$out" != *'claude --cloud'* ]] || fail "overlay output mentions claude --cloud"

rc=0
bash scripts/overlay.sh init no-such-point >/dev/null 2>&1 || rc=$?
[[ "$rc" -eq 2 ]] || fail "unknown point exited $rc, expected 2"

echo "all cases passed"
