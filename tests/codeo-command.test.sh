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
exit 0
STUB
        chmod +x "$cm_dir/bin/$n"
    done
    for n in codeo-container.sh codeo-sandbox.sh; do
        cat >"$cm_home/$n" <<'STUB'
#!/bin/bash
d=${0%/home/*}
echo "${0##*/} $* pwd=$(pwd)" >>"$d/calls"
exit 0
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
    for a in "issue abc" "issue 0" "issue 07" "shell x" "rm 1x"; do
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

cases=(
    t_no_args_usage
    t_unknown_command_usage
    t_bad_number_usage
    t_bad_branch_usage
    t_missing_arg_usage
    t_help_lists_commands
    t_executable_bash
    t_suite_covers
)

for current in "${cases[@]}"; do
    "$current"
done

if ((failures > 0)); then
    exit 1
fi
echo "all cases passed"
