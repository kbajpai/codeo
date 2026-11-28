#!/usr/bin/env bash
# A Claude Code hook that titles a session after its container: "<window title> · <NN>-<first eight characters
# of the session id>", where the window title is window-title.sh --print's ("codeo [home]" or
# "codeo [#<N>]") and <NN> is the session's number in this container, two upper-case hex digits (00 to FF, then
# 00 again). Registered for SessionStart and UserPromptSubmit, it reads the hook's JSON on stdin and
# prints {"hookSpecificOutput":{"hookEventName":"<event>","sessionTitle":"<title>"}} on one line.
#
# Only inside a dev container (REMOTE_CONTAINERS=true, a non-empty CODEO_CMD_MODE for one started from a host command
# line, where cmd mode writes no .vscode/settings.json, or the marker file ${CODEO_SANDBOX_MARK:-~/.codeo-sandbox} that
# .sbx/codeo-sandbox.sh writes in an sbx sandbox), and only for those two events. On every such run with
# REMOTE_CONTAINERS=true or the marker it first refreshes the VS Code window title through window-title.sh (a no-op when it
# is current), even for a session that was renamed. It then prints a session title only when the session has none, or when its title
# is one this hook set (one line, this container's "<codename> [home]" or "<codename> [#<N>]" then " · " and
# "<NN>-<eight hex digits>", or the older form without "<NN>-") and differs from the new one, so a lock change
# retitles the session and a /rename'd title is left alone. Nothing is read or written for a renamed session.
# Otherwise, and when the session id is shorter than eight characters or window-title.sh fails or prints nothing,
# it prints nothing. Stderr stays empty and the exit status is 0 on every path.
#
# The number comes from a ledger of "<NN> <session id>" lines in <git dir>/codeo/session-seq (per clone, so
# per container; the last 256 lines are kept). Three rules, in order: a session keeps the number in its own
# title (the title's eight hex digits are its id's, or the event is a SessionStart with source "resume");
# else a session id already in the ledger gets its recorded number; else it takes the number after the last
# ledger line's. When the ledger cannot be read or written the title falls back to
# "<window title> · <eight characters of the id>" with no number.
#
#   bash .devcontainer/scripts/session-title.sh < <hook json>
set -uo pipefail

# seq_file: prints the absolute path of the ledger; 1 when there is none.
seq_file() {
    local p root
    p=$(git -C "$here" rev-parse --path-format=absolute --git-path codeo/session-seq 2>/dev/null) || return 1
    [[ -n $p ]] || return 1
    if [[ $p != /* ]]; then
        root=$(git -C "$here" rev-parse --show-toplevel 2>/dev/null) || return 1
        p=$root/$p
    fi
    printf '%s\n' "$p"
}

# seq_take <sid> [<nn>]: prints the session's number. A sid already in the ledger gets its recorded number;
# else <nn> when given, else the number after the last ledger line's (FF wraps to 00); the pair is appended.
# 1, with no output, on any failure.
seq_take() {
    local sid=$1 want=${2:-} file dir tmp line n last='' found='' lines=()
    file=$(seq_file) || return 1
    dir=$(dirname "$file")
    mkdir -p "$dir" 2>/dev/null || return 1
    if [[ -e $file ]]; then
        while IFS= read -r line || [[ -n $line ]]; do
            [[ $line =~ ^([0-9A-F]{2})\ (.+)$ ]] || continue
            lines+=("$line")
            last=${BASH_REMATCH[1]}
            [[ -n $found || ${BASH_REMATCH[2]} != "$sid" ]] || found=$last
        done <"$file" 2>/dev/null || return 1
    fi
    if [[ -n $found ]]; then
        printf '%s\n' "$found"
        return 0
    fi
    if [[ -n $want ]]; then
        n=$want
    elif [[ -z $last ]]; then
        n=00
    else
        printf -v n '%02X' $(((16#$last + 1) % 256))
    fi
    lines+=("$n $sid")
    ((${#lines[@]} <= 256)) || lines=("${lines[@]: -256}")
    tmp=$(mktemp "$dir/session-seq.XXXXXX" 2>/dev/null) || return 1
    if ! { printf '%s\n' "${lines[@]}" >"$tmp" && mv -f "$tmp" "$file"; } 2>/dev/null; then
        rm -f "$tmp" 2>/dev/null
        return 1
    fi
    printf '%s\n' "$n"
}

mark=${CODEO_SANDBOX_MARK:-${HOME:-}/.codeo-sandbox}
[[ ${REMOTE_CONTAINERS:-} == true || ${CODEO_CMD_MODE:-} || -e $mark ]] || exit 0
input=$(cat)
{
    IFS= read -r -d '' event
    IFS= read -r -d '' sid
    IFS= read -r -d '' existing
    IFS= read -r -d '' source
} < <(
    jq -j '[(.hook_event_name // ""), (.session_id // ""), (.session_title // ""), (.source // "")] | map(tostring)[] | ., "\u0000"' <<<"$input" 2>/dev/null
)
case $event in
    SessionStart | UserPromptSubmit) ;;
    *) exit 0 ;;
esac
here=$(dirname "${BASH_SOURCE[0]}")
[[ ${REMOTE_CONTAINERS:-} != true && ! -e $mark ]] || bash "$here/window-title.sh" >/dev/null 2>&1 || true
((${#sid} >= 8)) || exit 0
base=$(bash "$here/window-title.sh" --print 2>/dev/null) || exit 0
[[ -n $base ]] || exit 0
id8=${sid:0:8}
nn=''
if [[ -n $existing ]]; then
    # Its own shape: one line, "<codename> [home]" or "<codename> [#<digits>]" before " · " and an optional
    # "<NN>-" and any eight hex digits (a forked or resumed session inherits another session's id), with this
    # container's codename. Anything else was renamed: leave it alone, take no number.
    codename=${base% \[*\]}
    [[ $existing != *$'\n'* && $existing =~ ^(.+)\ \[(home|#[0-9]+)\]\ ·\ (([0-9A-F]{2})-)?([0-9a-f]{8})$ \
        && ${BASH_REMATCH[1]} == "$codename" ]] || exit 0
    own_nn=${BASH_REMATCH[4]}
    own_id=${BASH_REMATCH[5]}
    # A numbered title of this session (or of the session a resume continues) keeps its number.
    if [[ -n $own_nn && ( $own_id == "$id8" || $source == resume ) ]]; then
        nn=$(seq_take "$sid" "$own_nn") || nn=$own_nn
    fi
fi
if [[ -z $nn ]]; then
    nn=$(seq_take "$sid") || nn=''
fi
if [[ -n $nn ]]; then
    title="$base · $nn-$id8"
else
    title="$base · $id8"
fi
[[ $title != "$existing" ]] || exit 0
jq -cn --arg e "$event" --arg t "$title" '{hookSpecificOutput:{hookEventName:$e,sessionTitle:$t}}' 2>/dev/null
exit 0
