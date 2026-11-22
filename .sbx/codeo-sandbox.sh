#!/usr/bin/env bash
# Starts, opens and ends one Docker Sandboxes (sbx) sandbox per GitHub issue. It runs on a Linux or
# WSL2 host (never macOS) under bash 4.3 or later, and drives sbx, or sbx.exe from WSL2.
#
#   codeo-sandbox.sh issue <N> <branch> [--yes]
#   codeo-sandbox.sh open <N>
#   codeo-sandbox.sh shell <N>
#   codeo-sandbox.sh end <N> [--force]
#
# CODEO_SBX  the sbx program to run, instead of sbx or sbx.exe found on PATH
# CODEO_REPO_URL  the repository issue clones (default https://github.com/kbajpai/codeo.git)
# CODEO_TRACK  the tracker (default: codeo-track.sh beside this script); issue records the sandbox on the issue, end marks it removed
set -euo pipefail

sbx=''
windows=0

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
        echo 'codeo-sandbox: note: codeo-track.sh is not beside this script, so nothing was recorded on the issue (codeo update fetches it)' >&2
    fi
    return 1
}

# track <args...>: run the tracker, ignoring its status: a failed record never fails a creation or an end.
track() {
    track_present || return 0
    "$BASH" "$tracker" "$@" || true
}

# track_confirm <N> <yes:0|1>: ask the tracker whether to go on (naming a local container codeo-N when docker
# lists one); exit 1 when it says stop.
track_confirm() {
    track_present || return 0
    local args=(confirm "$1") names
    if [[ "$2" == 1 ]]; then args+=(--yes); fi
    if command -v docker >/dev/null 2>&1; then
        names=$(docker ps -a --format '{{.Names}}' 2>/dev/null) || names=''
        if grep -Fxq "codeo-$1" <<<"$names"; then args+=(--local "a container codeo-$1 exists on this host"); fi
    fi
    "$BASH" "$tracker" "${args[@]}" || exit 1
}

# die <message> [exit-code]: print the message as one line on stderr and exit (1 by default).
die() {
    echo "codeo-sandbox: $1" >&2
    exit "${2:-1}"
}

# usage: print the usage line on stderr and exit 2.
usage() {
    echo 'usage: codeo-sandbox.sh issue <N> <branch> [--yes] | open <N> | shell <N> | end <N> [--force]' >&2
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

# sandbox_state <name>: print missing, stopped, running or detached from the rows of "$sbx" ls (name in
# column 1, a header row skipped; a leading marker word is dropped by position, so no locale matters).
# A failed ls is a die, so callers assign the output to a variable before testing it.
sandbox_state() {
    local name=$1 row_name agent status listing
    listing=$("$sbx" ls) || die "could not list sandboxes with $sbx"
    while read -r row_name agent status; do
        [[ "$row_name" == "$name" && "$agent" != AGENT ]] || continue
        [[ "$status" == [a-z]* ]] || status=${status#* }
        case "$status" in
            "running (detached)"*) echo detached ;;
            running*) echo running ;;
            *) echo stopped ;;
        esac
        return 0
    done <<<"$listing"
    echo missing
}

# The pinned Claude image reference, passed to "sbx create" as its kit reference in place of the agent name.
create_agent=''
# The state require_sandbox read for the sandbox, passed on to ensure_detached.
required_state=''

# read_pin <N>: read the one-line pin into create_agent from the first of CODEO_SBX_IMAGE (a file path),
# codeo-N/.sbx/claude-image, and origin/HEAD:.sbx/claude-image in the clone; refuse none of them, or a
# line that is not docker.io/sbx/claude@sha256:<64 hex>.
read_pin() {
    local dir=codeo-$1 source line=''
    if [[ -n "${CODEO_SBX_IMAGE:-}" ]]; then
        source=$CODEO_SBX_IMAGE
        [[ -f "$source" ]] || die "the image pin $source is missing: it holds one line, docker.io/sbx/claude@sha256:<64 hex digits>"
        read -r line <"$source" || [[ -n "$line" ]] || true
    elif [[ -f "$dir/.sbx/claude-image" ]]; then
        source=$dir/.sbx/claude-image
        read -r line <"$source" || [[ -n "$line" ]] || true
    else
        source=origin/HEAD:.sbx/claude-image
        line=$(git -C "$dir" show "$source" 2>/dev/null | head -n 1) || line=''
        [[ -n "$line" ]] ||
            die "no image pin: set CODEO_SBX_IMAGE to a file, or commit $dir/.sbx/claude-image, or put .sbx/claude-image on origin/HEAD (git show origin/HEAD:.sbx/claude-image)"
    fi
    line=${line//$'\r'/}
    [[ "$line" =~ ^docker\.io/sbx/claude@sha256:[0-9a-f]{64}$ ]] ||
        die "the image pin $source is not a digest: it must be one line, docker.io/sbx/claude@sha256:<64 hex digits>"
    create_agent=$line
}

# sandbox_path <name>: print the working folder inside the sandbox (sbx exec runs there, and starts a
# stopped sandbox on its own).
sandbox_path() {
    "$sbx" exec "$1" pwd
}

# ensure_host_clone <N> <branch>: make ./codeo-N a clone on <branch>, or refuse one that is not; an existing
# clone whose sandbox is missing is fast-forwarded to origin/<branch> (refused when it cannot be).
ensure_host_clone() {
    local dir=codeo-$1 branch=$2 current state
    if [[ ! -e "$dir" ]]; then
        git clone --branch "$branch" "${CODEO_REPO_URL:-https://github.com/kbajpai/codeo.git}" "$dir" ||
            die "git clone of $branch into $dir failed"
        return 0
    fi
    [[ -e "$dir/.git" ]] || die "$dir exists here but is not a git clone: move it away, then run this again"
    current=$(git -C "$dir" branch --show-current) || die "could not read the branch of $dir"
    [[ "$current" == "$branch" ]] ||
        die "$dir is on '$current', not $branch: check out $branch there, or remove $dir, then run this again"
    # A sandbox already made from the clone owns it now: leave it be. Otherwise bring it up to origin.
    state=$(sandbox_state "$dir")
    [[ "$state" == missing ]] || return 0
    git -C "$dir" fetch -q origin || die "git fetch origin in $dir failed: nothing was created"
    git -C "$dir" ls-remote --exit-code --heads origin "$branch" >/dev/null 2>&1 ||
        die "origin has no branch origin/$branch: push it, then run this again"
    git -C "$dir" merge --ff-only "origin/$branch" >/dev/null 2>&1 ||
        die "$dir cannot be brought up to origin/$branch: settle it there, or remove $dir, then run this again"
}

# ensure_windows_trust <N>: with sbx.exe, make Windows git trust the clone through its \\wsl.localhost
# path, adding the line once; without git.exe, print the command as one todo line.
ensure_windows_trust() {
    ((windows == 1)) || return 0
    local path
    if [[ -z ${WSL_DISTRO_NAME:-} ]]; then
        echo "todo: WSL_DISTRO_NAME is not set, so the clone's Windows path is not known: run git.exe config --global --add safe.directory %(prefix)///wsl.localhost/<distro>$(cd "codeo-$1" && pwd -P)"
        return 0
    fi
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

# ensure_sandbox <N>: read the image pin and create the sandbox from inside the clone unless one by that name exists (a stopped
# one is left alone: sbx exec starts it), then write the marker session-title.sh looks for, holding the sandbox name. The marker is
# written on every run, so a rerun repairs a missing one.
ensure_sandbox() {
    local name=codeo-$1 state yes=${2:-0}
    state=$(sandbox_state "$name")
    if [[ "$state" == missing ]]; then
        read_pin "$1"
        track_confirm "$1" "$yes"
        (cd "$name" && "$sbx" create --clone --name "$name" --cpus 2 --memory 4g "$create_agent" .) ||
            die "could not create the sandbox $name"
        track add "$1" sandbox "$name"
    fi
    # shellcheck disable=SC2016
    "$sbx" exec "$name" bash -c 'printf "%s\n" "$1" > "$HOME/.codeo-sandbox"' _ "$name" || die "could not mark the sandbox $name"
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
    if [[ "$lock" != codeo-[1-9]* ]]; then
        echo "todo: the sandbox is $name but its clone holds no workflow lock: run /codeo:init #${name#codeo-} on its branch, then issue ${name#codeo-} <branch> again"
        return 0
    fi
    echo "todo: the sandbox is $name but its lock is for $lock: end it and run issue ${lock#codeo-} <branch>"
}

# ensure_detached <name> [state]: unless the state (read with sandbox_state when not given) is detached,
# start the sandbox with sbx run -d (a stopped
# or attached one is started or re-run detached) so it does not stop when idle.
ensure_detached() {
    local name=$1 state=${2:-}
    [[ -n "$state" ]] || state=$(sandbox_state "$name")
    [[ "$state" == detached ]] && return 0
    "$sbx" run -d --name "$name" >/dev/null || die "could not start $name detached: run $sbx run -d --name $name"
}

cmd_issue() {
    local yes=0
    if (($# == 3)) && [[ "$3" == --yes ]]; then yes=1; set -- "$1" "$2"; fi
    (($# == 2)) || usage
    valid_number "$1" || usage
    valid_branch "$2" || usage
    pick_sbx
    ensure_host_clone "$1" "$2"
    ensure_windows_trust "$1"
    ensure_sandbox "$1" "$yes"
    run_start "codeo-$1" ||
        die "the start script failed in codeo-$1: fix what it printed above, then run codeo-sandbox.sh issue $1 $2 again, or codeo-sandbox.sh shell $1 to look inside"
    check_name "codeo-$1"
    ensure_detached "codeo-$1"
}

# require_sandbox <N>: leave the state in required_state; exit 1 naming the creating command unless the sandbox codeo-N exists (a stopped one
# is fine: sbx exec starts it).
require_sandbox() {
    local state
    state=$(sandbox_state "codeo-$1")
    required_state=$state
    [[ "$state" != missing ]] ||
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

# uri_path <path>: print the path with every byte outside A-Za-z0-9/._~- written %XX in upper-case hex
# (byte-wise, so a multi-byte character becomes one %XX per byte).
uri_path() {
    local LC_ALL=C s=$1 out='' c i
    for ((i = 0; i < ${#s}; i++)); do
        c=${s:i:1}
        case $c in
            [A-Za-z0-9/._~-]) out+=$c ;;
            *) out+=$(printf '%%%02X' "'$c") ;;
        esac
    done
    printf '%s' "$out"
}

cmd_open() {
    (($# == 1)) || usage
    valid_number "$1" || usage
    pick_sbx
    require_sandbox "$1"
    local name=codeo-$1 path ssh=ssh
    ensure_detached "$name" "$required_state"
    "$sbx" exec "$name" bash .devcontainer/scripts/window-title.sh || die "could not write the window title in $name"
    path=$(sandbox_path "$name") || die "could not read the folder of $name"
    path=${path//$'\r'/}
    [[ -n "$path" ]] || die "could not read the folder of $name"
    if ((windows == 1)); then ssh=ssh.exe; fi
    "$ssh" -o BatchMode=yes -o ConnectTimeout=10 "$name.sbx" -- true >/dev/null 2>&1 ||
        die "$name.sbx does not resolve over SSH: run $sbx setup ssh, then open again"
    launch_code "vscode-remote://ssh-remote+$name.sbx$(uri_path "$path")" || die "could not start VS Code"
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

# unpushed_commits <clone> <name>: print (one line each) the commits under refs/sandboxes/<name>/ that
# are on no origin branch and under no pull-request head (--remotes=origin covers refs/remotes/origin/pr/*,
# which cmd_end fetches: a squash merge leaves the commits only there); return 0 with no output when none.
unpushed_commits() {
    git -C "$1" rev-list --oneline --glob="refs/sandboxes/$2/*" --not --remotes=origin
}

# fetch_sandbox <dir> <name>: mirror the sandbox's branches into refs/sandboxes/<name>/. From WSL the
# sandbox's git daemon answers only Windows git, so git.exe runs from inside the clone.
fetch_sandbox() {
    if ((windows == 1)); then
        (cd "$1" && git.exe fetch "sandbox-$2")
    else
        git -C "$1" fetch "sandbox-$2"
    fi
}

# clear_sandbox_refs <clone> <name>: delete every ref under refs/sandboxes/<name>/ in one transaction.
clear_sandbox_refs() {
    local lines
    lines=$(git -C "$1" for-each-ref --format='delete %(refname) %(objectname)' "refs/sandboxes/$2/") || return 1
    [[ -z "$lines" ]] && return 0
    git -C "$1" update-ref --stdin <<<"$lines"
}

# set_aside_sandbox_refs <clone> <name>: move every ref under refs/sandboxes/<name>/ to
# refs/codeo/ended/<name>/<UTC>/ in one transaction and print that prefix (nothing when there are no refs).
# `create` refuses an existing ref, so a clash within one second fails the whole transaction and moves nothing.
set_aside_sandbox_refs() {
    local prefix lines ref sha rest
    lines=$(git -C "$1" for-each-ref --format='%(objectname) %(refname)' "refs/sandboxes/$2/") || return 1
    [[ -z "$lines" ]] && return 0
    prefix=refs/codeo/ended/$2/$(date -u +%Y%m%dT%H%M%SZ)/ || return 1
    local tx=
    while read -r sha ref; do
        rest=${ref#"refs/sandboxes/$2/"}
        tx+="create $prefix$rest $sha"$'\n'"delete $ref $sha"$'\n'
    done <<<"$lines"
    printf '%s' "$tx" | git -C "$1" update-ref --stdin || return 1
    echo "$prefix"
}

# uncommitted_work <name>: print what the sandbox's repository holds that no commit does: changes to files,
# stashes, a detached HEAD (each list cut at 10 lines). Return 0 with no output when it is clean, 1 when an
# exec fails. sbx exec from WSL can answer with CRLF, so \r is removed.
uncommitted_work() {
    local status stashes changes head n
    status=$("$sbx" exec "$1" git status --porcelain --branch) || return 1
    stashes=$("$sbx" exec "$1" git stash list) || return 1
    status=${status//$'\r'/}
    stashes=${stashes//$'\r'/}
    head=$(head -n 1 <<<"$status")
    changes=$(tail -n +2 <<<"$status")
    if [[ -n "$changes" ]]; then
        echo "$1 has uncommitted changes:"
        head -n 10 <<<"$changes"
        n=$(grep -c '' <<<"$changes")
        if ((n > 10)); then echo "and $((n - 10)) more"; fi
    fi
    if [[ -n "$stashes" ]]; then
        n=$(grep -c '' <<<"$stashes")
        echo "$1 has $n stash(es):"
        head -n 10 <<<"$stashes"
        if ((n > 10)); then echo "and $((n - 10)) more"; fi
    fi
    if [[ "$head" == "## HEAD (no branch)" ]]; then echo "$1 is on a detached HEAD"; fi
    return 0
}

# die_unreadable <name> <force> <what>: end could not start or fetch from the sandbox, so nothing in it was read; it
# removes nothing, with or without --force, and names sbx rm --force as the way to remove it anyway.
die_unreadable() {
    local note=""
    [[ "$2" == 0 ]] || note=" (--force cannot keep commits it could not fetch)"
    die "$3$note, nothing removed: nothing in it could be read, so nothing can be proved or kept; to remove it anyway run: $sbx rm --force $1"
}

cmd_end() {
    (($# == 1 || $# == 2)) || usage
    valid_number "$1" || usage
    local force=0
    if (($# == 2)); then
        [[ "$2" == --force ]] || usage
        force=1
    fi
    pick_sbx
    local name=codeo-$1 dir=codeo-$1 state commits count refs prefix report
    state=$(sandbox_state "$name")
    [[ "$state" != missing ]] || die "no sandbox $name"
    [[ -d "$dir" ]] || die "no clone $dir here: cannot check $name for unpushed commits, nothing removed"
    if [[ "$state" == stopped ]]; then
        "$sbx" exec "$name" true || die_unreadable "$name" "$force" "could not start $name"
    fi
    fetch_sandbox "$dir" "$name" || die_unreadable "$name" "$force" "could not fetch sandbox-$name into $dir"
    git -C "$dir" fetch origin || die "could not fetch origin: cannot prove anything is pushed, nothing removed"
    git -C "$dir" fetch origin '+refs/pull/*/head:refs/remotes/origin/pr/*' || die "could not fetch the pull-request heads of origin: cannot prove anything is delivered, nothing removed"
    refs=$(git -C "$dir" for-each-ref --count=1 --format=x "refs/sandboxes/$name/") || die "could not read the refs of $dir, nothing removed"
    if [[ -z "$refs" ]] && ((force == 0)); then
        die "no branches of $name were found under refs/sandboxes/$name/ after the fetch, so nothing can be proved and nothing is removed: end $1 --force removes it anyway"
    fi
    commits=$(unpushed_commits "$dir" "$name") || die "could not list the commits of $name, nothing removed"
    count=0
    [[ -z "$commits" ]] || count=$(grep -c '' <<<"$commits")
    report=$(uncommitted_work "$name") || die "could not check $name for uncommitted work, nothing removed"
    if ((force == 0)) && [[ -n "$commits" || -n "$report" ]]; then
        if [[ -n "$commits" ]]; then
            echo "$name has $count commit(s) on no origin branch:"
            head -n 10 <<<"$commits"
            if ((count > 10)); then echo "and $((count - 10)) more"; fi
        fi
        if [[ -n "$report" ]]; then
            echo "$report"
            echo "nothing removed: commit and push it from the sandbox, or run: codeo-sandbox.sh end $1 --force"
        else
            echo "nothing removed: push them from the sandbox, or run: codeo-sandbox.sh end $1 --force"
        fi
        return 1
    fi
    "$sbx" rm --force "$name" || die "could not remove $name"
    track mark "$1" sandbox "$name" removed
    if ((force == 0)); then
        clear_sandbox_refs "$dir" "$name" || die "removed $name, but could not delete its refs under refs/sandboxes/$name/ in ./$dir"
        echo "removed $name"
        return 0
    fi
    prefix=$(set_aside_sandbox_refs "$dir" "$name") || die "removed $name, but could not set aside its refs under refs/sandboxes/$name/ in ./$dir"
    if [[ -z "$prefix" ]]; then
        echo "removed $name"
    elif ((count == 0)); then
        echo "removed $name; its refs are kept in $prefix in ./$dir"
    else
        echo "removed $name; its $count unpushed commit(s) are kept in $prefix in ./$dir"
    fi
    if [[ -n "$report" ]]; then echo "its uncommitted work was not kept"; fi
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
