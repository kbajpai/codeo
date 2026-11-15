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
    'not inside this container' 'git status' 'PowerShell' \
    'When the lock'"'"'s `host` is `container`' 'nothing to remove' '/codeo:triage' '/codeo:cleanup' 'home container' \
    'After a finished close' 'After a stash:' 'After an abandon:' \
    'its number is the lock'"'"'s `issue`' 'the only copy' '/codeo:init #<N>' '.devcontainer/README.md'; do
    [[ "$out" == *"$needle"* ]] || fail "overlay output lacks: $needle"
done

# Structural checks on the overlay text, in one function so a scratch copy can be fed to it.
check_overlay() {
    local text=$1 fin rest stash aband part
    fin=${text#*'After a finished close'}
    fin=${fin%%'After a stash:'*}
    [[ "$fin" == *'docker rm -f <volume>; docker volume rm <volume>'* ]] \
        || { echo "finished-close paragraph lacks the removal command"; return 1; }
    rest='After a stash:'${text#*'After a stash:'}
    if [[ "$rest" == *'docker rm'* || "$rest" == *'docker volume rm'* ]]; then
        echo "text from After a stash: names a removal command"; return 1
    fi
    stash=${rest%%'After an abandon:'*}
    aband='After an abandon:'${rest#*'After an abandon:'}
    aband=${aband%%'For any other host'*}
    for part in "$stash" "$aband"; do
        [[ "$part" == *'print no removal command'* && "$part" == *'home container'* ]] \
            || { echo "stash or abandon paragraph lacks 'print no removal command' or 'home container'"; return 1; }
    done
}
msg=$(check_overlay "$out") || fail "$msg"

# Self-check: the removal sentence moved under the abandon paragraph must fail the checks.
scratch=${out//'docker rm -f <volume>; docker volume rm <volume>'/'(removed)'}
scratch=${scratch/'After an abandon:'/'After an abandon: docker rm -f <volume>; docker volume rm <volume>'}
if check_overlay "$scratch" >/dev/null 2>&1; then
    fail "self-check: a removal command under After an abandon: passed the checks"
fi

rc=0
bash scripts/overlay.sh close role-guard >/dev/null 2>&1 || rc=$?
[[ "$rc" -eq 0 ]] || fail "overlay.sh close role-guard exited $rc"

skill=skills/close/SKILL.md
bullet=$(awk '/^    - \*\*`host: container`\*\*/ {on=1; print; next} on && /^    - \*\*/ {exit} on {print}' "$skill")
[[ -n "$bullet" ]] || fail "no host: container bullet in $skill"
for needle in 'on the host' 'git status' 'volume:'; do
    [[ "$bullet" == *"$needle"* ]] || fail "host: container bullet lacks: $needle"
done
fin=$(awk '/\*\*Closing block — finished:\*\*/ {on=1} on && $0 == "" {exit} on {print}' "$skill")
[[ -n "$fin" ]] || fail "no Closing block — finished paragraph in $skill"
[[ "$fin" == *"the checkout the project's host workflow names"* ]] \
    || fail "finished closing block does not name the checkout the host workflow names"
if grep -qF 'nothing is lost either way' "$skill"; then
    fail "$skill still says nothing is lost either way"
fi
if grep -qi 'docker' "$skill"; then
    fail "$skill names a container engine: $(grep -i 'docker' "$skill" | head -1)"
fi

echo "all cases passed"
