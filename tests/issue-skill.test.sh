#!/usr/bin/env bash
# Checks that skills/issue/SKILL.md carries the wording the dossier forms depend on: the rename
# step rewrites the draft's numberless title to the one every dossier carries, so the dossier
# checker's title check holds for an issue.md the pipeline made.
#
#   issue-skill.test.sh
#       Exits non-zero and names the failing cases; prints "all cases passed" otherwise.
set -euo pipefail

plugin_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
# ISSUE_SKILL points the checks at another copy (an older revision, to see a case fail).
skill=${ISSUE_SKILL:-"$plugin_root/skills/issue/SKILL.md"}

failures=0
fail() {
    echo "FAIL: $1"
    failures=$((failures + 1))
}

# $1 case, $2 fixed string the skill must contain.
must_contain() { grep -qF -- "$2" "$skill" || fail "$1 — no [$2]"; }

# $1 case, $2 fixed string, $3 fixed string that must follow within three lines.
must_follow() {
    grep -F -A3 -- "$2" "$skill" | grep -F -- "$3" >/dev/null || fail "$1 — no [$3] within three lines of [$2]"
}

# Step 8: the rename and the title travel in one commit.
must_contain "the rename rewrites the title" 'rewrite its first line to `# Issue #<N> — issue`'
must_follow "the title rewrite is in the rename's commit" 'in the same commit as the rename,' 'rewrite its first line to'

# Step 8: the new issue is filed into the board's Backlog.
must_contain "step 8 files into the Backlog" 'put the new issue in the Backlog'
must_contain "step 8 runs the move" 'board.sh" set <N> backlog'
must_contain "a failed move never fails the filing" 'A failed move never fails the filing'
must_contain "the failure is quoted with its fix" 'quoted with the fix it names'
must_contain "no board, no call" 'With no board, make no `board.sh` call at all'
must_contain "the hand-off names the write" 'its board Status, to Backlog only'
must_contain "the hand-off bounds the write" 'any board Status other than the Backlog'

if ((failures)); then
    echo "$failures case(s) failed"
    exit 1
fi
echo "all cases passed"
