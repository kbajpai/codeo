#!/usr/bin/env bash
# Guards .sbx/codeo-sandbox.sh, the host-side script that starts, opens and ends one Docker Sandboxes
# (sbx) sandbox per GitHub issue on a Linux or WSL2 host. Each case is a function named in the final
# cases=( ... ) array; add a case by writing a function and listing it. The script runs with PATH
# holding only stub sbx, sbx.exe, git, git.exe and code (plus /usr/bin and /bin), against a scratch
# directory whose calls file logs every stub call and whose sandboxes file is what the stub `sbx ls`
# prints. It checks the usage errors, that a bad argument exits 2 before any call, the one-line
# error when no sbx is installed, the choice of program (sbx, sbx.exe, CODEO_SBX), the reading of
# `sbx ls` rows by sandbox_state, that the script is committed executable with a bash shebang, and
# that the config suite covers .sbx/.
#
#   bash tests/sandbox.test.sh
#
# Exits 0 and prints "all cases passed" when every case holds; prints one "FAIL <case>: <detail>"
# line per problem and exits 1 otherwise.
set -euo pipefail

repo_root() { cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd; }
repo=$(repo_root)
script="$repo/.sbx/codeo-sandbox.sh"
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

# sb_setup <name>: a scratch directory sb_dir with stubs in bin/ that log "<name> <args>" to calls.
# The stub sbx and sbx.exe answer `ls` with the contents of the sandboxes file.
sb_setup() {
    sb_dir="$scratch/$1"
    mkdir -p "$sb_dir/bin"
    : >"$sb_dir/calls"
    : >"$sb_dir/sandboxes"
    mkdir -p "$sb_dir/work"
    echo 'fix/x' >"$sb_dir/branch"
    echo 'codeo-113' >"$sb_dir/lockname"
    : >"$sb_dir/trusted"
    local n
    for n in sbx sbx.exe git git.exe code ssh ssh.exe cmd.exe; do
        cat >"$sb_dir/bin/$n" <<'STUB'
#!/bin/bash
d=${0%/bin/*}
echo "${0##*/} $*" >>"$d/calls"
case "${0##*/} $1" in
    "sbx ls" | "sbx.exe ls") cat "$d/sandboxes" ;;
    "sbx create" | "sbx.exe create") pwd >"$d/create_cwd" ;;
    "sbx exec" | "sbx.exe exec")
        case "$*" in
            *container-name.sh*) cat "$d/lockname" ;;
            *devcontainer-start.sh*) echo "start-output" ;;
            *" pwd") echo "/sandbox/clone" ;;
        esac ;;
    "ssh "* | "ssh.exe "*) [[ ! -e "$d/sshfail" ]] || exit 1 ;;
    "cmd.exe "*) pwd >"$d/cmd_cwd" ;;
    "git clone") mkdir -p "${@: -1}/.git" ;;
    "git.exe config")
        case "$*" in *--get-all*) cat "$d/trusted" ;; esac ;;
esac
if [[ "${0##*/}" == git && "$*" == *"branch --show-current"* ]]; then cat "$d/branch"; fi
exit 0
STUB
        chmod +x "$sb_dir/bin/$n"
    done
}

# sb_run <args...>: run the script with the stubs on PATH; sets sb_rc, sb_out, sb_err.
sb_run() {
    sb_rc=0
    # shellcheck disable=SC2016
    env -u CODEO_SBX PATH="$sb_dir/bin:/usr/bin:/bin" ${SB_SBX:+CODEO_SBX="$SB_SBX"} \
        "$bash_abs" -c 'cd "$1" && shift && exec "$@"' _ "$sb_dir/work" "$bash_abs" "$script" "$@" >"$sb_dir/out" 2>"$sb_dir/err" || sb_rc=$?
    sb_out=$(<"$sb_dir/out")
    sb_err=$(<"$sb_dir/err")
}

usage_line='usage: codeo-sandbox.sh issue <N> <branch> | open <N> | shell <N> | end <N> [--force]'

usage_without_arguments_exits_2() {
    sb_setup usage
    sb_run
    ((sb_rc == 2)) || fail "exited $sb_rc, not 2"
    [[ "$sb_err" == "$usage_line" ]] || fail "stderr was: $sb_err"
    [[ -z "$sb_out" ]] || fail "stdout was: $sb_out"
}

bad_numbers_and_branches_exit_2_before_any_call() {
    sb_setup bad
    local n b
    for n in 0 07 -1 1a ''; do
        sb_run open "$n"
        ((sb_rc == 2)) || fail "open '$n' exited $sb_rc"
        sb_run issue "$n" main
        ((sb_rc == 2)) || fail "issue '$n' exited $sb_rc"
    done
    # shellcheck disable=SC2016
    for b in -x a..b 'a b' 'a;b' '$(x)'; do
        sb_run issue 1 "$b"
        ((sb_rc == 2)) || fail "issue 1 '$b' exited $sb_rc"
    done
    sb_run end 1 --nope
    ((sb_rc == 2)) || fail "end 1 --nope exited $sb_rc"
    sb_run open 1 2
    ((sb_rc == 2)) || fail "open 1 2 exited $sb_rc"
    sb_run bogus
    ((sb_rc == 2)) || fail "bogus exited $sb_rc"
    [[ ! -s "$sb_dir/calls" ]] || fail "calls were logged: $(<"$sb_dir/calls")"
}

no_sbx_is_one_line() {
    sb_setup nosbx
    rm "$sb_dir/bin/sbx" "$sb_dir/bin/sbx.exe"
    sb_run open 1
    ((sb_rc == 1)) || fail "exited $sb_rc, not 1"
    [[ "$sb_err" == "codeo-sandbox: sbx is not installed"* ]] || fail "stderr was: $sb_err"
    [[ "$sb_err" != *$'\n'* ]] || fail "stderr is more than one line"
}

# sb_pick: source the script and print the program pick_sbx chose and the windows flag.
sb_pick() {
    # shellcheck disable=SC2016
    local probe='source "$1"; pick_sbx; echo "$sbx $windows"'
    env -u CODEO_SBX PATH="$sb_dir/bin:/usr/bin:/bin" ${SB_SBX:+CODEO_SBX="$SB_SBX"} "$bash_abs" -c "$probe" _ "$script"
}

sbx_is_preferred_over_sbx_exe() {
    sb_setup prefer
    [[ "$(sb_pick)" == "sbx 0" ]] || fail "with both, picked: $(sb_pick)"
    rm "$sb_dir/bin/sbx"
    [[ "$(sb_pick)" == "sbx.exe 1" ]] || fail "with only sbx.exe, picked: $(sb_pick)"
}

codeo_sbx_overrides_both() {
    sb_setup override
    [[ "$(SB_SBX=/x/mysbx sb_pick)" == "/x/mysbx 0" ]] || fail "override picked: $(SB_SBX=/x/mysbx sb_pick)"
    [[ "$(SB_SBX=/x/my.exe sb_pick)" == "/x/my.exe 1" ]] || fail "exe override picked: $(SB_SBX=/x/my.exe sb_pick)"
}

sandbox_state_reads_the_ls_rows() {
    sb_setup state
    cat >"$sb_dir/sandboxes" <<'ROWS'
NAME     AGENT   STATUS
codeo-a  claude  running (detached)
codeo-b  claude  stopped
ROWS
    # shellcheck disable=SC2016
    local probe='source "$1"; sbx=sbx; for n in codeo-a codeo-b codeo-c codeo claude; do echo "$n=$(sandbox_state $n)"; done'
    local out
    out=$(PATH="$sb_dir/bin:/usr/bin:/bin" "$bash_abs" -c "$probe" _ "$script")
    [[ "$out" == $'codeo-a=running\ncodeo-b=stopped\ncodeo-c=missing\ncodeo=missing\nclaude=missing' ]] || fail "states were: $out"
}

the_script_is_committed_executable_with_a_bash_shebang() {
    local mode
    mode=$(git -C "$repo" ls-files -s -- .sbx/codeo-sandbox.sh | cut -d' ' -f1)
    if [[ -n "$mode" ]]; then
        [[ "$mode" == 100755 ]] || fail "index mode is $mode, not 100755"
    else
        [[ -x "$script" ]] || fail "the script is missing or not executable"
    fi
    [[ -r "$script" && "$(head -n 1 "$script")" == '#!/usr/bin/env bash' ]] || fail "first line is not #!/usr/bin/env bash"
}

config_suite_covers_the_sandbox_folder() {
    jq -e '.suites[0].paths | index(".sbx/**")' "$repo/.codeo/config.json" >/dev/null || fail ".sbx/** is not in suites[0].paths"
}

# sb_calls: the calls file as one string.
sb_calls() { cat "$sb_dir/calls"; }

issue_clones_the_branch_on_the_host() {
    sb_setup clone
    sb_run issue 113 fix/x
    ((sb_rc == 0)) || fail "exited $sb_rc: $sb_err"
    [[ "$(sb_calls)" == *$'git clone --branch fix/x https://github.com/kbajpai/codeo.git codeo-113\n'* ]] || fail "calls: $(sb_calls)"
    sb_setup clone2
    CODEO_REPO_URL=https://example.test/r.git sb_run issue 113 fix/x
    [[ "$(sb_calls)" == *'git clone --branch fix/x https://example.test/r.git codeo-113'* ]] || fail "override calls: $(sb_calls)"
}

issue_refuses_a_host_clone_on_another_branch() {
    sb_setup otherbranch
    mkdir -p "$sb_dir/work/codeo-113/.git"
    echo other >"$sb_dir/branch"
    sb_run issue 113 fix/x
    ((sb_rc == 1)) || fail "exited $sb_rc"
    [[ "$sb_err" == *"'other'"*fix/x* && "$sb_err" != *$'\n'* ]] || fail "stderr was: $sb_err"
    [[ "$(sb_calls)" != *create* ]] || fail "create was called"
}

issue_refuses_a_folder_that_is_not_a_clone() {
    sb_setup notclone
    mkdir -p "$sb_dir/work/codeo-113"
    sb_run issue 113 fix/x
    ((sb_rc == 1)) || fail "exited $sb_rc"
    [[ "$sb_err" == *codeo-113* && "$sb_err" != *$'\n'* ]] || fail "stderr was: $sb_err"
    [[ "$(sb_calls)" != *create* ]] || fail "create was called"
}

issue_adds_the_windows_trust_line_once() {
    sb_setup trust
    rm "$sb_dir/bin/sbx"
    local want got
    sb_run issue 113 fix/x
    got=$(grep -c '^git.exe config --global --add safe.directory ' "$sb_dir/calls" || true)
    ((got == 1)) || fail "add called $got times"
    want="git.exe config --global --add safe.directory %(prefix)///wsl.localhost/${WSL_DISTRO_NAME:-}$(cd "$sb_dir/work/codeo-113" && pwd -P)"
    [[ "$(sb_calls)" == *"$want"* ]] || fail "want '$want' in: $(sb_calls)"
    sb_setup trust2
    rm "$sb_dir/bin/sbx"
    mkdir -p "$sb_dir/work/codeo-113/.git"
    echo "%(prefix)///wsl.localhost/${WSL_DISTRO_NAME:-}$(cd "$sb_dir/work/codeo-113" && pwd -P)" >"$sb_dir/trusted"
    sb_run issue 113 fix/x
    [[ "$(sb_calls)" != *"--add"* ]] || fail "added though trusted: $(sb_calls)"
}

issue_skips_the_windows_trust_with_linux_sbx() {
    sb_setup notrust
    sb_run issue 113 fix/x
    [[ "$(sb_calls)" != *git.exe* ]] || fail "git.exe called: $(sb_calls)"
}

issue_without_git_exe_prints_the_trust_command() {
    sb_setup nogitexe
    rm "$sb_dir/bin/sbx" "$sb_dir/bin/git.exe"
    sb_run issue 113 fix/x
    ((sb_rc == 0)) || fail "exited $sb_rc: $sb_err"
    local n
    n=$(grep -c '^todo:.*git.exe config --global --add safe.directory %(prefix)///wsl.localhost/' <<<"$sb_out" || true)
    ((n == 1)) || fail "todo lines: $n in: $sb_out"
    [[ "$(sb_calls)" == *"sbx.exe create"* ]] || fail "create not called"
}

issue_creates_with_the_limits() {
    sb_setup create
    sb_run issue 113 fix/x
    [[ "$(sb_calls)" == *$'sbx create --clone --name codeo-113 --cpus 2 --memory 4g docker.io/sbx/claude@sha256:'* ]] || fail "calls: $(sb_calls)"
    [[ "$(<"$sb_dir/create_cwd")" == "$(cd "$sb_dir/work/codeo-113" && pwd -P)" ]] || fail "create ran in: $(<"$sb_dir/create_cwd")"
}

issue_creates_at_the_pinned_image() {
    sb_setup pin
    local ref
    ref=$(<"$(dirname "$script")/claude-image")
    sb_run issue 113 fix/x
    [[ "$(sb_calls)" == *$'sbx create --clone --name codeo-113 --cpus 2 --memory 4g '"$ref"$' .\n'* ]] || fail "calls: $(sb_calls)"
    sb_setup pin2
    printf '%s\n' 'docker.io/sbx/claude@sha256:0000000000000000000000000000000000000000000000000000000000000000' >"$sb_dir/image"
    CODEO_SBX_IMAGE="$sb_dir/image" sb_run issue 113 fix/x
    [[ "$(sb_calls)" == *' 4g docker.io/sbx/claude@sha256:0000'*' .'* ]] || fail "override calls: $(sb_calls)"
}

a_pin_that_is_not_a_digest_is_refused() {
    sb_setup badpin
    printf '%s\n' 'docker.io/sbx/claude:latest' >"$sb_dir/image"
    CODEO_SBX_IMAGE="$sb_dir/image" sb_run issue 113 fix/x
    ((sb_rc == 1)) || fail "exited $sb_rc"
    [[ "$sb_err" == codeo-sandbox:*"$sb_dir/image"* && "$sb_err" != *$'\n'* ]] || fail "stderr was: $sb_err"
    [[ "$(sb_calls)" != *create* && "$(sb_calls)" != *clone* ]] || fail "calls: $(sb_calls)"
    sb_setup nopin
    CODEO_SBX_IMAGE="$sb_dir/missing" sb_run issue 113 fix/x
    ((sb_rc == 1)) || fail "missing exited $sb_rc"
    [[ "$sb_err" == codeo-sandbox:*"$sb_dir/missing"* && "$sb_err" != *$'\n'* ]] || fail "missing stderr: $sb_err"
    [[ "$(sb_calls)" != *create* ]] || fail "calls: $(sb_calls)"
}

the_pin_file_is_a_digest() {
    local line
    line=$(<"$(dirname "$script")/claude-image")
    [[ "$line" =~ ^docker\.io/sbx/claude@sha256:[0-9a-f]{64}$ ]] || fail "pin was: $line"
}

issue_runs_the_start_script_with_the_identity() {
    sb_setup start
    unset GIT_AUTHOR_NAME GIT_AUTHOR_EMAIL
    GIT_AUTHOR_NAME='Ann Dev' GIT_AUTHOR_EMAIL=a@x.test sb_run issue 113 fix/x
    [[ "$(sb_calls)" == *'sbx exec codeo-113 env CODEO_CMD_MODE=1 GIT_AUTHOR_NAME=Ann Dev GIT_AUTHOR_EMAIL=a@x.test bash .devcontainer/scripts/devcontainer-start.sh'* ]] || fail "calls: $(sb_calls)"
    [[ "$sb_out" == *start-output* ]] || fail "stdout was: $sb_out"
    sb_setup start2
    unset GIT_AUTHOR_EMAIL
    GIT_AUTHOR_NAME=Ann sb_run issue 113 fix/x
    [[ "$(sb_calls)" == *'env CODEO_CMD_MODE=1 GIT_AUTHOR_NAME=Ann bash .devcontainer'* ]] || fail "no-email calls: $(sb_calls)"
}

issue_rerun_on_an_existing_sandbox_creates_nothing() {
    local state
    for state in 'running (detached)' stopped; do
        sb_setup "rerun-${state%% *}"
        mkdir -p "$sb_dir/work/codeo-113/.git"
        printf 'NAME AGENT STATUS\ncodeo-113 claude %s\n' "$state" >"$sb_dir/sandboxes"
        sb_run issue 113 fix/x
        ((sb_rc == 0)) || fail "$state: exited $sb_rc: $sb_err"
        [[ "$(sb_calls)" != *"sbx create"* && "$(sb_calls)" != *"sbx run"* ]] || fail "$state: create or run: $(sb_calls)"
        [[ "$(sb_calls)" == *devcontainer-start.sh* ]] || fail "$state: no start exec"
    done
}

issue_writes_the_sandbox_marker() {
    local state mark='sbx exec codeo-113 bash -c : > "$HOME/.codeo-sandbox"' calls
    for state in missing 'running (detached)'; do
        sb_setup "mark-${state%% *}"
        mkdir -p "$sb_dir/work/codeo-113/.git"
        [[ $state == missing ]] || printf 'NAME AGENT STATUS\ncodeo-113 claude %s\n' "$state" >"$sb_dir/sandboxes"
        sb_run issue 113 fix/x
        calls=$(sb_calls)
        [[ "$calls" == *"$mark"* ]] || fail "$state: no marker exec: $calls"
        [[ "${calls%%"$mark"*}" != *devcontainer-start.sh* ]] || fail "$state: marker after the start script"
        [[ "${calls#*"$mark"}" == *devcontainer-start.sh* ]] || fail "$state: no start script after the marker"
    done
}

issue_name_that_disagrees_with_the_lock_is_one_todo() {
    sb_setup lock
    echo codeo-98 >"$sb_dir/lockname"
    sb_run issue 113 fix/x
    local want='todo: the sandbox is codeo-113 but its lock is for codeo-98: end it and run issue 98 <branch>'
    [[ "$sb_out" == *"$want"* ]] || fail "stdout was: $sb_out"
    [[ "$(grep -c '^todo:' <<<"$sb_out")" == 1 ]] || fail "not exactly one todo: $sb_out"
}

sandbox_path_prints_the_working_folder() {
    sb_setup path
    local out
    # shellcheck disable=SC2016
    out=$(PATH="$sb_dir/bin:/usr/bin:/bin" "$bash_abs" -c 'source "$1"; sbx=sbx; sandbox_path codeo-1' _ "$script")
    [[ "$out" == /sandbox/clone ]] || fail "path was: $out"
}

sb_err_lines() { wc -l <"$sb_dir/err" | tr -d ' '; }

# end_setup <name> [windows]: sb_setup, plus in work/ a real clone codeo-113 of a bare origin, a bare
# repository standing in for the sandbox's git remote (remote sandbox-codeo-113 mirrors its branches into
# refs/sandboxes/codeo-113/), and a git (or, with windows, git.exe) that logs, records its working
# directory, then runs the real git. Only sbx stays a stub.
real_git=$(command -v git)
end_setup() {
    sb_setup "$1"
    local w=$sb_dir/work g="$real_git -c user.name=t -c user.email=t@example.com" prog=git
    $real_git init -q -b main --bare "$sb_dir/origin.git"
    $real_git init -q "$sb_dir/seed"
    $g -C "$sb_dir/seed" commit -q --allow-empty -m base
    $g -C "$sb_dir/seed" branch -M main
    $real_git -C "$sb_dir/seed" push -q "$sb_dir/origin.git" main
    $real_git clone -q "$sb_dir/origin.git" "$w/codeo-113"
    $real_git clone -q --bare "$sb_dir/origin.git" "$sb_dir/sandbox.git"
    $real_git -C "$w/codeo-113" remote add sandbox-codeo-113 "$sb_dir/sandbox.git"
    $real_git -C "$w/codeo-113" config remote.sandbox-codeo-113.fetch '+refs/heads/*:refs/sandboxes/codeo-113/*'
    local progs=(git)
    if [[ "${2:-}" == windows ]]; then progs+=(git.exe); fi
    for prog in "${progs[@]}"; do
        cat >"$sb_dir/bin/$prog" <<STUB
#!/bin/bash
echo "\${0##*/} \$*" >>"$sb_dir/calls"
pwd >"$sb_dir/${prog}_cwd"
exec "$real_git" "\$@"
STUB
        chmod +x "$sb_dir/bin/$prog"
    done
    echo 'codeo-113 claude running' >"$sb_dir/sandboxes"
}

# end_commit <count>: add that many commits on branch work in the sandbox repo.
end_commit() {
    local i tmp=$sb_dir/wc
    [[ -d "$tmp" ]] || $real_git clone -q "$sb_dir/sandbox.git" "$tmp"
    for ((i = 1; i <= $1; i++)); do
        $real_git -c user.name=t -c user.email=t@example.com -C "$tmp" commit -q --allow-empty -m "unpushed $i"
    done
    $real_git -C "$tmp" push -q origin HEAD:refs/heads/work
}

end_with_nothing_to_lose_removes_the_sandbox() {
    end_setup endclean
    sb_run end 113
    ((sb_rc == 0)) || fail "exited $sb_rc: $sb_err"
    [[ "$sb_out" == "removed codeo-113" ]] || fail "stdout was: $sb_out"
    [[ "$(sb_calls)" == *$'\nsbx rm --force codeo-113' ]] || fail "calls: $(sb_calls)"
}

end_with_an_unpushed_commit_removes_nothing() {
    end_setup endlose
    end_commit 1
    sb_run end 113
    ((sb_rc == 1)) || fail "exited $sb_rc"
    [[ "$sb_out" == *"unpushed 1"* ]] || fail "stdout was: $sb_out"
    [[ "$sb_out" == *"end 113 --force"* ]] || fail "no --force hint: $sb_out"
    [[ "$(sb_calls)" != *" rm "* ]] || fail "rm ran: $(sb_calls)"
}

end_force_removes_and_says_where_the_commits_are() {
    end_setup endforce
    end_commit 1
    sb_run end 113 --force
    ((sb_rc == 0)) || fail "exited $sb_rc: $sb_err"
    [[ "$sb_out" == *"refs/sandboxes/codeo-113/ in ./codeo-113"* ]] || fail "stdout was: $sb_out"
    [[ "$(sb_calls)" == *$'\nsbx rm --force codeo-113' ]] || fail "calls: $(sb_calls)"
}

end_without_origin_removes_nothing() {
    end_setup endorigin
    $real_git -C "$sb_dir/work/codeo-113" remote set-url origin "$sb_dir/nowhere.git"
    sb_run end 113
    ((sb_rc == 1)) || fail "exited $sb_rc"
    [[ "$sb_err" == *origin* ]] || fail "stderr was: $sb_err"
    [[ "$(sb_calls)" != *" rm "* ]] || fail "rm ran: $(sb_calls)"
}

end_with_a_failed_sandbox_fetch_removes_nothing() {
    end_setup endfetch
    $real_git -C "$sb_dir/work/codeo-113" remote set-url sandbox-codeo-113 "$sb_dir/nowhere.git"
    sb_run end 113
    ((sb_rc == 1)) || fail "exited $sb_rc"
    [[ "$(sb_calls)" != *" rm "* ]] || fail "rm ran: $(sb_calls)"
}

end_starts_a_stopped_sandbox_first() {
    end_setup endstopped
    echo 'codeo-113 claude stopped' >"$sb_dir/sandboxes"
    sb_run end 113
    ((sb_rc == 0)) || fail "exited $sb_rc: $sb_err"
    local want
    want=$'sbx ls\nsbx exec codeo-113 true\ngit -C codeo-113 fetch sandbox-codeo-113'
    [[ "$(sb_calls)" == "$want"* ]] || fail "calls: $(sb_calls)"
    [[ "$(sb_calls)" == *$'\nsbx rm --force codeo-113' ]] || fail "no rm: $(sb_calls)"
}

end_on_a_missing_sandbox_is_one_line() {
    end_setup endmissing
    : >"$sb_dir/sandboxes"
    sb_run end 113
    ((sb_rc == 1)) || fail "exited $sb_rc"
    [[ "$sb_err" == "codeo-sandbox: no sandbox codeo-113" ]] || fail "stderr was: $sb_err"
    [[ "$(sb_calls)" == "sbx ls" ]] || fail "calls: $(sb_calls)"
}

end_without_the_clone_is_one_line() {
    end_setup endnoclone
    rm -rf "$sb_dir/work/codeo-113"
    sb_run end 113
    ((sb_rc == 1)) || fail "exited $sb_rc"
    [[ "$(sb_err_lines)" == 1 ]] || fail "stderr was: $sb_err"
    [[ "$(sb_calls)" != *" rm "* ]] || fail "rm ran: $(sb_calls)"
}

end_with_no_sandbox_refs_removes_nothing() {
    end_setup endnorefs
    $real_git -C "$sb_dir/work/codeo-113" config remote.sandbox-codeo-113.fetch '+refs/heads/*:refs/remotes/sandbox-codeo-113/*'
    sb_run end 113
    ((sb_rc == 1)) || fail "exited $sb_rc"
    [[ "${sb_err##*$'\n'}" == "codeo-sandbox: no branches of codeo-113 were found under refs/sandboxes/codeo-113/ after the fetch, so nothing can be proved and nothing is removed: end 113 --force removes it anyway" ]] || fail "stderr was: $sb_err"
    [[ "$(sb_calls)" != *" rm "* ]] || fail "rm ran: $(sb_calls)"
}

end_force_with_no_sandbox_refs_removes() {
    end_setup endnorefsforce
    $real_git -C "$sb_dir/work/codeo-113" config remote.sandbox-codeo-113.fetch '+refs/heads/*:refs/remotes/sandbox-codeo-113/*'
    sb_run end 113 --force
    ((sb_rc == 0)) || fail "exited $sb_rc: $sb_err"
    [[ "$(sb_calls)" == *$'\nsbx rm --force codeo-113' ]] || fail "calls: $(sb_calls)"
}

end_lists_at_most_ten_commits() {
    end_setup endten
    end_commit 12
    sb_run end 113
    ((sb_rc == 1)) || fail "exited $sb_rc"
    [[ "$(grep -c 'unpushed' <<<"$sb_out")" == 10 ]] || fail "stdout was: $sb_out"
    [[ "$sb_out" == *"and 2 more"* ]] || fail "no 'and 2 more': $sb_out"
}

end_with_sbx_exe_fetches_with_git_exe_from_the_clone() {
    end_setup endwin windows
    rm "$sb_dir/bin/sbx"
    sb_run end 113
    ((sb_rc == 0)) || fail "exited $sb_rc: $sb_err"
    [[ "$(<"$sb_dir/git.exe_cwd")" == "$sb_dir/work/codeo-113" ]] || fail "git.exe ran in: $(<"$sb_dir/git.exe_cwd")"
    [[ "$(sb_calls)" == *$'\ngit.exe fetch sandbox-codeo-113\n'* ]] || fail "calls: $(sb_calls)"
    [[ "$(sb_calls)" == *$'\nsbx.exe rm --force codeo-113' ]] || fail "calls: $(sb_calls)"
}

open_writes_the_title_and_opens_the_clone_folder() {
    sb_setup open
    echo 'codeo-113 claude running' >"$sb_dir/sandboxes"
    sb_run open 113
    ((sb_rc == 0)) || fail "exited $sb_rc: $sb_err"
    local want
    want=$'sbx ls\nsbx exec codeo-113 bash .devcontainer/scripts/window-title.sh\nsbx exec codeo-113 pwd\nssh codeo-113.sbx -- true\ncode --folder-uri vscode-remote://ssh-remote+codeo-113.sbx/sandbox/clone'
    [[ "$(sb_calls)" == "$want" ]] || fail "calls: $(sb_calls)"
    # CODEO_CODE replaces code
    printf '#!/bin/bash\necho "mycode $*" >>"%s/calls"\n' "$sb_dir" >"$sb_dir/bin/mycode"
    chmod +x "$sb_dir/bin/mycode"
    : >"$sb_dir/calls"
    CODEO_CODE=mycode sb_run open 113
    ((sb_rc == 0)) || fail "CODEO_CODE exited $sb_rc: $sb_err"
    [[ "$(sb_calls)" == *$'\nmycode --folder-uri vscode-remote://ssh-remote+codeo-113.sbx/sandbox/clone' ]] || fail "CODEO_CODE calls: $(sb_calls)"
    [[ "$(sb_calls)" != *$'\ncode '* ]] || fail "code also ran"
}

open_starts_a_stopped_sandbox_first() {
    sb_setup openstopped
    echo 'codeo-113 claude stopped' >"$sb_dir/sandboxes"
    sb_run open 113
    ((sb_rc == 0)) || fail "exited $sb_rc: $sb_err"
    [[ "$(sb_calls)" != *"sbx run"* && "$(sb_calls)" != *"sbx start"* ]] || fail "calls: $(sb_calls)"
    [[ "$(sb_calls | sed -n 2p)" == "sbx exec codeo-113 bash .devcontainer/scripts/window-title.sh" ]] || fail "calls: $(sb_calls)"
}

open_on_a_missing_sandbox_names_the_command_that_creates_it() {
    sb_setup openmissing
    sb_run open 113
    ((sb_rc == 1)) || fail "exited $sb_rc"
    [[ "$sb_err" == *"codeo-sandbox.sh issue 113 <branch>"* ]] || fail "stderr was: $sb_err"
    [[ "$(sb_err_lines)" == 1 ]] || fail "stderr not one line: $sb_err"
    [[ "$(sb_calls)" != *exec* ]] || fail "calls: $(sb_calls)"
    sb_run shell 113
    ((sb_rc == 1)) || fail "shell exited $sb_rc"
    [[ "$sb_err" == *"codeo-sandbox.sh issue 113 <branch>"* ]] || fail "shell stderr was: $sb_err"
}

open_without_ssh_setup_says_to_run_setup_ssh() {
    sb_setup opennossh
    echo 'codeo-113 claude running' >"$sb_dir/sandboxes"
    : >"$sb_dir/sshfail"
    sb_run open 113
    ((sb_rc == 1)) || fail "exited $sb_rc"
    [[ "$sb_err" == "codeo-sandbox: codeo-113.sbx does not resolve over SSH: run sbx setup ssh, then open again" ]] || fail "stderr was: $sb_err"
    [[ "$(sb_calls)" != *$'\ncode '* ]] || fail "code ran: $(sb_calls)"
    SB_SBX=sbx.exe sb_run open 113
    ((sb_rc == 1)) || fail "sbx.exe exited $sb_rc"
    [[ "$sb_err" == *"run sbx.exe setup ssh"* ]] || fail "sbx.exe stderr was: $sb_err"
    [[ "$(sb_calls)" == *"ssh.exe codeo-113.sbx -- true"* && "$(sb_calls)" != *cmd.exe* ]] || fail "sbx.exe calls: $(sb_calls)"
}

open_with_sbx_exe_launches_through_cmd_exe() {
    sb_setup opencmd
    echo 'codeo-113 claude running' >"$sb_dir/sandboxes"
    SB_SBX=sbx.exe sb_run open 113
    ((sb_rc == 0)) || fail "exited $sb_rc: $sb_err"
    [[ "$(sb_calls)" == *$'\nssh.exe codeo-113.sbx -- true\ncmd.exe /c code --folder-uri vscode-remote://ssh-remote+codeo-113.sbx/sandbox/clone' ]] || fail "calls: $(sb_calls)"
    [[ "$(sb_calls)" != *$'\ncode '* ]] || fail "code ran directly: $(sb_calls)"
    if [[ -d /mnt/c ]]; then
        [[ "$(<"$sb_dir/cmd_cwd")" == /mnt/c ]] || fail "cmd.exe ran in $(<"$sb_dir/cmd_cwd")"
    fi
}

shell_execs_bash_in_the_clone() {
    sb_setup shell
    echo 'codeo-113 claude running' >"$sb_dir/sandboxes"
    sb_run shell 113 </dev/null
    ((sb_rc == 0)) || fail "exited $sb_rc: $sb_err"
    [[ "$(sb_calls | tail -n 1)" == "sbx exec -i codeo-113 bash -l" ]] || fail "calls: $(sb_calls)"
    if command -v script >/dev/null 2>&1; then
        : >"$sb_dir/calls"
        echo 'codeo-113 claude running' >"$sb_dir/sandboxes"
        script -qec "env -u CODEO_SBX PATH='$sb_dir/bin:/usr/bin:/bin' '$bash_abs' '$script' shell 113" /dev/null >/dev/null 2>&1 || true
        [[ "$(sb_calls | tail -n 1)" == "sbx exec -it codeo-113 bash -l" ]] || fail "tty calls: $(sb_calls)"
    fi
}


cases=(
    usage_without_arguments_exits_2
    bad_numbers_and_branches_exit_2_before_any_call
    no_sbx_is_one_line
    sbx_is_preferred_over_sbx_exe
    codeo_sbx_overrides_both
    sandbox_state_reads_the_ls_rows
    the_script_is_committed_executable_with_a_bash_shebang
    config_suite_covers_the_sandbox_folder
    issue_clones_the_branch_on_the_host
    issue_refuses_a_host_clone_on_another_branch
    issue_refuses_a_folder_that_is_not_a_clone
    issue_adds_the_windows_trust_line_once
    issue_skips_the_windows_trust_with_linux_sbx
    issue_without_git_exe_prints_the_trust_command
    issue_creates_with_the_limits
    issue_creates_at_the_pinned_image
    a_pin_that_is_not_a_digest_is_refused
    the_pin_file_is_a_digest
    issue_runs_the_start_script_with_the_identity
    issue_rerun_on_an_existing_sandbox_creates_nothing
    issue_writes_the_sandbox_marker
    issue_name_that_disagrees_with_the_lock_is_one_todo
    sandbox_path_prints_the_working_folder
    open_writes_the_title_and_opens_the_clone_folder
    open_starts_a_stopped_sandbox_first
    open_on_a_missing_sandbox_names_the_command_that_creates_it
    open_without_ssh_setup_says_to_run_setup_ssh
    open_with_sbx_exe_launches_through_cmd_exe
    shell_execs_bash_in_the_clone
    end_with_nothing_to_lose_removes_the_sandbox
    end_with_an_unpushed_commit_removes_nothing
    end_force_removes_and_says_where_the_commits_are
    end_without_origin_removes_nothing
    end_with_a_failed_sandbox_fetch_removes_nothing
    end_starts_a_stopped_sandbox_first
    end_on_a_missing_sandbox_is_one_line
    end_without_the_clone_is_one_line
    end_with_no_sandbox_refs_removes_nothing
    end_force_with_no_sandbox_refs_removes
    end_lists_at_most_ten_commits
    end_with_sbx_exe_fetches_with_git_exe_from_the_clone
)

for current in "${cases[@]}"; do
    "$current"
done

if ((failures > 0)); then
    exit 1
fi
echo "all cases passed"
