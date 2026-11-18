#!/usr/bin/env bash
# Exercises hooks/live-signal.sh by feeding it the hook JSON a session would, against scratch git
# repos and a local-path bare origin. The hook runs the real scripts/, so a stub `gh` that always
# fails and CODEO_GITHUB_LOGIN keep every case off the network.
#
#   live-signal.test.sh
#       Exits non-zero and names the failing cases; prints "all cases passed" otherwise.
set -euo pipefail

plugin_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
hook="$plugin_root/hooks/live-signal.sh"

scratch_root=$(mktemp -d)
trap 'rm -rf "$scratch_root"' EXIT
export HOME="$scratch_root/home"
mkdir -p "$HOME" "$scratch_root/bin"
printf '#!/bin/sh\nexit 1\n' > "$scratch_root/bin/gh"
chmod +x "$scratch_root/bin/gh"
export PATH="$scratch_root/bin:$PATH"
export CODEO_GITHUB_LOGIN=alice CODEO_MACHINE=testbox GIT_TERMINAL_PROMPT=0
unset CODEO_LIVE_REFRESH_SECONDS CODEO_LIVE_TTL_SECONDS CODEO_LIVE_PUSH_TIMEOUT
export CODEO_LIVE_PUSH_TIMEOUT=3

failures=0
case_desc=
assert_eq() {
    if [[ $2 != "$3" ]]; then
        echo "FAIL: $case_desc — $1: want [$2] got [$3]"
        failures=$((failures + 1))
    fi
}

# new_world: a bare origin with main and feat/x, and a clone on feat/x holding the lock for #104.
new_world() {
    local seed
    origin=$(mktemp -d "$scratch_root/origin.XXXXXX")
    seed=$(mktemp -d "$scratch_root/seed.XXXXXX")
    git init -q --bare -b main "$origin"
    # Every push into this origin makes receive-pack start a detached `git maintenance run --auto`
    # that can race the next git operation. It is the origin's own config that counts: receive-pack
    # drops the caller's GIT_CONFIG_* environment.
    git -C "$origin" config gc.auto 0
    git -C "$origin" config maintenance.auto false
    git -C "$origin" config receive.autogc false
    git -C "$seed" init -q -b main
    echo x > "$seed/README.md"
    git -C "$seed" add README.md
    git -C "$seed" -c user.name=t -c user.email=t@t commit -q -m init
    git -C "$seed" branch feat/x
    git -C "$seed" push -q "$origin" main feat/x
    clone=$(mktemp -d "$scratch_root/clone.XXXXXX")
    git clone -q "$origin" "$clone" 2>/dev/null
    git -C "$clone" checkout -q feat/x
    mkdir -p "$clone/.codeo"
    printf '{"schema":1,"repo":{"owner":"o","name":"n"},"baseBranch":"main"}\n' > "$clone/.codeo/config.json"
    printf 'issue:   104\nbranch:  feat/x\nstarted: 2026-11-15\nhost:    local\n' > "$clone/.codeo/active"
}

sig=refs/codeo/live/104/testbox
has_ref() { git -C "$origin" rev-parse -q --verify "$sig" > /dev/null 2>&1; }
# Polls every 0.2 s for at most 10 s until the signal exists.
wait_for_ref() {
    local i
    for ((i = 0; i < 50; i++)); do has_ref && return 0; sleep 0.2; done
    return 1
}

# hook <mode> <json> [dir]: runs the hook from dir (default scratch root); sets out, err, rc.
out= err= rc=0
hook() {
    (cd "${3:-$scratch_root}" && printf '%s' "$2" | bash "$hook" "$1") > "$scratch_root/out" 2> "$scratch_root/err" && rc=0 || rc=$?
    out=$(cat "$scratch_root/out")
    err=$(cat "$scratch_root/err")
}

case_desc=hooks_json_registers_beat_and_clear
h="$plugin_root/hooks/hooks.json"
cmd() { jq -r --arg e "$1" '[.hooks[$e][]?.hooks[]?.command] | join("\n")' "$h"; }
[[ $(cmd UserPromptSubmit) == *"live-signal.sh\" beat"* ]] && ok=yes || ok=no
assert_eq "UserPromptSubmit beat" yes "$ok"
[[ $(cmd PostToolUse) == *"live-signal.sh\" beat"* ]] && ok=yes || ok=no
assert_eq "PostToolUse beat" yes "$ok"
[[ $(cmd SessionEnd) == *"live-signal.sh\" clear"* ]] && ok=yes || ok=no
assert_eq "SessionEnd clear" yes "$ok"
[[ $(cmd PreToolUse) == *"subagent-model.sh"* ]] && ok=yes || ok=no
assert_eq "PreToolUse kept" yes "$ok"
assert_eq "timeouts" "10 10 20" "$(jq -r '[.hooks.UserPromptSubmit[0].hooks[0].timeout, .hooks.PostToolUse[0].hooks[0].timeout, .hooks.SessionEnd[0].hooks[0].timeout] | join(" ")' "$h")"

case_desc=beat_publishes_in_the_background
new_world
hook beat "{\"cwd\": \"$clone\"}"
assert_eq "exit" 0 "$rc"
assert_eq "stdout" "" "$out"
assert_eq "stderr" "" "$err"
wait_for_ref && ok=yes || ok=no
assert_eq "signal published" yes "$ok"

case_desc=beat_judges_the_cwd_not_the_process_directory
new_world
other=$(mktemp -d "$scratch_root/other.XXXXXX")
git -C "$other" init -q -b main
mkdir -p "$other/.codeo"
hook beat "{\"cwd\": \"$other\"}" "$clone"
assert_eq "exit" 0 "$rc"
assert_eq "stdout" "" "$out"
sleep 1
has_ref && ok=yes || ok=no
assert_eq "nothing published for the lockless cwd" no "$ok"
hook beat "{\"cwd\": \"$clone\"}" "$other"
wait_for_ref && ok=yes || ok=no
assert_eq "named project's lock honoured" yes "$ok"

case_desc=no_lock_no_signal
new_world
rm "$clone/.codeo/active"
hook beat "{\"cwd\": \"$clone\"}"
assert_eq "exit" 0 "$rc"
assert_eq "stdout" "" "$out"
assert_eq "stderr" "" "$err"
sleep 1
has_ref && ok=yes || ok=no
assert_eq "no ref" no "$ok"

case_desc=clear_deletes_the_ref
new_world
hook beat "{\"cwd\": \"$clone\"}"
wait_for_ref && ok=yes || ok=no
assert_eq "published first" yes "$ok"
hook clear "{\"cwd\": \"$clone\"}"
assert_eq "exit" 0 "$rc"
assert_eq "stdout" "" "$out"
assert_eq "stderr" "" "$err"
has_ref && ok=yes || ok=no
assert_eq "ref gone on return" no "$ok"

case_desc=a_broken_environment_never_fails_the_hook
new_world
for mode in beat clear; do
    hook $mode 'not json {'
    assert_eq "$mode invalid json exit" 0 "$rc"
    assert_eq "$mode invalid json out" "" "$out$err"
    hook $mode "{\"cwd\": \"$scratch_root/nowhere\"}"
    assert_eq "$mode non-repo exit" 0 "$rc"
    assert_eq "$mode non-repo out" "" "$out$err"
done
git -C "$clone" remote set-url origin /nonexistent
for mode in beat clear; do
    hook $mode "{\"cwd\": \"$clone\"}"
    assert_eq "$mode unreachable origin exit" 0 "$rc"
    assert_eq "$mode unreachable origin out" "" "$out$err"
done
case_desc=docs_state_the_live_signal_limits
bullet=$(awk '/^- \*\*Who is working right now/{f=1;print;next} f&&/^- \*\*/{exit} f{print}' "$plugin_root/docs/handoff.md")
bullet=${bullet//$'\n'/ }
bullet=$(printf '%s' "$bullet" | tr -s ' ')
for want in '/codeo:close` clears' '20 seconds' 'ahead of the reader' 'the login lookup'; do
    [[ $bullet == *"$want"* ]] || {
        echo "FAIL $case_desc: no [$want]"
        failures=$((failures + 1))
    }
done
[[ $bullet == *'`CODEO_MACHINE`'*'same volume name'* ]] || {
    echo "FAIL $case_desc: no [CODEO_MACHINE ... same volume name]"
    failures=$((failures + 1))
}
handoff=$(<"$plugin_root/docs/handoff.md")
[[ $handoff == *'S->>O: /codeo:close runs live.sh clear and deletes the lock in one command'* ]] || {
    echo "FAIL $case_desc: no [S->>O close line]"
    failures=$((failures + 1))
}
for gone in 'S->>H: /codeo:close deletes the lock' 'H->>O: clear in the same command'; do
    [[ $handoff != *"$gone"* ]] || {
        echo "FAIL $case_desc: still has [$gone]"
        failures=$((failures + 1))
    }
done

case_desc=hook_header_fits_100_columns
over=$(awk 'length > 100 {print FNR ": " length}' "$hook")
assert_eq "lines over 100 columns" "" "$over"
sleep 1

if ((failures > 0)); then
    echo "$failures failure(s)"
    exit 1
fi
echo "all cases passed"
