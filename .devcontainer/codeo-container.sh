#!/usr/bin/env bash
# Starts a codeo dev container from a host shell, without VS Code. It runs on the host under bash 3.2
# (macOS) and needs only Docker: it builds the image from the repository's .devcontainer/, runs the
# container with the same name, volumes, memory cap and git config as the VS Code route, clones the
# repository into it and runs the container's start script in cmd mode (CODEO_CMD_MODE=1).
#
#   codeo-container.sh home [--rebuild]
#   codeo-container.sh issue <N> <branch> [--rebuild] [--yes]
#   codeo-container.sh shell home|<N>
#
# CODEO_REPO_URL  the repository to build from and clone (default https://github.com/kbajpai/codeo.git)
# CODEO_TRACK     the tracker (default: codeo-track.sh beside this script). An issue container, its image and volume are
#                 recorded on the issue, and a duplicate on another host is asked about first (--yes answers it)
# CODEO_CONTEXT   the .devcontainer directory of a local clone, to build the image from instead of the Git URL (the
#                 repository is still cloned from CODEO_REPO_URL)
set -euo pipefail

repo_url=${CODEO_REPO_URL:-https://github.com/kbajpai/codeo.git}
base_ref=main
context=${CODEO_CONTEXT:-}

# die <message> [exit-code]: print the message as one line on stderr and exit (1 by default).
die() {
    echo "codeo-container: $1" >&2
    exit "${2:-1}"
}

# usage: print the usage on stderr and exit 2.
usage() {
    {
        echo 'usage: codeo-container.sh home [--rebuild]'
        echo '       codeo-container.sh issue <N> <branch> [--rebuild] [--yes]'
        echo '       codeo-container.sh shell home|<N>'
    } >&2
    exit 2
}

# The tracker: CODEO_TRACK, else codeo-track.sh beside this script (a bare script name has no slash, so its
# directory is .).
script_dir=${BASH_SOURCE[0]%/*}
[[ "$script_dir" != "${BASH_SOURCE[0]}" ]] || script_dir=.
tracker=${CODEO_TRACK:-$script_dir/codeo-track.sh}
track_noted=0

# track_present: succeed when the tracker exists; otherwise say so once per run and fail.
track_present() {
    [[ -f "$tracker" ]] && return 0
    if [[ "$track_noted" == 0 ]]; then
        track_noted=1
        echo 'codeo-container: note: codeo-track.sh is not beside this script, so nothing was recorded on the issue (codeo update fetches it)' >&2
    fi
    return 1
}

# track <args...>: run the tracker, ignoring its status: a failed record never fails a creation.
track() {
    track_present || return 0
    "$BASH" "$tracker" "$@" || true
}

# track_confirm <N> <yes:0|1>: ask the tracker whether to go on; exit 1 when it says stop.
track_confirm() {
    track_present || return 0
    if [[ "$2" == 1 ]]; then
        "$BASH" "$tracker" confirm "$1" --yes || exit 1
    else
        "$BASH" "$tracker" confirm "$1" || exit 1
    fi
}

# container_state <name>: print missing, stopped or running.
container_state() {
    local running
    if ! running=$(docker inspect --format '{{.State.Running}}' "$1" 2>/dev/null); then
        echo missing
    elif [[ "$running" == true ]]; then
        echo running
    else
        echo stopped
    fi
}

# ensure_container <name> <ref> <rebuild:0|1> <fresh_only:0|1> <yes:0|1>: leave the container running, creating it
# (and its image) when missing. --rebuild removes it first; the volumes are never touched. With fresh_only
# (issue) a container that exists and is not being rebuilt is refused rather than reused.
ensure_container() {
    local name=$1 ref=$2 rebuild=$3 fresh_only=$4 yes=${5:-0} state build_context n="" tracked=0 built=0
    case "$name" in codeo-[0-9]*) tracked=1; n=${name#codeo-} ;; esac
    state=$(container_state "$name")
    if [[ "$fresh_only" == 1 && "$rebuild" == 0 && "$state" != missing ]]; then
        n=${name#codeo-}
        if [[ "$tracked" == 1 ]]; then echo "codeo-container: warning: $name already exists on this host ($state)" >&2; fi
        die "$name already exists: enter it with 'bash codeo-container.sh shell $n', rebuild it with 'bash codeo-container.sh issue $n $ref --rebuild', or remove it (docker rm -f $name; docker volume rm $name, once git status in it shows nothing unpushed) to start from a fresh clone"
    fi
    if [[ "$tracked" == 1 && ("$state" == missing || "$rebuild" == 1) ]]; then
        track_confirm "$n" "$yes"
    fi
    if [[ "$rebuild" == 1 && "$state" != missing ]]; then
        docker rm -f "$name"
        state=missing
        if [[ "$tracked" == 1 ]]; then
            track mark "$n" container "$name" removed
            track mark "$n" image "codeo-dev:$name" removed
        fi
    fi
    case "$state" in
        running) return 0 ;;
        stopped)
            docker start "$name"
            return 0
            ;;
    esac
    if [[ "$rebuild" == 1 ]] || ! docker image inspect "codeo-dev:$name" >/dev/null 2>&1; then
        build_context=${context:-$repo_url#$ref:.devcontainer}
        docker build -t "codeo-dev:$name" "$build_context"
        built=1
    fi
    docker run -d --init --name "$name" --hostname "$name" --memory=4g \
        -v "$name:/workspaces" -v codeo-gh:/home/dev/.config/gh -v codeo-git:/home/dev/.config/git \
        -e GIT_CONFIG_GLOBAL=/home/dev/.config/git/config -e CLAUDE_CONFIG_DIR=/workspaces/.claude \
        -e CODEO_CMD_MODE=1 "codeo-dev:$name" sleep infinity
    docker exec -u root "$name" chown dev:dev /workspaces
    if [[ "$tracked" == 1 ]]; then
        if [[ "$built" == 1 ]]; then track add "$n" image "codeo-dev:$name"; fi
        track add "$n" container "$name"
        track add "$n" volume "$name"
    fi
}

# ensure_clone <name> <ref> <check_branch:0|1>: clone the repository at <ref> into /workspaces/<name> unless
# it is there. With check_branch (issue) a clone already there must be on <ref>.
ensure_clone() {
    local name=$1 ref=$2 check_branch=$3 current
    if ! docker exec "$name" test -d "/workspaces/$name/.git"; then
        docker exec "$name" git clone --branch "$ref" "$repo_url" "/workspaces/$name" \
            || die "could not clone branch $ref of $repo_url into $name"
    elif [[ "$check_branch" == 1 ]]; then
        current=$(docker exec "$name" git -C "/workspaces/$name" branch --show-current) || current=''
        [[ "$current" == "$ref" ]] && return 0
        if [[ -n "$current" ]]; then current="'$current'"; else current='(no branch)'; fi
        die "the clone in $name is on $current, not '$ref': remove it (docker rm -f $name; docker volume rm $name, once git status in it shows nothing unpushed) or give the branch it is on"
    fi
}

# git_is_usable: succeed when git is on PATH and will not open an installer. On a Mac /usr/bin/git is a
# stub that opens the Command Line Tools install dialog, so there git counts only once xcode-select -p succeeds.
git_is_usable() {
    command -v git >/dev/null 2>&1 || return 1
    if [[ "$(uname -s 2>/dev/null || true)" == Darwin ]]; then
        xcode-select -p >/dev/null 2>&1 || return 1
    fi
    return 0
}

# run_start <name>: run the container's start script in its clone, carrying the host's git identity
# (git config --global user.name/user.email when git is usable, else GIT_AUTHOR_NAME/GIT_AUTHOR_EMAIL; each
# key on its own, and a missing value is left out). Only this exec gets it, never docker run.
run_start() {
    local name=$1 git_name='' git_email=''
    if git_is_usable; then
        git_name=$(git config --global user.name 2>/dev/null) || git_name=''
        git_email=$(git config --global user.email 2>/dev/null) || git_email=''
    fi
    : "${git_name:=${GIT_AUTHOR_NAME:-}}"
    : "${git_email:=${GIT_AUTHOR_EMAIL:-}}"
    set -- exec
    if [[ -n "$git_name" ]]; then set -- "$@" -e "GIT_AUTHOR_NAME=$git_name"; fi
    if [[ -n "$git_email" ]]; then set -- "$@" -e "GIT_AUTHOR_EMAIL=$git_email"; fi
    set -- "$@" -w "/workspaces/$name" "$name" bash .devcontainer/scripts/devcontainer-start.sh
    docker "$@"
}

# bring_up <name> <ref> <rebuild:0|1> <fresh_only:0|1> [yes:0|1]: the whole route for one container, shared by home
# and issue (fresh_only is 1 for issue: it refuses an existing container and a clone on another branch).
bring_up() {
    ensure_container "$1" "$2" "$3" "$4" "${5:-0}"
    ensure_clone "$1" "$2" "$4"
    run_start "$1"
}

# require_docker: exit 1 with one line unless the Docker daemon answers; the line carries the first line of
# docker info's own stderr when there is one.
require_docker() {
    local err
    err=$(docker info 2>&1 >/dev/null) && return 0
    err=${err%%$'\n'*}
    if [[ -n "$err" ]]; then
        die "Docker is not available: $err"
    fi
    die 'Docker is not available: install it and start it, then run this again'
}

# cmd_home <args...>: home [--rebuild].
cmd_home() {
    local rebuild=0
    case $# in
        0) ;;
        1) [[ "$1" == --rebuild ]] || usage; rebuild=1 ;;
        *) usage ;;
    esac
    require_docker
    bring_up codeo-home "$base_ref" "$rebuild" 0
}

# cmd_issue <args...>: issue <N> <branch> [--rebuild] [--yes], the flags in either order. N is a positive integer without a leading zero;
# the branch starts with a letter or digit and holds only letters, digits, . _ / - and no "..".
cmd_issue() {
    local rebuild=0 yes=0 arg num branch
    [[ $# -ge 2 ]] || usage
    num=$1 branch=$2
    shift 2
    for arg in "$@"; do
        case "$arg" in
            --rebuild) rebuild=1 ;;
            --yes) yes=1 ;;
            *) usage ;;
        esac
    done
    case "$num" in '' | 0* | *[!0-9]*) usage ;; esac
    case "$branch" in '' | *..* | [!A-Za-z0-9]* | *[!A-Za-z0-9._/-]*) usage ;; esac
    require_docker
    bring_up "codeo-$num" "$branch" "$rebuild" 1 "$yes"
}

# cmd_shell <args...>: shell home|<N>. Opens a login bash in the container's clone, starting the container
# first when it is stopped. N is as for issue. The container's shell status becomes the script's.
cmd_shell() {
    local name title create flags=''
    [[ $# -eq 1 ]] || usage
    case "$1" in
        home)
            name=codeo-home
            title='codeo [home]'
            create="bash codeo-container.sh home"
            ;;
        '' | 0* | *[!0-9]*) usage ;;
        *)
            name="codeo-$1"
            title="codeo [#$1]"
            create="bash codeo-container.sh issue $1 <branch>"
            ;;
    esac
    require_docker
    case "$(container_state "$name")" in
        missing) die "no container $name: create it with '$create'" ;;
        stopped) docker start "$name" ;;
    esac
    if [ -t 1 ]; then printf '\033]0;%s\007' "$title"; fi
    flags=-i
    if [ -t 0 ] && [ -t 1 ]; then flags=-it; fi
    # shellcheck disable=SC2086
    exec docker exec $flags -w "/workspaces/$name" "$name" bash -l
}

main() {
    [[ $# -ge 1 ]] || usage
    local cmd=$1
    shift
    case "$cmd" in
        home) cmd_home "$@" ;;
        issue) cmd_issue "$@" ;;
        shell) cmd_shell "$@" ;;
        *) usage ;;
    esac
}

main "$@"
