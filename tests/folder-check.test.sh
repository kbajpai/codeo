#!/usr/bin/env bash
# Guards .devcontainer/scripts/folder-check.sh, which says whether a container's clone folder agrees
# with its workflow lock. Each case runs the real script (and the real container-name.sh) copied into
# a scratch git repo whose .codeo/config.json names the codename "codeo": the home folder on main, a
# wrong folder on main, a locked clone in the right and the wrong folder, an issue branch with no lock
# (an issue folder is left alone, any other folder is reported), and the failure outside a clone.
#
#   bash tests/folder-check.test.sh
#
# Exits 0 and prints "all cases passed" when every case holds; prints one "FAIL <case>: <detail>"
# line per problem and exits 1 otherwise.
set -euo pipefail

repo_root() { cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd; }
repo=$(repo_root)

failures=0
current=""
root=""
fc_dir=""
fc_rc=0
fc_out=""
fc_err=""

# fail <message>: record one failure against the running case.
fail() {
    printf 'FAIL %s: %s\n' "$current" "$1"
    failures=$((failures + 1))
}

# fc_setup <name> <branch>: a scratch git repo on <branch> holding the real scripts. Sets fc_dir.
fc_setup() {
    local name=$1 branch=$2 script
    [[ -n $root ]] || root=$(mktemp -d)
    fc_dir="$root/$name"
    mkdir -p "$fc_dir/.devcontainer/scripts" "$fc_dir/.codeo"
    git -C "$fc_dir" init -q || { fail 'git init failed'; return 1; }
    git -C "$fc_dir" symbolic-ref HEAD "refs/heads/$branch"
    for script in container-name.sh folder-check.sh; do
        cp "$repo/.devcontainer/scripts/$script" "$fc_dir/.devcontainer/scripts/$script" \
            || { fail "$script is missing"; return 1; }
    done
    printf '%s\n' '{"codename":"codeo"}' > "$fc_dir/.codeo/config.json"
}

# fc_run <folder> [dir]: runs the scratch copy of the script. Sets fc_rc, fc_out, fc_err.
fc_run() {
    local errf folder=$1 dir=${2:-$fc_dir}
    errf=$(mktemp -p "$root")
    fc_rc=0
    fc_out=$(bash "$fc_dir/.devcontainer/scripts/folder-check.sh" "$folder" "$dir" 2>"$errf") || fc_rc=$?
    fc_err=$(cat "$errf")
}

# silent <folder>: the folder passes without a word.
silent() {
    fc_run "$1"
    ((fc_rc == 0)) || fail "exit $fc_rc: $fc_err"
    [[ -z $fc_out ]] || fail "folder '$1': wanted no output, got '$fc_out'"
}

# todo <folder> <fragment>: one "todo:" line naming the fragment and the README.
todo() {
    fc_run "$1"
    ((fc_rc == 0)) || fail "exit $fc_rc: $fc_err"
    [[ $fc_out == todo:* && $fc_out != *$'\n'* ]] || fail "folder '$1': wanted one 'todo:' line, got '$fc_out'"
    [[ $fc_out == *"$2"* ]] || fail "folder '$1': wanted the line to contain $2, got '$fc_out'"
    [[ $fc_out == *'(.devcontainer/README.md)' ]] || fail "folder '$1': wanted the line to end with the README, got '$fc_out'"
}

home_folder_on_main_is_silent() {
    fc_setup home main || return 0
    silent codeo-home
}

wrong_folder_on_main() {
    fc_setup wrong main || return 0
    todo scratch "'codeo-home'"
}

locked_right_folder_is_silent() {
    fc_setup locked main || return 0
    printf 'issue: 55\n' > "$fc_dir/.codeo/active"
    silent codeo-55
}

locked_wrong_folder_names_the_right_one() {
    fc_setup lockedwrong main || return 0
    printf 'issue: 55\n' > "$fc_dir/.codeo/active"
    todo codeo-home "'codeo-55'"
}

issue_branch_without_lock_leaves_an_issue_folder_alone() {
    fc_setup nolock feat/x || return 0
    silent codeo-12
    todo scratch "'codeo-<N>'"
}

not_a_clone_fails() {
    fc_setup outside main || return 0
    local plain
    plain=$(mktemp -d -p "$root")
    fc_run codeo-home "$plain"
    ((fc_rc == 1)) || fail "wanted exit 1, got $fc_rc"
    [[ -z $fc_out ]] || fail "wanted no stdout, got '$fc_out'"
    [[ $fc_err == folder-check:* && $fc_err != *$'\n'* ]] || fail "wanted one 'folder-check: ...' line, got '$fc_err'"
}

cases=(
    home_folder_on_main_is_silent
    wrong_folder_on_main
    locked_right_folder_is_silent
    locked_wrong_folder_names_the_right_one
    issue_branch_without_lock_leaves_an_issue_folder_alone
    not_a_clone_fails
)

for current in "${cases[@]}"; do
    "$current"
done

[[ -z $root ]] || rm -rf "$root"

if ((failures > 0)); then
    exit 1
fi
echo "all cases passed"
