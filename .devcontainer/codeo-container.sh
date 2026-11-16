#!/usr/bin/env bash
# Starts a codeo dev container from a host shell, without VS Code. It runs on the host under bash 3.2
# (macOS) and needs only Docker: it builds the image from the repository's .devcontainer/, runs the
# container with the same name, volumes, memory cap and git config as the VS Code route, clones the
# repository into it and runs the container's start script in cmd mode (CODEO_CMD_MODE=1).
#
#   codeo-container.sh home [--rebuild]
#   codeo-container.sh issue <N> <branch> [--rebuild]
#   codeo-container.sh shell home|<N>
#
# CODEO_REPO_URL  the repository to build from and clone (default https://github.com/kbajpai/codeo.git)
# CODEO_CONTEXT   a local directory to build the image from instead of the Git URL (a developer's own clone)
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
        echo '       codeo-container.sh issue <N> <branch> [--rebuild]'
        echo '       codeo-container.sh shell home|<N>'
    } >&2
    exit 2
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

# ensure_container <name> <ref> <rebuild:0|1>: leave the container running, creating it (and its image)
# when missing. --rebuild removes it first; the volumes are never touched.
ensure_container() {
    local name=$1 ref=$2 rebuild=$3 state build_context
    state=$(container_state "$name")
    if [[ "$rebuild" == 1 && "$state" != missing ]]; then
        docker rm -f "$name"
        state=missing
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
    fi
    docker run -d --init --name "$name" --hostname "$name" --memory=4g \
        -v "$name:/workspaces" -v codeo-gh:/home/dev/.config/gh -v codeo-git:/home/dev/.config/git \
        -e GIT_CONFIG_GLOBAL=/home/dev/.config/git/config -e CLAUDE_CONFIG_DIR=/workspaces/.claude \
        -e CODEO_CMD_MODE=1 "codeo-dev:$name" sleep infinity
    docker exec -u root "$name" chown dev:dev /workspaces
}

# ensure_clone <name> <ref>: clone the repository at <ref> into /workspaces/<name> unless it is there.
ensure_clone() {
    local name=$1 ref=$2
    if ! docker exec "$name" test -d "/workspaces/$name/.git"; then
        docker exec "$name" git clone --branch "$ref" "$repo_url" "/workspaces/$name" \
            || die "could not clone branch $ref of $repo_url into $name"
    fi
}

# run_start <name>: run the container's start script in its clone, carrying the host's git identity
# (git config user.name/user.email when git is on PATH, else GIT_AUTHOR_NAME/GIT_AUTHOR_EMAIL; each
# key on its own, and a missing value is left out). Only this exec gets it, never docker run.
run_start() {
    local name=$1 git_name='' git_email=''
    if command -v git >/dev/null 2>&1; then
        git_name=$(git config user.name 2>/dev/null) || git_name=''
        git_email=$(git config user.email 2>/dev/null) || git_email=''
    fi
    : "${git_name:=${GIT_AUTHOR_NAME:-}}"
    : "${git_email:=${GIT_AUTHOR_EMAIL:-}}"
    set -- exec
    if [[ -n "$git_name" ]]; then set -- "$@" -e "GIT_AUTHOR_NAME=$git_name"; fi
    if [[ -n "$git_email" ]]; then set -- "$@" -e "GIT_AUTHOR_EMAIL=$git_email"; fi
    set -- "$@" -w "/workspaces/$name" "$name" bash .devcontainer/scripts/devcontainer-start.sh
    docker "$@"
}

# bring_up <name> <ref> <rebuild:0|1>: the whole route for one container, shared by home and issue.
bring_up() {
    ensure_container "$1" "$2" "$3"
    ensure_clone "$1" "$2"
    run_start "$1"
}

# require_docker: exit 1 with one line unless the Docker daemon answers.
require_docker() {
    docker info >/dev/null 2>&1 \
        || die 'Docker is not available: install it and start it, then run this again'
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
    bring_up codeo-home "$base_ref" "$rebuild"
}

# cmd_issue <args...>: issue <N> <branch> [--rebuild]. N is a positive integer without a leading zero;
# the branch starts with a letter or digit and holds only letters, digits, . _ / - and no "..".
cmd_issue() {
    local rebuild=0
    case $# in
        2) ;;
        3) [[ "$3" == --rebuild ]] || usage; rebuild=1 ;;
        *) usage ;;
    esac
    case "$1" in '' | 0* | *[!0-9]*) usage ;; esac
    case "$2" in '' | *..* | [!A-Za-z0-9]* | *[!A-Za-z0-9._/-]*) usage ;; esac
    require_docker
    bring_up "codeo-$1" "$2" "$rebuild"
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
