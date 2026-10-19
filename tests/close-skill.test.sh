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

# The final review wave.
step_contains "the dossier's place is read from the committed tree" 1 'read from `HEAD`, the committed tree'
step_contains "a staged rename is not an archive" 1 'a rename staged but never committed is not an archive'
step_contains "an open PR with a live dossier and no review round is a first open resumed" 1 'is the first open resumed, not a return from review'
step_contains "a merged pull request cannot be stashed or abandoned" 1 'A merged pull request cannot be'
step_contains "the stash row excludes a merged pull request" 1 'on any pull request not merged'
step_contains "close-04 names step 9's merge as its one exception" 3 'bar the clean base-branch merge step 9 makes'
step_contains "a return from review pulls an Update-branch merge first" 3 'so nothing is committed on a stale tip'
step_contains "diverged from upstream is a stop" 3 'Ahead and behind both is a stop'
step_contains "the first-open record has its own round heading" 5 '### Round <n> — pull request opened'
step_contains "a first open resumed keeps the PR subject" 7 'a first open resumed keeps the `— PR #<pr>` subject'
step_contains "the review-return comment is conditional on a review round" 7 'a review round in `close.md`, not a first open resumed'
step_contains "the watch after an approval ends on the merge only" 8 "jq -e '.state != \"open\"' >/dev/null"
step_contains "step 9 starts with step 3's checks" 9 'First, step 3'"'"'s tree and upstream checks'
step_contains "a staged uncommitted rename is step 3's stop" 9 'a staged, uncommitted rename'
step_order "unpushed commits are pushed before anything is reported" 9 '`git push` them' '`review_decision` from step 1'
step_order "an Update-branch merge is pulled before the base is merged" 9 'git pull --ff-only' 'git merge --no-edit origin/<base>'
step_contains "the re-offered watch is the merge-only one" 9 'merge-only one, which ends on `.state != "open"` alone'
step_contains "a send-back is not handed off until pushed" 11 'there is no hand-off until'
step_contains "an unclosed issue leaves the card at In review" 13 'the card stays at In review'
step_contains "a live dossier on the base is reported loudly" 13 'git ls-tree -d --name-only origin/<base> .codeo/<N>'
step_contains "the live-dossier report commits nothing to the base" 13 'does not commit to the base branch'
step_contains "the ci-publish-check text is relayed, not executed" 13 'relay it, and read only what'
step_contains "the host-workflow text is relayed, not executed" 17 'relay the'
step_contains "the host-workflow commands are the engineer's" 17 'never this skill'"'"'s'
section_contains "the hand-off names step 9's merge commit" Hand-off 'its one commit that is not a dossier commit'
section_contains "the hand-off names the abandon deletion" Hand-off 'on an abandon, the'
section_contains "the non-goals allow the abandon deletion on request" Non-goals 'except on an abandon, when the engineer asks in so many words'
section_contains "the non-goals never dispatch a workflow" Non-goals 'workflow dispatch'
section_contains "overlay text is never executed" Non-goals 'never executed'

# Re-invocation safety.
step_contains "an interrupted stash is detected without --stash" 1 "ends in a \`— stashed\` round while the lock is held"
step_contains "an interrupted abandon is detected" 1 "ends in a \`— abandoned\` round while the lock is held"
step_contains "an interrupted park is finished" 1 'is an interrupted park, which this run finishes'
step_contains "a failed send-back push is found before the qc stop" 2 'git log --format=%s @{u}..HEAD'
step_order "the failed send-back push is checked before routing" 2 'Before that stop' 'hand off to `/codeo:implement` as step 11'
step_contains "a failed send-back push is never routed to qc" 2 'would let a clear round on unchanged code pass the review'
step_contains "close-04 keeps this skill's own modified close.md" 3 'The one exception is this skill'"'"'s own dossier'
step_contains "a staged rename is still a stop" 3 'A staged rename, or any other path, is still a stop.'
step_contains "an existing PR-opened round is not duplicated" 3 'step 5 adds no second `— pull request opened` round'
step_contains "only this skill's own commits ahead are pushed" 3 'they are pushed only when each'
step_contains "unjudged commits ahead route to qc" 3 '`/codeo:qc` never judged: name it, stop, and route to `/codeo:qc`'
step_contains "the conflict send-back push has a failure path" 3 'reported loudly and the commit kept, and there is no hand-off until it lands'
step_contains "a resumed first open records from the lookup" 5 "(on a first open resumed, from step 1's lookup)"
step_contains "the review-return comment waits for the push" 7 'only once the push has landed'
step_contains "a re-run into Phase 2 posts the review-return comment" 7 'a re-run into Phase 2 never skips it'
step_contains "step 9 pushes only this skill's own commits" 9 'only when each is this skill'"'"'s own'
step_contains "step 9 routes unjudged commits to qc" 9 '`/codeo:qc` never judged: name it, stop, and'
step_contains "step 9 posts a pending review-return comment" 9 "post step 7's review-return"
section_contains "an abandon's deletion warns the dossier goes with it" "Stash, and closed unmerged" 'deletes the only copy of its dossier'
section_contains "a failed abandon deletion keeps the lock" "Stash, and closed unmerged" 'a deletion that failed keeps it'
section_order "an abandon deletes the branch before the lock" "Stash, and closed unmerged" 'deletes the only copy of its dossier' 'Then the lock is deleted last'

# The stash and closed-unmerged section.
stash_section='Stash, and closed unmerged'
section_contains "the stash heading" "$stash_section" '### Round <n> — stashed'
section_contains "the abandon heading" "$stash_section" '### Round <n> — abandoned'
section_contains "the date goes beneath the heading" "$stash_section" 'no date'
section_contains "the put-back point marker" "$stash_section" '<!-- point: close/put-back -->'
must_follow "the put-back marker sits above its fetch" '<!-- point: close/put-back -->' 'close put-back'
section_order "the put-back exit 3 is handled" "$stash_section" 'close put-back' 'on exit 3'
section_order "the put-back failure exits are handled" "$stash_section" 'close put-back' 'on exit 1, 2 or 4'
section_contains "the put-back runs only when the branch recorded a deploy" "$stash_section" '`.codeo/<N>/implement.md` records a `Deployed revision:`'
section_contains "the put-back takes the lease when the issue no longer holds it" "$stash_section" 'intake.sh" lease take "$ENV_RESOURCE" <N> "put-back"'
section_contains "the put-back take never overrides" "$stash_section" 'never with `--override`'
section_contains "a refused put-back take is a stop and a question" "$stash_section" 'means stop and ask'
section_order "the put-back take comes before the release" "$stash_section" 'lease take "$ENV_RESOURCE" <N> "put-back"' 'lease release-all <N>'
section_contains "proceeding without the lease runs only the steps that do not need it" "$stash_section" 'does only the steps that do not'
section_contains "a re-run skips a put-back already recorded" "$stash_section" 'the put-back is done: skip it'
section_contains "the stash is live from its push" "$stash_section" 'already reads the stash as live'
section_contains "what was not put back is what qc will name" "$stash_section" 'whatever was not put back is what the'
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

# A date that breaks the "### Round <n> — " prefix the reader needs makes that park invisible,
# which is why the date goes beneath the heading. (claim.sh still reads a date set off after the
# prefix, as in "### Round 2 — 2026-10-01 — stashed"; tests/claim.test.sh pins those.)
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
