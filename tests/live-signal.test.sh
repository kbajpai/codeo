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
unset CLAUDE_CODE_REMOTE CLAUDE_CODE_REMOTE_SESSION_ID
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
for want in '/codeo:close` clears' '20 seconds' 'ahead of the reader' 'the login lookup' \
    'at the default `CODEO_LIVE_PUSH_TIMEOUT`' 'can end `clear` during the REST delete' \
    "lose the origin's ref lock" 'fresh either way'; do
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
[[ $handoff == *'S->>O: /codeo:close runs live.sh clear and live.sh sweep, and deletes the lock in one command'* ]] || {
    echo "FAIL $case_desc: no [S->>O close line]"
    failures=$((failures + 1))
}
for gone in 'S->>H: /codeo:close deletes the lock' 'H->>O: clear in the same command'; do
    [[ $handoff != *"$gone"* ]] || {
        echo "FAIL $case_desc: still has [$gone]"
        failures=$((failures + 1))
    }
done

case_desc=docs_state_the_web_session_signal
handoff=$(<"$plugin_root/docs/handoff.md")
for want in 'refs/heads/codeo-live/' 'live.sh sweep' '[skip ci]' 'codeo-live/**' 'refs/codeo/live-web/' 'codeo-live-machine' 'CLAUDE_CODE_REMOTE_SESSION_ID' 'CODEO_GITHUB_LOGIN' 'takes the lock' 'first assignee' 'else `unknown`'; do
    [[ $handoff == *"$want"* ]] || {
        echo "FAIL $case_desc: no [$want]"
        failures=$((failures + 1))
    }
done
[[ $handoff != *'so it publishes no signal'* ]] || {
    echo "FAIL $case_desc: still has [so it publishes no signal]"
    failures=$((failures + 1))
}
[[ $handoff != *'take the lock and beat'* ]] || {
    echo "FAIL $case_desc: still has [take the lock and beat]"
    failures=$((failures + 1))
}
for want in 'never for a' 'whatever its lock' 'only here' 'committed dossier'; do
    [[ $handoff == *"$want"* ]] || {
        echo "FAIL $case_desc: no [$want]"
        failures=$((failures + 1))
    }
done
for gone in 'nothing else is needed' 'same two groups'; do
    [[ $handoff != *"$gone"* ]] || {
        echo "FAIL $case_desc: still has [$gone]"
        failures=$((failures + 1))
    }
done

case_desc=live_sh_comment_names_both_bounded_calls
entry=$(awk '/^#   CODEO_LIVE_PUSH_TIMEOUT/{f=1;print;next} f&&/^# {10,}/{print;next} {f=0}' \
    "$plugin_root/scripts/live.sh")
entry=${entry//$'\n'/ }
entry=$(printf '%s' "$entry" | tr -s ' ')
for want in 'github.sh ref put' 'github.sh ref delete'; do
    [[ $entry == *"$want"* ]] || {
        echo "FAIL $case_desc: no [$want]"
        failures=$((failures + 1))
    }
done

case_desc=hook_header_fits_100_columns
over=$(awk 'length > 100 {print FNR ": " length}' "$hook")
assert_eq "lines over 100 columns" "" "$over"
sleep 1

case_desc=settings_json_registers_the_web_session_hooks
s="$plugin_root/.claude/settings.json"
scmd() { jq -r --arg e "$1" '[.hooks[$e][]?.hooks[]?.command] | join("\n")' "$s"; }
[[ $(scmd SessionStart) != *'lock.sh'* ]] && ok=yes || ok=no
assert_eq "SessionStart takes no lock" yes "$ok"
for e in UserPromptSubmit PostToolUse; do
    [[ $(scmd $e) == *'live-signal.sh" beat'* ]] && ok=yes || ok=no
    assert_eq "$e beat" yes "$ok"
done
assert_eq "SessionStart groups" 1 "$(jq -r '.hooks.SessionStart | length' "$s")"
for e in SessionStart UserPromptSubmit; do
    [[ $(scmd $e) == *'session-title.sh'* ]] && ok=yes || ok=no
    assert_eq "$e session-title kept" yes "$ok"
done
assert_eq "gated commands" 2 "$(jq -r '[.hooks[][].hooks[].command
    | select(contains("live-signal.sh") or contains("lock.sh"))
    | select(contains("CLAUDE_CODE_REMOTE"))] | length' "$s")"
assert_eq "no SessionEnd" null "$(jq -c '.hooks.SessionEnd' "$s")"

# run_settings <event> <stdin> [dir]: runs an event's lock/beat command from dir (default scratch
# root) the way a session would; sets rc.
run_settings() {
    local c
    c=$(jq -r --arg e "$1" '[.hooks[$e][].hooks[].command
        | select(contains("live-signal.sh") or contains("lock.sh"))][0]' "$s")
    (cd "${3:-$scratch_root}" && printf '%s' "$2" | CLAUDE_PROJECT_DIR=$plugin_root timeout 30 sh -c "$c") \
        > "$scratch_root/out" 2> "$scratch_root/err" && rc=0 || rc=$?
}
web_ref() { git -C "$origin" rev-parse -q --verify refs/heads/codeo-live/104/testbox > /dev/null 2>&1; }

case_desc=settings_hooks_do_nothing_outside_a_web_session
new_world
sed -i 's/^host:.*/host:    web/' "$clone/.codeo/active"
(unset CLAUDE_CODE_REMOTE; run_settings PostToolUse "{\"cwd\": \"$clone\"}")
assert_eq "exit" 0 "$rc"
sleep 2
assert_eq "no branch" "" "$(git -C "$origin" for-each-ref 'refs/heads/codeo-live/')"

case_desc=settings_beat_hook_publishes_in_a_web_session
new_world
sed -i 's/^host:.*/host:    web/' "$clone/.codeo/active"
(export CLAUDE_CODE_REMOTE=true; run_settings PostToolUse "{\"cwd\": \"$clone\"}")
assert_eq "exit" 0 "$rc"
found=no
for ((i = 0; i < 50; i++)); do web_ref && { found=yes; break; }; sleep 0.2; done
assert_eq "branch published" yes "$found"

# new_world_with_dossier: new_world plus a live dossier for #104 naming feat/x and no lock,
# committed and pushed.
new_world_with_dossier() {
    new_world
    rm "$clone/.codeo/active"
    mkdir -p "$clone/.codeo/104"
    printf '# Init\n\n| Field | Value |\n|---|---|\n| Branch | `feat/x` |\n' > "$clone/.codeo/104/init.md"
    git -C "$clone" add .codeo
    git -C "$clone" -c user.name=t -c user.email=t@t commit -q -m dossier
    git -C "$clone" push -q origin feat/x
}
# wait_for_file <path>: polls up to 10 s.
wait_for_file() {
    local i
    for ((i = 0; i < 50; i++)); do [[ -e $1 ]] && return 0; sleep 0.2; done
    return 1
}

case_desc=settings_beat_hook_takes_the_lock_and_publishes
new_world_with_dossier
(export CLAUDE_CODE_REMOTE=true CLAUDE_CODE_REMOTE_SESSION_ID=cse_abcdef0123456789
    run_settings UserPromptSubmit "{\"hook_event_name\":\"UserPromptSubmit\",\"cwd\": \"$clone\"}" "$clone")
assert_eq "exit" 0 "$rc"
wait_for_file "$clone/.codeo/active" && ok=yes || ok=no
assert_eq "lock appears" yes "$ok"
active=$(cat "$clone/.codeo/active" 2> /dev/null || true)
[[ $active == *'host:    web'* ]] && ok=yes || ok=no
assert_eq "host web" yes "$ok"
found=no
for ((i = 0; i < 50; i++)); do web_ref && { found=yes; break; }; sleep 0.2; done
assert_eq "branch published" yes "$found"

case_desc=hook_takes_the_lock_in_a_web_session_when_none_exists
new_world_with_dossier
(export CLAUDE_CODE_REMOTE=true CLAUDE_CODE_REMOTE_SESSION_ID=cse_abcdef0123456789
    hook beat "{\"hook_event_name\":\"UserPromptSubmit\",\"cwd\": \"$clone\"}")
assert_eq "exit" 0 "$rc"
assert_eq "stdout" "" "$out"
assert_eq "stderr" "" "$err"
wait_for_file "$clone/.codeo/active" && ok=yes || ok=no
assert_eq "lock appears" yes "$ok"
active=$(cat "$clone/.codeo/active" 2> /dev/null || true)
[[ $active == *'host:    web'* ]] && ok=yes || ok=no
assert_eq "host web" yes "$ok"
[[ $active == *'session: abcdef0123456789'* ]] && ok=yes || ok=no
assert_eq "session id without cse_" yes "$ok"
found=no
for ((i = 0; i < 50; i++)); do web_ref && { found=yes; break; }; sleep 0.2; done
assert_eq "branch published" yes "$found"

case_desc=hook_without_a_session_id_takes_a_lock_with_session_unknown
new_world_with_dossier
(export CLAUDE_CODE_REMOTE=true; unset CLAUDE_CODE_REMOTE_SESSION_ID
    hook beat "{\"hook_event_name\":\"UserPromptSubmit\",\"cwd\": \"$clone\"}")
assert_eq "exit" 0 "$rc"
wait_for_file "$clone/.codeo/active" && ok=yes || ok=no
assert_eq "lock appears" yes "$ok"
active=$(cat "$clone/.codeo/active" 2> /dev/null || true)
[[ $active == *'session: unknown'* ]] && ok=yes || ok=no
assert_eq "session unknown" yes "$ok"
found=no
for ((i = 0; i < 50; i++)); do web_ref && { found=yes; break; }; sleep 0.2; done
assert_eq "branch published" yes "$found"

case_desc=hook_takes_no_lock_outside_a_web_session
new_world_with_dossier
(unset CLAUDE_CODE_REMOTE; export CLAUDE_CODE_REMOTE_SESSION_ID=cse_abcdef0123456789
    hook beat "{\"hook_event_name\":\"UserPromptSubmit\",\"cwd\": \"$clone\"}")
assert_eq "exit" 0 "$rc"
sleep 2
[[ ! -e $clone/.codeo/active ]] && ok=yes || ok=no
assert_eq "no lock" yes "$ok"

case_desc=hook_takes_no_lock_without_a_codeo_directory
new_world_with_dossier
rm -rf "$clone/.codeo"
(export CLAUDE_CODE_REMOTE=true CLAUDE_CODE_REMOTE_SESSION_ID=cse_abcdef0123456789
    hook beat "{\"hook_event_name\":\"UserPromptSubmit\",\"cwd\": \"$clone\"}")
assert_eq "exit" 0 "$rc"
sleep 2
[[ ! -e $clone/.codeo ]] && ok=yes || ok=no
assert_eq "no .codeo" yes "$ok"

# stub_plugin: a copy of the plugin whose lock.sh logs each call and takes no lock.
stub_plugin() {
    stub=$(mktemp -d "$scratch_root/stub.XXXXXX")
    cp -R "$plugin_root/hooks" "$plugin_root/scripts" "$plugin_root/lib" "$stub/"
    printf '#!/usr/bin/env bash\necho "$*" >> "%s"\n' "$stub/log" > "$stub/scripts/lock.sh"
    : > "$stub/log"
}

case_desc=hook_leaves_an_existing_lock_alone
new_world_with_dossier
stub_plugin
printf 'issue:   104\nbranch:  feat/x\nstarted: 2026-11-15\nhost:    local\n' > "$clone/.codeo/active"
(export CLAUDE_CODE_REMOTE=true CLAUDE_CODE_REMOTE_SESSION_ID=cse_abcdef0123456789
    hook=$stub/hooks/live-signal.sh
    hook beat "{\"hook_event_name\":\"UserPromptSubmit\",\"cwd\": \"$clone\"}")
assert_eq "exit" 0 "$rc"
sleep 2
[[ ! -s $stub/log ]] && ok=yes || ok=no
assert_eq "lock.sh never called" yes "$ok"

case_desc=hook_tries_the_lock_once_per_refresh_interval
new_world_with_dossier
stub_plugin
(export CLAUDE_CODE_REMOTE=true CLAUDE_CODE_REMOTE_SESSION_ID=cse_abcdef0123456789
    hook=$stub/hooks/live-signal.sh
    hook beat "{\"hook_event_name\":\"UserPromptSubmit\",\"cwd\": \"$clone\"}"
    wait_for_file "$stub/log" || true
    hook beat "{\"hook_event_name\":\"UserPromptSubmit\",\"cwd\": \"$clone\"}")
assert_eq "exit" 0 "$rc"
sleep 2
assert_eq "one call" 1 "$(wc -l < "$stub/log" | tr -d ' ')"
assert_eq "arguments" "take web abcdef0123456789" "$(head -1 "$stub/log")"
claims=$({ compgen -G "$clone/$(git -C "$clone" rev-parse --git-path codeo-live-lock-try).*" || true; } | wc -l | tr -d ' ')
assert_eq "one claim file" 1 "$claims"
rm -f "$clone/$(git -C "$clone" rev-parse --git-path codeo-live-lock-try)".*
(export CLAUDE_CODE_REMOTE=true CLAUDE_CODE_REMOTE_SESSION_ID=cse_abcdef0123456789
    hook=$stub/hooks/live-signal.sh
    hook beat "{\"hook_event_name\":\"UserPromptSubmit\",\"cwd\": \"$clone\"}")
assert_eq "second call in a new interval" 2 "$(wc -l < "$stub/log" | tr -d ' ')"

ups() { printf '{"hook_event_name":"UserPromptSubmit","cwd":"%s"}' "$1"; }
claim_glob() { echo "$clone/$(git -C "$clone" rev-parse --git-path codeo-live-lock-try)"; }

case_desc=hook_posttooluse_never_takes_the_lock
new_world_with_dossier
stub_plugin
(export CLAUDE_CODE_REMOTE=true CLAUDE_CODE_REMOTE_SESSION_ID=cse_abcdef0123456789
    hook=$stub/hooks/live-signal.sh
    hook beat "{\"hook_event_name\":\"PostToolUse\",\"cwd\": \"$clone\"}"
    hook beat "{\"cwd\": \"$clone\"}")
assert_eq "exit" 0 "$rc"
sleep 1
[[ ! -s $stub/log ]] && ok=yes || ok=no
assert_eq "lock.sh never called" yes "$ok"
[[ -z $(git -C "$origin" for-each-ref 'refs/heads/codeo-live/') ]] && ok=yes || ok=no
assert_eq "nothing published" yes "$ok"

case_desc=hook_does_not_take_a_lock_for_a_stashed_dossier
new_world_with_dossier
printf '# Close\n\n### Round 1 — stashed\n' > "$clone/.codeo/104/close.md"
git -C "$clone" add .codeo
git -C "$clone" -c user.name=t -c user.email=t@t commit -q -m stash
git -C "$clone" push -q origin feat/x
(export CLAUDE_CODE_REMOTE=true CLAUDE_CODE_REMOTE_SESSION_ID=cse_abcdef0123456789 CODEO_LIVE_REFRESH_SECONDS=1
    hook beat "$(ups "$clone")"
    sleep 2
    hook beat "$(ups "$clone")")
assert_eq "exit" 0 "$rc"
sleep 1
[[ ! -e $clone/.codeo/active ]] && ok=yes || ok=no
assert_eq "no lock" yes "$ok"
[[ -z $(git -C "$origin" for-each-ref 'refs/heads/codeo-live/') ]] && ok=yes || ok=no
assert_eq "no codeo-live branch" yes "$ok"

case_desc=hook_positive_control_takes_the_lock_for_a_non_stashed_dossier
new_world_with_dossier
(export CLAUDE_CODE_REMOTE=true CLAUDE_CODE_REMOTE_SESSION_ID=cse_abcdef0123456789 CODEO_LIVE_REFRESH_SECONDS=1
    hook beat "$(ups "$clone")"
    sleep 2
    hook beat "$(ups "$clone")")
assert_eq "exit" 0 "$rc"
[[ -e $clone/.codeo/active ]] && ok=yes || ok=no
assert_eq "lock taken without a stash" yes "$ok"

case_desc=hook_takes_the_lock_in_the_foreground
new_world_with_dossier
(export CLAUDE_CODE_REMOTE=true CLAUDE_CODE_REMOTE_SESSION_ID=cse_abcdef0123456789
    hook beat "$(ups "$clone")")
assert_eq "exit" 0 "$rc"
[[ -e $clone/.codeo/active ]] && ok=yes || ok=no
assert_eq "lock present on return" yes "$ok"
found=no
for ((i = 0; i < 50; i++)); do web_ref && { found=yes; break; }; sleep 0.2; done
assert_eq "branch published" yes "$found"

case_desc=hook_two_simultaneous_hooks_take_once
new_world_with_dossier
stub_plugin
for n in 1 2 3 4 5; do
    rm -f "$(claim_glob)".*
    : > "$stub/log"
    (export CLAUDE_CODE_REMOTE=true CLAUDE_CODE_REMOTE_SESSION_ID=cse_abcdef0123456789
        cd "$clone"
        ups "$clone" | bash "$stub/hooks/live-signal.sh" beat > /dev/null 2>&1 &
        ups "$clone" | bash "$stub/hooks/live-signal.sh" beat > /dev/null 2>&1 &
        wait)
    assert_eq "pair $n lock.sh calls" 1 "$(wc -l < "$stub/log" | tr -d ' ')"
done

case_desc=hook_bounds_the_take
if ! command -v timeout > /dev/null 2>&1; then
    echo "SKIP: $case_desc — no timeout binary installed"
else
    new_world_with_dossier
    stub_plugin
    printf '#!/usr/bin/env bash\nsleep 30\n' > "$stub/scripts/lock.sh"
    start=$SECONDS
    (export CLAUDE_CODE_REMOTE=true CLAUDE_CODE_REMOTE_SESSION_ID=cse_abcdef0123456789
        hook=$stub/hooks/live-signal.sh
        hook beat "$(ups "$clone")")
    assert_eq "exit" 0 "$rc"
    ((SECONDS - start < 12)) && ok=yes || ok=no
    assert_eq "returned within 12 s" yes "$ok"
    [[ ! -e $clone/.codeo/active ]] && ok=yes || ok=no
    assert_eq "no lock" yes "$ok"
fi

if ((failures > 0)); then
    echo "$failures failure(s)"
    exit 1
fi
echo "all cases passed"
