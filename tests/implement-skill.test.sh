#!/usr/bin/env bash
# Checks that skills/implement/SKILL.md carries the wording later steps and the plugin's own rules
# depend on: the Outcome line /codeo:qc reads, the subagent model read, the deploy hook and its
# plan-gap stops, no escalation off the subagent model, and no release of the lease.
#
#   implement-skill.test.sh
#       Exits non-zero and names the failing cases; prints "all cases passed" otherwise.
set -euo pipefail

plugin_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
skill="$plugin_root/skills/implement/SKILL.md"

failures=0
fail() {
    echo "FAIL: $1"
    failures=$((failures + 1))
}

# $1 case, $2 fixed string the skill must contain.
must_contain() { grep -qF -- "$2" "$skill" || fail "$1 — no [$2]"; }

must_contain "the Outcome line qc reads" 'Deployed revision:'
must_contain "the subagent model read" "config.sh\" get '.models.subagent // \"sonnet\"'"
must_contain "the deploy hook" 'hooks.deploy'
must_contain "the lease marker" 'Needs lease:'

# Escalation is only ever named to be ruled out.
while IFS= read -r line; do
    [[ $line == *never* || $line == *"no "* ]] || fail "escalation named without a negation — [$line]"
done < <(grep -i 'escalat' "$skill" || true)

# The lease is /codeo:qc's to release, never this skill's.
if grep -qF 'lease release' "$skill"; then
    fail "the skill releases a lease — $(grep -nF 'lease release' "$skill" | head -1)"
fi

# A missing lease marker and a missing deploy hook are both plan gaps.
count=$(grep -o 'plan gap' "$skill" | wc -l || true)
((count >= 2)) || fail "'plan gap' appears $count time(s), want at least 2"

# Task 2's placeholder for these steps is gone.
if grep -qF 'added by the next task' "$skill"; then
    fail "the steps 5-9 placeholder is still in the skill"
fi

if ((failures)); then
    echo "$failures case(s) failed"
    exit 1
fi
echo "all cases passed"
