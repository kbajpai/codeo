#!/usr/bin/env bash
# Checks that skills/init/SKILL.md carries the wording its dossier depends on: step 7 drafts
# init.md in the shape docs/dossier.md gives, ## Questions included, so dossier-check.sh's
# sections check finds every section in order.
#
#   init-skill.test.sh
#       Exits non-zero and names the failing cases; prints "all cases passed" otherwise.
set -euo pipefail

plugin_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
# INIT_SKILL points the checks at another copy (an older revision, to see a case fail).
skill=${INIT_SKILL:-"$plugin_root/skills/init/SKILL.md"}

failures=0
fail() {
    echo "FAIL: $1"
    failures=$((failures + 1))
}

# Prints step $1's text: from its "<n>. **" line up to the next step, section heading or comment.
step() {
    awk -v n="$1" '
        $0 ~ "^" n "\\. \\*\\*" { f = 1; print; next }
        f && (/^[0-9]+\. \*\*/ || /^## / || /^<!-- [a-z]/) { exit }
        f { print }' "$skill"
}

# $1 case, $2 step number, $3 fixed string the step must contain.
step_contains() {
    local text
    text=$(step "$2" | tr '\n' ' ' | tr -s ' ')
    [[ -n $text ]] || { fail "$1 — no step $2 in the skill"; return; }
    grep -qF -- "$3" <<<"$text" || fail "$1 — step $2 has no [$3]"
}

# $1 case, $2 step number, $3 fixed string the step must not contain.
step_lacks() {
    local text
    text=$(step "$2" | tr '\n' ' ' | tr -s ' ')
    [[ -n $text ]] || { fail "$1 — no step $2 in the skill"; return; }
    ! grep -qF -- "$3" <<<"$text" || fail "$1 — step $2 still has [$3]"
}

# Step 7: the draft carries every section, in dossier-check's order, Questions included.
step_contains "the draft names the section order" 7 '`## Where this stands`, `## Questions`, `## Outcome`, `## Log`'
step_contains "an empty Questions section says None." 7 '`None.`'
step_contains "Notes is optional" 7 '`## Notes` only when there is something to keep'

# Step 6: a resume is found by its dossier, not by a derived name.
step_contains "step 6 finds the branch by its dossier" 6 'scripts/inflight.sh" --branches'
step_contains "step 6 names the new shape" 6 '<type>/<N>-<slug>'
step_contains "step 6 stops on two branches for one issue" 6 'more than one row'
step_lacks "step 6 no longer says the number is absent" 6 'There is no issue number in it.'
step_contains "either TODO case ends the turn" 11 'Either way, end the turn with the block for the case and do not invoke `/codeo:plan` in this turn; with the lock taken, the block names `/codeo:plan` as the step after the fix:'
# Whole file, not step 3: step() stops at step 3's first rule comment (init-02), so it would pass vacuously.
! grep -qF -- 'restore the title' "$skill" || fail "step 3 no longer says restore the title — the skill still has [restore the title]"

# Task 6 (#195): init resolves the user strictly and records the owner.
# Whole file: step() would stop at step 3's first rule comment.
grep -qF -- 'scripts/github.sh" user whoami' "$skill" || fail "the skill never runs user whoami"
grep -qF -- 'When `user whoami` exits 1, print its one `codeo:` line and stop' "$skill" || fail "the skill does not stop on whoami's exit 1"
! grep -qF -- 'say so and continue' "$skill" || fail "the skill still says [say so and continue]"
! grep -qF -- 'never compared with an assignee' "$skill" || fail "the skill still exempts an unverified login from the assignee comparison"
! grep -qF -- 'skips only the assignee comparison' "$skill" || fail "the skill still says an unverified login skips the assignee comparison"
! grep -qF -- 'no login to' "$skill" "$skill" || fail "the skill still has [no login to]"
! grep -qF -- 'user login' "$skill" || fail "the skill still has [user login]"
grep -qF -- '| Owner | <login> |' "$skill" || fail "the skill names no Owner row"
! sed -n '/^```markdown/,/^```/p' "$skill" | grep -qF -- '| Owner |' || fail "the Outcome template carries an Owner row — it lives in the header table"
step_contains "step 9 puts the owner in the header table" 9 "the header table, after \`| Branch |\`"
step_contains "the resume passes the whoami login to --resume-line" 6 'whoami` printed'
grep -qF -- '<!-- rule: init-11 -->' "$skill" || fail "marker init-11 is missing"

# Fix round 1 (#195): no Claim line; the exit-3 resume carves out unverified.
! grep -qF -- 'Present only when step 9' "$skill" || fail "the skill still has the Claim line rule [Present only when step 9]"
! grep -qF -- '**Claim.**' "$skill" || fail "the skill still has a Claim line in the outcome"
! grep -qF -- 'trailing **Claim**' "$skill" || fail "the skill still mentions a trailing Claim line"
! grep -qF -- '(not for `unverified`)' "$skill" || fail "step 6 exit 3 still exempts unverified"
! grep -qF -- 'not recorded in `init.md`' "$skill" || fail "the skill still says a failed assignee-add is not recorded"

# Fix round 2 (#195): an unverified login is compared; a failed assignee-add is recorded.
init11=$(sed -n '/<!-- rule: init-11 -->/,/^$/p' "$skill")
grep -qF -- 'unverified' <<<"$init11" || fail "init-11 does not mention unverified"
grep -qF -- 'compared' <<<"$init11" || fail "init-11 does not say the login is compared"
step_contains "step 9 records a failed assignee-add" 9 'assignee-add failed'
step_contains "step 9 records it under Notes" 9 '## Notes'

step_contains "the resume path records a failed assignee-add" 6 'assignee-add failed'

# --approved (#217): approval given in advance by `codeo go`, rule init-12.
grep -qF -- '[--approved]' <(grep '^argument-hint:' "$skill") || fail "argument-hint has no [--approved]"
step_contains "step 0 ignores --approved" 0 '--approved'
step_contains "step 2 accepts --approved" 2 '--approved'
step_contains "step 8 names --approved" 8 '--approved'
step_contains "step 8 gate is unchanged" 8 'Nothing below this line runs before it'
step_contains "step 8 proceeds only when nothing is open" 8 'only when nothing in the file is still open and no earlier stop applies'
grep -qF -- '<!-- rule: init-12 -->' "$skill" || fail "no init-12 rule"
grep -qF -- 'approved in advance by the engineer through codeo go' "$skill" || fail "no approved-in-advance note wording"

if ((failures)); then
    echo "$failures case(s) failed"
    exit 1
fi
echo "all cases passed"
