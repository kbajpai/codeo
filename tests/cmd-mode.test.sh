#!/usr/bin/env bash
# Guards .devcontainer/codeo-container.sh, the host-side script that starts a codeo dev container
# without VS Code. Each case is a function named in the final cases=( ... ) array; add a case by
# writing a function and listing it. The script runs with PATH holding only a stub docker (so it can
# use nothing but shell builtins and docker), against a scratch directory that logs every docker call.
# Today it checks the usage errors, the Docker-not-available line, the exact docker calls of a fresh
# home, a re-run on a running and on a stopped container, --rebuild keeping the volumes, a failed
# clone reported as one line, and that the script is committed executable with a bash shebang.
#
#   bash tests/cmd-mode.test.sh
#
# Exits 0 and prints "all cases passed" when every case holds; prints one "FAIL <case>: <detail>"
# line per problem and exits 1 otherwise.
set -euo pipefail

repo_root() { cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd; }
repo=$(repo_root)
script="$repo/.devcontainer/codeo-container.sh"
bash_abs=$(command -v bash)

failures=0
current=""

# fail <message>: record one failure against the running case.
fail() {
    printf 'FAIL %s: %s\n' "$current" "$1"
    failures=$((failures + 1))
}

scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT

# cm_setup <name>: a scratch directory cm_dir with a stub docker in bin/ that logs each call to calls.
# The stub answers from STUB_INFO_RC, STUB_IMAGE, STUB_CLONE, STUB_CLONE_RC and the state, image and
# clone files; it uses builtins only, since PATH holds nothing else.
cm_setup() {
    cm_dir="$scratch/$1"
    cm_git_bin=""
    mkdir -p "$cm_dir/bin"
    : >"$cm_dir/calls"
    echo missing >"$cm_dir/state"
    cat >"$cm_dir/bin/docker" <<'STUB'
#!/bin/bash
d=${0%/bin/docker}
echo "$*" >>"$d/calls"
state=$(<"$d/state")
case "$1" in
    info) exit "${STUB_INFO_RC:-0}" ;;
    inspect)
        case "$state" in
            missing) exit 1 ;;
            running) echo true ;;
            *) echo false ;;
        esac
        ;;
    image) [[ -e "$d/image" || "${STUB_IMAGE:-}" == present ]] || exit 1 ;;
    build) : >"$d/image" ;;
    run | start) echo running >"$d/state" ;;
    rm) echo missing >"$d/state" ;;
    exec)
        case "$*" in
            *" test -d "*) [[ -e "$d/clone" || "${STUB_CLONE:-}" == present ]] || exit 1 ;;
            *" git clone "*)
                rc=${STUB_CLONE_RC:-0}
                if ((rc == 0)); then : >"$d/clone"; fi
                exit "$rc"
                ;;
            *devcontainer-start.sh*)
                echo "devcontainer-start: ready"
                case "$*" in *codeo-113*) echo "lock: took the lock for #113 on ${STUB_BRANCH:-}" ;; esac
                ;;
        esac
        ;;
esac
exit 0
STUB
    chmod +x "$cm_dir/bin/docker"
}

# cm_run <args...>: run the script with only the stub on PATH; sets cm_rc, cm_out, cm_err.
cm_run() {
    cm_rc=0
    # Per-case settings: cm_git_bin (a directory with git, put on PATH after bin/), CM_GIT_NAME and
    # CM_GIT_EMAIL (the host's GIT_AUTHOR_*), CM_CONTEXT (the host's CODEO_CONTEXT).
    [[ -e "$cm_dir/gitconfig" ]] || : >"$cm_dir/gitconfig"
    env -u GIT_AUTHOR_NAME -u GIT_AUTHOR_EMAIL -u CODEO_CONTEXT -u CODEO_REPO_URL GIT_CONFIG_NOSYSTEM=1 \
        PATH="$cm_dir/bin${cm_git_bin:+:$cm_git_bin}" HOME="$cm_dir" GIT_CONFIG_GLOBAL="$cm_dir/gitconfig" \
        ${CM_GIT_NAME:+GIT_AUTHOR_NAME="$CM_GIT_NAME"} ${CM_GIT_EMAIL:+GIT_AUTHOR_EMAIL="$CM_GIT_EMAIL"} \
        ${CM_CONTEXT:+CODEO_CONTEXT="$CM_CONTEXT"} \
        "$bash_abs" "$script" "$@" >"$cm_dir/out" 2>"$cm_dir/err" || cm_rc=$?
    cm_out=$(<"$cm_dir/out")
    cm_err=$(<"$cm_dir/err")
}

# cm_with_git: put a directory holding only a symlink to the real git on PATH for later cm_run calls.
cm_with_git() {
    mkdir -p "$cm_dir/gitbin"
    ln -sf "$(command -v git)" "$cm_dir/gitbin/git"
    cm_git_bin="$cm_dir/gitbin"
}

# cm_calls: the docker calls the stub logged, one per line.
cm_calls() { cat "$cm_dir/calls"; }

url=https://github.com/kbajpai/codeo.git
l_info='info'
l_inspect='inspect --format {{.State.Running}} codeo-home'
l_image="image inspect codeo-dev:codeo-home"
l_build="build -t codeo-dev:codeo-home $url#main:.devcontainer"
l_run='run -d --init --name codeo-home --hostname codeo-home --memory=4g -v codeo-home:/workspaces -v codeo-gh:/home/dev/.config/gh -v codeo-git:/home/dev/.config/git -e GIT_CONFIG_GLOBAL=/home/dev/.config/git/config -e CLAUDE_CONFIG_DIR=/workspaces/.claude -e CODEO_CMD_MODE=1 codeo-dev:codeo-home sleep infinity'
l_chown='exec -u root codeo-home chown dev:dev /workspaces'
l_test='exec codeo-home test -d /workspaces/codeo-home/.git'
l_clone="exec codeo-home git clone --branch main $url /workspaces/codeo-home"
l_start='exec -w /workspaces/codeo-home codeo-home bash .devcontainer/scripts/devcontainer-start.sh'

# lines <line...>: the lines joined with newlines, for comparing against cm_calls.
lines() { printf '%s\n' "$@"; }

usage_errors_exit_2_and_run_no_docker() {
    local args
    for args in "" "frobnicate" "home --nope" "issue"; do
        cm_setup usage
        # shellcheck disable=SC2086
        cm_run $args
        ((cm_rc == 2)) || fail "'$args' exited $cm_rc, not 2"
        [[ "$cm_err" == *"usage: codeo-container.sh home"* ]] || fail "'$args' printed no usage: $cm_err"
        [[ -z "$(cm_calls)" ]] || fail "'$args' called docker: $(cm_calls)"
    done
}

docker_that_is_not_there_is_one_line() {
    cm_setup nodocker
    STUB_INFO_RC=1 cm_run home
    ((cm_rc == 1)) || fail "exited $cm_rc, not 1"
    [[ "$cm_err" == "codeo-container: Docker is not available"* && "$cm_err" != *$'\n'* ]] \
        || fail "stderr is not the one line: $cm_err"
    [[ "$(cm_calls)" == "info" ]] || fail "calls were: $(cm_calls)"
}

home_creates_builds_clones_and_starts() {
    cm_setup fresh
    cm_run home
    ((cm_rc == 0)) || fail "exited $cm_rc: $cm_err"
    [[ "$(cm_calls)" == "$(lines "$l_info" "$l_inspect" "$l_image" "$l_build" "$l_run" "$l_chown" "$l_test" "$l_clone" "$l_start")" ]] \
        || fail "calls were: $(cm_calls)"
    [[ "$cm_out" == *"devcontainer-start: ready"* ]] || fail "start script output missing: $cm_out"
}

home_rerun_on_a_running_container_creates_nothing() {
    cm_setup rerun
    echo running >"$cm_dir/state"
    STUB_CLONE=present cm_run home
    ((cm_rc == 0)) || fail "exited $cm_rc: $cm_err"
    [[ "$(cm_calls)" == "$(lines "$l_info" "$l_inspect" "$l_test" "$l_start")" ]] || fail "calls were: $(cm_calls)"
}

home_starts_a_stopped_container() {
    cm_setup stopped
    echo stopped >"$cm_dir/state"
    STUB_CLONE=present cm_run home
    ((cm_rc == 0)) || fail "exited $cm_rc: $cm_err"
    [[ "$(cm_calls)" == "$(lines "$l_info" "$l_inspect" 'start codeo-home' "$l_test" "$l_start")" ]] \
        || fail "calls were: $(cm_calls)"
}

rebuild_removes_the_container_and_keeps_the_volumes() {
    cm_setup rebuild
    echo running >"$cm_dir/state"
    STUB_IMAGE=present STUB_CLONE=present cm_run home --rebuild
    ((cm_rc == 0)) || fail "exited $cm_rc: $cm_err"
    local calls rm_at build_at run_at
    calls=$(cm_calls)
    rm_at=$(printf '%s\n' "$calls" | grep -n '^rm -f codeo-home$' | head -n 1 | cut -d: -f1) || true
    build_at=$(printf '%s\n' "$calls" | grep -n '^build ' | head -n 1 | cut -d: -f1) || true
    run_at=$(printf '%s\n' "$calls" | grep -n '^run ' | head -n 1 | cut -d: -f1) || true
    if [[ -z "$rm_at" || -z "$build_at" || -z "$run_at" ]] || ((rm_at > build_at || build_at > run_at)); then
        fail "expected rm, then build, then run; calls were: $calls"
    fi
    if printf '%s\n' "$calls" | grep -q '^volume'; then fail "a volume was touched: $calls"; fi
}

home_reports_a_failed_clone_as_one_line() {
    cm_setup badclone
    STUB_CLONE_RC=1 cm_run home
    ((cm_rc == 1)) || fail "exited $cm_rc, not 1"
    [[ "$cm_err" != *$'\n'* && -n "$cm_err" ]] || fail "stderr is not one line: $cm_err"
    [[ "$cm_err" == *main* && "$cm_err" == *"$url"* && "$cm_err" == *codeo-home* ]] \
        || fail "stderr misses the branch, URL or name: $cm_err"
    if cm_calls | grep -q 'devcontainer-start.sh'; then fail "the start script ran after a failed clone"; fi
}

the_script_is_committed_executable_with_a_bash_shebang() {
    local mode
    mode=$(git -C "$repo" ls-files -s -- .devcontainer/codeo-container.sh | cut -d' ' -f1)
    if [[ -n "$mode" ]]; then
        [[ "$mode" == 100755 ]] || fail "index mode is $mode, not 100755"
    else
        [[ -x "$script" ]] || fail "the script is missing or not executable"
    fi
    [[ -r "$script" && "$(head -n 1 "$script")" == '#!/usr/bin/env bash' ]] || fail "first line is not #!/usr/bin/env bash"
}

home_builds_from_a_local_context_when_codeo_context_is_set() {
    cm_setup context
    CM_CONTEXT=/x cm_run home
    ((cm_rc == 0)) || fail "exited $cm_rc: $cm_err"
    [[ "$(cm_calls)" == "$(lines "$l_info" "$l_inspect" "$l_image" 'build -t codeo-dev:codeo-home /x' "$l_run" "$l_chown" "$l_test" "$l_clone" "$l_start")" ]] \
        || fail "calls were: $(cm_calls)"
}

l_start_id="-w /workspaces/codeo-home codeo-home bash .devcontainer/scripts/devcontainer-start.sh"

identity_is_passed_to_the_start_script_only() {
    cm_setup identity
    cm_with_git
    git config --file "$cm_dir/gitconfig" user.name "Ada O'Neil"
    git config --file "$cm_dir/gitconfig" user.email ada@example.com
    cm_run home
    ((cm_rc == 0)) || fail "exited $cm_rc: $cm_err"
    local want="exec -e GIT_AUTHOR_NAME=Ada O'Neil -e GIT_AUTHOR_EMAIL=ada@example.com $l_start_id"
    [[ "$(cm_calls)" == "$(lines "$l_info" "$l_inspect" "$l_image" "$l_build" "$l_run" "$l_chown" "$l_test" "$l_clone" "$want")" ]] \
        || fail "calls were: $(cm_calls)"
    if cm_calls | grep '^run ' | grep -q GIT_AUTHOR; then fail "run carries the identity"; fi
}

identity_falls_back_to_the_host_environment_then_to_nothing() {
    cm_setup fallback
    cm_with_git
    CM_GIT_NAME=Grace CM_GIT_EMAIL=g@example.com cm_run home
    ((cm_rc == 0)) || fail "exited $cm_rc: $cm_err"
    [[ "$(cm_calls | tail -n 1)" == "exec -e GIT_AUTHOR_NAME=Grace -e GIT_AUTHOR_EMAIL=g@example.com $l_start_id" ]] \
        || fail "with git: $(cm_calls | tail -n 1)"
    cm_setup nothing
    cm_run home
    ((cm_rc == 0)) || fail "exited $cm_rc: $cm_err"
    [[ "$(cm_calls | tail -n 1)" == "$l_start" ]] || fail "without git: $(cm_calls | tail -n 1)"
}

a_host_with_only_a_name_passes_only_the_name() {
    cm_setup nameonly
    cm_with_git
    git config --file "$cm_dir/gitconfig" user.name "Ada O'Neil"
    cm_run home
    ((cm_rc == 0)) || fail "exited $cm_rc: $cm_err"
    [[ "$(cm_calls | tail -n 1)" == "exec -e GIT_AUTHOR_NAME=Ada O'Neil $l_start_id" ]] \
        || fail "line was: $(cm_calls | tail -n 1)"
}

issue_without_docker_is_one_line() {
    cm_setup nodockerissue
    STUB_INFO_RC=1 cm_run issue 113 b
    ((cm_rc == 1)) || fail "exited $cm_rc, not 1"
    [[ "$cm_err" == "codeo-container: Docker is not available"* && "$cm_err" != *$'\n'* ]] \
        || fail "stderr is not the one line: $cm_err"
    [[ "$(cm_calls)" == "info" ]] || fail "calls were: $(cm_calls)"
}

issue_uses_the_numbered_name_and_the_branch() {
    cm_setup issue
    local b=feat/cmd-mode-start-use-home want
    STUB_BRANCH=$b cm_run issue 113 "$b"
    ((cm_rc == 0)) || fail "exited $cm_rc: $cm_err"
    want=$(lines "$l_info" 'inspect --format {{.State.Running}} codeo-113' 'image inspect codeo-dev:codeo-113' \
        "build -t codeo-dev:codeo-113 $url#$b:.devcontainer" \
        'run -d --init --name codeo-113 --hostname codeo-113 --memory=4g -v codeo-113:/workspaces -v codeo-gh:/home/dev/.config/gh -v codeo-git:/home/dev/.config/git -e GIT_CONFIG_GLOBAL=/home/dev/.config/git/config -e CLAUDE_CONFIG_DIR=/workspaces/.claude -e CODEO_CMD_MODE=1 codeo-dev:codeo-113 sleep infinity' \
        'exec -u root codeo-113 chown dev:dev /workspaces' 'exec codeo-113 test -d /workspaces/codeo-113/.git' \
        "exec codeo-113 git clone --branch $b $url /workspaces/codeo-113" \
        'exec -w /workspaces/codeo-113 codeo-113 bash .devcontainer/scripts/devcontainer-start.sh')
    [[ "$(cm_calls)" == "$want" ]] || fail "calls were: $(cm_calls)"
    [[ "$cm_out" == *"lock: took the lock for #113 on $b" ]] || fail "stdout was: $cm_out"
}

issue_rejects_unsafe_numbers_and_branches() {
    local n b
    for n in abc 0 1a -1 01 ''; do
        cm_setup badnum
        cm_run issue "$n" b
        ((cm_rc == 2)) || fail "number '$n' exited $cm_rc, not 2"
        [[ "$cm_err" == *"usage: codeo-container.sh home"* ]] || fail "number '$n' printed no usage"
        [[ -z "$(cm_calls)" ]] || fail "number '$n' called docker: $(cm_calls)"
    done
    # shellcheck disable=SC2016
    for b in -x 'a b' 'a;b' '$(id)' 'a/../b' '`id`' ''; do
        cm_setup badbranch
        cm_run issue 113 "$b"
        ((cm_rc == 2)) || fail "branch '$b' exited $cm_rc, not 2"
        [[ "$cm_err" == *"usage: codeo-container.sh home"* ]] || fail "branch '$b' printed no usage"
        [[ -z "$(cm_calls)" ]] || fail "branch '$b' called docker: $(cm_calls)"
    done
}

issue_rebuild_and_rerun_follow_home() {
    cm_setup issuerebuild
    echo running >"$cm_dir/state"
    STUB_IMAGE=present STUB_CLONE=present cm_run issue 113 b --rebuild
    ((cm_rc == 0)) || fail "exited $cm_rc: $cm_err"
    local calls
    calls=$(cm_calls)
    [[ "$calls" == *$'\nrm -f codeo-113\n'* && "$calls" == *"build -t codeo-dev:codeo-113 $url#b:.devcontainer"* ]] \
        || fail "no rm and build: $calls"
    cm_setup issuererun
    echo running >"$cm_dir/state"
    STUB_CLONE=present cm_run issue 113 b
    ((cm_rc == 0)) || fail "rerun exited $cm_rc: $cm_err"
    [[ "$(cm_calls)" == "$(lines info 'inspect --format {{.State.Running}} codeo-113' 'exec codeo-113 test -d /workspaces/codeo-113/.git' \
        'exec -w /workspaces/codeo-113 codeo-113 bash .devcontainer/scripts/devcontainer-start.sh')" ]] || fail "rerun calls: $(cm_calls)"
}

cases=(
    usage_errors_exit_2_and_run_no_docker
    docker_that_is_not_there_is_one_line
    home_creates_builds_clones_and_starts
    home_rerun_on_a_running_container_creates_nothing
    home_starts_a_stopped_container
    rebuild_removes_the_container_and_keeps_the_volumes
    home_reports_a_failed_clone_as_one_line
    the_script_is_committed_executable_with_a_bash_shebang
    home_builds_from_a_local_context_when_codeo_context_is_set
    identity_is_passed_to_the_start_script_only
    identity_falls_back_to_the_host_environment_then_to_nothing
    a_host_with_only_a_name_passes_only_the_name
    issue_without_docker_is_one_line
    issue_uses_the_numbered_name_and_the_branch
    issue_rejects_unsafe_numbers_and_branches
    issue_rebuild_and_rerun_follow_home
)

for current in "${cases[@]}"; do
    "$current"
done

if ((failures > 0)); then
    exit 1
fi
echo "all cases passed"
