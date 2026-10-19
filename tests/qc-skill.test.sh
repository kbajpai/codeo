#!/usr/bin/env bash
# Checks that skills/qc/SKILL.md carries the wording its steps and the plugin's own rules depend
# on: the scope and suite reads, the reviewer's model and description and what it is never given,
# the classification's Phase 1 stop, and the environment evidence — the revision it reads, the
# lease refusals, the stopped-row rule, orphans, and that qc never deploys.
#
#   qc-skill.test.sh
#       Exits non-zero and names the failing cases; prints "all cases passed" otherwise.
set -euo pipefail

plugin_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
# QC_SKILL points the checks at another copy (an older revision, to see a case fail).
skill=${QC_SKILL:-"$plugin_root/skills/qc/SKILL.md"}

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

# Steps 2-4.
must_follow "the deploy= line needs an environment and a suite" 'deploy=` line' 'at least one suite'
must_contain "only the cannot-diff line is fetched and retried" '`scope: cannot diff'
must_contain "a narrow run never replaces a full suite a criterion depends on" 'never replaces the full'
if grep -qF 'part of a suite' "$skill"; then
    fail "step 4 still allows running part of a suite"
fi

# Step 5.
must_contain "each criterion is met, not met or untestable" 'not met, or untestable'

# Step 6.
must_contain "files outside the footprint are listed" 'overlap.sh" --outside <N>'

# Step 7: the reviewer.
must_contain "the reviewer model read" "config.sh\" get '.models.reviewer // \"opus\"'"
must_follow "the reviewer runs on models.reviewer as QC review:" 'models.reviewer' 'QC review:'
must_contain "the reviewer dispatch passes the reviewer model" 'model: "$REVIEWER_MODEL"'
must_contain "every other dispatch passes the subagent model" 'model: "$SUBAGENT_MODEL"'
must_contain "one round reports every defect" 'every defect'
must_contain "no round for non-blocking polish" 'non-blocking polish'
# implement.md is named in step 7 only as something the reviewer is never given.
step7=$(awk '/^7\. \*\*/{f=1} /^8\. \*\*/{f=0} f' "$skill")
[[ -n "$step7" ]] || fail "no step 7 in the skill"
# Each mention must read "never `implement.md`".
while IFS= read -r line; do
    [[ $line == 'never `implement.md' ]] || fail "step 7 names implement.md other than as never given — [$line]"
done < <(grep -oE '(never `)?implement\.md' <<<"$step7" || true)

# Step 8.
must_follow "debugging stops at Phase 1" 'Stop at the end of' 'Phase 1'
must_contain "the blocking axis" '**Blocking or not.**'
must_contain "the whose axis" '**Whose it is.**'

# Step 9: environment evidence.
must_contain "the revision is read as implement writes it" 'Deployed revision:'
if grep -qF 'Environment revision' "$skill"; then
    fail "the skill invents an Environment revision record"
fi
must_contain "the evidence block" '#### Environment'
must_contain "the deployed hook is read" 'config.sh" get .environment.hooks.deployed'
must_contain "a missing lease is not yet checkable" 'not yet checkable'
must_follow "no evidence hook means untestable" 'no evidence hook exists' 'untestable'
must_follow "an orphan is non-blocking" 'is an orphan' 'non-blocking'
must_contain "an orphan goes to triage" '/codeo:triage'
must_contain "the lease is checked first" 'lease check "$ENV_RESOURCE" <N>'
must_follow "a lease not held is not yet checkable" '**Exit 1**' 'not yet checkable'
must_follow "a lease not held is a send-back to implement" '**Exit 1**' '/codeo:implement'
must_contain "a holder's re-take drops a stale override line" 'drops a stale `override:` line'
must_contain "the evidence hook is read before the lease" 'The evidence hook comes first'
must_contain "a stale base re-runs the pass from step 2" 'Run this pass again from step 2'
# qc never takes a lease its issue does not hold, so it never queues for one either.
if grep -qF 'take it with the same command' "$skill"; then
    fail "the skill takes a lease its issue does not hold"
fi
if grep -qF 'lease wait' "$skill"; then
    fail "the skill records a lease wait — $(grep -nF 'lease wait' "$skill" | head -1)"
fi
must_follow "a hook refusal records no wait" 'hook exited' 'no wait'
must_contain "a refusal for a stale base re-runs step 2's sync" 'does not contain origin/'
must_contain "a stopped row runs the start hook" 'config.sh" get .environment.hooks.start'
must_contain "a stopped row re-runs the deployed hook once" 're-run the `deployed` hook once'
must_contain "the ancestor check" 'git merge-base --is-ancestor'
must_contain "a later round reuses evidence only on deploy=false" 'environment evidence from round <n> stands'
must_contain "qc never deploys" 'This skill never deploys'
must_contain "a missing deploy is implement's" 'naming the missing deploy'
if grep -qF -- '--override' "$skill"; then
    fail "the skill takes a lease with --override — $(grep -nF -- '--override' "$skill" | head -1)"
fi

# Deferred to the next task (steps 10-12 and the hand-off): the verdict spans, the last-span rule,
# the round heading, the lease release and the failed-release hand-off, a non-clear verdict
# releasing nothing, the full re-run after a send-back, the usage.sh Log line, the verdict-script
# behaviour test, and the removal of the placeholder.

if ((failures)); then
    echo "$failures case(s) failed"
    exit 1
fi
echo "all cases passed"
