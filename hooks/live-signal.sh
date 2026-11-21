#!/usr/bin/env bash
# Keeps the live-session signal (scripts/live.sh) fresh while a codeo session works and clears it
# when the session ends. Hooked to UserPromptSubmit and PostToolUse (`beat`) and SessionEnd
# (`clear`).
#
#   live-signal.sh beat|clear
#       Reads the hook JSON on stdin and judges the project its cwd names, falling back to the
#       process directory only when the JSON carries none. Does nothing without a project or a
#       .codeo/active lock, except that `beat` takes the lock first when the hook JSON's
#       hook_event_name is UserPromptSubmit (never PostToolUse or any other event),
#       CLAUDE_CODE_REMOTE=true, a .codeo directory exists and this interval's claim succeeds:
#       the claim is a file <git dir>/codeo-live-lock-try.<now / CODEO_LIVE_REFRESH_SECONDS>
#       (default 300) created with noclobber, so one of two simultaneous hooks proceeds. The
#       winner runs `lock.sh take web` (session id minus its cse_ prefix, CODEO_LOCK_SKIP_PARKED=1
#       so a stashed or abandoned dossier gets no lock) in the foreground, bounded by `timeout 8`
#       when that exists, then beats if a lock now exists. With a lock, `beat` starts live.sh in
#       the background with every stream closed, so the hook returns at once; `clear` runs in the
#       foreground and still needs a lock. Always exits 0 and prints nothing: a signal must
#       never break a tool call.
# No `set -e`: every failure below is swallowed on purpose.

mode=${1:-}
input=$(cat 2> /dev/null) || input=
cwd=$(jq -r '.cwd // empty' <<< "$input" 2> /dev/null) || cwd=
root=$(git -C "${cwd:-.}" rev-parse --show-toplevel 2> /dev/null) || exit 0
[[ -n $root ]] || exit 0

cd "$root" 2> /dev/null || exit 0
here="$(dirname "${BASH_SOURCE[0]}")/.."
live="$here/scripts/live.sh"

if [[ ! -f $root/.codeo/active ]]; then
    event=$(jq -r '.hook_event_name // empty' <<< "$input" 2> /dev/null) || event=
    [[ $mode == beat && $event == UserPromptSubmit && ${CLAUDE_CODE_REMOTE:-} == true \
        && -d $root/.codeo ]] || exit 0
    prefix=$(git rev-parse --git-path codeo-live-lock-try 2> /dev/null) || exit 0
    interval=${CODEO_LIVE_REFRESH_SECONDS:-300}
    [[ $interval =~ ^[1-9][0-9]*$ ]] || interval=300
    claim=$prefix.$(($(date +%s) / interval))
    (set -C; : > "$claim") 2> /dev/null || exit 0
    for old in "$prefix".*; do [[ $old == "$claim" ]] || rm -f "$old" 2> /dev/null; done
    bound=()
    command -v timeout > /dev/null 2>&1 && bound=(timeout 8)
    CODEO_LOCK_SKIP_PARKED=1 "${bound[@]}" bash "$here/scripts/lock.sh" take web \
        "${CLAUDE_CODE_REMOTE_SESSION_ID#cse_}" < /dev/null > /dev/null 2>&1
    [[ -f $root/.codeo/active ]] || exit 0
    (bash "$live" beat < /dev/null > /dev/null 2>&1 &) > /dev/null 2>&1
    exit 0
fi

case $mode in
    beat) (bash "$live" beat < /dev/null > /dev/null 2>&1 &) > /dev/null 2>&1 ;;
    clear) bash "$live" clear < /dev/null > /dev/null 2>&1 ;;
esac
exit 0
