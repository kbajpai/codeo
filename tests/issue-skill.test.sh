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
    grep -F -A3 -- "$2" "$skill" | grep -qF -- "$3" || fail "$1 — no [$3] within three lines of [$2]"
}

# Step 8: the rename and the title travel in one commit.
must_contain "the rename rewrites the title" 'rewrite its first line to `# Issue #<N> — issue`'
must_follow "the title rewrite is in the rename's commit" 'in the same commit as the rename,' 'rewrite its first line to'

if ((failures)); then
    echo "$failures case(s) failed"
    exit 1
fi
echo "all cases passed"
