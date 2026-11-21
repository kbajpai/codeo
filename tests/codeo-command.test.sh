#!/usr/bin/env bash
# Guards .devcontainer/codeo, the host command that wraps codeo-container.sh and codeo-sandbox.sh.
# Each case is a function named in the final cases=( ... ) array; add a case by writing a function
# and listing it. The command runs under env -i with PATH holding only stub docker, sbx, git and
# curl plus sys/ links to plain system tools (never docker, sbx, git or curl) against a scratch
# directory whose calls file logs every stub call
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

# cm_sys: $cm_dir/sys holds links to the plain system tools codeo and the stubs use, and never docker,
# sbx, git or curl, so a program a case removes from bin/ is missing whatever the host has installed.
cm_sys() {
    local t p
    mkdir -p "$cm_dir/sys"
    for t in bash env cat grep sed sort cut head tail tr wc mkdir mv cp rm chmod mktemp readlink \
        dirname basename ls sleep date find id flock; do
        p=$(PATH=/usr/bin:/bin command -v "$t" 2>/dev/null) || continue
        ln -sf "$p" "$cm_dir/sys/$t"
    done
}

# cm_setup <name>: a scratch directory cm_dir with stubs in bin/ that log "<stub> <args>" to calls,
# and a $CODEO_HOME (cm_home) holding stub codeo-container.sh and codeo-sandbox.sh that log
# "<script> <args> pwd=<cwd>" to calls.
cm_setup() {
    cm_dir="$scratch/$1"
    cm_home="$cm_dir/home"
    cm_script=""
    mkdir -p "$cm_dir/bin" "$cm_home" "$cm_dir/h"
    : >"$cm_dir/calls"
    cm_sys
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
    # git stub: for-each-ref prints the lines of $d/branches; rev-parse <branch>:... succeeds when
    # <branch> is a line of $d/has.
    cat >"$cm_dir/bin/git" <<'STUB'
#!/bin/bash
d=${0%/bin/*}
echo "${0##*/} $*" >>"$d/calls"
for a in "$@"; do
    case "$a" in
        clone) [[ ! -e "$d/slow" ]] || sleep 0.3; mkdir -p "${@: -1}"; exit 0 ;;
        for-each-ref) [[ ! -e "$d/foreach_fail" ]] || exit 1; cat "$d/branches" 2>/dev/null || true; exit 0 ;;
        *:.codeo/*/init.md) b=${a%%:*}; b=${b#refs/heads/}; grep -qxF "$b" "$d/has" 2>/dev/null && exit 0 || exit 1 ;;
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
        [[ ! -e "$d/slow" ]] || sleep 0.3
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
[[ ! -e "$d/stderr_text" ]] || cat "$d/stderr_text" >&2
exit "$(cat "$d/status" 2>/dev/null || echo 0)"
STUB
        chmod +x "$cm_home/$n"
    done
}

# cm_run <args...>: run codeo with a clean environment; set cm_status, cm_out and cm_err.
cm_run() {
    cm_status=0
    env -i HOME="$cm_dir/h" CODEO_HOME="$cm_home" PATH="$cm_dir/bin:$cm_dir/sys" ${CODEO_REPO_URL:+CODEO_REPO_URL="$CODEO_REPO_URL"} ${CODEO_SBX:+CODEO_SBX="$CODEO_SBX"} \
        "$bash_abs" "${cm_script:-$script}" "$@" >"$cm_dir/out" 2>"$cm_dir/err" || cm_status=$?
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
    grep -q '^git .*clone --bare -q --filter=blob:none https://github.com/kbajpai/codeo.git ' "$cm_dir/calls" || fail "no blob-less bare clone"
    grep -q 'fetch -q --prune origin' "$cm_dir/calls" || fail "no fetch"
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
    local target
    target=$(grep -o "clone --bare .* $cm_home/\.lookup\.[^ ]*\$" "$cm_dir/calls" | sed 's/.* //') || true
    [[ -n "$target" && "$target" != "$cm_home/.lookup.git" && "$target" != "$cm_home/.lookup.git.part" ]] ||
        fail "clone not into a temporary .lookup.* directory: $(tr '\n' '|' <"$cm_dir/calls")"
    [[ ! -e "$target" ]] || fail "temporary clone directory left behind"
    [[ -d "$cm_home/.lookup.git" ]] || fail "no .lookup.git"
    [[ ! -e "$cm_home/.lookup.git/stale" ]] || fail "stale part read as the clone"
}

t_lookup_checks_file_without_blob() {
    cm_setup "$current"
    printf 'feat/a\n' >"$cm_dir/branches"
    printf 'feat/a\n' >"$cm_dir/has"
    cm_run issue 5
    grep -qF -- "rev-parse -q --verify refs/heads/feat/a:.codeo/5/init.md" "$cm_dir/calls" || fail "no rev-parse --verify: $(tr '\n' '|' <"$cm_dir/calls")"
    ! grep -q "cat-file" "$cm_dir/calls" || fail "cat-file fetches a blob"
}

t_concurrent_first_use() {
    cm_setup "$current"
    rm -f "$cm_home"/*.sh
    touch "$cm_dir/slow"
    printf 'feat/a\n' >"$cm_dir/branches"
    printf 'feat/a\n' >"$cm_dir/has"
    local pid1 pid2 s1=0 s2=0 f
    env -i HOME="$cm_dir/h" CODEO_HOME="$cm_home" PATH="$cm_dir/bin:$cm_dir/sys" \
        "$bash_abs" "$script" issue 5 >"$cm_dir/out1" 2>"$cm_dir/err1" &
    pid1=$!
    env -i HOME="$cm_dir/h" CODEO_HOME="$cm_home" PATH="$cm_dir/bin:$cm_dir/sys" \
        "$bash_abs" "$script" issue 5 >"$cm_dir/out2" 2>"$cm_dir/err2" &
    pid2=$!
    wait "$pid1" || s1=$?
    wait "$pid2" || s2=$?
    [[ "$s1" -eq 0 && "$s2" -eq 0 ]] || fail "exit $s1 and $s2: $(cat "$cm_dir/err1" "$cm_dir/err2")"
    for f in codeo-container.sh codeo-sandbox.sh; do
        [[ -s "$cm_home/$f" && "$(head -c2 "$cm_home/$f")" == "#!" ]] || fail "$f missing or not a script"
    done
    [[ -d "$cm_home/.lookup.git" ]] || fail "no .lookup.git"
    [[ -z "$(find "$cm_home" -maxdepth 1 -name ".lookup.*" ! -name .lookup.git ! -name .lookup.lock)" ]] || fail "temporary .lookup.* left behind"
    ! compgen -G "$cm_home/.lookup.git?*" >/dev/null || fail ".lookup.git.* left behind"
    ! compgen -G "$cm_home/*.part" >/dev/null || fail ".part left behind"
    ! compgen -G "$cm_home/.codeo-*" >/dev/null || fail ".codeo-* left behind"
    [[ "$(grep -c '^git clone' "$cm_dir/calls")" -eq 1 ]] || fail "clones: $(grep -c '^git clone' "$cm_dir/calls")"
}

t_lookup_repoints_clone_at_url() {
    cm_setup "$current"
    mkdir -p "$cm_home/.lookup.git"
    printf 'feat/a\n' >"$cm_dir/branches"
    printf 'feat/a\n' >"$cm_dir/has"
    CODEO_REPO_URL=https://example.test/new.git cm_run issue 5
    local set fetch
    set=$(grep -n "remote set-url origin https://example.test/new.git$" "$cm_dir/calls" | head -1 | cut -d: -f1) || true
    fetch=$(grep -n "fetch -q --prune origin" "$cm_dir/calls" | head -1 | cut -d: -f1) || true
    [[ -n "$set" && -n "$fetch" && "$set" -lt "$fetch" ]] || fail "set-url not before fetch: $(tr '\n' '|' <"$cm_dir/calls")"
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

t_run_path_has_no_host_programs() {
    cm_setup "$current"
    # A real docker, sbx, git or curl on the host's PATH must not be visible to a run.
    local fake="$scratch/hostbin" n out
    mkdir -p "$fake"
    for n in docker sbx git curl; do printf '#!/bin/bash\necho host-%s\n' "$n" >"$fake/$n"; chmod +x "$fake/$n"; done
    rm -f "$cm_dir/bin/docker" "$cm_dir/bin/sbx" "$cm_dir/bin/git" "$cm_dir/bin/curl"
    out=$(PATH="$fake:$PATH" env -i PATH="$cm_dir/bin:$cm_dir/sys" "$bash_abs" -c 'command -v docker sbx git curl' 2>&1) || true
    [[ -z "$out" ]] || fail "a run's PATH finds host programs: $out"
    PATH="$fake:$PATH" cm_run list
    [[ "$cm_status" -eq 1 && "$cm_err" == "codeo: neither docker nor sbx is installed"* ]] || fail "list: $cm_status $cm_err"
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
if [[ -e "$d/docker_fail" ]]; then cat "$d/docker_err" >&2 2>/dev/null; exit 1; fi
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
    printf 'codeo-140 exited\ncodeo-home running\ncodeo-131 running\ncodeo-9 paused\ncodeo-10 restarting\nother running\n' >"$cm_dir/docker_out"
    printf 'fix/a\n' >"$cm_dir/dbranch_codeo-131"
    printf 'NAME AGENT STATUS\ncodeo-133 claude running\ncodeo-12 claude stopped\ncodeo-5 claude running (detached)\nnotcodeo-7 claude running\n' >"$cm_dir/sbx_out"
    printf 'feat/s\n' >"$cm_dir/gbranch_codeo-133"
    mkdir -p "$cm_home/codeo-133"
    cm_run list
    local want
    want=$'#9  container  paused  -\n#10  container  restarting  -\n#131  container  running  fix/a\n#140  container  stopped  -\n#5  sandbox  detached  -\n#12  sandbox  stopped  -\n#133  sandbox  running  feat/s'
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

# sbx_down_stub: an sbx that logs, prints $d/sbx_err on stderr and exits 1.
sbx_down_stub() {
    cat >"$cm_dir/bin/sbx" <<'STUB'
#!/bin/bash
d=${0%/bin/*}
echo "${0##*/} $*" >>"$d/calls"
cat "$d/sbx_err" >&2 2>/dev/null || true
exit 1
STUB
    chmod +x "$cm_dir/bin/sbx"
}

t_list_docker_down() {
    cm_setup "$current"
    list_stubs
    touch "$cm_dir/docker_fail"
    printf 'Cannot connect to the Docker daemon\nsecond line\n' >"$cm_dir/docker_err"
    printf 'NAME AGENT STATUS\ncodeo-133 claude running\n' >"$cm_dir/sbx_out"
    cm_run list
    [[ "$cm_status" -eq 1 ]] || fail "exit $cm_status, want 1"
    [[ "$cm_out" == "#133  sandbox  running  -" ]] || fail "output: $cm_out"
    [[ "$cm_err" == $'codeo: could not list docker containers\n  Cannot connect to the Docker daemon' ]] || fail "stderr: $cm_err"
    cm_setup "$current-2"
    rm -f "$cm_dir/bin/sbx"
    printf 'codeo-4 running\n' >"$cm_dir/docker_out"
    list_stubs
    cm_run list
    [[ "$cm_out" == "#4  container  running  -" && "$cm_status" -eq 0 && -z "$cm_err" ]] || fail "sbx missing: $cm_status $cm_out $cm_err"
}

t_list_sbx_down() {
    cm_setup "$current"
    list_stubs
    sbx_down_stub
    printf 'daemon not running\n' >"$cm_dir/sbx_err"
    printf 'codeo-4 running\n' >"$cm_dir/docker_out"
    cm_run list
    [[ "$cm_status" -eq 1 ]] || fail "exit $cm_status, want 1"
    [[ "$cm_out" == "#4  container  running  -" ]] || fail "output: $cm_out"
    [[ "$cm_err" == $'codeo: could not list sbx sandboxes\n  daemon not running' ]] || fail "stderr: $cm_err"
}

t_list_one_down_nothing_shown() {
    cm_setup "$current"
    list_stubs
    touch "$cm_dir/docker_fail"
    printf 'NAME AGENT STATUS\n' >"$cm_dir/sbx_out"
    cm_run list
    [[ "$cm_status" -eq 1 ]] || fail "exit $cm_status, want 1"
    [[ -z "$cm_out" ]] || fail "printed on stdout: $cm_out"
    [[ "$cm_err" == "codeo: could not list docker containers" ]] || fail "stderr: $cm_err"
    cm_setup "$current-2"
    list_stubs
    touch "$cm_dir/docker_fail"
    rm -f "$cm_dir/bin/sbx"
    cm_run list
    [[ "$cm_status" -eq 1 && -z "$cm_out" ]] || fail "docker only, failing: $cm_status $cm_out"
    grep -q 'could not list docker containers' <<<"$cm_err" || fail "no warning: $cm_err"
}

# detect_down_setup <name>: docker fails, sbx lists no codeo-5.
detect_down_setup() {
    cm_setup "$1"
    list_stubs
    touch "$cm_dir/docker_fail"
    printf 'NAME AGENT STATUS\ncodeo-55 claude running\n' >"$cm_dir/sbx_out"
}

expect_could_not_ask() {
    [[ "$cm_status" -eq 1 ]] || fail "exit $cm_status, want 1"
    grep -qF 'codeo: could not ask docker or sbx whether codeo-5 exists; fix that, or pick one with --container or --sandbox' <<<"$cm_err" || fail "stderr: $cm_err"
    ! grep -q 'codeo issue 5' <<<"$cm_err" || fail "tells the engineer to start one: $cm_err"
    grep -q 'could not list docker containers' <<<"$cm_err" || fail "no listing warning: $cm_err"
}

t_shell_listing_down_nothing_found() {
    detect_down_setup "$current"
    cm_run shell 5
    expect_could_not_ask
    expect_no_script
}

t_rm_listing_down_nothing_found() {
    detect_down_setup "$current"
    cm_run rm 5
    expect_could_not_ask
    expect_no_script
    expect_nothing_removed
    cm_setup "$current-2"
    list_stubs
    sbx_down_stub
    printf 'codeo-4\n' >"$cm_dir/docker_out"
    cm_run open 5
    [[ "$cm_status" -eq 1 ]] || fail "open: exit $cm_status"
    grep -q 'could not ask docker or sbx' <<<"$cm_err" || fail "open: stderr: $cm_err"
    expect_no_script
}

t_shell_docker_down_sandbox_found() {
    cm_setup "$current"
    list_stubs
    touch "$cm_dir/docker_fail"
    printf 'NAME AGENT STATUS\ncodeo-5 claude running\n' >"$cm_dir/sbx_out"
    cm_run shell 5
    [[ "$cm_status" -eq 1 ]] || fail "exit $cm_status, want 1"
    grep -q 'could not list docker containers' <<<"$cm_err" || fail "no warning: $cm_err"
    grep -q 'as the other kind; pick one with --container or --sandbox' <<<"$cm_err" || fail "no die: $cm_err"
    expect_no_script
}

t_shell_docker_down_sandbox_flag() {
    cm_setup "$current"
    list_stubs
    touch "$cm_dir/docker_fail"
    printf 'NAME AGENT STATUS\ncodeo-5 claude running\n' >"$cm_dir/sbx_out"
    cm_run shell 5 --sandbox
    [[ "$cm_status" -eq 0 ]] || fail "exit $cm_status, err: $cm_err"
    expect_call "codeo-sandbox.sh shell 5 pwd=$cm_home"
}

t_home_rebuild_twice_usage() { expect_usage home --rebuild --rebuild; }

t_lookup_quiet_git() {
    cm_setup "$current"
    printf 'feat/a\n' >"$cm_dir/branches"
    printf 'feat/a\n' >"$cm_dir/has"
    cm_run issue 5
    grep -q '^git clone --bare -q ' "$cm_dir/calls" || fail "clone not quiet: $(cat "$cm_dir/calls")"
    grep -q 'fetch -q --prune origin' "$cm_dir/calls" || fail "fetch not quiet"
}

t_lookup_branch_list_failure() {
    cm_setup "$current"
    printf 'feat/a\n' >"$cm_dir/branches"
    printf 'feat/a\n' >"$cm_dir/has"
    touch "$cm_dir/foreach_fail"
    cm_run issue 5
    [[ "$cm_status" -eq 1 ]] || fail "exit $cm_status, want 1"
    grep -q 'could not list branches of' <<<"$cm_err" || fail "stderr: $cm_err"
    expect_no_script
}

t_help_names_kind_flags() {
    cm_setup "$current"
    cm_run help
    local c
    for c in 'shell home|<N> [--container|--sandbox]' 'open <N> [--container|--sandbox]' 'rm <N> [--force] [--container|--sandbox]'; do
        grep -qF -- "$c" <<<"$cm_out" || fail "help lacks '$c'"
    done
    cm_run frob
    for c in 'shell home|<N> [--container|--sandbox]' 'open <N> [--container|--sandbox]' 'rm <N> [--force] [--container|--sandbox]'; do
        grep -qF -- "$c" <<<"$cm_err" || fail "usage lacks '$c'"
    done
}

t_rm_refusal_stops_started_container() {
    cm_setup "$current"
    rm_stubs
    echo exited >"$cm_dir/dstate"
    printf 'abc1234\n' >"$cm_dir/g_rev-list"
    cm_run rm 5
    expect_refused abc1234
    grep -q '^docker stop codeo-5' "$cm_dir/calls" || fail "no docker stop: $(tr '\n' '|' <"$cm_dir/calls")"
    cm_setup "$current-2"
    rm_stubs
    echo exited >"$cm_dir/dstate"
    touch "$cm_dir/fetch_fail"
    cm_run rm 5
    grep -q '^docker stop codeo-5' "$cm_dir/calls" || fail "cannot-check: no docker stop"
    cm_setup "$current-3"
    rm_stubs
    printf 'abc1234\n' >"$cm_dir/g_rev-list"
    cm_run rm 5
    ! grep -q '^docker stop' "$cm_dir/calls" || fail "stopped a container that was running"
}

t_rm_container_not_found() {
    cm_setup "$current"
    rm_stubs
    touch "$cm_dir/gone" "$cm_dir/start_fail"
    cm_run rm 5 --container
    [[ "$cm_status" -eq 1 && "$cm_err" == "codeo: no container codeo-5 found"* ]] || fail "$cm_status $cm_err"
    [[ "$(wc -l <"$cm_dir/err")" -eq 1 ]] || fail "not one line: $cm_err"
    ! grep -q "^docker rm" "$cm_dir/calls" || fail "removed something"
    cm_setup "$current-2"
    rm_stubs
    touch "$cm_dir/start_fail"
    echo exited >"$cm_dir/dstate"
    cm_run rm 5 --container
    grep -q "unsaved work" <<<"$cm_err" || fail "existing container that will not start: $cm_err"
}

t_rm_unlisted_state_not_stopped_by_us() {
    cm_setup "$current"
    rm_stubs
    touch "$cm_dir/ps_fail" "$cm_dir/fetch_fail"
    cm_run rm 5 --container
    grep -q "^docker start codeo-5" "$cm_dir/calls" || fail "did not try to start"
    ! grep -q "^docker stop" "$cm_dir/calls" || fail "stopped a container that may have been running: $(tr '\n' '|' <"$cm_dir/calls")"
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
# exists, or for the git subcommand named in exec_fail; docker ps lists nothing once docker rm ran when gone_after_rm exists; docker start, rm, volume rm and rmi fail when start_fail, rm_fail, vol_fail, rmi_fail exist;
# docker inspect prints $d/mounts (default "volume codeo-5") and fails when inspect_fail exists; docker volume inspect
# and rm fail when vol_gone exists; docker restart fails when restart_fail exists; once docker restart is in the calls file, $d/g2_<sub> (when it
# exists) replaces $d/g_<sub> as the output of docker exec ... git -C <dir> <sub>.
rm_stubs() {
    cat >"$cm_dir/bin/docker" <<'STUB'
#!/bin/bash
d=${0%/bin/*}
echo "${0##*/} $*" >>"$d/calls"
case "$1" in
    ps)
        [[ ! -e "$d/ps_fail" ]] || exit 1
        if [[ -e "$d/gone" ]]; then :
        elif [[ -e "$d/gone_after_rm" ]] && grep -q "^docker rm" "$d/calls"; then :
        elif [[ "$*" == *State* ]]; then echo "codeo-5 $(cat "$d/dstate" 2>/dev/null || echo running)"; else echo codeo-5; fi ;;
    start) [[ ! -e "$d/start_fail" ]] || exit 1 ;;
    restart) [[ ! -e "$d/restart_fail" ]] || exit 1 ;;
    rm) [[ ! -e "$d/rm_fail" ]] || exit 1 ;;
    volume)
        [[ "$2" != inspect && "$2" != rm || ! -e "$d/vol_gone" ]] || exit 1
        [[ "$2" != rm || ! -e "$d/vol_fail" ]] || exit 1 ;;
    inspect)
        [[ ! -e "$d/inspect_fail" ]] || exit 1
        cat "$d/mounts" 2>/dev/null || echo "volume codeo-5" ;;
    rmi) [[ ! -e "$d/rmi_fail" ]] || exit 1 ;;
    exec)
        sub=$6
        [[ "$sub" != fetch || ! -e "$d/fetch_fail" ]] || exit 1
        [[ "$*" != *refs/pull/* || ! -e "$d/prfetch_fail" ]] || exit 1
        # once the pull-request head fetch ran: rev-list prints nothing when rev_pr_covered exists, and
        # branch -r --contains prints g_branch_r_pr when that exists
        prf=0
        ! grep -q 'refs/pull/' "$d/calls" || prf=1
        if [[ "$prf" -eq 1 && "$sub" == rev-list && -e "$d/rev_pr_covered" ]]; then exit 0; fi
        if [[ "$prf" -eq 1 && "$sub" == branch && "$*" == *" -r "* && -e "$d/g_branch_r_pr" ]]; then cat "$d/g_branch_r_pr"; exit 0; fi
        [[ "$sub" != "$(cat "$d/exec_fail" 2>/dev/null)" ]] || exit 1
        g=g
        ! grep -q '^docker restart' "$d/calls" || [[ ! -e "$d/g2_$sub" ]] || g=g2
        if [[ "$sub" == branch && "$*" == *" -r "* ]]; then cat "$d/g_branch_r" 2>/dev/null || true
        elif [[ "$sub" == branch && ! -e "$d/g_branch" && "$g" == g ]]; then echo main; else cat "$d/${g}_$sub" 2>/dev/null || true; fi ;;
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
    grep -qF 'codeo rm 5 --force removes it anyway' <<<"$cm_err" || fail "no --force hint: $cm_err"
    ! grep -qF 'sbx rm --force' <<<"$cm_err" || fail "names sbx rm --force without --force: $cm_err"
    cm_setup "$current-3"
    cm_run rm 5 --sandbox
    [[ "$cm_status" -eq 0 ]] || fail "exit $cm_status"
    ! grep -q 'to remove it anyway' <<<"$cm_err" || fail "hint on success: $cm_err"
    ! grep -q 'removes it anyway' <<<"$cm_err" || fail "hint on success: $cm_err"
}

t_rm_sandbox_hints() {
    local last want n
    cm_setup "$current"
    echo 1 >"$cm_dir/status"
    cm_run rm 5 --sandbox --force
    [[ "$cm_status" -eq 1 ]] || fail "exit $cm_status, want 1"
    last=$(tail -n 1 "$cm_dir/err")
    want='codeo: to remove it anyway, discarding whatever it holds: sbx rm --force codeo-5'
    [[ "$last" == "$want" ]] || fail "last stderr line '$last', want '$want'"
    cm_setup "$current-2"
    echo 1 >"$cm_dir/status"
    printf 'could not read it\nto remove it anyway run: sbx rm --force codeo-5\n' >"$cm_dir/stderr_text"
    cm_run rm 5 --sandbox --force
    [[ "$cm_status" -eq 1 ]] || fail "exit $cm_status, want 1"
    n=$(grep -c 'sbx rm --force codeo-5' "$cm_dir/err" || true)
    [[ "$n" -eq 1 ]] || fail "sbx rm --force line count $n, want 1: $cm_err"
    grep -qxF 'to remove it anyway run: sbx rm --force codeo-5' <<<"$cm_err" || fail "script's own line lost: $cm_err"
    grep -qxF 'could not read it' <<<"$cm_err" || fail "script's stderr not replayed: $cm_err"
    cm_setup "$current-4"
    echo 1 >"$cm_dir/status"
    printf 'to remove it anyway run: sbx rm --force codeo-15\n' >"$cm_dir/stderr_text"
    cm_run rm 1 --sandbox --force
    [[ "$cm_status" -eq 1 ]] || fail "exit $cm_status, want 1"
    last=$(tail -n 1 "$cm_dir/err")
    want='codeo: to remove it anyway, discarding whatever it holds: sbx rm --force codeo-1'
    [[ "$last" == "$want" ]] || fail "codeo-15 in stderr suppressed the hint for 1: '$last'"
    [[ -z "$(ls -A "$cm_dir/h" "$cm_home" | grep '^\.rm-err' || true)" ]] || fail "temp file left behind"
    cm_setup "$current-3"
    echo 1 >"$cm_dir/status"
    printf 'could not read it\n' >"$cm_dir/stderr_text"
    cm_run rm 5 --sandbox
    [[ "$cm_status" -eq 1 ]] || fail "exit $cm_status, want 1"
    grep -qxF 'could not read it' <<<"$cm_err" || fail "script's stderr not replayed: $cm_err"
    grep -qF "$cm_home/codeo-5" <<<"$cm_err" || fail "hint lacks the clone directory: $cm_err"
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
    want=$'docker ps -a --format {{.Names}}\nsbx ls\ndocker ps -a --format {{.Names}} {{.State}}\ndocker exec codeo-5 git -C /workspaces/codeo-5 fetch --prune origin\ndocker exec codeo-5 git -C /workspaces/codeo-5 fetch origin +refs/pull/*/head:refs/remotes/origin/pr/*\ndocker exec codeo-5 git -C /workspaces/codeo-5 status --porcelain --untracked-files=normal\ndocker exec codeo-5 git -C /workspaces/codeo-5 stash list\ndocker exec codeo-5 git -C /workspaces/codeo-5 branch --show-current\ndocker exec codeo-5 git -C /workspaces/codeo-5 rev-list --branches --not --remotes=origin\ndocker restart codeo-5\ndocker exec codeo-5 git -C /workspaces/codeo-5 status --porcelain --untracked-files=normal\ndocker exec codeo-5 git -C /workspaces/codeo-5 stash list\ndocker exec codeo-5 git -C /workspaces/codeo-5 branch --show-current\ndocker exec codeo-5 git -C /workspaces/codeo-5 rev-list --branches --not --remotes=origin\ndocker inspect -f {{range .Mounts}}{{if eq .Destination "/workspaces"}}{{.Type}} {{.Name}}{{end}}{{end}} codeo-5\ndocker rm -f codeo-5\ndocker volume rm codeo-5\ndocker rmi codeo-dev:codeo-5'
    [[ "$(cat "$cm_dir/calls")" == "$want" ]] || fail "calls: $(tr '\n' '|' <"$cm_dir/calls")"
    [[ "$cm_out" == "removed codeo-5"* ]] || fail "stdout: $cm_out"
    grep -qi 'login' <<<"$cm_out" || fail "no login note: $cm_out"
    expect_no_script
}

t_rm_restarts_running_container_and_reads_again() {
    cm_setup "$current"
    rm_stubs
    cm_run rm 5
    [[ "$cm_status" -eq 0 ]] || fail "exit $cm_status, err: $cm_err"
    local calls first_rev restart rmf k
    calls=$(tr '\n' '|' <"$cm_dir/calls")
    first_rev=$(grep -n ' rev-list ' "$cm_dir/calls" | head -1 | cut -d: -f1 || true)
    restart=$(grep -n '^docker restart codeo-5' "$cm_dir/calls" | head -1 | cut -d: -f1 || true)
    rmf=$(grep -n '^docker rm -f' "$cm_dir/calls" | head -1 | cut -d: -f1 || true)
    [[ -n "$first_rev" && -n "$restart" && -n "$rmf" && "$first_rev" -lt "$restart" && "$restart" -lt "$rmf" ]] ||
        fail "restart not between first rev-list and rm: $calls"
    for k in ' status ' ' stash list' ' branch --show-current' ' rev-list '; do
        [[ "$(grep -cF -- "$k" "$cm_dir/calls" || true)" -eq 2 ]] || fail "'$k' not read twice: $calls"
    done
    [[ "$(grep -c ' fetch ' "$cm_dir/calls" || true)" -eq 2 ]] || fail "fetch not exactly twice: $calls"
    [[ "$(grep -c -- '--prune' "$cm_dir/calls" || true)" -eq 1 ]] || fail "want one --prune: $calls"
    [[ "$(grep -c 'refs/pull/' "$cm_dir/calls" || true)" -eq 1 ]] || fail "want one pull-request fetch: $calls"
}

t_rm_write_after_check_refused() {
    cm_setup "$current"
    rm_stubs
    printf '?? new\n' >"$cm_dir/g2_status"
    cm_run rm 5
    expect_refused '?? new'
    grep -q '^docker restart codeo-5' "$cm_dir/calls" || fail "no restart: $(tr '\n' '|' <"$cm_dir/calls")"
    ! grep -q '^docker stop' "$cm_dir/calls" || fail "stopped a running container"
}

t_rm_restart_fails() {
    cm_setup "$current"
    rm_stubs
    touch "$cm_dir/restart_fail"
    cm_run rm 5
    expect_refused 'could not check'
    cm_setup "$current-2"
    rm_stubs
    touch "$cm_dir/restart_fail"
    cm_run rm 5 --force
    [[ "$cm_status" -eq 0 ]] || fail "--force: exit $cm_status, err: $cm_err"
    grep -q '^docker rm -f codeo-5' "$cm_dir/calls" || fail "--force: not removed"
}

t_rm_started_container_not_restarted() {
    cm_setup "$current"
    rm_stubs
    echo exited >"$cm_dir/dstate"
    cm_run rm 5
    [[ "$cm_status" -eq 0 ]] || fail "exit $cm_status, err: $cm_err"
    ! grep -q '^docker restart' "$cm_dir/calls" || fail "restarted a container we started"
}

t_rm_check_prunes_and_sees_untracked() {
    cm_setup "$current"
    rm_stubs
    cm_run rm 5 --container
    local pr_line prune_line
    prune_line=$(grep -nF 'docker exec codeo-5 git -C /workspaces/codeo-5 fetch --prune origin' "$cm_dir/calls" | head -1 | cut -d: -f1 || true)
    [[ -n "$prune_line" ]] || fail "no fetch --prune"
    pr_line=$(grep -nF 'refs/pull/*/head' "$cm_dir/calls" | head -1 | cut -d: -f1 || true)
    [[ -n "$pr_line" && "$prune_line" -lt "$pr_line" ]] || fail "prune not before pull-request fetch"
    grep -qF 'status --porcelain --untracked-files=normal' "$cm_dir/calls" || fail "no untracked-files=normal"
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

t_rm_container_detached_pushed() {
    cm_setup "$current"
    rm_stubs
    : >"$cm_dir/g_branch"
    printf '  origin/main\n' >"$cm_dir/g_branch_r"
    cm_run rm 5 --container
    [[ "$cm_status" -eq 0 ]] || fail "exit $cm_status, err: $cm_err"
    ! grep -qi 'detached' <<<"$cm_err$cm_out" || fail "reported a pushed detached HEAD: $cm_err"
    grep -q '^docker rm' "$cm_dir/calls" || fail "not removed"
}

t_rm_container_cuts_at_ten() {
    local k
    for k in status stash rev-list; do
        cm_setup "$current-$k"
        rm_stubs
        seq 1 25 | sed 's/^/line/' >"$cm_dir/g_$k"
        cm_run rm 5 --container
        [[ "$(grep -c '^  line' <<<"$cm_err")" -eq 10 ]] || fail "$k: not cut at 10: $cm_err"
        expect_nothing_removed
    done
}

t_rm_exec_failure_is_not_clean() {
    local k
    for k in status stash branch rev-list; do
        cm_setup "$current-$k"
        rm_stubs
        echo "$k" >"$cm_dir/exec_fail"
        cm_run rm 5 --container
        expect_refused 'docker rm -f codeo-5; docker volume rm codeo-5'
        cm_setup "$current-$k-force"
        rm_stubs
        echo "$k" >"$cm_dir/exec_fail"
        cm_run rm 5 --container --force
        [[ "$cm_status" -eq 0 ]] || fail "$k --force: exit $cm_status, err: $cm_err"
        grep -q '^docker rm -f codeo-5' "$cm_dir/calls" || fail "$k --force: not removed"
        grep -qi 'could not' <<<"$cm_out" || fail "$k --force: no could-not-check note: $cm_out"
    done
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
    ! grep -q removed <<<"$cm_out" || fail "rm -f: stdout says removed: $cm_out"
    cm_setup "$current-2"
    rm_stubs
    touch "$cm_dir/vol_fail"
    cm_run rm 5 --container
    [[ "$cm_status" -eq 1 && "$(wc -l <"$cm_dir/err")" -eq 1 && "$cm_err" == "codeo: "* ]] || fail "volume rm: $cm_status $cm_err"
    ! grep -q removed <<<"$cm_out" || fail "volume rm: stdout says removed: $cm_out"
}

t_rm_force_container_gone() {
    cm_setup "$current"
    rm_stubs
    touch "$cm_dir/rm_fail" "$cm_dir/gone_after_rm"
    cm_run rm 5 --container --force
    [[ "$cm_status" -eq 0 ]] || fail "exit $cm_status, err: $cm_err"
    grep -q '^docker volume rm codeo-5' "$cm_dir/calls" || fail "volume kept: $(tr '\n' '|' <"$cm_dir/calls")"
    grep -q '^docker rmi codeo-dev:codeo-5' "$cm_dir/calls" || fail "image kept"
    [[ "$cm_out" == *"removed volume codeo-5"* ]] || fail "no removed line: $cm_out"
    ! grep -q 'removed container' <<<"$cm_out" || fail "says removed container: $cm_out"
}

t_rm_force_failing_rm_still_listed_dies() {
    cm_setup "$current"
    rm_stubs
    touch "$cm_dir/rm_fail"
    cm_run rm 5 --container --force
    [[ "$cm_status" -eq 1 && "$(wc -l <"$cm_dir/err")" -eq 1 && "$cm_err" == "codeo: "* ]] || fail "$cm_status $cm_err"
    ! grep -q removed <<<"$cm_out" || fail "stdout says removed: $cm_out"
    ! grep -qE '^docker (volume|rmi)' "$cm_dir/calls" || fail "went on to remove: $(tr '\n' '|' <"$cm_dir/calls")"
}

t_rm_stopped_container_started_first() {
    cm_setup "$current"
    rm_stubs
    echo exited >"$cm_dir/dstate"
    cm_run rm 5
    [[ "$cm_status" -eq 0 ]] || fail "exit $cm_status, err: $cm_err"
    local start fetch
    start=$(grep -n '^docker start codeo-5' "$cm_dir/calls" | head -1 | cut -d: -f1 || true)
    fetch=$(grep -n 'fetch .*origin' "$cm_dir/calls" | head -1 | cut -d: -f1 || true)
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

# update_setup <name>: cm_setup plus an installed copy of codeo in $cm_dir/inst (cm_script), installed
# scripts with known "old" bodies, a curl stub that serves $cm_dir/body_<file> (a #! script by
# default) and fails for a file named in $cm_dir/fail, and an mv stub that logs to calls.
update_setup() {
    cm_setup "$1"
    mkdir -p "$cm_dir/inst"
    cp "$script" "$cm_dir/inst/codeo"
    cm_script="$cm_dir/inst/codeo"
    printf '#!/bin/bash\n# old container\n' >"$cm_home/codeo-container.sh"
    printf '#!/bin/bash\n# old sandbox\n' >"$cm_home/codeo-sandbox.sh"
    cat >"$cm_dir/bin/curl" <<'STUB'
#!/bin/bash
d=${0%/bin/*}
echo "curl $*" >>"$d/calls"
out=""
url=""
while [[ $# -gt 0 ]]; do
    [[ "$1" == -o ]] && { out=$2; shift; }
    url=$1
    shift
done
f=${url##*/}
if grep -qxF "$f" "$d/fail" 2>/dev/null; then exit 22; fi
if [[ -e "$d/body_$f" ]]; then cp "$d/body_$f" "$out"; else printf '#!/bin/bash\n# new %s\n' "$f" >"$out"; fi
STUB
    cat >"$cm_dir/bin/mv" <<'STUB'
#!/bin/bash
d=${0%/bin/*}
echo "mv $*" >>"$d/calls"
[[ "$(grep -c "^mv " "$d/calls")" == "$(cat "$d/mv_fail_at" 2>/dev/null)" ]] && exit 1
exec /bin/mv "$@"
STUB
    chmod +x "$cm_dir/bin/curl" "$cm_dir/bin/mv"
}

# update_snapshot: print a checksum of the three installed files.
update_snapshot() {
    cksum "$cm_home/codeo-container.sh" "$cm_home/codeo-sandbox.sh" "$cm_dir/inst/codeo"
}

# expect_update_untouched <before-snapshot> <file-named-in-error>: update failed with one codeo: line
# naming the file, nothing installed changed and no temporary file or directory is left.
expect_update_untouched() {
    [[ "$cm_status" -eq 1 ]] || fail "exit $cm_status, want 1"
    [[ "$(wc -l <"$cm_dir/err")" -eq 1 ]] || fail "stderr is not one line: $cm_err"
    [[ "$cm_err" == codeo:*"$2"* ]] || fail "stderr does not name $2: $cm_err"
    [[ "$(update_snapshot)" == "$1" ]] || fail "installed files changed"
    local left
    left=$(find "$cm_home" -mindepth 1 \( -name '.update.*' -o -name '*.part' \) | head -n 3)
    [[ -z "$left" ]] || fail "leftovers: $left"
    [[ "$(ls -A "$cm_dir/inst")" == codeo ]] || fail "inst holds more than codeo: $(ls -A "$cm_dir/inst")"
}

t_update_replaces_three() {
    update_setup "$current"
    cm_run update
    [[ "$cm_status" -eq 0 ]] || fail "exit $cm_status: $cm_err"
    [[ "$cm_out" == "updated codeo and both scripts" ]] || fail "stdout: $cm_out"
    grep -q 'new codeo-container.sh' "$cm_home/codeo-container.sh" || fail "container script not replaced"
    grep -q 'new codeo-sandbox.sh' "$cm_home/codeo-sandbox.sh" || fail "sandbox script not replaced"
    grep -q 'new codeo$' "$cm_dir/inst/codeo" || fail "codeo not replaced"
    [[ -x "$cm_home/codeo-container.sh" && -x "$cm_home/codeo-sandbox.sh" && -x "$cm_dir/inst/codeo" ]] ||
        fail "an installed file is not executable"
    [[ "$(stat -c %a "$cm_home/codeo-container.sh" "$cm_home/codeo-sandbox.sh" "$cm_dir/inst/codeo" | sort -u)" == 755 ]] || fail "installed files are not all mode 755"
    [[ "$(grep -c '^curl .*-fsSL' "$cm_dir/calls")" -eq 3 ]] || fail "want three curl -fsSL calls: $(cat "$cm_dir/calls")"
    local mvs
    mvs=$(grep '^mv ' "$cm_dir/calls")
    [[ "$(tail -n 1 <<<"$mvs")" == "mv "*" $cm_dir/inst/codeo" ]] || fail "last mv is not onto codeo: $mvs"
    [[ "$(grep -c " $cm_dir/inst/codeo\$" <<<"$mvs")" -eq 1 ]] || fail "codeo moved more than once: $mvs"
    [[ "$mvs" == *" $cm_home/codeo-container.sh"* && "$mvs" == *" $cm_home/codeo-sandbox.sh"* ]] ||
        fail "scripts not moved into home: $mvs"
    [[ -z "$(find "$cm_home" -name '.update.*')" ]] || fail "temp directory left"
}

t_update_failed_download_changes_nothing() {
    update_setup "$current"
    echo codeo-sandbox.sh >"$cm_dir/fail"
    local before
    before=$(update_snapshot)
    cm_run update
    expect_update_untouched "$before" codeo-sandbox.sh
    ! grep -q '^mv ' "$cm_dir/calls" || fail "mv ran: $(grep '^mv ' "$cm_dir/calls")"
}

t_update_empty_file_refused() {
    update_setup "$current"
    : >"$cm_dir/body_codeo-sandbox.sh"
    local before
    before=$(update_snapshot)
    cm_run update
    expect_update_untouched "$before" codeo-sandbox.sh
}

t_update_not_a_script_refused() {
    update_setup "$current"
    printf '<html><body>404: Not Found</body></html>\n' >"$cm_dir/body_codeo"
    local before
    before=$(update_snapshot)
    cm_run update
    expect_update_untouched "$before" codeo
}

t_update_without_scripts() {
    update_setup "$current"
    rm -rf "$cm_home"
    cm_run update
    [[ "$cm_status" -eq 0 ]] || fail "exit $cm_status: $cm_err"
    [[ -s "$cm_home/codeo-container.sh" && -s "$cm_home/codeo-sandbox.sh" ]] || fail "scripts not installed"
}

# expect_update_partial <fail-at> <new-files-text>: the <fail-at>th mv fails; one codeo: line says
# the update is partial and what is new, and the temporary directory and file are gone.
expect_update_partial() {
    update_setup "$current"
    echo "$1" >"$cm_dir/mv_fail_at"
    cm_run update
    [[ "$cm_status" -eq 1 ]] || fail "exit $cm_status, want 1"
    [[ "$(wc -l <"$cm_dir/err")" -eq 1 ]] || fail "stderr is not one line: $cm_err"
    [[ "$cm_err" == "codeo: update failed part-way: "*"$2"* ]] || fail "stderr: $cm_err"
    [[ -z "$(find "$cm_home" -name '.update.*')" ]] || fail "temp directory left"
    [[ "$(ls -A "$cm_dir/inst")" == codeo ]] || fail "inst holds more than codeo: $(ls -A "$cm_dir/inst")"
}

t_update_partial_second_mv() { expect_update_partial 2 "codeo-container.sh is new, codeo-sandbox.sh and codeo are still old"; }
t_update_partial_final_mv() { expect_update_partial 3 "both scripts are new, codeo is still old"; }

t_update_usage_extra_args() { expect_usage update now; }

t_relative_codeo_home() {
    cm_setup "$current"
    cd "$cm_dir"
    cm_status=0
    env -i HOME="$cm_dir/h" CODEO_HOME=home PATH="$cm_dir/bin:$cm_dir/sys" \
        "$bash_abs" "$script" home >"$cm_dir/out" 2>"$cm_dir/err" || cm_status=$?
    cd "$repo"
    cm_err=$(cat "$cm_dir/err")
    [[ "$cm_status" -eq 0 ]] || fail "exit $cm_status, err: $cm_err"
    expect_call "codeo-container.sh home pwd=$cm_home"
}

t_home_unset() {
    cm_setup "$current"
    cm_status=0
    env -i PATH="$cm_dir/bin:$cm_dir/sys" "$bash_abs" "$script" help >"$cm_dir/out" 2>"$cm_dir/err" || cm_status=$?
    [[ "$cm_status" -eq 0 ]] || fail "help with HOME unset: exit $cm_status, err: $(cat "$cm_dir/err")"
    grep -q 'export PATH=' "$cm_dir/out" || fail "help lacks the PATH line"
    cm_status=0
    env -i PATH="$cm_dir/bin:$cm_dir/sys" "$bash_abs" "$script" home >"$cm_dir/out" 2>"$cm_dir/err" || cm_status=$?
    cm_err=$(cat "$cm_dir/err")
    [[ "$cm_status" -eq 1 && "$cm_err" == "codeo: set CODEO_HOME or HOME" ]] || fail "home: $cm_status $cm_err"
    [[ ! -s "$cm_dir/calls" ]] || fail "made calls: $(cat "$cm_dir/calls")"
}

t_home_dir_uncreatable() {
    cm_setup "$current"
    : >"$cm_dir/afile"
    cm_home="$cm_dir/afile/sub"
    cm_run home
    [[ "$cm_status" -eq 1 && "$(wc -l <"$cm_dir/err")" -eq 1 && "$cm_err" == "codeo: could not create $cm_home" ]] ||
        fail "$cm_status $cm_err"
    [[ ! -s "$cm_dir/calls" ]] || fail "made calls: $(cat "$cm_dir/calls")"
}

t_rebuild_saved_sandbox_usage() {
    cm_setup "$current"
    echo sandbox >"$cm_home/default"
    cm_run issue 5 fix/x --rebuild
    [[ "$cm_status" -eq 2 ]] || fail "exit $cm_status, want 2"
    grep -q '^usage:' "$cm_dir/err" || fail "no usage: line"
    grep -q '^codeo: --rebuild applies only to a container' "$cm_dir/err" || fail "no reason: $cm_err"
    [[ ! -s "$cm_dir/calls" ]] || fail "made calls: $(cat "$cm_dir/calls")"
}

t_shell_home_sandbox_usage() { expect_usage shell home --sandbox; }

t_update_through_symlink() {
    update_setup "$current"
    ln -s "$cm_dir/inst/codeo" "$cm_dir/link"
    cm_script="$cm_dir/link"
    cm_run update
    [[ "$cm_status" -eq 0 ]] || fail "exit $cm_status: $cm_err"
    [[ -L "$cm_dir/link" ]] || fail "symlink replaced"
    grep -q 'new codeo$' "$cm_dir/inst/codeo" || fail "target not replaced"
    [[ "$(ls -A "$cm_dir/inst")" == codeo ]] || fail "inst holds more than codeo"
}

t_rm_pr_head_delivered() {
    cm_setup "$current"
    rm_stubs
    printf 'abc1234\n' >"$cm_dir/g_rev-list"
    touch "$cm_dir/rev_pr_covered"
    cm_run rm 5 --container
    [[ "$cm_status" -eq 0 ]] || fail "exit $cm_status, err: $cm_err"
    grep -q '^docker rm -f codeo-5' "$cm_dir/calls" || fail "not removed"
    grep -qF 'fetch origin +refs/pull/*/head:refs/remotes/origin/pr/*' "$cm_dir/calls" || fail "no pull-request head fetch"
}

t_rm_pr_head_detached_delivered() {
    cm_setup "$current"
    rm_stubs
    : >"$cm_dir/g_branch"
    printf '  origin/pr/7\n' >"$cm_dir/g_branch_r_pr"
    cm_run rm 5 --container
    [[ "$cm_status" -eq 0 ]] || fail "exit $cm_status, err: $cm_err"
    grep -q '^docker rm -f codeo-5' "$cm_dir/calls" || fail "not removed"
}

t_rm_pr_fetch_fails() {
    cm_setup "$current"
    rm_stubs
    echo exited >"$cm_dir/dstate"
    touch "$cm_dir/prfetch_fail"
    cm_run rm 5 --container
    expect_refused 'could not check'
    grep -q '^docker stop codeo-5' "$cm_dir/calls" || fail "started container not stopped"
    cm_setup "$current-2"
    rm_stubs
    touch "$cm_dir/prfetch_fail"
    cm_run rm 5 --container --force
    [[ "$cm_status" -eq 0 ]] || fail "--force: exit $cm_status, err: $cm_err"
    grep -q '^docker rm -f codeo-5' "$cm_dir/calls" || fail "--force: not removed"
}

t_rm_commits_under_no_ref_refuse() {
    cm_setup "$current"
    rm_stubs
    printf 'abc1234\n' >"$cm_dir/g_rev-list"
    cm_run rm 5 --container
    expect_refused abc1234
    grep -qF 'refs/pull/' "$cm_dir/calls" || fail "pull-request head fetch not made"
}

t_rm_volume_failure_says_container_removed() {
    cm_setup "$current"
    rm_stubs
    touch "$cm_dir/vol_fail"
    cm_run rm 5 --container
    [[ "$cm_status" -eq 1 ]] || fail "exit $cm_status"
    grep -qF 'removed container codeo-5 but could not remove volume codeo-5' <<<"$cm_err" || fail "stderr: $cm_err"
}

t_rm_container_not_found_force() {
    cm_setup "$current"
    rm_stubs
    touch "$cm_dir/gone" "$cm_dir/start_fail" "$cm_dir/rm_fail" "$cm_dir/vol_gone" "$cm_dir/rmi_fail"
    cm_run rm 5 --container --force
    [[ "$cm_status" -eq 1 ]] || fail "exit $cm_status"
    [[ "$cm_err" == "codeo: nothing named codeo-5 to remove" ]] || fail "stderr: $cm_err"
    ! grep -q 'removed container' <<<"$cm_out$cm_err" || fail "says removed container: $cm_out $cm_err"
}

t_rm_force_volume_only() {
    cm_setup "$current"
    rm_stubs
    touch "$cm_dir/gone" "$cm_dir/start_fail" "$cm_dir/rm_fail" "$cm_dir/rmi_fail"
    cm_run rm 5 --container --force
    [[ "$cm_status" -eq 0 ]] || fail "exit $cm_status, err: $cm_err"
    grep -q '^docker volume rm codeo-5' "$cm_dir/calls" || fail "volume kept"
    grep -qF 'removed volume codeo-5' <<<"$cm_out" || fail "stdout: $cm_out"
    ! grep -q 'removed container' <<<"$cm_out" || fail "says removed container: $cm_out"
}

t_rm_bind_mount_keeps_volume() {
    cm_setup "$current"
    rm_stubs
    printf 'bind \n' >"$cm_dir/mounts"
    cm_run rm 5 --container
    [[ "$cm_status" -eq 0 ]] || fail "exit $cm_status, err: $cm_err"
    grep -q '^docker rm -f codeo-5' "$cm_dir/calls" || fail "container kept"
    grep -q '^docker rmi' "$cm_dir/calls" || fail "image kept"
    ! grep -q '^docker volume rm' "$cm_dir/calls" || fail "volume removed"
    grep -qF 'docker volume rm codeo-5' <<<"$cm_out" || fail "stdout: $cm_out"
}

t_rm_bind_mount_force() {
    cm_setup "$current"
    rm_stubs
    printf 'bind \n' >"$cm_dir/mounts"
    cm_run rm 5 --container --force
    [[ "$cm_status" -eq 0 ]] || fail "exit $cm_status, err: $cm_err"
    grep -q '^docker volume rm codeo-5' "$cm_dir/calls" || fail "volume kept"
    grep -qF 'not checked' <<<"$cm_out" || fail "no not-checked note: $cm_out"
}

t_rm_inspect_fails() {
    cm_setup "$current"
    rm_stubs
    touch "$cm_dir/inspect_fail"
    cm_run rm 5 --container
    expect_refused 'could not check'
    cm_setup "$current-2"
    rm_stubs
    touch "$cm_dir/inspect_fail"
    cm_run rm 5 --container --force
    [[ "$cm_status" -eq 0 ]] || fail "--force: exit $cm_status, err: $cm_err"
    grep -q '^docker volume rm codeo-5' "$cm_dir/calls" || fail "--force: volume kept"
}

t_codeo_sbx_honoured() {
    cm_setup "$current"
    mkdir -p "$cm_dir/alt"
    rm -f "$cm_dir/bin/sbx"
    cat >"$cm_dir/alt/mysbx" <<'STUB'
#!/bin/bash
d=${0%/alt/*}
echo "mysbx $*" >>"$d/calls"
printf 'NAME AGENT STATUS\ncodeo-5 claude running\n'
STUB
    chmod +x "$cm_dir/alt/mysbx"
    CODEO_SBX="$cm_dir/alt/mysbx" cm_run shell 5
    [[ "$cm_status" -eq 0 ]] || fail "shell: exit $cm_status, err: $cm_err"
    expect_call "codeo-sandbox.sh shell 5 pwd=$cm_home"
    grep -qx 'mysbx ls' "$cm_dir/calls" || fail "CODEO_SBX not used by host_kinds"
    : >"$cm_dir/calls"
    CODEO_SBX="$cm_dir/alt/mysbx" cm_run list
    [[ "$cm_status" -eq 0 ]] || fail "list: exit $cm_status, err: $cm_err"
    grep -q '^#5  sandbox' <<<"$cm_out" || fail "list lacks the sandbox: $cm_out"
    grep -qx 'mysbx ls' "$cm_dir/calls" || fail "CODEO_SBX not used by list"
}

t_issue_lookup_invalid_branch() {
    cm_setup "$current"
    printf 'feat/a b\n' >"$cm_dir/branches"
    printf 'feat/a b\n' >"$cm_dir/has"
    cm_run issue 5
    [[ "$cm_status" -eq 1 && "$(wc -l <"$cm_dir/err")" -eq 1 && "$cm_err" == "codeo: "* ]] || fail "$cm_status $cm_err"
    grep -qF 'is not a name codeo accepts; pass a branch: codeo issue 5 <branch>' <<<"$cm_err" || fail "stderr: $cm_err"
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
    t_lookup_checks_file_without_blob
    t_concurrent_first_use
    t_lookup_repoints_clone_at_url
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
    t_run_path_has_no_host_programs
    t_no_docker_program
    t_sandbox_uses_home_clone
    t_list_rows
    t_list_empty
    t_list_no_programs
    t_list_docker_down
    t_list_sbx_down
    t_list_one_down_nothing_shown
    t_shell_listing_down_nothing_found
    t_rm_listing_down_nothing_found
    t_shell_docker_down_sandbox_found
    t_shell_docker_down_sandbox_flag
    t_home_rebuild_twice_usage
    t_lookup_quiet_git
    t_lookup_branch_list_failure
    t_help_names_kind_flags
    t_rm_refusal_stops_started_container
    t_rm_container_not_found
    t_rm_unlisted_state_not_stopped_by_us
    t_list_extra_args_usage
    t_host_kinds_exact_name
    t_rm_sandbox
    t_rm_sandbox_hints
    t_rm_sandbox_force
    t_rm_usage
    t_rm_container_clean
    t_rm_restarts_running_container_and_reads_again
    t_rm_write_after_check_refused
    t_rm_restart_fails
    t_rm_started_container_not_restarted
    t_rm_container_untracked
    t_rm_check_prunes_and_sees_untracked
    t_rm_container_unpushed
    t_rm_container_stash
    t_rm_container_detached
    t_rm_container_detached_pushed
    t_rm_container_cuts_at_ten
    t_rm_exec_failure_is_not_clean
    t_rm_container_force
    t_rm_container_cannot_check
    t_rm_image_failure_warns
    t_rm_removal_failure_dies
    t_rm_stopped_container_started_first
    t_rm_container_detected
    t_update_replaces_three
    t_update_failed_download_changes_nothing
    t_update_empty_file_refused
    t_update_not_a_script_refused
    t_update_without_scripts
    t_update_usage_extra_args
    t_update_partial_second_mv
    t_update_partial_final_mv
    t_update_through_symlink
    t_relative_codeo_home
    t_home_unset
    t_home_dir_uncreatable
    t_rebuild_saved_sandbox_usage
    t_shell_home_sandbox_usage
    t_rm_force_container_gone
    t_rm_force_failing_rm_still_listed_dies
    t_rm_pr_head_delivered
    t_rm_pr_head_detached_delivered
    t_rm_pr_fetch_fails
    t_rm_commits_under_no_ref_refuse
    t_rm_volume_failure_says_container_removed
    t_rm_container_not_found_force
    t_rm_force_volume_only
    t_rm_bind_mount_keeps_volume
    t_rm_bind_mount_force
    t_rm_inspect_fails
    t_codeo_sbx_honoured
    t_issue_lookup_invalid_branch
)

for current in "${cases[@]}"; do
    "$current"
done

if ((failures > 0)); then
    exit 1
fi
echo "all cases passed"
