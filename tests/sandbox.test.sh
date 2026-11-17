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
    local n
    for n in sbx sbx.exe git git.exe code; do
        cat >"$sb_dir/bin/$n" <<'STUB'
#!/bin/bash
d=${0%/bin/*}
echo "${0##*/} $*" >>"$d/calls"
case "${0##*/} $1" in
    "sbx ls" | "sbx.exe ls") cat "$d/sandboxes" ;;
esac
exit 0
STUB
        chmod +x "$sb_dir/bin/$n"
    done
}

# sb_run <args...>: run the script with the stubs on PATH; sets sb_rc, sb_out, sb_err.
sb_run() {
    sb_rc=0
    env -u CODEO_SBX PATH="$sb_dir/bin:/usr/bin:/bin" ${SB_SBX:+CODEO_SBX="$SB_SBX"} \
        "$bash_abs" "$script" "$@" >"$sb_dir/out" 2>"$sb_dir/err" || sb_rc=$?
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

cases=(
    usage_without_arguments_exits_2
    bad_numbers_and_branches_exit_2_before_any_call
    no_sbx_is_one_line
    sbx_is_preferred_over_sbx_exe
    codeo_sbx_overrides_both
    sandbox_state_reads_the_ls_rows
    the_script_is_committed_executable_with_a_bash_shebang
    config_suite_covers_the_sandbox_folder
)

for current in "${cases[@]}"; do
    "$current"
done

if ((failures > 0)); then
    exit 1
fi
echo "all cases passed"
