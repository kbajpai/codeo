#!/usr/bin/env bash
# Guards .devcontainer/codeo, the host command that wraps codeo-container.sh and codeo-sandbox.sh.
# Each case is a function named in the final cases=( ... ) array; add a case by writing a function
# and listing it. The command runs under env -i with PATH holding only stub docker, sbx, git and
# curl (plus /usr/bin and /bin) against a scratch directory whose calls file logs every stub call
# and every call of the stub scripts in a stub $CODEO_HOME. It checks the argument checks (usage on
# stderr, exit 2, no call made), the help text, and that the file is committed executable with a
# bash shebang and covered by the config suite.
#
#   bash tests/codeo-command.test.sh
#
# Exits 0 and prints "all cases passed" when every case holds; prints one "FAIL <case>: <detail>"
# line per problem and exits 1 otherwise.
set -euo pipefail

repo_root() { cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd; }
repo=$(repo_root)
script="$repo/.devcontainer/codeo"
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

# cm_setup <name>: a scratch directory cm_dir with stubs in bin/ that log "<stub> <args>" to calls,
# and a $CODEO_HOME (cm_home) holding stub codeo-container.sh and codeo-sandbox.sh that log
# "<script> <args> pwd=<cwd>" to calls.
cm_setup() {
    cm_dir="$scratch/$1"
    cm_home="$cm_dir/home"
    mkdir -p "$cm_dir/bin" "$cm_home" "$cm_dir/h"
    : >"$cm_dir/calls"
    local n
    for n in docker sbx git curl; do
        cat >"$cm_dir/bin/$n" <<'STUB'
#!/bin/bash
d=${0%/bin/*}
echo "${0##*/} $*" >>"$d/calls"
cat "$d/${0##*/}_out" 2>/dev/null || true
exit 0
STUB
        chmod +x "$cm_dir/bin/$n"
    done
    # git stub: for-each-ref prints the lines of $d/branches; cat-file -e <branch>:... succeeds when
    # <branch> is a line of $d/has.
    cat >"$cm_dir/bin/git" <<'STUB'
#!/bin/bash
d=${0%/bin/*}
echo "${0##*/} $*" >>"$d/calls"
for a in "$@"; do
    case "$a" in
        clone) mkdir -p "${@: -1}"; exit 0 ;;
        for-each-ref) cat "$d/branches" 2>/dev/null || true; exit 0 ;;
        *:.codeo/*/init.md) grep -qxF "${a%%:*}" "$d/has" 2>/dev/null && exit 0 || exit 1 ;;
    esac
done
exit 0
STUB
    # curl stub: writes a stub script to the -o target.
    cat >"$cm_dir/bin/curl" <<'STUB'
#!/bin/bash
d=${0%/bin/*}
echo "${0##*/} $*" >>"$d/calls"
[[ ! -e "$d/curl_fail" ]] || exit 22
while [[ $# -gt 0 ]]; do
    if [[ "$1" == -o ]]; then
        if [[ -e "$d/curl_body" ]]; then cp "$d/curl_body" "$2"; else printf '#!/bin/bash\nexit 0\n' >"$2"; fi
    fi
    shift
done
exit 0
STUB
    chmod +x "$cm_dir/bin/git" "$cm_dir/bin/curl"
    for n in codeo-container.sh codeo-sandbox.sh; do
        cat >"$cm_home/$n" <<'STUB'
#!/bin/bash
d=${0%/home/*}
echo "${0##*/} $* pwd=$(pwd)" >>"$d/calls"
exit "$(cat "$d/status" 2>/dev/null || echo 0)"
STUB
        chmod +x "$cm_home/$n"
    done
}

# cm_run <args...>: run codeo with a clean environment; set cm_status, cm_out and cm_err.
cm_run() {
    cm_status=0
    env -i HOME="$cm_dir/h" CODEO_HOME="$cm_home" PATH="$cm_dir/bin:/usr/bin:/bin" \
        "$bash_abs" "$script" "$@" >"$cm_dir/out" 2>"$cm_dir/err" || cm_status=$?
    cm_out=$(cat "$cm_dir/out")
    cm_err=$(cat "$cm_dir/err")
}

# expect_usage <args...>: codeo exits 2 with a usage: line on stderr and makes no call.
expect_usage() {
    cm_setup "$current"
    cm_run "$@"
    [[ "$cm_status" -eq 2 ]] || fail "'$*': exit $cm_status, want 2"
    grep -q '^usage:' "$cm_dir/err" || fail "'$*': no usage: line on stderr"
    [[ ! -s "$cm_dir/calls" ]] || fail "'$*': made calls: $(cat "$cm_dir/calls")"
}

t_no_args_usage() { expect_usage; }
t_unknown_command_usage() { expect_usage frobnicate; }

t_bad_number_usage() {
    local a
    for a in "issue abc" "issue 0" "issue 07" "shell x" "rm 1x" "shell 0"; do
        # shellcheck disable=SC2086
        expect_usage $a
    done
}

t_bad_branch_usage() {
    expect_usage issue 5 -x
    expect_usage issue 5 a..b
    expect_usage issue 5 'a b'
}

t_missing_arg_usage() {
    local a
    for a in issue shell rm open; do expect_usage "$a"; done
}

# expect_call <line>: the calls file holds exactly that line (a stub script call, with pwd).
expect_call() {
    grep -qxF "$1" "$cm_dir/calls" || fail "calls lack '$1'; have: $(tr '\n' '|' <"$cm_dir/calls")"
}

# expect_no_script: neither stub script was called.
expect_no_script() {
    ! grep -q '^codeo-.*\.sh ' "$cm_dir/calls" || fail "a script was called: $(cat "$cm_dir/calls")"
}

t_home_runs_script() {
    cm_setup "$current"
    cd "$cm_dir/h"
    cm_run home --rebuild
    cd "$repo"
    [[ "$cm_status" -eq 0 ]] || fail "exit $cm_status"
    expect_call "codeo-container.sh home --rebuild pwd=$cm_home"
}

t_runs_from_any_directory() {
    cm_setup "$current"
    cd "$cm_dir/h"
    cm_run issue 5 fix/x
    cd "$repo"
    expect_call "codeo-container.sh issue 5 fix/x pwd=$cm_home"
}

t_issue_with_branch() {
    cm_setup "$current"
    cm_run issue 5 fix/x
    [[ "$cm_status" -eq 0 ]] || fail "exit $cm_status"
    expect_call "codeo-container.sh issue 5 fix/x pwd=$cm_home"
    ! grep -q '^git ' "$cm_dir/calls" || fail "git called with a branch given"
}

t_issue_accepts_valid_branch() {
    cm_setup "$current"
    cm_run issue 7 a/b.c-d
    [[ "$cm_status" -eq 0 ]] || fail "exit $cm_status, err: $cm_err"
    expect_call "codeo-container.sh issue 7 a/b.c-d pwd=$cm_home"
}

t_issue_rebuild_flag() {
    cm_setup "$current"
    cm_run issue 5 fix/x --rebuild --container
    expect_call "codeo-container.sh issue 5 fix/x --rebuild pwd=$cm_home"
    cm_setup "$current-2"
    printf 'fix/x\n' >"$cm_dir/branches"
    printf 'fix/x\n' >"$cm_dir/has"
    cm_run issue 5 --rebuild
    expect_call "codeo-container.sh issue 5 fix/x --rebuild pwd=$cm_home"
}

t_home_bad_flag_usage() { expect_usage home --bogus; }

t_issue_branch_lookup_one() {
    cm_setup "$current"
    printf 'feat/a\nfeat/b\n' >"$cm_dir/branches"
    printf 'feat/b\n' >"$cm_dir/has"
    cm_run issue 5
    [[ "$cm_status" -eq 0 ]] || fail "exit $cm_status, err: $cm_err"
    expect_call "codeo-container.sh issue 5 feat/b pwd=$cm_home"
    grep -q '^git .*clone --bare --filter=blob:none https://github.com/kbajpai/codeo.git ' "$cm_dir/calls" || fail "no blob-less bare clone"
    grep -q 'fetch --prune origin' "$cm_dir/calls" || fail "no fetch"
}

t_issue_lookup_none() {
    cm_setup "$current"
    printf 'feat/a\n' >"$cm_dir/branches"
    cm_run issue 5
    [[ "$cm_status" -eq 1 ]] || fail "exit $cm_status, want 1"
    [[ "$(wc -l <"$cm_dir/err")" -eq 1 ]] || fail "stderr not one line: $cm_err"
    [[ "$cm_err" == "codeo: "* ]] || fail "stderr lacks 'codeo: ' prefix: $cm_err"
    grep -q '5' <<<"$cm_err" || fail "stderr does not name the issue: $cm_err"
    expect_no_script
}

t_issue_lookup_several() {
    cm_setup "$current"
    printf 'feat/a\nfeat/b\n' >"$cm_dir/branches"
    printf 'feat/a\nfeat/b\n' >"$cm_dir/has"
    cm_run issue 5
    [[ "$cm_status" -eq 1 ]] || fail "exit $cm_status, want 1"
    [[ "$(wc -l <"$cm_dir/err")" -eq 1 ]] || fail "stderr not one line: $cm_err"
    [[ "$cm_err" == "codeo: "* ]] || fail "stderr lacks 'codeo: ' prefix: $cm_err"
    { grep -q 'feat/a' <<<"$cm_err" && grep -q 'feat/b' <<<"$cm_err"; } || fail "stderr does not name both: $cm_err"
    expect_no_script
}

t_shell_container() {
    cm_setup "$current"
    printf 'codeo-5\n' >"$cm_dir/docker_out"
    cm_run shell 5
    expect_call "codeo-container.sh shell 5 pwd=$cm_home"
    cm_setup "$current-2"
    cm_run shell home
    expect_call "codeo-container.sh shell home pwd=$cm_home"
    ! grep -q '^\(git\|docker\|sbx\) ' "$cm_dir/calls" || fail "lookup called for shell home"
}

t_first_use_downloads() {
    cm_setup "$current"
    rm -f "$cm_home"/*.sh
    cm_run home
    [[ "$cm_status" -eq 0 ]] || fail "exit $cm_status, err: $cm_err"
    local f
    for f in .devcontainer/codeo-container.sh .sbx/codeo-sandbox.sh; do
        grep -q "^curl -fsSL -o $cm_home/.* https://raw.githubusercontent.com/kbajpai/codeo/main/$f\$" "$cm_dir/calls" || fail "no download of $f"
    done
    [[ -f "$cm_home/codeo-container.sh" && -f "$cm_home/codeo-sandbox.sh" ]] || fail "scripts not installed"
}

t_creates_home() {
    cm_setup "$current"
    rm -rf "$cm_home"
    cm_run home
    [[ -f "$cm_home/codeo-container.sh" ]] || fail "home not created and populated"
}

t_help_lists_commands() {
    cm_setup "$current"
    cm_run help
    [[ "$cm_status" -eq 0 ]] || fail "help exit $cm_status, want 0"
    local c
    for c in home issue shell open list rm default update help; do
        grep -qw "$c" <<<"$cm_out" || fail "help does not name $c"
    done
    grep -q 'export PATH="$HOME/.local/bin:$PATH"' <<<"$cm_out" || fail "help lacks the PATH line"
    [[ ! -s "$cm_dir/calls" ]] || fail "help made calls"
}

t_executable_bash() {
    local mode
    mode=$(git -C "$repo" ls-files -s .devcontainer/codeo | cut -d' ' -f1)
    [[ "$mode" == 100755 ]] || fail "mode is '$mode', want 100755"
    [[ "$(head -n1 "$script")" == '#!/usr/bin/env bash' ]] || fail "first line is not '#!/usr/bin/env bash'"
}

t_suite_covers() {
    jq -e '.suites[] | select(.name == "shell") | .paths | any(. == ".devcontainer/**" or . == ".devcontainer/codeo")' \
        "$repo/.codeo/config.json" >/dev/null || fail "shell suite does not cover .devcontainer/codeo"
}

t_exit_status_passthrough() {
    cm_setup "$current"
    echo 7 >"$cm_dir/status"
    cm_run home
    [[ "$cm_status" -eq 7 ]] || fail "exit $cm_status, want 7"
}

t_download_failure() {
    cm_setup "$current"
    rm -f "$cm_home"/*.sh
    touch "$cm_dir/curl_fail"
    cm_run home
    [[ "$cm_status" -ne 0 ]] || fail "exit 0 after a failed download"
    [[ "$(wc -l <"$cm_dir/err")" -eq 1 && "$cm_err" == "codeo: "* ]] || fail "stderr not one codeo: line: $cm_err"
    ! compgen -G "$cm_home/*.part" >/dev/null || fail ".part left behind"
    expect_no_script
}

t_download_not_script() {
    cm_setup "$current"
    rm -f "$cm_home"/*.sh
    printf '<html>404</html>\n' >"$cm_dir/curl_body"
    cm_run home
    [[ "$cm_status" -ne 0 ]] || fail "exit 0 for a non-script download"
    [[ "$(wc -l <"$cm_dir/err")" -eq 1 && "$cm_err" == "codeo: "* ]] || fail "stderr not one codeo: line: $cm_err"
    ! compgen -G "$cm_home/*.part" >/dev/null || fail ".part left behind"
    [[ ! -e "$cm_home/codeo-container.sh" ]] || fail "bad file installed"
    expect_no_script
}

t_lookup_clone_atomic() {
    cm_setup "$current"
    mkdir -p "$cm_home/.lookup.git.part"
    touch "$cm_home/.lookup.git.part/stale"
    printf 'feat/a\n' >"$cm_dir/branches"
    printf 'feat/a\n' >"$cm_dir/has"
    cm_run issue 5
    grep -q "clone --bare --filter=blob:none .* $cm_home/.lookup.git.part\$" "$cm_dir/calls" || fail "clone not into .lookup.git.part"
    [[ -d "$cm_home/.lookup.git" && ! -e "$cm_home/.lookup.git.part" ]] || fail "part not renamed"
    [[ ! -e "$cm_home/.lookup.git/stale" ]] || fail "stale part kept"
}

t_lookup_uses_lstrip() {
    cm_setup "$current"
    printf 'feat/a\n' >"$cm_dir/branches"
    printf 'feat/a\n' >"$cm_dir/has"
    cm_run issue 5
    grep -q 'for-each-ref --format=%(refname:lstrip=2) refs/heads' "$cm_dir/calls" || fail "no lstrip=2"
}

t_issue_sandbox_flag() {
    cm_setup "$current"
    cm_run issue 5 fix/x --sandbox
    [[ "$cm_status" -eq 0 ]] || fail "exit $cm_status, err: $cm_err"
    expect_call "codeo-sandbox.sh issue 5 fix/x pwd=$cm_home"
}

t_issue_default_sandbox() {
    cm_setup "$current"
    cm_run default sandbox
    cm_run issue 5 fix/x
    expect_call "codeo-sandbox.sh issue 5 fix/x pwd=$cm_home"
    cm_setup "$current-2"
    echo sandbox >"$cm_home/default"
    cm_run issue 5 fix/x --container
    expect_call "codeo-container.sh issue 5 fix/x pwd=$cm_home"
    cm_setup "$current-3"
    echo bogus >"$cm_home/default"
    cm_run issue 5 fix/x
    expect_call "codeo-container.sh issue 5 fix/x pwd=$cm_home"
}

t_issue_rebuild_sandbox_usage() {
    expect_usage issue 5 fix/x --rebuild --sandbox
    expect_usage issue 5 --container --sandbox
}

t_default_show_and_save() {
    cm_setup "$current"
    cm_run default
    [[ "$cm_out" == container ]] || fail "no file: printed '$cm_out'"
    cm_run default sandbox
    [[ "$(cat "$cm_home/default")" == sandbox ]] || fail "default not saved"
    cm_run default
    [[ "$cm_out" == sandbox ]] || fail "printed '$cm_out', want sandbox"
    expect_usage default bogus
    expect_usage default sandbox extra
}

t_shell_sandbox() {
    cm_setup "$current"
    printf 'NAME AGENT STATUS\ncodeo-5 claude running\ncodeo-55 claude running\n' >"$cm_dir/sbx_out"
    cm_run shell 5
    expect_call "codeo-sandbox.sh shell 5 pwd=$cm_home"
}

t_shell_neither() {
    cm_setup "$current"
    printf 'NAME AGENT STATUS\ncodeo-55 claude running\n' >"$cm_dir/sbx_out"
    printf 'codeo-6\n' >"$cm_dir/docker_out"
    cm_run shell 5
    [[ "$cm_status" -eq 1 ]] || fail "exit $cm_status, want 1"
    [[ "$(wc -l <"$cm_dir/err")" -eq 1 && "$cm_err" == "codeo: "* ]] || fail "not one line: $cm_err"
    grep -q 'codeo issue 5' <<<"$cm_err" || fail "does not name codeo issue 5: $cm_err"
    expect_no_script
}

t_shell_both() {
    cm_setup "$current"
    printf 'codeo-5\n' >"$cm_dir/docker_out"
    printf 'NAME AGENT STATUS\ncodeo-5 claude running\n' >"$cm_dir/sbx_out"
    cm_run shell 5
    [[ "$cm_status" -eq 1 ]] || fail "exit $cm_status, want 1"
    [[ "$(wc -l <"$cm_dir/err")" -eq 1 && "$cm_err" == "codeo: "* ]] || fail "not one line: $cm_err"
    { grep -q -- '--container' <<<"$cm_err" && grep -q -- '--sandbox' <<<"$cm_err"; } || fail "no flags named: $cm_err"
    expect_no_script
    cm_run shell 5 --sandbox
    expect_call "codeo-sandbox.sh shell 5 pwd=$cm_home"
    cm_run shell --container 5
    expect_call "codeo-container.sh shell 5 pwd=$cm_home"
}

t_shell_container_found() {
    cm_setup "$current"
    printf 'codeo-5\n' >"$cm_dir/docker_out"
    cm_run shell 5
    expect_call "codeo-container.sh shell 5 pwd=$cm_home"
}

t_open_sandbox() {
    cm_setup "$current"
    printf 'NAME AGENT STATUS\ncodeo-5 claude running\n' >"$cm_dir/sbx_out"
    cm_run open 5
    expect_call "codeo-sandbox.sh open 5 pwd=$cm_home"
}

t_open_container_refused() {
    cm_setup "$current"
    printf 'codeo-5\n' >"$cm_dir/docker_out"
    cm_run open 5
    [[ "$cm_status" -eq 1 ]] || fail "exit $cm_status, want 1"
    [[ "$(wc -l <"$cm_dir/err")" -eq 1 && "$cm_err" == "codeo: "* ]] || fail "not one line: $cm_err"
    expect_no_script
    cm_run open 5 --container
    [[ "$cm_status" -eq 1 ]] || fail "--container: exit $cm_status, want 1"
    expect_no_script
}

t_no_docker_program() {
    cm_setup "$current"
    rm -f "$cm_dir/bin/docker"
    printf 'NAME AGENT STATUS\ncodeo-5 claude running\n' >"$cm_dir/sbx_out"
    cm_run shell 5
    [[ "$cm_status" -eq 0 ]] || fail "exit $cm_status, err: $cm_err"
    expect_call "codeo-sandbox.sh shell 5 pwd=$cm_home"
}

t_sandbox_uses_home_clone() {
    cm_setup "$current"
    mkdir -p "$cm_dir/h/codeo-5"
    printf 'NAME AGENT STATUS\ncodeo-5 claude running\n' >"$cm_dir/sbx_out"
    cd "$cm_dir/h"
    cm_run shell 5
    cd "$repo"
    expect_call "codeo-sandbox.sh shell 5 pwd=$cm_home"
}

# list_stubs: replace the docker and git stubs with ones that answer list: docker ps prints
# $d/docker_out, docker exec codeo-<N> ... prints $d/dbranch_codeo-<N>, and git -C <dir> branch
# --show-current prints $d/gbranch_<basename dir>; a docker_fail file makes docker exit 1.
list_stubs() {
    cat >"$cm_dir/bin/docker" <<'STUB'
#!/bin/bash
d=${0%/bin/*}
echo "${0##*/} $*" >>"$d/calls"
[[ ! -e "$d/docker_fail" ]] || exit 1
case "$1" in
    ps) cat "$d/docker_out" 2>/dev/null || true ;;
    exec) cat "$d/dbranch_$2" 2>/dev/null || true ;;
esac
exit 0
STUB
    cat >"$cm_dir/bin/git" <<'STUB'
#!/bin/bash
d=${0%/bin/*}
echo "${0##*/} $*" >>"$d/calls"
[[ "$1" == -C ]] && cat "$d/gbranch_${2##*/}" 2>/dev/null
exit 0
STUB
    chmod +x "$cm_dir/bin/docker" "$cm_dir/bin/git"
}

t_list_rows() {
    cm_setup "$current"
    list_stubs
    rm -f "$cm_home"/*.sh
    printf 'codeo-140 exited\ncodeo-home running\ncodeo-131 running\ncodeo-9 paused\nother running\n' >"$cm_dir/docker_out"
    printf 'fix/a\n' >"$cm_dir/dbranch_codeo-131"
    printf 'NAME AGENT STATUS\ncodeo-133 claude running\ncodeo-12 claude stopped\ncodeo-5 claude running (detached)\nnotcodeo-7 claude running\n' >"$cm_dir/sbx_out"
    printf 'feat/s\n' >"$cm_dir/gbranch_codeo-133"
    mkdir -p "$cm_home/codeo-133"
    cm_run list
    local want
    want=$'#9  container  stopped  -\n#131  container  running  fix/a\n#140  container  stopped  -\n#5  sandbox  detached  -\n#12  sandbox  stopped  -\n#133  sandbox  running  feat/s'
    [[ "$cm_status" -eq 0 ]] || fail "exit $cm_status, err: $cm_err"
    [[ "$cm_out" == "$want" ]] || fail "output: $cm_out"
    ! grep -qE '^(docker (start|exec codeo-(140|9) )|sbx exec|curl)' "$cm_dir/calls" || fail "started something: $(cat "$cm_dir/calls")"
    [[ ! -e "$cm_home/codeo-container.sh" ]] || fail "downloaded a script"
    grep -q "^git -C $cm_home/codeo-133 branch --show-current" "$cm_dir/calls" || fail "no sandbox branch read"
    grep -q '^docker exec codeo-131 git -C /workspaces/codeo-131 branch --show-current' "$cm_dir/calls" || fail "no container branch read"
}

t_list_empty() {
    cm_setup "$current"
    list_stubs
    printf 'codeo-home running\n' >"$cm_dir/docker_out"
    printf 'NAME AGENT STATUS\n' >"$cm_dir/sbx_out"
    cm_run list
    [[ "$cm_status" -eq 0 ]] || fail "exit $cm_status"
    [[ "$cm_out" == "no issue containers or sandboxes" ]] || fail "output: $cm_out"
}

t_list_no_programs() {
    cm_setup "$current"
    rm -f "$cm_dir/bin/docker" "$cm_dir/bin/sbx"
    cm_run list
    [[ "$cm_status" -eq 1 ]] || fail "exit $cm_status, want 1"
    [[ "$(wc -l <"$cm_dir/err")" -eq 1 && "$cm_err" == "codeo: "* ]] || fail "stderr not one codeo: line: $cm_err"
}

t_list_docker_down() {
    cm_setup "$current"
    list_stubs
    touch "$cm_dir/docker_fail"
    printf 'NAME AGENT STATUS\ncodeo-133 claude running\n' >"$cm_dir/sbx_out"
    cm_run list
    [[ "$cm_status" -eq 0 ]] || fail "exit $cm_status"
    [[ "$cm_out" == "#133  sandbox  running  -" ]] || fail "output: $cm_out"
    [[ -z "$cm_err" ]] || fail "stderr: $cm_err"
    cm_setup "$current-2"
    rm -f "$cm_dir/bin/sbx"
    printf 'codeo-4 running\n' >"$cm_dir/docker_out"
    list_stubs
    cm_run list
    [[ "$cm_out" == "#4  container  running  -" && "$cm_status" -eq 0 ]] || fail "sbx missing: $cm_status $cm_out"
}

t_list_extra_args_usage() { expect_usage list now; }

t_host_kinds_exact_name() {
    cm_setup "$current"
    printf 'codeo-50\ncodeo-home\n' >"$cm_dir/docker_out"
    cm_run shell 5
    [[ "$cm_status" -eq 1 ]] || fail "codeo-50 matched codeo-5: exit $cm_status"
    expect_no_script
    cm_setup "$current-2"
    printf 'NAME AGENT STATUS\ncodeo-9 codeo-5 running\n' >"$cm_dir/sbx_out"
    cm_run shell 5
    [[ "$cm_status" -eq 1 ]] || fail "codeo-5 in column 2 matched: exit $cm_status"
    expect_no_script
}

# rm_stubs: replace the docker stub with one that answers rm. docker ps with {{.State}} prints
# "codeo-5 $(dstate)" (running when absent), other docker ps prints "codeo-5"; docker exec ... git -C
# <dir> <sub> prints $d/g_<sub> (g_branch defaults to main) and fails for fetch when fetch_fail
# exists; docker start, rm, volume rm and rmi fail when start_fail, rm_fail, vol_fail, rmi_fail exist.
rm_stubs() {
    cat >"$cm_dir/bin/docker" <<'STUB'
#!/bin/bash
d=${0%/bin/*}
echo "${0##*/} $*" >>"$d/calls"
case "$1" in
    ps)
        if [[ "$*" == *State* ]]; then echo "codeo-5 $(cat "$d/dstate" 2>/dev/null || echo running)"; else echo codeo-5; fi ;;
    start) [[ ! -e "$d/start_fail" ]] || exit 1 ;;
    rm) [[ ! -e "$d/rm_fail" ]] || exit 1 ;;
    volume) [[ ! -e "$d/vol_fail" ]] || exit 1 ;;
    rmi) [[ ! -e "$d/rmi_fail" ]] || exit 1 ;;
    exec)
        sub=$6
        [[ "$sub" != fetch || ! -e "$d/fetch_fail" ]] || exit 1
        if [[ "$sub" == branch && ! -e "$d/g_branch" ]]; then echo main; else cat "$d/g_$sub" 2>/dev/null || true; fi ;;
esac
exit 0
STUB
    chmod +x "$cm_dir/bin/docker"
}

# expect_nothing_removed: no docker rm, volume rm or rmi call was made.
expect_nothing_removed() {
    ! grep -qE '^docker (rm|volume|rmi)' "$cm_dir/calls" || fail "removed something: $(tr '\n' '|' <"$cm_dir/calls")"
}

# expect_refused <text>: exit 1, stderr names <text>, nothing removed.
expect_refused() {
    [[ "$cm_status" -eq 1 ]] || fail "exit $cm_status, want 1"
    grep -qF -- "$1" <<<"$cm_err" || fail "stderr lacks '$1': $cm_err"
    expect_nothing_removed
}

t_rm_sandbox() {
    cm_setup "$current"
    printf 'NAME AGENT STATUS\ncodeo-5 claude running\n' >"$cm_dir/sbx_out"
    cm_run rm 5
    [[ "$cm_status" -eq 0 ]] || fail "exit $cm_status, err: $cm_err"
    expect_call "codeo-sandbox.sh end 5 pwd=$cm_home"
    cm_setup "$current-2"
    echo 3 >"$cm_dir/status"
    cm_run rm 5 --sandbox
    [[ "$cm_status" -eq 3 ]] || fail "exit $cm_status, want 3"
    expect_call "codeo-sandbox.sh end 5 pwd=$cm_home"
}

t_rm_sandbox_force() {
    cm_setup "$current"
    cm_run rm --force 5 --sandbox
    expect_call "codeo-sandbox.sh end 5 --force pwd=$cm_home"
}

t_rm_usage() {
    expect_usage rm 5 --container --sandbox
    expect_usage rm 5 --bogus
    expect_usage rm abc --force
    expect_usage rm 5 6
    expect_usage rm --force
}

t_rm_container_clean() {
    cm_setup "$current"
    rm_stubs
    cm_run rm 5
    [[ "$cm_status" -eq 0 ]] || fail "exit $cm_status, err: $cm_err"
    local want
    want=$'docker ps -a --format {{.Names}}\nsbx ls\ndocker ps -a --format {{.Names}} {{.State}}\ndocker exec codeo-5 git -C /workspaces/codeo-5 fetch origin\ndocker exec codeo-5 git -C /workspaces/codeo-5 status --porcelain\ndocker exec codeo-5 git -C /workspaces/codeo-5 stash list\ndocker exec codeo-5 git -C /workspaces/codeo-5 branch --show-current\ndocker exec codeo-5 git -C /workspaces/codeo-5 rev-list --branches --not --remotes=origin\ndocker rm -f codeo-5\ndocker volume rm codeo-5\ndocker rmi codeo-dev:codeo-5'
    [[ "$(cat "$cm_dir/calls")" == "$want" ]] || fail "calls: $(tr '\n' '|' <"$cm_dir/calls")"
    [[ "$cm_out" == "removed codeo-5"* ]] || fail "stdout: $cm_out"
    grep -qi 'login' <<<"$cm_out" || fail "no login note: $cm_out"
    expect_no_script
}

t_rm_container_untracked() {
    cm_setup "$current"
    rm_stubs
    printf '?? f\n' >"$cm_dir/g_status"
    cm_run rm 5 --container
    expect_refused '?? f'
}

t_rm_container_unpushed() {
    cm_setup "$current"
    rm_stubs
    printf 'abc1234\n' >"$cm_dir/g_rev-list"
    cm_run rm 5 --container
    expect_refused abc1234
}

t_rm_container_stash() {
    cm_setup "$current"
    rm_stubs
    printf 'stash@{0}: WIP on x\n' >"$cm_dir/g_stash"
    cm_run rm 5 --container
    expect_refused 'stash@{0}'
}

t_rm_container_detached() {
    cm_setup "$current"
    rm_stubs
    : >"$cm_dir/g_branch"
    cm_run rm 5 --container
    expect_refused "detached HEAD"
    grep -qi 'detached' <<<"$cm_err" || fail "no detached heading: $cm_err"
}

t_rm_container_cuts_at_ten() {
    cm_setup "$current"
    rm_stubs
    seq 1 25 | sed 's/^/?? file/' >"$cm_dir/g_status"
    cm_run rm 5 --container
    [[ "$(grep -c '?? file' <<<"$cm_err")" -eq 10 ]] || fail "not cut at 10: $cm_err"
    expect_nothing_removed
}

t_rm_container_force() {
    cm_setup "$current"
    rm_stubs
    printf '?? f\n' >"$cm_dir/g_status"
    printf 'abc1234\n' >"$cm_dir/g_rev-list"
    cm_run rm 5 --container --force
    [[ "$cm_status" -eq 0 ]] || fail "exit $cm_status, err: $cm_err"
    grep -q '^docker rm -f codeo-5' "$cm_dir/calls" || fail "not removed"
    grep -q '^docker volume rm codeo-5' "$cm_dir/calls" || fail "volume kept"
    grep -qF '?? f' <<<"$cm_out" || fail "does not say what was not kept: $cm_out"
    grep -qF abc1234 <<<"$cm_out" || fail "does not list unpushed: $cm_out"
    [[ "$cm_out" == *"removed codeo-5"* ]] || fail "no removed line: $cm_out"
}

t_rm_container_cannot_check() {
    cm_setup "$current"
    rm_stubs
    touch "$cm_dir/fetch_fail"
    cm_run rm 5 --container
    expect_refused 'docker rm -f codeo-5; docker volume rm codeo-5'
    [[ "$(wc -l <"$cm_dir/err")" -eq 1 && "$cm_err" == "codeo: "* ]] || fail "not one line: $cm_err"
    cm_setup "$current-2"
    rm_stubs
    touch "$cm_dir/fetch_fail"
    cm_run rm 5 --container --force
    [[ "$cm_status" -eq 0 ]] || fail "--force: exit $cm_status, err: $cm_err"
    grep -q '^docker rm -f codeo-5' "$cm_dir/calls" || fail "--force: not removed"
    grep -qi 'could not' <<<"$cm_out$cm_err" || fail "--force: no could-not-check note: $cm_out $cm_err"
}

t_rm_image_failure_warns() {
    cm_setup "$current"
    rm_stubs
    touch "$cm_dir/rmi_fail"
    cm_run rm 5 --container
    [[ "$cm_status" -eq 0 ]] || fail "exit $cm_status"
    grep -qi 'warning' <<<"$cm_err" || fail "no warning: $cm_err"
    [[ "$cm_out" == "removed codeo-5"* ]] || fail "stdout: $cm_out"
}

t_rm_removal_failure_dies() {
    cm_setup "$current"
    rm_stubs
    touch "$cm_dir/rm_fail"
    cm_run rm 5 --container
    [[ "$cm_status" -eq 1 && "$(wc -l <"$cm_dir/err")" -eq 1 && "$cm_err" == "codeo: "* ]] || fail "rm -f: $cm_status $cm_err"
    cm_setup "$current-2"
    rm_stubs
    touch "$cm_dir/vol_fail"
    cm_run rm 5 --container
    [[ "$cm_status" -eq 1 && "$(wc -l <"$cm_dir/err")" -eq 1 && "$cm_err" == "codeo: "* ]] || fail "volume rm: $cm_status $cm_err"
}

t_rm_stopped_container_started_first() {
    cm_setup "$current"
    rm_stubs
    echo exited >"$cm_dir/dstate"
    cm_run rm 5
    [[ "$cm_status" -eq 0 ]] || fail "exit $cm_status, err: $cm_err"
    local start fetch
    start=$(grep -n '^docker start codeo-5' "$cm_dir/calls" | head -1 | cut -d: -f1)
    fetch=$(grep -n 'fetch origin' "$cm_dir/calls" | head -1 | cut -d: -f1)
    [[ -n "$start" && -n "$fetch" && "$start" -lt "$fetch" ]] || fail "start not before fetch: $(tr '\n' '|' <"$cm_dir/calls")"
    cm_setup "$current-2"
    rm_stubs
    echo exited >"$cm_dir/dstate"
    touch "$cm_dir/start_fail"
    cm_run rm 5
    expect_refused 'docker rm -f codeo-5; docker volume rm codeo-5'
}

t_rm_container_detected() {
    cm_setup "$current"
    rm_stubs
    cm_run rm 5
    grep -q '^docker rm -f codeo-5' "$cm_dir/calls" || fail "container not detected: $cm_err"
    cm_setup "$current-2"
    rm_stubs
    printf 'NAME AGENT STATUS\ncodeo-5 claude running\n' >"$cm_dir/sbx_out"
    cm_run rm 5
    [[ "$cm_status" -eq 1 ]] || fail "both kinds: exit $cm_status, want 1"
    expect_nothing_removed
    expect_no_script
}

cases=(
    t_no_args_usage
    t_unknown_command_usage
    t_bad_number_usage
    t_bad_branch_usage
    t_missing_arg_usage
    t_home_runs_script
    t_runs_from_any_directory
    t_issue_with_branch
    t_issue_accepts_valid_branch
    t_issue_rebuild_flag
    t_home_bad_flag_usage
    t_issue_branch_lookup_one
    t_issue_lookup_none
    t_issue_lookup_several
    t_shell_container
    t_first_use_downloads
    t_creates_home
    t_help_lists_commands
    t_executable_bash
    t_suite_covers
    t_exit_status_passthrough
    t_download_failure
    t_download_not_script
    t_lookup_clone_atomic
    t_lookup_uses_lstrip
    t_issue_sandbox_flag
    t_issue_default_sandbox
    t_issue_rebuild_sandbox_usage
    t_default_show_and_save
    t_shell_sandbox
    t_shell_neither
    t_shell_both
    t_shell_container_found
    t_open_sandbox
    t_open_container_refused
    t_no_docker_program
    t_sandbox_uses_home_clone
    t_list_rows
    t_list_empty
    t_list_no_programs
    t_list_docker_down
    t_list_extra_args_usage
    t_host_kinds_exact_name
    t_rm_sandbox
    t_rm_sandbox_force
    t_rm_usage
    t_rm_container_clean
    t_rm_container_untracked
    t_rm_container_unpushed
    t_rm_container_stash
    t_rm_container_detached
    t_rm_container_cuts_at_ten
    t_rm_container_force
    t_rm_container_cannot_check
    t_rm_image_failure_warns
    t_rm_removal_failure_dies
    t_rm_stopped_container_started_first
    t_rm_container_detected
)

for current in "${cases[@]}"; do
    "$current"
done

if ((failures > 0)); then
    exit 1
fi
echo "all cases passed"
