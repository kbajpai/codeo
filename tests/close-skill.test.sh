#!/usr/bin/env bash
# Checks that skills/close/SKILL.md carries the wording its steps and the plugin's own rules depend
# on: the frontmatter's stash and abandon paths, the round-number rule for a return from review,
# the conflict check's literal file list and first-parent log, where the pull request's record and
# the review-return comment body go, and Phases 2 and 3 — the checks and mergeability report, the
# release at approval recorded in a PR comment, the send-back round with its qc round line, the
# proof of the merge, the release of every lease, the one question before the branch is deleted,
# the record on the merged PR, the lock removed last, the point fetches with their exit handling
# and the last report by the lock's host; then the stash and closed-unmerged section, the put-back
# point, the hand-off, the non-goals, and a behavioural check that the stash and abandon headings
# the skill writes are the ones `claim.sh --stash-live` reads (scratch repos, no network).
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

# $1 case, $2 text, $3 fixed string, $4 fixed string whose first occurrence must come after $3's
# first occurrence, both within $2. Character offsets, so two on one line are ordered too.
text_order() {
    local text=$2 before first
    if [[ $text != *"$3"* || $text != *"$4"* ]]; then
        fail "$1 — no [$4] after [$3]"
        return
    fi
    before=${text%%"$3"*}
    first=${#before}
    before=${text%%"$4"*}
    ((${#before} > first)) || fail "$1 — [$4] first appears before [$3]"
}

# $1 case, $2 step number, $3 fixed string, $4 fixed string that must come later in the same step.
step_order() {
    local text
    text=$(step "$2")
    [[ -n $text ]] || { fail "$1 — no step $2 in the skill"; return; }
    text_order "$1 (step $2)" "$text" "$3" "$4"
}

# Prints the "## $1" section: from its heading up to the next "## " heading.
section() {
    awk -v h="## $1" '
        $0 == h { f = 1; print; next }
        f && /^## / { exit }
        f { print }' "$skill"
}

# $1 case, $2 section heading, $3 fixed string the section must contain.
section_contains() {
    local text
    text=$(section "$2")
    [[ -n $text ]] || { fail "$1 — no section [## $2] in the skill"; return; }
    grep -qF -- "$3" <<<"$text" || fail "$1 — section [$2] has no [$3]"
}

# $1 case, $2 section heading, $3 fixed string, $4 fixed string that must come later in it.
section_order() {
    local text
    text=$(section "$2")
    [[ -n $text ]] || { fail "$1 — no section [## $2] in the skill"; return; }
    text_order "$1 ($2)" "$text" "$3" "$4"
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
step_contains "the lock is deleted last" 16 'Delete `.codeo/active` — last, so a failure anywhere above'

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

# Review carry-overs on Phases 2 and 3.
step_contains "the required-checks read tolerates an absent ci key" 9 "config.sh\" get '.ci.requiredChecks[]?'"
step_contains "required checks are matched against check runs only" 9 'commit status'
step_contains "Phase 2 writes nothing until a send-back" 9 'Until a send-back at step 11, this phase writes nothing'
step_order "the upstream is checked before the merge" 9 'git pull --ff-only' 'git merge --no-edit origin/<base>'
step_contains "no run for the merge commit is reported" 13 'no run found for the merge commit'
step_contains "a re-run after a kept lock records only what is new" 15 'the earlier comment stands'

# The stash and closed-unmerged section.
stash_section='Stash, and closed unmerged'
section_contains "the stash heading" "$stash_section" '### Round <n> — stashed'
section_contains "the abandon heading" "$stash_section" '### Round <n> — abandoned'
section_contains "the date goes beneath the heading" "$stash_section" 'no date'
section_contains "the put-back point marker" "$stash_section" '<!-- point: close/put-back -->'
must_follow "the put-back marker sits above its fetch" '<!-- point: close/put-back -->' 'close put-back'
section_order "the put-back exit 3 is handled" "$stash_section" 'close put-back' 'on exit 3'
section_order "the put-back failure exits are handled" "$stash_section" 'close put-back' 'on exit 1, 2 or 4'
section_contains "the put-back runs only when the environment is configured and held" "$stash_section" 'only when `$ENV_RESOURCE` is set and `lease list` shows this issue holding it'
section_contains "the default records what the environment carries" "$stash_section" 'Deployed revision:'
section_contains "an orphan workload is never removed" "$stash_section" 'never removed'
section_contains "close-12 names irreversible steps" "$stash_section" 'irreversible'
section_contains "close-12 shows the engineer" "$stash_section" 'show it to the engineer'
section_contains "close-11 never infers a stash" "$stash_section" 'Never infer a stash from a failing verdict'
section_contains "close-13 names the skill not to use" "$stash_section" 'finishing-a-development-branch'
section_contains "a stash releases every lease" "$stash_section" 'lease release-all <N>'
section_order "the put-back comes before the release" "$stash_section" 'close put-back' 'lease release-all <N>'
section_contains "the assignee is removed" "$stash_section" 'github.sh" issue assignee-remove <N>'
section_contains "no login is a skip" "$stash_section" 'github.sh" user login'
section_contains "a stash moves the card to Ready" "$stash_section" 'board.sh" set <N> "$READY"'
section_contains "an abandon moves the card to Backlog" "$stash_section" 'board.sh" set <N> "$BACKLOG"'
section_contains "init resumes a stash" "$stash_section" '/codeo:init #<N>'
section_contains "an open pull request stays open" "$stash_section" 'stays open'
section_contains "the abandon deletes the branch only on request" "$stash_section" 'same confirmation as step 14'
section_order "a stash deletes the lock last" "$stash_section" 'lease release-all <N>' 'Delete `.codeo/active`'
for id in close-11 close-12 close-13; do
    section_contains "$id sits in the stash section" "$stash_section" "<!-- rule: $id -->"
done
for heading in Hand-off Non-goals Tips; do
    grep -qxF "## $heading" "$skill" || fail "no ## $heading section"
done
section_contains "the hand-off says close hands off to implement" Hand-off '/codeo:implement'
section_contains "the hand-off names the subagent model" Hand-off '$SUBAGENT_MODEL'
section_contains "the non-goals never force-push" Non-goals 'force-push'
if grep -qF 'added by the next task' "$skill"; then
    fail "the placeholder for the next task is still there"
fi

# Behavioural: the stash and abandon headings the skill tells close to write are the ones
# `claim.sh --stash-live` reads, so `init` resumes a stash and stops on an abandon. Each is the
# first "### Round" line within three lines below its "<!-- example: … -->" marker.
example_heading() {
    grep -F -A3 -- "<!-- example: $1 -->" "$skill" | grep -m1 -E '^### Round ' || true
}

export GIT_COMMITTER_NAME="Close Test" GIT_COMMITTER_EMAIL="close-test@example.com"
export GIT_AUTHOR_NAME="Close Test" GIT_AUTHOR_EMAIL="close-test@example.com"
scratch_root=$(mktemp -d)
trap 'rm -rf "$scratch_root"' EXIT
export HOME="$scratch_root/home"
mkdir -p "$HOME"
# claim.sh reads the base branch from the config of the project it runs in, so the project is a
# repo of its own; the repos it is pointed at are scratch ones, origin reached by a local path.
project="$scratch_root/project"
git init -q "$project"
mkdir -p "$project/.codeo"
printf '{"schema":1,"repo":{"owner":"o","name":"n"},"baseBranch":"main"}\n' > "$project/.codeo/config.json"

origin=$(mktemp -d "$scratch_root/origin.XXXXXX")
git -C "$origin" -c init.defaultBranch=main init -q
git -C "$origin" config gc.auto 0
git -C "$origin" config maintenance.auto false
git -C "$origin" config receive.autogc false
echo placeholder > "$origin/README.md"
git -C "$origin" add README.md
git -C "$origin" commit -q -m init

# park_branch <branch> <heading>: pushes <branch> off main with init.md and a close.md whose
# ## Outcome carries that heading, then fetches; prints the clone's path.
park_branch() {
    local c
    c=$(mktemp -d "$scratch_root/clone.XXXXXX")
    git clone -q "$origin" "$c"
    git -C "$c" checkout -q -b "$1" origin/main
    mkdir -p "$c/.codeo/42"
    printf '## Log\n\n- initialized: branch %s\n' "$1" > "$c/.codeo/42/init.md"
    printf '## Outcome\n\n%s\n\n2026-10-19 — parked: why, and what the next person needs\n' "$2" > "$c/.codeo/42/close.md"
    git -C "$c" add .codeo
    git -C "$c" commit -q -m "docs(codeo): close dossier for #42"
    git -C "$c" push -q origin "$1"
    git -C "$c" fetch -q origin
    printf '%s' "$c"
}

status=0 out=
run_stash_live() {
    status=0
    out=$(cd "$project" && bash "$plugin_root/scripts/claim.sh" --stash-live 42 "$1" "$2" 2>&1) || status=$?
}

for kind in stash abandon; do
    heading=$(example_heading "$kind")
    if [[ -z $heading ]]; then
        fail "no ### Round heading under <!-- example: $kind -->"
        continue
    fi
    if grep -qE '[0-9]{4}-[0-9]{2}-[0-9]{2}' <<<"$heading"; then
        fail "the $kind heading the skill writes carries a date: [$heading]"
    fi
    heading=${heading//<n>/2}
    clone=$(park_branch "feat/$kind" "$heading")
    run_stash_live "feat/$kind" "$clone"
    if [[ $kind == stash ]]; then
        [[ $status == 0 && $out == *"claim: #42's stash is live"* ]] ||
            fail "claim.sh does not read the skill's stash heading [$heading] as live: exit $status [$out]"
    else
        [[ $status == 4 && $out == *"claim: #42 was abandoned on "* ]] ||
            fail "claim.sh does not read the skill's abandon heading [$heading] as abandoned: exit $status [$out]"
    fi
done

# A date written into the heading's own place, between the round and its kind, breaks the
# "### Round <n> — " prefix the reader needs: that park is invisible, which is why the date goes
# beneath the heading.
i=0
for heading in "### Round 2 (2026-10-19) — stashed" "### 2026-10-19 Round 2 — stashed" "### Round 2, 2026-10-19 — abandoned"; do
    i=$((i + 1))
    clone=$(park_branch "feat/dated$i" "$heading")
    run_stash_live "feat/dated$i" "$clone"
    [[ $status == 3 && $out == *"has no stash"* ]] ||
        fail "a dated heading [$heading] counted as a park: exit $status [$out]"
done

if ((failures)); then
    echo "$failures case(s) failed"
    exit 1
fi
echo "all cases passed"
