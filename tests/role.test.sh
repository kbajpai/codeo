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
state=""         # the state a stale refusal must report: finished, stashed, abandoned, lost, unknown, offbase
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

# stale_needles <skill> <line>: the per-state wording of a stale refusal, by $state (finished, stashed,
# abandoned, lost, unknown).
stale_needles() {
    local skill=$1 line=$2 want=() bad=()
    case $state in
        finished) want=("is finished") ;;
        stashed|abandoned) want=("was $state" "holds no lock") ;;
        lost) want=("holds no lock") ;;
        unknown) want=("no dossier says why") ;;
        offbase) want=() ;;
    esac
    if is_home_skill "$skill"; then
        case $state in
            offbase) want+=("not on the base branch main" "switch back to main"); bad=("run it in the home container" "no dossier says why") ;;
            *) want+=("run it in the home container"); bad=(devcontainer-start.sh "/codeo:init #") ;;
        esac
    else
        case $state in
            finished) want+=("/codeo:cleanup"); bad=(devcontainer-start.sh re-run) ;;
            stashed) want+=("/codeo:init #67" "never the start script" "remove this one" ".devcontainer/README.md"); bad=(re-run finished) ;;
            abandoned) want+=("nothing more runs here" "the only copy"); bad=("/codeo:init #" devcontainer-start.sh re-run "the way back") ;;
            lost) want+=("workflow is live" "re-run bash .devcontainer/scripts/devcontainer-start.sh"); bad=(finished stashed abandoned /codeo:cleanup) ;;
            unknown) want+=("container of the issue it is for"); bad=(devcontainer-start.sh finished) ;;
            offbase) want+=("off the base branch main" "container of the issue it is for"); bad=("no dossier says why") ;;
        esac
    fi
    local n
    for n in "${want[@]}"; do [[ $line == *"$n"* ]] || fail "$role: $skill ($state) refusal lacks '$n': '$line'"; done
    for n in "${bad[@]}"; do [[ $line != *"$n"* ]] || fail "$role: $skill ($state) refusal must not say '$n': '$line'"; done
}

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
            [[ -z $number || $state == unknown || $state == offbase || $out == *"#$number"* ]] || fail "$role: $skill refusal does not name #$number: '$out'"
            case $role in
                stale:*)
                    stale_needles "$skill" "$out" ;;
            esac
            if is_home_skill "$skill"; then
                [[ $out == *"home container"* ]] || fail "$role: $skill refusal does not say it runs in the home container: '$out'"
            elif [[ $role != stale:* ]]; then
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
    state=unknown
    role_is stale:67
    check_matrix stale:67 67
}

stale_on_a_feature_branch() {
    mk stalefeat codeo-67 feat/x || return 0
    role_is stale:67
}

home_off_the_base_branch() {
    state=offbase
    mk staleq codeo-home feat/x || return 0
    role_is 'stale:?'
    check_matrix 'stale:?' ""
}

home_on_a_detached_head() {
    state=offbase
    mk detached codeo-home main || return 0
    git -C "$dir" -c user.name=t -c user.email=t@t commit -q --allow-empty -m base
    git -C "$dir" checkout -q --detach
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

# stale_with <name> <state> <file> <content> [<file2> <content2>]: a codeo-67 clone with no lock and
# <content> in .codeo/<file> (and <content2> in .codeo/<file2> when given).
stale_with() {
    mk "$1" codeo-67 main || return 1
    state=$2
    mkdir -p "$dir/.codeo/$(dirname "$3")"
    printf '%b' "$4" >"$dir/.codeo/$3"
    if [[ $# -ge 6 ]]; then
        mkdir -p "$dir/.codeo/$(dirname "$5")"
        printf '%b' "$6" >"$dir/.codeo/$5"
    fi
}

# commit_archive <branch>: commits .codeo/done/67 on <branch> (the clone's HEAD is put back afterwards).
commit_archive() {
    local back
    back=$(git -C "$dir" symbolic-ref HEAD)
    git -C "$dir" symbolic-ref HEAD "refs/heads/$1"
    git -C "$dir" add -f .codeo/done/67
    git -C "$dir" -c user.name=t -c user.email=t@t commit -q -m archive
    git -C "$dir" symbolic-ref HEAD "$back"
}

stale_finished() {
    stale_with fin finished done/67/close.md '### Round 1 — pull request opened\n' || return 0
    commit_archive main
    role_is stale:67
    check_matrix stale:67 67
}

stale_finished_by_the_remote_base() {
    stale_with finremote finished done/67/close.md '### Round 1 — pull request opened\n' || return 0
    commit_archive other
    git -C "$dir" update-ref refs/remotes/origin/main refs/heads/other
    role_is stale:67
    check_matrix stale:67 67
}

stale_archived_with_an_open_pull_request_is_lock_lost() {
    stale_with openpr lost done/67/close.md '### Round 1 — pull request opened\n' || return 0
    check_matrix stale:67 67
}

stale_stashed() {
    stale_with stashed stashed 67/close.md '### Round 1 — pull request opened\n\n### Round 2 — stashed\n' || return 0
    check_matrix stale:67 67
}

stale_abandoned() {
    stale_with abandoned abandoned 67/close.md '### Round 1 — abandoned — the pull request was closed\n' || return 0
    check_matrix stale:67 67
}

stale_lock_lost_without_a_close() {
    stale_with lost lost 67/init.md 'issue: 67\n' || return 0
    check_matrix stale:67 67
}

stale_resumed_stash_is_lock_lost() {
    stale_with resumed lost 67/close.md '### Round 1 — stashed\n' \
        67/init.md '- 2026-11-01 — resumed: by someone after the stash of 2026-10-30\n' || return 0
    check_matrix stale:67 67
}

stale_stashed_twice_resumed_once_is_stashed() {
    stale_with twice stashed 67/close.md '### Round 1 — stashed\n\n### Round 2 — stashed\n' \
        67/init.md '- 2026-11-01 — resumed: by someone after the stash of 2026-10-30\n' || return 0
    check_matrix stale:67 67
}

stale_abandoned_after_a_resumed_stash() {
    stale_with abandonresumed abandoned 67/close.md '### Round 1 — stashed\n\n### Round 2 — abandoned — closed\n' \
        67/init.md '- 2026-11-01 — resumed: by someone after the stash of 2026-10-30\n' || return 0
    check_matrix stale:67 67
}

stale_parked_with_a_later_round_is_still_parked() {
    stale_with laterround stashed 67/close.md '### Round 1 — stashed\n\n### Round 2 — pull request opened\n' || return 0
    check_matrix stale:67 67
}

stale_dossier_is_read_under_the_root() {
    stale_with subdir stashed 67/close.md '### Round 1 — stashed\n' || return 0
    mkdir -p "$dir/sub/deep"
    run --check plan "$dir/sub/deep"
    [[ $out == *"was stashed"* ]] || fail "from a subdirectory: wanted the stashed line, got '$out'"
}

cases=(
    home_on_main
    issue_container
    stale_on_main
    stale_on_a_feature_branch
    stale_finished
    stale_finished_by_the_remote_base
    stale_archived_with_an_open_pull_request_is_lock_lost
    stale_stashed
    stale_abandoned
    stale_lock_lost_without_a_close
    stale_resumed_stash_is_lock_lost
    stale_stashed_twice_resumed_once_is_stashed
    stale_abandoned_after_a_resumed_stash
    stale_parked_with_a_later_round_is_still_parked
    stale_dossier_is_read_under_the_root
    home_off_the_base_branch
    home_on_a_detached_head
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
