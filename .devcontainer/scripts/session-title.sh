#!/usr/bin/env bash
# A Claude Code hook that titles a session after its container: "<window title> · <first eight characters
# of the session id>", where the window title is window-title.sh --print's ("codeo [home]" or
# "codeo [#<N>]"). Registered for SessionStart and UserPromptSubmit, it reads the hook's JSON on stdin and
# prints {"hookSpecificOutput":{"hookEventName":"<event>","sessionTitle":"<title>"}} on one line.
#
# Only inside a dev container (REMOTE_CONTAINERS=true), and only for those two events. On every such run it
# first refreshes the VS Code window title through window-title.sh (a no-op when it is current), even for a
# session that was renamed. It then prints a session title only when the session has none, or when its title
# is one this hook set (it ends in " · <first eight of this session id>") and differs from the new one, so a
# lock change retitles the session and a /rename'd title is left alone. Otherwise, and when the session id is
# shorter than eight characters or window-title.sh fails or prints nothing, it prints nothing. Stderr stays
# empty and the exit status is 0 on every path.
#
#   bash .devcontainer/scripts/session-title.sh < <hook json>
set -uo pipefail

[[ ${REMOTE_CONTAINERS:-} == true ]] || exit 0
input=$(cat)
{
    IFS= read -r -d '' event
    IFS= read -r -d '' sid
    IFS= read -r -d '' existing
} < <(
    jq -j '[(.hook_event_name // ""), (.session_id // ""), (.session_title // "")] | map(tostring)[] | ., "\u0000"' <<<"$input" 2>/dev/null
)
case $event in
    SessionStart | UserPromptSubmit) ;;
    *) exit 0 ;;
esac
here=$(dirname "${BASH_SOURCE[0]}")
bash "$here/window-title.sh" >/dev/null 2>&1 || true
((${#sid} >= 8)) || exit 0
base=$(bash "$here/window-title.sh" --print 2>/dev/null) || exit 0
[[ -n $base ]] || exit 0
title="$base · ${sid:0:8}"
if [[ -n $existing ]]; then
    [[ $existing == *" · ${sid:0:8}" && $existing != "$title" ]] || exit 0
fi
jq -cn --arg e "$event" --arg t "$title" '{hookSpecificOutput:{hookEventName:$e,sessionTitle:$t}}' 2>/dev/null
exit 0
