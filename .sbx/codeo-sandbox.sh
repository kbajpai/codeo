#!/usr/bin/env bash
# Starts, opens and ends one Docker Sandboxes (sbx) sandbox per GitHub issue. It runs on a Linux or
# WSL2 host (never macOS) under bash 4.3 or later, and drives sbx, or sbx.exe from WSL2.
#
#   codeo-sandbox.sh issue <N> <branch>
#   codeo-sandbox.sh open <N>
#   codeo-sandbox.sh shell <N>
#   codeo-sandbox.sh end <N> [--force]
#
# CODEO_SBX  the sbx program to run, instead of sbx or sbx.exe found on PATH
# CODEO_REPO_URL  the repository issue clones (default https://github.com/kbajpai/codeo.git)
set -euo pipefail

sbx=''
windows=0

# die <message> [exit-code]: print the message as one line on stderr and exit (1 by default).
die() {
    echo "codeo-sandbox: $1" >&2
    exit "${2:-1}"
}

# usage: print the usage line on stderr and exit 2.
usage() {
    echo 'usage: codeo-sandbox.sh issue <N> <branch> | open <N> | shell <N> | end <N> [--force]' >&2
    exit 2
}

# pick_sbx: set sbx to the program to run (CODEO_SBX, else sbx, else sbx.exe) and windows to 1 when
# its name ends in .exe, else 0.
pick_sbx() {
    if [[ -n "${CODEO_SBX:-}" ]]; then
        sbx=$CODEO_SBX
    elif command -v sbx >/dev/null 2>&1; then
        sbx=sbx
    elif command -v sbx.exe >/dev/null 2>&1; then
        sbx=sbx.exe
    else
        die "sbx is not installed: install Docker Sandboxes (sbx), or from WSL2 make sbx.exe reachable on PATH"
    fi
    # shellcheck disable=SC2034 # read by the sub-commands to come
    if [[ "${sbx##*/}" == *.exe ]]; then windows=1; else windows=0; fi
}

# valid_number <N>: a positive integer with no leading zero.
valid_number() {
    [[ "$1" =~ ^[1-9][0-9]*$ ]]
}

# valid_branch <branch>: starts with a letter or digit, holds only A-Za-z0-9._/- and has no "..".
valid_branch() {
    [[ "$1" =~ ^[A-Za-z0-9][A-Za-z0-9._/-]*$ && "$1" != *..* ]]
}

# sandbox_state <name>: print missing, stopped or running from the rows of "$sbx" ls (name in column 1,
# state word in column 3).
sandbox_state() {
    local name=$1 row_name _agent status _rest listing
    listing=$("$sbx" ls) || die "could not list sandboxes with $sbx"
    while read -r row_name _agent status _rest; do
        [[ "$row_name" == "$name" ]] || continue
        if [[ "$status" == running* ]]; then echo running; else echo stopped; fi
        return 0
    done <<<"$listing"
    echo missing
}

# The pinned Claude image reference, passed to "sbx create" as its kit reference in place of the agent name.
create_agent=''

# read_pin: read the one-line pin file (CODEO_SBX_IMAGE, else claude-image next to this script) into
# create_agent, refusing a missing file or a line that is not docker.io/sbx/claude@sha256:<64 hex>.
read_pin() {
    local file=${CODEO_SBX_IMAGE:-$(dirname "${BASH_SOURCE[0]}")/claude-image} line=''
    [[ -f "$file" ]] || die "the image pin $file is missing: it holds one line, docker.io/sbx/claude@sha256:<64 hex digits>"
    read -r line <"$file" || [[ -n "$line" ]] || true
    line=${line//$'\r'/}
    [[ "$line" =~ ^docker\.io/sbx/claude@sha256:[0-9a-f]{64}$ ]] ||
        die "the image pin $file is not a digest: it must be one line, docker.io/sbx/claude@sha256:<64 hex digits>"
    create_agent=$line
}

# sandbox_path <name>: print the working folder inside the sandbox (sbx exec runs there, and starts a
# stopped sandbox on its own).
sandbox_path() {
    "$sbx" exec "$1" pwd
}

# ensure_host_clone <N> <branch>: make ./codeo-N a clone on <branch>, or refuse one that is not.
ensure_host_clone() {
    local dir=codeo-$1 branch=$2 current
    if [[ ! -e "$dir" ]]; then
        git clone --branch "$branch" "${CODEO_REPO_URL:-https://github.com/kbajpai/codeo.git}" "$dir" ||
            die "git clone of $branch into $dir failed"
        return 0
    fi
    [[ -e "$dir/.git" ]] || die "$dir exists here but is not a git clone: move it away, then run this again"
    current=$(git -C "$dir" branch --show-current) || die "could not read the branch of $dir"
    [[ "$current" == "$branch" ]] ||
        die "$dir is on '$current', not $branch: check out $branch there, or remove $dir, then run this again"
}

# ensure_windows_trust <N>: with sbx.exe, make Windows git trust the clone through its \\wsl.localhost
# path, adding the line once; without git.exe, print the command as one todo line.
ensure_windows_trust() {
    ((windows == 1)) || return 0
    local path
    path="%(prefix)///wsl.localhost/${WSL_DISTRO_NAME:-}$(cd "codeo-$1" && pwd -P)"
    if ! command -v git.exe >/dev/null 2>&1; then
        echo "todo: git on Windows does not trust the clone yet: run git.exe config --global --add safe.directory $path"
        return 0
    fi
    if git.exe config --global --get-all safe.directory | tr -d '\r' | grep -Fxq -- "$path"; then
        return 0
    fi
    git.exe config --global --add safe.directory "$path" || die "git.exe could not add $path to safe.directory"
}

# ensure_sandbox <N>: create the sandbox from inside the clone unless one by that name exists (a stopped
# one is left alone: sbx exec starts it), then write the marker session-title.sh looks for. The marker is
# written on every run, so a rerun repairs a missing one.
ensure_sandbox() {
    local name=codeo-$1
    if [[ "$(sandbox_state "$name")" == missing ]]; then
        (cd "$name" && "$sbx" create --clone --name "$name" --cpus 2 --memory 4g "$create_agent" .) ||
            die "could not create the sandbox $name"
    fi
    # shellcheck disable=SC2016
    "$sbx" exec "$name" bash -c ': > "$HOME/.codeo-sandbox"' || die "could not mark the sandbox $name"
}

# git_is_usable: git is on PATH and will not open an installer (a Mac stub).
git_is_usable() {
    command -v git >/dev/null 2>&1
}

# run_start <name>: run the start script in the sandbox, carrying the host's git identity (read as in
# codeo-container.sh: git config --global, else GIT_AUTHOR_NAME/GIT_AUTHOR_EMAIL; each key on its own, a
# missing value left out).
run_start() {
    local name=$1 git_name='' git_email=''
    if git_is_usable; then
        git_name=$(git config --global user.name 2>/dev/null) || git_name=''
        git_email=$(git config --global user.email 2>/dev/null) || git_email=''
    fi
    : "${git_name:=${GIT_AUTHOR_NAME:-}}"
    : "${git_email:=${GIT_AUTHOR_EMAIL:-}}"
    set -- env CODEO_CMD_MODE=1
    if [[ -n "$git_name" ]]; then set -- "$@" "GIT_AUTHOR_NAME=$git_name"; fi
    if [[ -n "$git_email" ]]; then set -- "$@" "GIT_AUTHOR_EMAIL=$git_email"; fi
    "$sbx" exec "$name" "$@" bash .devcontainer/scripts/devcontainer-start.sh
}

# check_name <name>: print one todo line when the clone's lock names another sandbox.
check_name() {
    local name=$1 lock
    lock=$("$sbx" exec "$name" bash .devcontainer/scripts/container-name.sh --docker) || return 0
    lock=${lock//$'\r'/}
    [[ "$lock" == "$name" ]] && return 0
    echo "todo: the sandbox is $name but its lock is for $lock: end it and run issue ${lock#codeo-} <branch>"
}

cmd_issue() {
    (($# == 2)) || usage
    valid_number "$1" || usage
    valid_branch "$2" || usage
    pick_sbx
    read_pin
    ensure_host_clone "$1" "$2"
    ensure_windows_trust "$1"
    ensure_sandbox "$1"
    run_start "codeo-$1"
    check_name "codeo-$1"
}

# require_sandbox <N>: exit 1 naming the creating command unless the sandbox codeo-N exists (a stopped one
# is fine: sbx exec starts it).
require_sandbox() {
    [[ "$(sandbox_state "codeo-$1")" != missing ]] ||
        die "codeo-$1 does not exist: create it with codeo-sandbox.sh issue $1 <branch>"
}

# launch_code <uri>: open VS Code on the folder URI: CODEO_CODE when set; else with sbx.exe cmd.exe /c code
# run from /mnt/c (a UNC working folder makes cmd.exe warn); else code.
launch_code() {
    if [[ -n "${CODEO_CODE:-}" ]]; then
        "$CODEO_CODE" --folder-uri "$1"
    elif ((windows == 1)); then
        (
            if [[ -d /mnt/c ]]; then cd /mnt/c; fi
            cmd.exe /c code --folder-uri "$1"
        )
    else
        code --folder-uri "$1"
    fi
}

cmd_open() {
    (($# == 1)) || usage
    valid_number "$1" || usage
    pick_sbx
    require_sandbox "$1"
    local name=codeo-$1 path ssh=ssh
    "$sbx" exec "$name" bash .devcontainer/scripts/window-title.sh || die "could not write the window title in $name"
    path=$(sandbox_path "$name") || die "could not read the folder of $name"
    path=${path//$'\r'/}
    [[ -n "$path" ]] || die "could not read the folder of $name"
    if ((windows == 1)); then ssh=ssh.exe; fi
    "$ssh" "$name.sbx" -- true >/dev/null 2>&1 ||
        die "$name.sbx does not resolve over SSH: run $sbx setup ssh, then open again"
    launch_code "vscode-remote://ssh-remote+$name.sbx$path" || die "could not start VS Code"
}

cmd_shell() {
    (($# == 1)) || usage
    valid_number "$1" || usage
    pick_sbx
    require_sandbox "$1"
    if [[ -t 0 ]]; then
        exec "$sbx" exec -it "codeo-$1" bash -l
    fi
    exec "$sbx" exec -i "codeo-$1" bash -l
}

cmd_end() {
    (($# == 1 || $# == 2)) || usage
    valid_number "$1" || usage
    if (($# == 2)); then [[ "$2" == --force ]] || usage; fi
    pick_sbx
    die 'not yet'
}

main() {
    (($# >= 1)) || usage
    local cmd=$1
    shift
    case "$cmd" in
        issue) cmd_issue "$@" ;;
        open) cmd_open "$@" ;;
        shell) cmd_shell "$@" ;;
        end) cmd_end "$@" ;;
        *) usage ;;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi
