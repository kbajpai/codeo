#!/usr/bin/env bash
# Two branches that reword different rules of docs/skills-inventory.md each re-pin with
# `bash tests/inventory.test.sh --update`; the merge must be clean and the merged tree must pass.
# Rewording the same rule on both branches must still conflict, on the inventory itself. Runs in a
# scratch git repository holding copies of the inventory, the check and its fixture; the real
# docs/skills-inventory.md is never touched and no case touches the network or a real git config.
#
#   inventory-pin.test.sh
#       Exits non-zero and names the failing cases; prints "all cases passed" otherwise.
set -euo pipefail

src=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

export GIT_AUTHOR_NAME="Inventory Pin Test" GIT_AUTHOR_EMAIL="inventory-pin-test@example.com"
export GIT_COMMITTER_NAME="Inventory Pin Test" GIT_COMMITTER_EMAIL="inventory-pin-test@example.com"

scratch_root=$(mktemp -d)
trap 'rm -rf "$scratch_root"' EXIT
export HOME="$scratch_root/home"
mkdir -p "$HOME"

failures=0
case_desc=
fail() { echo "FAIL: $case_desc — $1"; failures=$((failures + 1)); }

# new_repo <name> — a scratch repository on branch main holding the three files, committed.
new_repo() {
    local r="$scratch_root/$1"
    mkdir -p "$r/docs" "$r/tests/fixtures"
    cp "$src/docs/skills-inventory.md" "$r/docs/"
    cp "$src/tests/inventory.test.sh" "$r/tests/"
    cp "$src/tests/fixtures/skills-inventory.rules.sha256" "$r/tests/fixtures/"
    git -C "$r" init -q -b main
    git -C "$r" add -A
    git -C "$r" commit -q -m base
    echo "$r"
}

# reword_and_pin <repo> <branch> <rule-id> <word> — on a new branch, append <word> to the rule's
# bullet line, re-pin, commit, and go back to main.
reword_and_pin() {
    git -C "$1" checkout -q -b "$2" main
    sed -i "s/^\(- \[$3\] .*\)\$/\1 $4/" "$1/docs/skills-inventory.md"
    (cd "$1" && bash tests/inventory.test.sh --update >/dev/null)
    git -C "$1" commit -q -am "reword $3"
    git -C "$1" checkout -q main
}

different_rules_merge_cleanly() {
    case_desc=different_rules_merge_cleanly
    local r out
    r=$(new_repo different)
    reword_and_pin "$r" a plan-01 alpha
    reword_and_pin "$r" b qc-01 bravo
    git -C "$r" checkout -q a
    if ! git -C "$r" merge --no-edit b >/dev/null 2>&1; then
        fail "merge of b into a conflicted: $(git -C "$r" diff --name-only --diff-filter=U | tr '\n' ' ')"
        return
    fi
    out=$(cd "$r" && bash tests/inventory.test.sh 2>&1) || true
    [[ "$out" == *"all cases passed"* ]] || fail "merged tree does not pass: $out"
    (cd "$r" && bash tests/inventory.test.sh --update >/dev/null)
    git -C "$r" diff --quiet || fail "--update changed the merged tree"
}

the_same_rule_still_conflicts() {
    case_desc=the_same_rule_still_conflicts
    local r conflicted
    r=$(new_repo same)
    reword_and_pin "$r" a plan-01 alpha
    reword_and_pin "$r" b plan-01 bravo
    git -C "$r" checkout -q a
    if git -C "$r" merge --no-edit b >/dev/null 2>&1; then
        fail "merge of b into a succeeded though both reworded plan-01"
        return
    fi
    conflicted=$(git -C "$r" diff --name-only --diff-filter=U)
    [[ "$conflicted" == *docs/skills-inventory.md* ]] || fail "docs/skills-inventory.md is not among the conflicts: [$conflicted]"
}

different_rules_merge_cleanly
the_same_rule_still_conflicts

if ((failures > 0)); then
    exit 1
fi
echo "all cases passed"
