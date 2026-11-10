#!/usr/bin/env bash
# Whether a container's clone folder says what its workflow lock does, for devcontainer-start.sh.
# The folder is the container's Docker name (.devcontainer/devcontainer.json runArgs --name), and
# container-name.sh --docker is what the name should be.
#
#   folder-check.sh <folder> [dir]
#       Prints nothing when the folder is right, or one "todo: ..." line naming the folder it should
#       have. dir is anywhere inside the clone (default: the current directory). Exits 0 whether or
#       not it prints a line, and 1 when container-name.sh fails (not a git clone, say), after one
#       "folder-check: ..." line carrying its message.
#
# With a lock the folder must be exactly the Docker name. Without one the branch decides. On main the
# clone is the home container, so its folder must be exactly '<codename>-home'. Anything else is an
# issue container that failed to take its lock (and the lock script has already said why), so an
# issue folder, <codename>-<digits>, is left alone and only a folder of neither shape is reported.
set -euo pipefail

here=$(dirname "${BASH_SOURCE[0]}")
have=${1:?folder}
dir=${2:-.}
# container-name.sh prints one line; its failure message is repeated on folder-check's own line,
# because the caller keeps that line and the message would be lost.
errf=$(mktemp)
trap 'rm -f "$errf"' EXIT
want=$(bash "$here/container-name.sh" --docker "$dir" 2>"$errf") || {
    echo "folder-check: container-name.sh failed for '$dir': $(sed ':a;N;$!ba;s/\n/ \/ /g' "$errf")" >&2
    exit 1
}
codename=$(bash "$here/container-name.sh" --codename "$dir")
# The codename may hold regex metacharacters, so the issue-folder test compares a prefix and digits.
locked=
[[ $want == "$codename-home" ]] || locked=1

branch=
if [[ -z $locked ]]; then
    branch=$(git -C "$dir" branch --show-current 2>/dev/null || true)
fi

if [[ -n $locked ]]; then
    [[ $have == "$want" ]] \
        || echo "todo: this container's folder is '$have' but its lock says '$want', so 'docker ps' names it wrongly: remove it and open it again with the folder '$want' (.devcontainer/README.md)"
elif [[ $branch == main ]]; then
    [[ $have == "$codename-home" ]] \
        || echo "todo: this container's folder is '$have' but its clone is on main with no lock, so it is the home container and 'docker ps' names it wrongly: remove it and open it again with the folder '$codename-home' (.devcontainer/README.md)"
else
    suffix=${have#"$codename-"}
    if [[ $have != "$codename-home" && ( $suffix == "$have" || ! $suffix =~ ^[0-9]+$ ) ]]; then
        echo "todo: this container's folder is '$have', so 'docker ps' names it wrongly: remove it and open it again with the folder '$codename-<N>' (or '$codename-home' for the home container) (.devcontainer/README.md)"
    fi
fi
