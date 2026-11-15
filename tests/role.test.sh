#!/usr/bin/env bash
# Guards .devcontainer/scripts/role.sh, which says what role this dev container plays (unguarded, home,
# issue:<N>, stale:<N>, stale:?, mismatch:<N>:<folder>) and whether a codeo skill may run in it. Each
# case runs the real script (and the real container-name.sh) copied into a scratch git clone whose
# folder is named per case and whose .codeo/config.json names the codename "codeo" and baseBranch
# "main"; CODEO_DOCKERENV points at a stub file (or a missing one) and CLAUDE_CODE_REMOTE is set or
# unset explicitly, so no case depends on the machine it runs on. The role of every shape is asserted,
# then the --check matrix: all eight skills against every role, the exit codes and the one-line refusal.
#
#   bash tests/role.test.sh
#
# Exits 0 and prints "all cases passed" when every case holds; prints one "FAIL <case>: <detail>"
# line per problem and exits 1 otherwise.
set -euo pipefail

repo_root() { cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd; }
repo=$(repo_root)

failures=0
current=""
root=""
dir=""
rc=0
out=""
err=""
remote=""        # the value of CLAUDE_CODE_REMOTE, or empty for unset
dockerenv=""     # the file CODEO_DOCKERENV names

home_skills=(issue init triage cleanup)
lock_skills=(plan implement qc close)

fail() {
    printf 'FAIL %s: %s\n' "$current" "$1"
    failures=$((failures + 1))
}

# mk <name> <folder> <branch> [lock-content]: a scratch clone in <name>/<folder> on <branch>, holding
# the real scripts, with the dockerenv stub present, and .codeo/active holding <lock-content> when given.
mk() {
    local name=$1 folder=$2 branch=$3 script
    [[ -n $root ]] || root=$(mktemp -d)
    dir="$root/$name/$folder"
    mkdir -p "$dir/.devcontainer/scripts" "$dir/.codeo"
    git -C "$dir" init -q || { fail 'git init failed'; return 1; }
    git -C "$dir" symbolic-ref HEAD "refs/heads/$branch"
    for script in container-name.sh role.sh; do
        cp "$repo/.devcontainer/scripts/$script" "$dir/.devcontainer/scripts/$script" \
            || { fail "$script is missing"; return 1; }
    done
    printf '%s\n' '{"codename":"codeo","baseBranch":"main"}' >"$dir/.codeo/config.json"
    if [[ $# -ge 4 ]]; then printf '%s\n' "$4" >"$dir/.codeo/active"; fi
    dockerenv="$root/dockerenv"
    : >"$dockerenv"
    remote=""
}

# run <args...>: runs the scratch copy of role.sh. Sets rc, out, err.
run() {
    local errf
    errf=$(mktemp -p "$root")
    rc=0
    out=$(env -u CLAUDE_CODE_REMOTE ${remote:+CLAUDE_CODE_REMOTE=$remote} CODEO_DOCKERENV="$dockerenv" \
        bash "$dir/.devcontainer/scripts/role.sh" "$@" 2>"$errf") || rc=$?
    err=$(cat "$errf")
}

# role_is <expected>: the plain call prints exactly that line and exits 0.
role_is() {
    run "$dir"
    ((rc == 0)) || fail "exit $rc: $err"
    [[ $out == "$1" ]] || fail "wanted role '$1', got '$out'"
}

# is_home_skill <skill>
is_home_skill() { local s; for s in "${home_skills[@]}"; do [[ $s == "$1" ]] && return 0; done; return 1; }

# check_matrix <role> <number>: every one of the eight skills against the clone in $dir,
# whose role is <role>. <number> is the issue number a refusal must name ("" when there is none).
check_matrix() {
    local role=$1 number=$2 skill allowed
    for skill in "${home_skills[@]}" "${lock_skills[@]}"; do
        allowed=0
        case $role in
            unguarded) allowed=1 ;;
            home) allowed=1 ;;
            issue:*) is_home_skill "$skill" || allowed=1 ;;
        esac
        run --check "$skill" "$dir"
        if ((allowed)); then
            ((rc == 0)) || fail "$role: $skill wanted exit 0, got $rc ($out / $err)"
            [[ -z $out && -z $err ]] || fail "$role: $skill wanted no output, got '$out' / '$err'"
        else
            ((rc == 1)) || fail "$role: $skill wanted exit 1, got $rc ($err)"
            [[ -n $out && $out != *$'\n'* ]] || fail "$role: $skill wanted one refusal line, got '$out'"
            [[ $out == *"$role"* ]] || fail "$role: $skill refusal does not name the role: '$out'"
            [[ -z $number || $out == *"#$number"* ]] || fail "$role: $skill refusal does not name #$number: '$out'"
            case $role in
                stale:*) [[ $out == *finished* ]] || fail "$role: $skill refusal does not say the container is finished: '$out'" ;;
            esac
            if is_home_skill "$skill"; then
                [[ $out == *"home container"* ]] || fail "$role: $skill refusal does not say it runs in the home container: '$out'"
            else
                [[ $out == *"'s container"* ]] || fail "$role: $skill refusal does not say it runs in the issue's container: '$out'"
            fi
        fi
    done
    for skill in doctor setup nonsense; do
        run --check "$skill" "$dir"
        ((rc == 2)) || fail "$role: $skill wanted exit 2, got $rc"
        [[ -z $out && $err == role:* && $err != *$'\n'* ]] || fail "$role: $skill wanted one 'role:' line on stderr, got '$out' / '$err'"
    done
}

home_on_main() {
    mk home codeo-home main || return 0
    role_is home
    check_matrix home ""
}

issue_container() {
    mk issue codeo-70 feat/x 'issue:   70' || return 0
    role_is issue:70
    check_matrix issue:70 70
}

stale_on_main() {
    mk stalemain codeo-67 main || return 0
    role_is stale:67
    check_matrix stale:67 67
}

stale_on_a_feature_branch() {
    mk stalefeat codeo-67 feat/x || return 0
    role_is stale:67
}

stale_unknown_issue() {
    mk staleq codeo-home feat/x || return 0
    role_is 'stale:?'
    check_matrix 'stale:?' ""
}

mismatch_in_the_home_folder() {
    mk mismatchhome codeo-home feat/x 'issue: 70' || return 0
    role_is mismatch:70:codeo-home
    check_matrix mismatch:70:codeo-home 70
}

mismatch_in_another_issue_folder() {
    mk mismatch71 codeo-71 feat/x 'issue: 70' || return 0
    role_is mismatch:70:codeo-71
}

lock_without_an_issue_line_is_no_lock() {
    mk nolockline codeo-67 main 'some notes, no issue line' || return 0
    role_is stale:67
}

no_dockerenv_is_unguarded() {
    mk nodockerenv codeo-70 feat/x 'issue: 70' || return 0
    dockerenv="$root/missing"
    role_is unguarded
    check_matrix unguarded ""
}

remote_is_unguarded() {
    mk remote codeo-70 feat/x 'issue: 70' || return 0
    remote=true
    role_is unguarded
}

other_folders_are_unguarded() {
    mk plain codeo main || return 0
    role_is unguarded
    mk othernum other-70 feat/x 'issue: 70' || return 0
    role_is unguarded
}

not_a_clone_fails() {
    mk outside codeo-home main || return 0
    local plain
    plain=$(mktemp -d -p "$root")
    run "$plain"
    ((rc == 2)) || fail "wanted exit 2, got $rc"
    [[ -z $out && $err == role:* && $err != *$'\n'* ]] || fail "wanted one 'role:' line on stderr, got '$out' / '$err'"
    run --check plan "$plain"
    ((rc == 2)) || fail "--check: wanted exit 2, got $rc"
    [[ -z $out && $err == role:* && $err != *$'\n'* ]] || fail "--check: wanted one 'role:' line on stderr, got '$out' / '$err'"
}

cases=(
    home_on_main
    issue_container
    stale_on_main
    stale_on_a_feature_branch
    stale_unknown_issue
    mismatch_in_the_home_folder
    mismatch_in_another_issue_folder
    lock_without_an_issue_line_is_no_lock
    no_dockerenv_is_unguarded
    remote_is_unguarded
    other_folders_are_unguarded
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
