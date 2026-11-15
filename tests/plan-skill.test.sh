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
must_contain 'a second pass'\''s Outcome is not pending' 'On a pass after a send-back, `## Outcome` is not pending: it holds the earlier rounds, which'
must_contain 'pending means no new round yet' '"pending" in sub-steps 1-3 means no new round is written yet'
must_contain 'the draft footprint goes under Notes again' 'footprint goes under `## Notes` again all the same'
must_contain 'a qc send-back keeps the earlier rounds' 'After a send-back from `/codeo:qc`, the earlier rounds stay as they were written: this'
must_contain 'the round names the qc round on the next line' 'with the date as its first line and, on the next line, `(send-back from qc.md round <k>)`'
must_contain 'the new footprint replaces the old' 'naming the `qc.md` round it answers. The new `### Footprint` replaces the earlier round'\''s:'
must_contain 'moving it removes the old block' 'moving it out of `## Notes` to end the new round removes the old block, because'
must_contain 'the one sanctioned edit of an answered round' 'That removal is the one edit an answered round ever takes'
must_contain 'a block written after a send-back covers the branch' 'A block written after a send-back covers the branch, not only this round'
must_contain 'the outside check adds every path to files' 'run `overlap.sh --outside <N>` and add every path it prints to `files:` before committing'
must_contain 'the pair check runs again after an addition' 'run `overlap.sh <N>` again if you added any'
must_contain 'the host-run rule has its heading' '**Mark the tasks the engineer runs on their own host.**'
must_contain 'a host-run task opens with the Runs on line' "Runs on: the engineer's host"
must_contain 'a host-run command is neutral' 'no shell variable or substitution'
must_contain 'a command that cannot be neutral is labelled with its shell' '`Shell: <name>`'
must_contain 'the shell is asked as a numbered question' 'a numbered question in plan.md'
must_contain 'a local lock needs no shell question unless on Windows' 'unless the session runs on Windows'
must_contain 'a host task is marked with a Runs on line' "is marked with a line \`Runs on: the engineer's host\`"
must_contain 'a lease task carries a Needs lease line' 'carries a line `Needs lease:'
must_contain 'a script is in a language the host is known to have' "in a language the engineer's host is known to have"
must_contain 'a host task on the environment carries both markers' 'carries both markers, each on its own line'
must_contain 'step 8 lists sequenced as the fourth key, none when nothing was sequenced' 'is the fourth key and reads `none` when nothing was sequenced'
must_contain 'step 8 says a footprint without the key fails' 'fails a footprint that lacks any of the four'
must_contain 'step 10 keeps sequenced none when nothing was sequenced' 'stays `none` otherwise'

dossier="$plugin_root/docs/dossier.md"
grep -qF -- 'only when an overlap question was answered that way' "$dossier" &&
    fail 'docs/dossier.md still says sequenced is written only when something was sequenced'
grep -qF -- '`sequenced` — `none` unless an overlap question was answered *sequence after #M*' "$dossier" ||
    fail 'docs/dossier.md does not say sequenced reads none unless something was sequenced'

if ((failures)); then
    echo "$failures case(s) failed"
    exit 1
fi
echo "all cases passed"
