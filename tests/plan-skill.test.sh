#!/usr/bin/env bash
# Checks that skills/plan/SKILL.md carries the wording the dossier checker depends on: the round a
# send-back from /codeo:qc adds to plan.md, its date line, the send-back parenthesis naming the qc
# round it answers, and the single footprint block it keeps.
#
#   plan-skill.test.sh
#       Exits non-zero and names the failing cases; prints "all cases passed" otherwise.
set -euo pipefail

plugin_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
# PLAN_SKILL points the checks at another copy (an older revision, to see a case fail).
skill=${PLAN_SKILL:-"$plugin_root/skills/plan/SKILL.md"}

failures=0
fail() {
    echo "FAIL: $1"
    failures=$((failures + 1))
}

# $1 case, $2 fixed string the skill must contain.
must_contain() { grep -qF -- "$2" "$skill" || fail "$1 — no [$2]"; }

# Step 10: the dossier forms docs/dossier.md documents and the dossier checker reads.
must_contain "a qc send-back keeps the first outcome" 'After a send-back from `/codeo:qc`, the first outcome stays as it was written'
must_contain "the send-back adds the next round" 'outcome goes beneath it as the next `### Round <n>` (the unheaded first is round 1)'
must_contain "the round names the qc round it answers" 'the date as its first line, followed by `(send-back from qc.md round <n>)` naming the'
must_contain "the footprint moves rather than repeats" 'The `### Footprint` moves to the end of that round, so the file'

if ((failures)); then
    echo "$failures case(s) failed"
    exit 1
fi
echo "all cases passed"