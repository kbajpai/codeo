#!/usr/bin/env bash
# Exercises `intake.sh commit` and `intake.sh restore` against real scratch git repos: a dossier
# directory goes onto codeo/intake and is pushed, without touching HEAD, the index or the working
# tree; --drop removes the old directory in the same commit; a push that loses a race is rebuilt on
# origin's new tip; the triage ledger's rows are unioned rather than overwritten; a refused push
# keeps its local commit; and restore writes only what this clone lacks. No network, no real git
# config: "origin" is a scratch repo reached by a local path.
#
#   intake.test.sh
#       Exits non-zero and names the failing cases; prints "all cases passed" otherwise.
set -euo pipefail

plugin_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
intake="$plugin_root/scripts/intake.sh"

export GIT_AUTHOR_NAME="Intake Test" GIT_AUTHOR_EMAIL="intake-test@example.com"
export GIT_COMMITTER_NAME="Intake Test" GIT_COMMITTER_EMAIL="intake-test@example.com"

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
assert_matches() {
    local label=$1 pattern=$2 got=$3
    if [[ ! $got =~ $pattern ]]; then
        echo "FAIL: $case_desc — $label: want match for [$pattern] got [$got]"
        failures=$((failures + 1))
    fi
}

# An origin with one commit on main and no intake branch. No config: commit and restore need none.
fresh_origin() {
    local dir
    dir=$(mktemp -d "$scratch_root/origin.XXXXXX")
    git -C "$dir" -c init.defaultBranch=main init -q
    # No background maintenance after a push or a commit: it would race a later clone.
    git -C "$dir" config gc.auto 0
    git -C "$dir" config maintenance.auto false
    git -C "$dir" config receive.autogc false
    echo placeholder > "$dir/README.md"
    mkdir -p "$dir/.codeo"
    printf 'active\nintake/\n' > "$dir/.codeo/.gitignore"
    git -C "$dir" add README.md .codeo
    git -C "$dir" commit -q -m init
    printf '%s' "$dir"
}

clone_of() {
    local dir
    dir=$(mktemp -d "$scratch_root/clone.XXXXXX")
    git clone -q "$1" "$dir"
    printf '%s' "$dir"
}

# Runs intake.sh in <clone>; sets out, err and status.
run() {
    local clone=$1
    shift
    status=0
    out=$(cd "$clone" && bash "$intake" "$@" 2>"$scratch_root/stderr") || status=$?
    err=$(cat "$scratch_root/stderr")
}

# Writes <content> to .codeo/intake/<path> in <clone>.
dossier() {
    mkdir -p "$(dirname "$1/.codeo/intake/$2")"
    printf '%s\n' "$3" > "$1/.codeo/intake/$2"
}
on_origin() { git -C "$1" ls-tree -r --name-only codeo/intake -- .codeo/intake | grep -v '\.keep$' || true; }
show_origin() { git -C "$1" show "codeo/intake:.codeo/intake/$2" 2>/dev/null || true; }

refuse_intake() {
    cat > "$1/.git/hooks/pre-receive" <<'HOOK'
#!/bin/sh
while read old new ref; do [ "$ref" = refs/heads/codeo/intake ] && exit 1; done
exit 0
HOOK
    chmod +x "$1/.git/hooks/pre-receive"
}

# --- commit -----------------------------------------------------------------------------------------

case_desc="commit_puts_the_directory_on_the_intake_branch_and_pushes_it"
o=$(fresh_origin)
c=$(clone_of "$o")
dossier "$c" 42/issue.md "the issue"
run "$c" commit 42 "docs(codeo): issue dossier for #42"
assert_eq "exit" 0 "$status"
assert_matches "says so" '^intake: committed 42 as [0-9a-f]{7}$' "$out"
assert_eq "origin has it" ".codeo/intake/42/issue.md" "$(on_origin "$o")"
assert_eq "content" "the issue" "$(show_origin "$o" 42/issue.md)"
assert_eq "message" "docs(codeo): issue dossier for #42" "$(git -C "$o" log -1 --format=%s codeo/intake)"
assert_eq "local branch follows" "$(git -C "$o" rev-parse codeo/intake)" "$(git -C "$c" rev-parse codeo/intake)"

case_desc="commit_with_nothing_new_says_so_and_moves_nothing"
before=$(git -C "$o" rev-parse codeo/intake)
run "$c" commit 42 "again"
assert_eq "exit" 0 "$status"
assert_eq "says so" "intake: nothing to commit for 42" "$out"
assert_eq "origin unmoved" "$before" "$(git -C "$o" rev-parse codeo/intake)"

case_desc="commit_leaves_head_the_index_and_the_working_tree_alone"
o=$(fresh_origin)
c=$(clone_of "$o")
git -C "$c" checkout -q -b feat/x
echo staged > "$c/staged.txt"
git -C "$c" add staged.txt
echo dirty >> "$c/README.md"
head_before=$(git -C "$c" rev-parse HEAD)
status_before=$(git -C "$c" status --porcelain)
cached_before=$(git -C "$c" diff --cached)
dossier "$c" 7/issue.md "seven"
run "$c" commit 7 "docs(codeo): #7"
assert_eq "exit" 0 "$status"
assert_eq "HEAD" "$head_before" "$(git -C "$c" rev-parse HEAD)"
assert_eq "branch" "feat/x" "$(git -C "$c" branch --show-current)"
assert_eq "status" "$status_before" "$(git -C "$c" status --porcelain)"
assert_eq "staged" "$cached_before" "$(git -C "$c" diff --cached)"
assert_eq "origin has it" ".codeo/intake/7/issue.md" "$(on_origin "$o")"

case_desc="commit_drop_removes_the_old_directory_in_the_same_commit"
o=$(fresh_origin)
c=$(clone_of "$o")
dossier "$c" new-login/issue.md "draft"
run "$c" commit new-login "docs(codeo): draft"
mv "$c/.codeo/intake/new-login" "$c/.codeo/intake/43"
before=$(git -C "$o" rev-parse codeo/intake)
run "$c" commit 43 "docs(codeo): filed as #43" --drop new-login
assert_eq "exit" 0 "$status"
assert_eq "origin has only the new name" ".codeo/intake/43/issue.md" "$(on_origin "$o")"
assert_eq "one commit" "$before" "$(git -C "$o" rev-parse codeo/intake~1)"

case_desc="commit_of_a_missing_directory_dies"
run "$c" commit 99 "nothing"
assert_eq "exit" 1 "$status"
assert_contains "says so" "intake: .codeo/intake/99 does not exist" "$err"

case_desc="commit_rebuilds_on_origins_tip_when_its_push_loses_a_race"
o=$(fresh_origin)
a=$(clone_of "$o")
b=$(clone_of "$o")
dossier "$a" 1/issue.md "first"
run "$a" commit 1 "one"
git -C "$b" fetch -q origin
dossier "$b" 2/issue.md "second"
dossier "$a" 3/issue.md "third"
# A git whose first push from clone a lets clone b push first, so a's push is refused as stale.
real_git=$(command -v git)
race_bin="$scratch_root/race-bin"
mkdir -p "$race_bin"
cat > "$race_bin/git" <<STUB
#!/usr/bin/env bash
if [[ \${1:-} == push && ! -e "$scratch_root/raced" ]]; then
    : > "$scratch_root/raced"
    (cd "$b" && PATH="$PATH" bash "$intake" commit 2 two >/dev/null 2>&1)
fi
exec "$real_git" "\$@"
STUB
chmod +x "$race_bin/git"
status=0
out=$(cd "$a" && PATH="$race_bin:$PATH" bash "$intake" commit 3 three 2>"$scratch_root/stderr") || status=$?
err=$(cat "$scratch_root/stderr")
assert_eq "exit" 0 "$status"
assert_contains "retried" "push refused (attempt 1) — rebuilding on origin's tip" "$err"
assert_eq "origin has all three" $'.codeo/intake/1/issue.md\n.codeo/intake/2/issue.md\n.codeo/intake/3/issue.md' "$(on_origin "$o")"

case_desc="commit_unions_the_triage_ledger_rows_by_fingerprint"
o=$(fresh_origin)
a=$(clone_of "$o")
b=$(clone_of "$o")
header=$'# Triage ledger\n\n| Fingerprint | Decision | Date |\n|---|---|---|'
dossier "$a" triage/ledger.md "$header"$'\n| `fp1` | filed #4 | 2026-10-01 |\n| `fp3` | dropped | 2026-10-09 |\n\nfooter'
run "$a" commit triage "docs(codeo): triage a"
dossier "$b" triage/ledger.md "$header"$'\n| `fp1` | stashed | 2026-10-05 |\n| `fp2` | filed #5 | 2026-10-02 |\n| `fp3` | kept | 2026-10-02 |\n\nfooter'
run "$b" commit triage "docs(codeo): triage b"
assert_eq "exit" 0 "$status"
ledger=$(show_origin "$o" triage/ledger.md)
assert_eq "header once" 1 "$(grep -c '^# Triage ledger' <<<"$ledger")"
assert_contains "the later fp1 wins" '| `fp1` | stashed | 2026-10-05 |' "$ledger"
assert_contains "b's new row" '| `fp2` | filed #5 | 2026-10-02 |' "$ledger"
assert_contains "the later fp3 wins" '| `fp3` | dropped | 2026-10-09 |' "$ledger"
assert_eq "three rows" 3 "$(grep -c '^| `' <<<"$ledger")"
assert_eq "footer kept" "footer" "$(tail -n 1 <<<"$ledger")"

case_desc="a_refused_commit_keeps_its_local_commit"
o=$(fresh_origin)
c=$(clone_of "$o")
dossier "$c" 42/issue.md "hi"
refuse_intake "$o"
run "$c" commit 42 "docs(codeo): issue dossier for #42"
assert_eq "exit" 3 "$status"
assert_contains "says so" "committed locally but not on origin" "$err"
assert_eq "local branch holds the dossier" ".codeo/intake/42/issue.md" "$(git -C "$c" ls-tree -r --name-only refs/heads/codeo/intake -- .codeo/intake/42)"

case_desc="a_diverged_branch_is_rebuilt_only_over_its_own_paths"
# c's refused commit of 42 sits locally; origin then gains 43 from another clone.
rm "$o/.git/hooks/pre-receive"
other=$(clone_of "$o")
dossier "$other" 43/issue.md "theirs"
run "$other" commit 43 "theirs"
run "$c" commit 42 "docs(codeo): issue dossier for #42"
assert_eq "re-adding its own path: exit" 0 "$status"
assert_eq "origin has both" $'.codeo/intake/42/issue.md\n.codeo/intake/43/issue.md' "$(on_origin "$o")"
refuse_intake "$o"
dossier "$c" 50/issue.md "unpushed"
run "$c" commit 50 "unpushed"
rm "$o/.git/hooks/pre-receive"
dossier "$other" 44/issue.md "theirs again"
run "$other" commit 44 "theirs again"
run "$c" commit 42 "another"
assert_eq "another path's unpushed commit: exit" 1 "$status"
assert_contains "says so" "local codeo/intake has unpushed commits touching .codeo/intake/50/issue.md; reconcile them by hand" "$err"

# --- restore ----------------------------------------------------------------------------------------

case_desc="restore_writes_what_is_missing_and_keeps_what_is_here"
o=$(fresh_origin)
a=$(clone_of "$o")
dossier "$a" 42/issue.md "origin's issue"
dossier "$a" 42/plan.md "origin's plan"
run "$a" commit 42 "both"
c=$(clone_of "$o")
dossier "$c" 42/issue.md "local answers"
run "$c" restore 42
assert_eq "exit" 0 "$status"
assert_contains "kept" "intake: kept local .codeo/intake/42/issue.md" "$out"
assert_contains "restored" "intake: restored .codeo/intake/42/plan.md" "$out"
assert_eq "local kept" "local answers" "$(cat "$c/.codeo/intake/42/issue.md")"
assert_eq "missing written" "origin's plan" "$(cat "$c/.codeo/intake/42/plan.md")"
assert_eq "HEAD untouched" "main" "$(git -C "$c" branch --show-current)"
assert_eq "working tree clean" "" "$(git -C "$c" status --porcelain)"

case_desc="restore_of_a_directory_the_branch_lacks_dies"
run "$c" restore 99
assert_eq "exit" 1 "$status"
assert_contains "says so" "intake: codeo/intake has no .codeo/intake/99" "$err"

case_desc="restore_with_no_intake_branch_dies"
c=$(clone_of "$(fresh_origin)")
run "$c" restore 42
assert_eq "exit" 1 "$status"
assert_contains "says so" "intake: no codeo/intake branch, locally or on origin" "$err"

case_desc="an unknown verb prints the usage"
run "$c" bogus
assert_eq "exit" 1 "$status"
assert_contains "usage" "usage: intake.sh commit <dir> <message> [--drop <old-dir>] | restore <dir> | lease" "$err"

if ((failures)); then
    echo "$failures case(s) failed"
    exit 1
fi
echo "all cases passed"
