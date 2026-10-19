#!/usr/bin/env bash
# Checks that skills/qc/SKILL.md carries the wording its steps and the plugin's own rules depend
# on: the scope and suite reads, the reviewer's model and description and what it is never given,
# the classification's Phase 1 stop, and the environment evidence — the revision it reads, the
# lease refusals, the stopped-row rule, orphans, and that qc never deploys — and the verdict, the
# release and the hand-off, including that the clear verdict line the skill tells qc to write passes
# scripts/qc-verdict.sh in a scratch repo while the form it forbids fails closed.
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

# The final review wave.
must_follow "the block runs on a recorded revision too" 'It runs when `implement.md` records' 'or a criterion needs the environment'
must_follow "only neither short-circuits the block" 'stale, stopped or orphaned workload' 'neither holds'
must_follow "no evidence hook has its own phrase" 'no evidence hook exists' 'untestable here — no evidence hook'
must_follow "untestable here is not a question" 'untestable here — no evidence hook' 'not a question'
must_follow "untestable here does not stop the verdict" 'untestable here — no evidence hook' 'does not stop the verdict'
must_follow "implement owing nothing is a plan gap" 'owes nothing by its own rule' 'plan gap'
must_contain "the plan gap goes to plan" 'Route it back to `/codeo:plan`, naming the gap'
must_follow "the review skill's feedback section does not apply" 'Act on feedback' 'step 8'
must_follow "a rejected finding is recorded, not argued" 'would reject' 'recorded with the evidence'
must_follow "the re-take follows a deployed failure" 'missing in this' 're-take the lease once as its holder'
must_follow "the re-take re-runs the deployed hook once" 'drops a stale `override:` line' 'then re-run the `deployed` hook once'
must_follow "a stop keeps the pass" '**Stopping here.**' '## Where this stands'
must_contain "a failed push is not fatal" 'loud but not fatal'
must_follow "a later round with no revision runs as a first" 'recorded no revision' 'first round'
must_follow "the stale-base re-run happens once" 'Run this pass again from step 2' 'once only'
must_follow "the restarted attempt is the same round" 'second such refusal is a stop' 'same'
must_follow "an overlap question stop writes a Log line" "*sequence after #M* · *re-scope*" '## Log'
must_follow "a step 10 question stop writes a Log line" 'With a question open' '## Log'
must_follow "interim content lives in Notes until step 11" 'both its answers from step 8' '## Notes'
must_contain "a failed release is recorded as not released" 'Environment NOT released:'
must_follow "the hand-off logs per invocation" '`## Log` line per' 'invocation'
must_follow "the sync merge rides the dossier push" 'pushes its own dossier commits' 'merge commit'
if awk '/<!-- rule: qc-11 -->/{f=1;next} f&&/^$/{exit} f' "$skill" | grep -qF 'opens the pull request'; then
    fail "the hand-off to close sits inside the failed-release paragraph"
fi

# Steps 10-12 and the hand-off.
must_contain "the Verdict span is named" '**Verdict: …**'
must_contain "the Routing span is named" '**Routing: …**'
must_contain "only the last span of the round decides" 'the last such span'
must_contain "a round is a ### Round heading" '### Round <n>'
must_contain "the Log line carries usage.sh's cost" 'usage.sh" qc'
must_contain "a clear verdict releases the lease" 'lease release "$ENV_RESOURCE" <N>'
must_contain "the release is recorded in the round" 'Environment released at the clear verdict:'
must_contain "a failed release still hands off" 'still hand off'
must_contain "a verdict that is not clear releases nothing" 'does not release'
must_contain "a send-back return re-runs the whole pass" 're-run the whole pass'
must_contain "the hand-off writes only qc.md" '**Writes** `.codeo/<N>/qc.md`'
must_contain "the reviewer dispatch is the one exception in the hand-off" '**Spins out subagents**'
must_contain "no invented criteria" "Doesn't invent acceptance criteria"
if grep -qF 'added by the next task' "$skill"; then
    fail "the placeholder for the next task is still in the skill"
fi

# The clear verdict line the skill tells qc to write must pass scripts/qc-verdict.sh, and the form
# it forbids must fail closed. The line is the one directly below the example marker.
verdict_line=$(grep -F -A1 -- '<!-- example: clear -->' "$skill" | sed -n 2p | sed -E 's/^[[:space:]]+//' || true)
if [[ -z $verdict_line ]]; then
    fail "no line below <!-- example: clear --> in the skill"
else
    scratch=$(mktemp -d)
    trap 'rm -rf "$scratch"' EXIT
    export GIT_AUTHOR_NAME="Test" GIT_AUTHOR_EMAIL="test@example.com"
    export GIT_COMMITTER_NAME="Test" GIT_COMMITTER_EMAIL="test@example.com"
    # $1 the round's decision line; prints the script's output and sets rc.
    verdict_of() {
        local dir
        dir=$(mktemp -d -p "$scratch")
        git -C "$dir" -c init.defaultBranch=main init -q
        git -C "$dir" commit -q --allow-empty -m base
        mkdir -p "$dir/.codeo/done/1"
        printf '## Outcome\n\n### Round 1 — 2026-09-01\n\nEvery criterion met.\n\n%s\n\n## Log\n\n- log line\n' \
            "$1" >"$dir/.codeo/done/1/qc.md"
        git -C "$dir" add .codeo
        git -C "$dir" commit -q -m head
        out=$(cd "$dir" && bash "$plugin_root/scripts/qc-verdict.sh" HEAD~1 HEAD 2>&1) && rc=0 || rc=$?
    }
    verdict_of "$verdict_line"
    ((rc == 0)) || fail "the skill's clear verdict line [$verdict_line] fails qc-verdict.sh — $out"
    [[ $out == *"round 1 clear"* ]] || fail "qc-verdict.sh does not call [$verdict_line] clear — $out"
    verdict_of '**Verdict:** clear'
    ((rc != 0)) || fail "qc-verdict.sh passes the forbidden form **Verdict:** clear"
fi

if ((failures)); then
    echo "$failures case(s) failed"
    exit 1
fi
echo "all cases passed"
