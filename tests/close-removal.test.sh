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
for needle in 'codeo rm <N>' '^codeo-[0-9]+$' 'unknown' 'docker ps' \
    'not inside this container' 'git status' 'PowerShell' \
    'When the lock'"'"'s `host` is `container`' 'nothing to remove' '/codeo:triage' '/codeo:cleanup' 'home checkout' 'the host clone named `codeo-home`' \
    'After a finished close' 'After a stash:' 'After an abandon:' \
    'its number is the lock'"'"'s `issue`' '/codeo:init #<N>' '.devcontainer/README.md' \
    'When the lock has a `sandbox:` line' 'codeo-sandbox.sh issue <N> <branch>' \
    'bash .devcontainer/codeo-track.sh mark <N> branch <branch> deleted' 'track:' 'project root' 'step 14'; do
    [[ "$out" == *"$needle"* ]] || fail "overlay output lacks: $needle"
done

# Structural checks on the overlay text, in one function so a scratch copy can be fed to it.
check_overlay() {
    local text=$1 fin rest stash aband part name needle cmd='codeo rm <N>'
    fin=${text#*'After a finished close'}
    fin=${fin%%'After a stash:'*}
    [[ "$fin" == *"$cmd"* ]] \
        || { echo "check a: finished-close paragraph lacks the removal command"; return 1; }
    [[ "$fin" != *'docker rm'* ]] || { echo "check a: finished-close paragraph names docker rm"; return 1; }
    rest='After a stash:'${text#*'After a stash:'}
    stash=${rest%%'After an abandon:'*}
    aband='After an abandon:'${rest#*'After an abandon:'}
    aband=${aband%%'When the lock has a `sandbox:` line'*}
    aband=${aband%%'For any other host'*}
    for name in stash abandon; do
        part=$stash; [[ $name == abandon ]] && part=$aband
        if [[ "$part" == *'docker rm'* || "$part" == *'docker volume rm'* ]]; then
            echo "check b: the $name paragraph names a removal command"; return 1
        fi
    done
    for name in stash abandon; do
        part=$stash; [[ $name == abandon ]] && part=$aband
        [[ "$part" == *'print no removal command'* ]] \
            || { echo "check c: the $name paragraph lacks 'print no removal command'"; return 1; }
        [[ "$part" == *'home checkout'* ]] \
            || { echo "check c: the $name paragraph lacks 'home checkout'"; return 1; }
    done
    for needle in 'the only copy' '.devcontainer/README.md'; do
        [[ "$aband" == *"$needle"* ]] || { echo "check d: the abandon paragraph lacks $needle"; return 1; }
    done
    sbx='When the lock has a `sandbox:` line'${text#*'When the lock has a `sandbox:` line'}
    sbx=${sbx%%'For a `container` lock with neither'*}
    sbx=${sbx%%'For any other host'*}
    if [[ "$sbx" == *'docker rm'* || "$sbx" == *'docker volume rm'* ]]; then
        echo "check e: the sandbox section names a removal command"; return 1
    fi
    local sfin
    sfin=${sbx%%'After a stash:'*}
    [[ "$sfin" == *'codeo rm <N>'* && "$sfin" != *'codeo-sandbox.sh end'* ]] \
        || { echo "check g: the sandbox finished paragraph does not print codeo rm <N>"; return 1; }
    local sstash saband
    sstash='After a stash:'${sbx#*'After a stash:'}
    sstash=${sstash%%'After an abandon:'*}
    saband='After an abandon:'${sbx#*'After an abandon:'}
    for needle in 'print no removal command' 'codeo-home'; do
        [[ "$sstash" == *"$needle"* ]] || { echo "check f: the sandbox stash paragraph lacks $needle"; return 1; }
    done
    for needle in 'print no removal command' 'codeo-home' 'codeo rm <N>' '--force' 'only copy'; do
        [[ "$saband" == *"$needle"* ]] || { echo "check f: the sandbox abandon paragraph lacks $needle"; return 1; }
    done
}
msg=$(check_overlay "$out") || fail "$msg"

# Self-check: each mutant of the real overlay must fail, and from its own check.
cmd='docker rm -f x; docker volume rm x'
mutant() { # $1 label, $2 overlay text, $3 expected message prefix
    local m
    m=$(check_overlay "$2") && fail "self-check: $1 passed the checks"
    [[ "$m" == "$3"* ]] || fail "self-check: $1 failed from the wrong check: $m"
}
mutant 'a removal command in the abandon paragraph' \
    "${out/'When the lock has a `sandbox:` line'/"$cmd
When the lock has a \`sandbox:\` line"}" 'check b: the abandon'
mutant 'a removal command in the sandbox section' \
    "${out/'For a `container` lock with neither'/"docker rm -f x
For a \`container\` lock with neither"}" 'check e:'
mutant 'a removal command in the stash paragraph' \
    "${out/'After an abandon:'/"$cmd
After an abandon:"}" 'check b: the stash'
mutant 'the sandbox abandon paragraph without --force' \
    "${out/'refuses without `--force`'/'refuses'}" 'check f: the sandbox abandon'
mutant 'the removal command deleted from the finished paragraph' \
    "${out/'codeo rm <N>'/'(removed)'}" 'check a:'

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
