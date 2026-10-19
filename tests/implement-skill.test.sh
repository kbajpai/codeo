#!/usr/bin/env bash
# Checks that skills/implement/SKILL.md carries the wording later steps and the plugin's own rules
# depend on: the Outcome line /codeo:qc reads, the subagent model read, the deploy hook and its
# plan-gap stops, no escalation off the subagent model, and no release of the lease.
#
#   implement-skill.test.sh
#       Exits non-zero and names the failing cases; prints "all cases passed" otherwise.
set -euo pipefail

plugin_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
# IMPLEMENT_SKILL points the checks at another copy (an older revision, to see a case fail).
skill=${IMPLEMENT_SKILL:-"$plugin_root/skills/implement/SKILL.md"}

failures=0
fail() {
    echo "FAIL: $1"
    failures=$((failures + 1))
}

# $1 case, $2 fixed string the skill must contain.
must_contain() { grep -qF -- "$2" "$skill" || fail "$1 — no [$2]"; }

# Step 8: the dossier forms docs/dossier.md documents and the dossier checker reads.
must_contain 'every later round'\''s date is its first line' 'Every later round'\''s date is its first line,'
must_contain 'the link goes on the next line' 'beneath the heading, and the next line names what the round answers:'
must_contain 'a qc or close send-back round names its source' '`(send-back from qc.md round <k>)` or `(send-back from close.md round <k>)` for the round'
must_contain 'a round after a re-plan names the plan round' 'step 3 read, or `(after plan.md round <k>)` when it follows a re-plan'

must_contain "the Outcome line qc reads" 'Deployed revision:'
must_contain "the revision is a bare line" 'Write `Deployed revision: <x>` as a bare line under'
must_contain "the subagent model read" "config.sh\" get '.models.subagent // \"sonnet\"'"
# Word-bounded: environment.hooks.deployed is qc's hook, not this one.
grep -qE 'hooks\.deploy([^A-Za-z]|$)' "$skill" || fail "the deploy hook — no [hooks.deploy] (hooks.deployed does not count)"
must_contain "the lease marker" 'Needs lease:'

# Escalation is only ever named to be ruled out.
while IFS= read -r line; do
    grep -qiE 'never escalat|no escalat|never an escalation' <<<"$line" ||
        fail "escalation named without a negation — [$line]"
done < <(grep -i 'escalat' "$skill" || true)

must_contain "a queued take records a wait" 'lease wait'
must_contain "a turn refusal is watched by its time" 'right of way until'
must_contain "the redeploy check reads deploy=true" 'deploy=true'
must_contain "the redeploy check reads deploy=false" 'deploy=false'
must_contain "the scope script never overrules the diff" 'never overrules the diff'
must_contain "no suites means no build command" 'there is no build command'
must_contain "no environment means none of it applies" 'nothing in the rest of this part'
must_contain "the redeploy check runs in every round" 'the first included'
must_contain "the deploy precedes the lease task" 'before dispatching the task that needed it'
must_contain "other take refusals stop without a wait" '**Anything else**'
must_contain "no suites means no deploy= line" 'no `deploy=` line at all'
must_contain "a failing scope.sh is retried after a fetch" 'A non-zero exit from the script'
must_contain "the deployed revision is committed at once" 'deployed <revision as printed, or its short SHA>'
must_contain "the redeploy check prefers the newer Where-this-stands line" 'the one under `## Where this stands` when there is one'
must_contain "the pipeline status is read in the same command" 'echo "deploy-exit=${PIPESTATUS[0]}"'
must_contain "its own dossier commits do not re-trigger the check" "other than this skill's own dossier"

must_contain "an empty revision is HEAD after the hook" 'after the hook and the clean-tree check'
must_contain "a missing deploy hook stops before the take" 'with nothing taken'
must_contain "an unresolvable revision is a take and deploy" 'the lease and deploy as above'
must_contain "the redeploy check is the last thing before step 8" 'the last thing before step 8'
must_contain "the build comes before the redeploy check" 'redeploy check comes after this build'
if grep -qF 'before the hook ran' "$skill"; then
    fail "an empty revision still reads the HEAD from before the hook"
fi

# $1 case, $2 fixed string, $3 fixed string that must follow within three lines.
must_follow() {
    grep -F -A3 -- "$2" "$skill" | grep -qF -- "$3" || fail "$1 — no [$3] within three lines of [$2]"
}
must_follow "a hook refusal records no wait" 'hook exited' 'no wait'
must_follow "a dirty tree after the deploy is never committed" 'git status --porcelain' 'never commit'

# The comparison revision is this skill's own; no other skill's dossier format is assumed.
if grep -qF 'environment block' "$skill"; then
    fail "the skill reads another skill's environment block — $(grep -nF 'environment block' "$skill" | head -1)"
fi

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
