#!/usr/bin/env bash
# Keeps the live-session signal (scripts/live.sh) fresh while a codeo session works and clears it
# when the session ends. Hooked to UserPromptSubmit and PostToolUse (`beat`) and SessionEnd
# (`clear`).
#
#   live-signal.sh beat|clear
#       Reads the hook JSON on stdin and judges the project its cwd names, falling back to the
#       process directory only when the JSON carries none. Does nothing without a project or a
#       .codeo/active lock, except that `beat` in a hosted web session (CLAUDE_CODE_REMOTE=true,
#       a .codeo directory, no lock) takes the lock first (scripts/lock.sh take web, with
#       CLAUDE_CODE_REMOTE_SESSION_ID minus its cse_ prefix), at most once per
#       CODEO_LIVE_REFRESH_SECONDS (default 300), then beats. `beat` starts live.sh (and that
#       lock) in the background with every stream closed, so the hook returns at once; `clear`
#       runs in the foreground and still needs a lock. Always exits 0 and prints nothing: a
#       signal must never break a tool call.
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
    [[ $mode == beat && ${CLAUDE_CODE_REMOTE:-} == true && -d $root/.codeo ]] || exit 0
    stamp=$(git rev-parse --git-path codeo-live-lock-try 2> /dev/null) || exit 0
    interval=${CODEO_LIVE_REFRESH_SECONDS:-300}
    [[ $interval =~ ^[0-9]+$ ]] || interval=300
    now=$(date +%s)
    mtime=$(stat -c %Y "$stamp" 2> /dev/null || stat -f %m "$stamp" 2> /dev/null) || mtime=
    [[ $mtime =~ ^[0-9]+$ ]] && ((now - mtime < interval)) && exit 0
    : > "$stamp" 2> /dev/null || exit 0
    (
        bash "$here/scripts/lock.sh" take web "${CLAUDE_CODE_REMOTE_SESSION_ID#cse_}" \
            && bash "$live" beat
    ) < /dev/null > /dev/null 2>&1 &
    exit 0
fi

case $mode in
    beat) (bash "$live" beat < /dev/null > /dev/null 2>&1 &) > /dev/null 2>&1 ;;
    clear) bash "$live" clear < /dev/null > /dev/null 2>&1 ;;
esac
exit 0
