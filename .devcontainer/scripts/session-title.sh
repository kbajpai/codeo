#!/usr/bin/env bash
# A Claude Code hook that titles a session after its container: "<window title> · <first eight characters
# of the session id>", where the window title is window-title.sh --print's ("codeo [home]" or
# "codeo [#<N>]"). Registered for SessionStart and UserPromptSubmit, it reads the hook's JSON on stdin and
# prints {"hookSpecificOutput":{"hookEventName":"<event>","sessionTitle":"<title>"}} on one line.
# Only inside a dev container (REMOTE_CONTAINERS=true), and only for those two events. Prints nothing and
# exits 0 on any failure, and when the session already has a title (session_title is non-empty), when the
# session id is shorter than eight characters, or when window-title.sh fails or prints nothing.
#
#   bash .devcontainer/scripts/session-title.sh < <hook json>
set -uo pipefail

[[ ${REMOTE_CONTAINERS:-} == true ]] || exit 0
input=$(cat)
IFS=$'\x1f' read -r event sid existing < <(
    jq -r '[.hook_event_name // "", .session_id // "", .session_title // ""] | join("\u001f")' <<<"$input" 2>/dev/null
) || exit 0
case $event in
    SessionStart | UserPromptSubmit) ;;
    *) exit 0 ;;
esac
[[ -z $existing ]] || exit 0
((${#sid} >= 8)) || exit 0
base=$(bash "$(dirname "${BASH_SOURCE[0]}")/window-title.sh" --print 2>/dev/null) || exit 0
[[ -n $base ]] || exit 0
jq -cn --arg e "$event" --arg t "$base · ${sid:0:8}" '{hookSpecificOutput:{hookEventName:$e,sessionTitle:$t}}' 2>/dev/null
exit 0
