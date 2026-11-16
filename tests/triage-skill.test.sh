#!/usr/bin/env bash
# Checks that skills/triage/SKILL.md carries the wording that matches /codeo:issue filing each new
# issue into the board's Backlog: triage does not treat Backlog as a decision and does not move a
# card that is already there.
#
#   triage-skill.test.sh
#       Exits non-zero and names the failing cases; prints "all cases passed" otherwise.
set -euo pipefail

plugin_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
# TRIAGE_SKILL points the checks at another copy (an older revision, to see a case fail).
skill=${TRIAGE_SKILL:-"$plugin_root/skills/triage/SKILL.md"}

failures=0
fail() {
    echo "FAIL: $1"
    failures=$((failures + 1))
}

# $1 case, $2 fixed string the skill must contain.
must_contain() { grep -qF -- "$2" "$skill" || fail "$1 — no [$2]"; }

must_contain "says who writes Backlog" 'a new issue is already in the Backlog when it reaches this skill'
must_contain "Backlog is not a decision" 'Being in the Backlog is not a decision'
must_contain "a no after filing is a backlog decision" 'a no is a *leave in the backlog*'
must_contain "a card already in Backlog is not moved" 'make no `board.sh set` call'
must_contain "the read decides" 'when it prints the Backlog status'
must_contain "the hand-off bounds the write" 'only when the card is not already in the Backlog'
must_contain "no board, no call" 'no card move, no `board.sh` call'
must_contain "one fingerprint whichever source finds it" 'has one fingerprint, `issue:<N>`, whichever source finds it'
must_contain "intake fingerprints are for drafts" 'is only for a `new-<slug>/` draft'
must_contain "the intake dossier is not a second item" 'the same item the next bullet finds'
must_contain "a backlog decision is dropped at step 2" 'left-in-the-backlog items are not shown again'
must_contain "leave in the backlog records, and moves only when needed" 'records the decision, and moves the card only for an issue that is not there yet'
must_contain "no move quotes the status line" 'the `status` line when no move was made'
must_contain "the question says when the card moves" 'the card moves to Backlog when it is not already there'

if ((failures)); then
    echo "$failures case(s) failed"
    exit 1
fi
echo "all cases passed"
