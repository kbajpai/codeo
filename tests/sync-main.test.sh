#!/usr/bin/env bash
# Exercises sync-main.sh against real scratch git repos: "origin" is a scratch repo reached by a
# local path, HOME is a scratch directory, and nothing touches the network or real git config.
#
#   sync-main.test.sh
#       Exits non-zero and names the failing cases; prints "all cases passed" otherwise.
set -euo pipefail

plugin_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

export GIT_AUTHOR_NAME="Sync Test" GIT_AUTHOR_EMAIL="sync-test@example.com"
export GIT_COMMITTER_NAME="Sync Test" GIT_COMMITTER_EMAIL="sync-test@example.com"

scratch_root=$(mktemp -d)
cleanup() { rm -rf "$scratch_root"; }
trap cleanup EXIT
export HOME="$scratch_root/home"
mkdir -p "$HOME"

failures=0
case_desc=
assert_eq() {
    local label=$1 want=$2 got=$3
    if [[ $want != "$got" ]]; then
        echo "FAIL: $case_desc — $label: want [$want] got [$got]"
        failures=$((failures + 1))
    fi
}
assert_contains() {
    local label=$1 needle=$2 haystack=$3
    if [[ $haystack != *"$needle"* ]]; then
        echo "FAIL: $case_desc — $label: want substring [$needle] in [$haystack]"
        failures=$((failures + 1))
    fi
}
assert_absent() {
    local label=$1 needle=$2 haystack=$3
    if [[ $haystack == *"$needle"* ]]; then
        echo "FAIL: $case_desc — $label: unwanted substring [$needle] in [$haystack]"
        failures=$((failures + 1))
    fi
}

# An origin on main holding a.txt, b.txt, c.txt (each with three lines), and a clone on feat/x.
setup() {
    origin=$(mktemp -d "$scratch_root/origin.XXXXXX")
    git -C "$origin" -c init.defaultBranch=main init -q
    # No background maintenance after a push or a commit: it would race a later clone — see
    # claim.test.sh's fresh_origin.
    git -C "$origin" config gc.auto 0
    git -C "$origin" config maintenance.auto false
    git -C "$origin" config receive.autogc false
    local f
    for f in a b c; do printf 'one\ntwo\nthree\n' > "$origin/$f.txt"; done
    git -C "$origin" add .
    git -C "$origin" commit -q -m init
    clone=$(mktemp -d "$scratch_root/clone.XXXXXX")
    git clone -q "$origin" "$clone"
    # An untracked config; the script must not mind it (only tracked changes block a round).
    mkdir -p "$clone/.codeo"
    printf '{"schema":1,"repo":{"owner":"o","name":"n"},"baseBranch":"%s"}\n' "${base:-main}" > "$clone/.codeo/config.json"
    git -C "$clone" checkout -q -b feat/x
}
# commit_in <repo> <file> <line1-text> <message>: rewrites line 1 of <file> and commits it.
commit_in() {
    sed -i "1s/.*/$3/" "$1/$2"
    git -C "$1" add "$2"
    git -C "$1" commit -q -m "$4"
}
run_sync() {
    status=0
    out=$(cd "$clone" && bash "$plugin_root/scripts/sync-main.sh" "$@" 2>"$scratch_root/stderr") || status=$?
    err=$(cat "$scratch_root/stderr")
}

setup
case_desc="already contains origin/main"
run_sync
assert_eq "exit" 0 "$status"
assert_eq "stdout" "sync-main: the branch already contains origin/main" "$out"
assert_eq "stderr" "" "$err"

setup
case_desc="clean merge reports both-changed files"
commit_in "$origin" a.txt main-a "main a"
commit_in "$origin" b.txt main-b "main b"
commit_in "$clone" c.txt feat-c "feat c"
sed -i '3s/.*/feat-b/' "$clone/b.txt"
git -C "$clone" add b.txt
git -C "$clone" commit -q -m "feat b"
run_sync
assert_eq "exit" 0 "$status"
assert_contains "merged line" "sync-main: merged origin/main (2 commit(s))" "$out"
assert_contains "b.txt reported" "sync-main: also changed on main: b.txt" "$out"
assert_absent "a.txt not reported" "changed on main: a.txt" "$out"
assert_absent "c.txt not reported" "changed on main: c.txt" "$out"
assert_eq "merge commit has two parents" 3 "$(git -C "$clone" rev-list --parents -n1 HEAD | wc -w | tr -d ' ')"

setup
case_desc="conflict without --abort-on-conflict leaves the merge in progress"
commit_in "$origin" b.txt main-b "main b"
commit_in "$clone" b.txt feat-b "feat b"
run_sync
assert_eq "exit" 2 "$status"
assert_contains "names the file" "sync-main: conflict: b.txt" "$err"
assert_contains "resolution hint" "resolve each file against both changes' intent, then git commit" "$err"
[[ -f $clone/.git/MERGE_HEAD ]] && merge_head=yes || merge_head=no
assert_eq "MERGE_HEAD" yes "$merge_head"

setup
case_desc="conflict with --abort-on-conflict restores the tree"
commit_in "$origin" b.txt main-b "main b"
commit_in "$clone" b.txt feat-b "feat b"
before=$(git -C "$clone" rev-parse HEAD)
run_sync --abort-on-conflict
assert_eq "exit" 2 "$status"
assert_contains "names the file" "sync-main: conflict: b.txt" "$err"
assert_absent "no resolution hint" "then git commit" "$err"
[[ -f $clone/.git/MERGE_HEAD ]] && merge_head=yes || merge_head=no
assert_eq "MERGE_HEAD" no "$merge_head"
assert_eq "HEAD unchanged" "$before" "$(git -C "$clone" rev-parse HEAD)"
assert_eq "tree clean" "" "$(git -C "$clone" status --porcelain --untracked-files=no)"

setup
case_desc="dirty tree refused"
commit_in "$origin" a.txt main-a "main a"
before=$(git -C "$clone" rev-parse HEAD)
echo dirt >> "$clone/c.txt"
run_sync
assert_eq "exit" 1 "$status"
assert_contains "message" "sync-main: the tree is not clean — commit or stash first" "$err"
assert_eq "HEAD unchanged" "$before" "$(git -C "$clone" rev-parse HEAD)"

base=develop
setup
case_desc="sync_main_follows_a_develop_base_branch"
# setup cut origin's only branch as main; the project's base is develop, so develop is the one
# whose commits must arrive, and a commit on main must not.
git -C "$origin" checkout -q -b develop
commit_in "$origin" a.txt develop-a "develop a"
git -C "$origin" checkout -q main
commit_in "$origin" b.txt main-b "main b"
git -C "$clone" checkout -q -B feat/x main
run_sync
assert_eq "exit" 0 "$status"
assert_contains "merged line" "sync-main: merged origin/develop (1 commit(s))" "$out"
assert_eq "develop's file arrived" "develop-a" "$(head -n1 "$clone/a.txt")"
assert_eq "main's change did not" "one" "$(head -n1 "$clone/b.txt")"
run_sync
assert_eq "second run: exit" 0 "$status"
assert_eq "second run: stdout" "sync-main: the branch already contains origin/develop" "$out"
base=main

if ((failures)); then
    echo "$failures case(s) failed"
    exit 1
fi
echo "all cases passed"
