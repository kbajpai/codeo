#!/usr/bin/env bash
# Checks that skills/close/SKILL.md carries the wording its steps and the plugin's own rules depend
# on: the frontmatter's stash and abandon paths, the round-number rule for a return from review,
# the conflict check's literal file list and first-parent log, where the pull request's record and
# the review-return comment body go, and Phases 2 and 3 — the checks and mergeability report, the
# release at approval recorded in a PR comment, the send-back round with its qc round line, the
# proof of the merge, the release of every lease, the one question before the branch is deleted,
# the record on the merged PR, the lock removed last, the point fetches with their exit handling
# and the last report by the lock's host.
#
#   close-skill.test.sh
#       Exits non-zero and names the failing cases; prints "all cases passed" otherwise.
set -euo pipefail

plugin_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
# CLOSE_SKILL points the checks at another copy (an older revision, to see a case fail).
skill=${CLOSE_SKILL:-"$plugin_root/skills/close/SKILL.md"}

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
    text=$(step "$2")
    [[ -n $text ]] || { fail "$1 — no step $2 in the skill"; return; }
    grep -qF -- "$3" <<<"$text" || fail "$1 — step $2 has no [$3]"
}

# $1 case, $2 step number, $3 fixed string, $4 fixed string that must come later in the same step.
step_order() {
    local text first second
    text=$(step "$2")
    first=$(grep -nF -- "$3" <<<"$text" | head -1 | cut -d: -f1 || true)
    second=$(grep -nF -- "$4" <<<"$text" | tail -1 | cut -d: -f1 || true)
    if [[ -z $first || -z $second ]] || ((second < first)); then
        fail "$1 — step $2 has no [$4] after [$3]"
    fi
}

# The frontmatter: stash and abandon are named, and abandoning is the closed-unmerged path.
description=$(sed -n 's/^description:[[:space:]]*//p' "$skill" | head -1)
grep -qF 'stash' <<<"$description" || fail "the description does not name the stash path"
grep -qF 'closed unmerged' <<<"$description" || fail "the description does not tie abandoning to a pull request closed unmerged"
if grep -qF '"abandon this"' <<<"$description"; then
    fail "the description triggers on \"abandon this\", which has no phase row"
fi

# Step 2: the round-number rule for a return from review.
must_contain "the send-back round records the qc round" 'qc round at review: <k>'
must_contain "the clear round must be greater than every recorded round" 'must be greater than the'
step_contains "with no qc round line any clear round passes" 2 'any clear round passes'

# Step 3: the conflict check lists files literally and the log is first-parent.
step_contains "the merge check lists conflicted files by name" 3 'git merge-tree --write-tree --name-only origin/<base> HEAD'
step_contains "the conflict log follows the first parent" 3 "git log --first-parent --format='%h %s'"

# Step 5: the record follows a first-open conflict round.
step_contains "the record goes in as the next round after a conflict round" 5 'next `### Round <n>`'

# Step 7: the review-return comment body is written outside the tree.
step_order "the review-return comment body is a mktemp file" 7 'pr comment <PR> <body-file>' 'mktemp'

# Step 9: where the pull request stands.
step_contains "checks are read" 9 'github.sh" pr checks <PR>'
step_contains "mergeability is read" 9 'github.sh" pr view <PR>'
step_contains "behind is brought up to date" 9 '`BEHIND`'
step_contains "an Update-branch merge on GitHub is pulled fast-forward" 9 'git pull --ff-only'
step_contains "conflicting is a send-back" 9 '`CONFLICTING`'
step_contains "a conflicting pull request goes to step 11" 9 'step 11'

# Step 10: the release at approval.
step_contains "the release at approval is only for a lease still held" 10 'lease list'
step_contains "the release at approval" 10 'lease release "$ENV_RESOURCE" <N>'
step_order "the approval release is recorded in a PR comment" 10 'lease release "$ENV_RESOURCE" <N>' 'PR comment'
step_contains "the approval release is never a commit" 10 'never a commit'
step_contains "who is waiting is named" 10 'waiting'

# Step 11: the send-back.
step_contains "review feedback is a round" 11 '### Round <n> — review feedback'
step_contains "a conflict is a round" 11 '— conflicts with <base>'
step_contains "the send-back round records the qc round line" 11 'qc round at review: <k>'
step_contains "the feedback is collected verbatim" 11 'verbatim'
step_contains "the reviews are read" 11 'github.sh" pr reviews <PR>'
step_contains "the inline comments are read" 11 'github.sh" pr review-comments <PR>'
step_contains "the dossier is un-archived" 11 'git mv .codeo/done/<N> .codeo/<N>'
step_contains "the card goes back to in progress" 11 'board.sh" set <N> "$IN_PROGRESS"'
step_contains "the sender never starts the fixing" 11 'never start the fixing'
step_contains "the send-back hands off to implement" 11 '/codeo:implement'

# Step 12: the proof of the merge.
step_contains "the ancestor check" 12 'git merge-base --is-ancestor'
step_contains "the proof is state and merged_at plus the tip match" 12 '`state` and `merged_at` plus the tip match'
step_contains "a squashed branch cannot be told apart by ancestry" 12 'squash'

# Step 13: what the merge should have done.
step_contains "the issue is checked closed" 13 'github.sh" issue view <N>'
step_contains "an open issue is offered, not closed" 13 "don't on your own"
step_contains "the card is Done" 13 'board.sh" set <N> "$DONE"'
step_contains "the ci-publish-check point is fetched" 13 'overlay.sh" close ci-publish-check'
step_order "the ci-publish-check exit 3 is handled" 13 'close ci-publish-check' 'on exit 3'
step_order "the ci-publish-check failure exits are handled" 13 'close ci-publish-check' 'on exit 1, 2 or 4'
step_contains "the ci-publish-check is never a blocker" 13 'never a blocker'

# Step 14: release every lease, then ask once and delete.
step_contains "every lease is released" 14 'lease release-all <N>'
step_order "the leases are released before the branch is deleted" 14 'lease release-all <N>' 'git push origin --delete <branch>'
step_order "the engineer is asked once before the deletion" 14 'ask once' 'git push origin --delete <branch>'
step_contains "the branch is deleted only if it still exists" 14 'git ls-remote --exit-code --heads origin <branch>'
step_contains "a declined deletion keeps the branch and runs the rest" 14 'the rest still runs'

# Step 15: the record on the merged PR.
step_contains "nothing is committed to the base branch after the merge" 15 'Nothing is committed to the base branch after the merge'
step_contains "the record is one PR comment" 15 'github.sh" pr comment <PR> <body-file>'
step_contains "the record carries the cost" 15 'usage.sh" close'

# Step 16: the lock last.
step_contains "the lock is deleted" 16 '.codeo/active'
step_contains "the lock is deleted last" 16 'last'

# Step 17: the last report by the lock's host.
step_contains "the host-workflow point is fetched" 17 'overlay.sh" close host-workflow'
step_order "the host-workflow exit 3 is handled" 17 'close host-workflow' 'on exit 3'
step_order "the host-workflow failure exits are handled" 17 'close host-workflow' 'on exit 1, 2 or 4'
step_contains "the host line is read before the lock goes" 17 'before step 16 deletes it'
step_contains "a web host has nothing to remove" 17 '`host: web`'
step_contains "a container host names the volume" 17 '`host: container`'
step_contains "the container's volume line is named" 17 '`volume:`'
step_contains "a local host has nothing to remove" 17 '`host: local`'
step_contains "triage is suggested" 17 '/codeo:triage'

# Each point marker sits once, and the point it marks is fetched.
for point in ci-publish-check host-workflow; do
    must_contain "the $point marker" "<!-- point: close/$point -->"
    must_follow "the $point marker sits above its fetch" "<!-- point: close/$point -->" "close $point"
done

# Rules placed by Phases 2 and 3, each above its own step's paragraph.
for pair in close-06:10 close-07:12 close-08:14 close-09:15 close-10:16; do
    id=${pair%%:*} n=${pair#*:}
    step_contains "$id sits in step $n" "$n" "<!-- rule: $id -->"
done

if ((failures)); then
    echo "$failures case(s) failed"
    exit 1
fi
echo "all cases passed"
