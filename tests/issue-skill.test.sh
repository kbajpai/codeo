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

# $1 case, $2 file relative to the repository root, $3 fixed string the file must contain.
doc_has() { grep -qF -- "$3" "$plugin_root/$2" || fail "$1 — no [$3] in $2"; }

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

doc_has "the board bullet says issue files into Backlog" docs/handoff.md 'puts every issue it files in **Backlog**'
doc_has "the transition table has the filing row" docs/handoff.md '| A new issue is filed | `issue` | `backlog` |'
doc_has "the failure sentence names issue's exception" docs/handoff.md 'and `issue`, whose dossier is committed before the card moves'
doc_has "the ownership table gives backlog to issue" docs/handoff.md '`backlog`: `/codeo:issue` at filing'
doc_has "skills.md says issue writes Backlog only" docs/skills.md "Writes the new issue's board Status, to Backlog only"
doc_has "skills.md says a failed move never fails the filing" docs/skills.md 'a failed move is reported and never fails the filing'
doc_has "skills.md says triage finds the card already in Backlog" docs/skills.md 'because `/codeo:issue` writes that Status when it files it'

# F2, F5: the scope sentences name the Backlog write and the success line is reported.
must_contain "the scope sentence names the board write" "and, with a board, puts it in the board's Backlog, and that is all it does"
must_contain "the success line is reported" 'Quote them in the report.'
must_contain 'set prints one line per project' 'one line per project'
must_contain 'the Backlog fix is named' 'board.statuses.backlog'
doc_has "skills.md's scope sentence names the board write" docs/skills.md "puts it in the board's Backlog when the project has a board, and does nothing else"

if ((failures)); then
    echo "$failures case(s) failed"
    exit 1
fi
echo "all cases passed"
