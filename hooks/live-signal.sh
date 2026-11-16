#!/usr/bin/env bash
# Keeps the live-session signal (scripts/live.sh) fresh while a codeo session works and clears it
# when the session ends. Hooked to UserPromptSubmit and PostToolUse (`beat`) and SessionEnd (`clear`).
#
#   live-signal.sh beat|clear
#       Reads the hook JSON on stdin and judges the project its cwd names, falling back to the
#       process directory only when the JSON carries none. Does nothing without a project or a .codeo/active lock. `beat` starts live.sh in the
#       background with every stream closed, so the hook returns at once; `clear` runs in the
#       foreground. Always exits 0 and prints nothing: a signal must never break a tool call.
# No `set -e`: every failure below is swallowed on purpose.

mode=${1:-}
input=$(cat 2> /dev/null) || input=
cwd=$(jq -r '.cwd // empty' <<< "$input" 2> /dev/null) || cwd=
root=$(git -C "${cwd:-.}" rev-parse --show-toplevel 2> /dev/null) || exit 0
[[ -n $root && -f $root/.codeo/active ]] || exit 0

cd "$root" 2> /dev/null || exit 0
live="$(dirname "${BASH_SOURCE[0]}")/../scripts/live.sh"

case $mode in
    beat) (bash "$live" beat < /dev/null > /dev/null 2>&1 &) > /dev/null 2>&1 ;;
    clear) bash "$live" clear < /dev/null > /dev/null 2>&1 ;;
esac
exit 0
