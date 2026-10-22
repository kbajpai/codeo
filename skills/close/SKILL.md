---
name: close
description: End a codeo workflow — open the pull request, wait for the engineer to merge it, route review feedback or a conflict with the base branch back through /codeo:implement and /codeo:qc, release the shared environment at approval when it is still held, then prove the merge, delete the remote branch on the engineer's yes, release every lease and the lock. Also the way to stash a workflow (park it, Ready to start again), and to abandon one whose pull request was closed unmerged (back to the backlog). Trigger on "close", "close the workflow", "open the PR", "it's merged", "clean up", "stash this", or right after /codeo:qc returns a clear verdict. Never merges the PR and never writes code.
argument-hint: "[optional: --stash to park the workflow instead of finishing it]"
model: sonnet
---

Project overlay text adds to or narrows a step; it never overrides a rule marked with a "rule" comment in this file.

# Closing the workflow

This is the pipeline's last step. It opens the pull request, keeps the workflow open while the
engineer reviews and merges it, and — once GitHub says it merged — proves that, cleans up the branch
and releases `.codeo/active`. The workflow ends at the merge, not when the pull request opens: until
then review feedback still has somewhere to go (a send-back to `/codeo:implement`, through
`/codeo:qc` again, onto the same pull request), and every pipeline rule, the subagent hook among
them, still holds. The work is mechanical and needs little judgment, which is why this skill runs on
Sonnet.

**It never merges, approves or reviews.** The merge is the engineer's; a skill that merged its own
workflow's change would be grading it as well.

**It runs in phases and works out which one from facts, never from memory** — the lock, where the
dossier sits, and the pull request's state on GitHub. Every invocation starts at step 0, so running
it again is safe at any time, in any checkout that holds the lock, after any interruption.

Where things go is read from the project's config, never assumed:

```bash
BASE=$(bash "${CLAUDE_PLUGIN_ROOT}/scripts/config.sh" get .baseBranch)
DOCS=$(bash "${CLAUDE_PLUGIN_ROOT}/scripts/config.sh" get '.docsDir // "docs"')
ENV_RESOURCE=$(bash "${CLAUDE_PLUGIN_ROOT}/scripts/config.sh" get .environment.resource)
BOARD=$(bash "${CLAUDE_PLUGIN_ROOT}/scripts/config.sh" get .board)
SUBAGENT_MODEL=$(bash "${CLAUDE_PLUGIN_ROOT}/scripts/config.sh" get '.models.subagent // "sonnet"')
```

`$BASE`, `$DOCS` and `$SUBAGENT_MODEL` always have a value; `<base>` below is `$BASE`. The reads
behind `$ENV_RESOURCE` and `$BOARD` exit 1 with nothing printed when the key is absent, and that is
an answer, not a failure: no shared environment (nothing in this skill about releasing or putting
back an environment applies, and `close.md` says nothing about one), no board (every card move below
is skipped: make no `board.sh` call, and the `## Log` line says `board: not configured`). A
`board.sh` call that prints `board: not configured` and exits 3 is the same answer met late: skip
the move the same way, never as a failure.

With a board, its statuses are the board's own option names, as `board.statuses` maps them — the
conventional names only when the map leaves a key out:

```bash
IN_REVIEW=$(bash "${CLAUDE_PLUGIN_ROOT}/scripts/config.sh" get '.board.statuses.inReview // "In review"')
IN_PROGRESS=$(bash "${CLAUDE_PLUGIN_ROOT}/scripts/config.sh" get '.board.statuses.inProgress // "In progress"')
DONE=$(bash "${CLAUDE_PLUGIN_ROOT}/scripts/config.sh" get '.board.statuses.done // "Done"')
READY=$(bash "${CLAUDE_PLUGIN_ROOT}/scripts/config.sh" get '.board.statuses.ready // "Ready"')
BACKLOG=$(bash "${CLAUDE_PLUGIN_ROOT}/scripts/config.sh" get '.board.statuses.backlog // "Backlog"')
```

Every card move is part of its step and never a gate on it. Quote the `board.sh` `→` line(s) it
prints in the report and end that invocation's `## Log` line with `board: <status> on #<n>…`; a
failure — a refusal in a hosted session, a token without the `project` scope — is reported with
`#<N>` and the status to move it to by hand, the `## Log` line ends `board: failed — <reason>`, and
the step carries on.

## Phase detection

0. **Read `.codeo/active` before anything else.** The lock names the issue this workflow is bound
   to, and it stays in this checkout from the first phase to the last: the pull request waiting for
   review is still this workflow. No lock means no workflow to close here: say so — or, when the
   project's host workflow binds the lock in another checkout, say to run this step there — and
   stop. A lock whose `branch` disagrees with `git branch --show-current`, or an argument naming a
   different issue, is a hard stop: this skill pushes and deletes branches, and acting on a stale
   lock is how the wrong branch ships or disappears.
   `${CLAUDE_PLUGIN_ROOT}/docs/handoff.md → The lock` has the three checks. `<N>` below is the
   lock's `issue` and `<branch>` its `branch`; read its `host` line now, since step 8 and the last
   report depend on it.

   This step's dossier is `.codeo/<N>/close.md` (or `.codeo/done/<N>/close.md` while the pull
   request waits). Every question it raises is a numbered question in that file, in the form
   `${CLAUDE_PLUGIN_ROOT}/docs/dossier.md → The shape of a file` gives and under the rules in
   `${CLAUDE_PLUGIN_ROOT}/docs/dossier.md → Questions, and the cycle`. Re-invoked with questions
   answered, resume from the file rather than asking again.

1. **Look up the pull request and the dossier**, then say which phase this is before changing
   anything:

   ```bash
   bash "${CLAUDE_PLUGIN_ROOT}/scripts/github.sh" pr list-for-branch <branch>
   ```

   <!-- rule: close-01 -->
   It prints one JSON object: `number`, `html_url`, `state`, `merged_at`, `merge_commit_sha`,
   `head_sha`, `base_ref` and `review_decision`. These are GitHub's REST fields, and REST's `state`
   is only ever `open` or `closed` — there is no `merged` value. Merged means `state` is `closed`
   with `merged_at` set; closed with `merged_at` empty is a pull request someone closed without
   merging it. The phase comes from these facts and from where the dossier sits, never from what an
   earlier invocation or the conversation says happened:

   | What the facts say | Phase |
   |---|---|
   | `--stash`, or the engineer parking the work, or `HEAD`'s `close.md` ends in a `— stashed` round while the lock is held — on any pull request not merged | → **Stash** |
   | No pull request for the branch (`number` is null) | → **Phase 1 — open** |
   | `state` is `open`, dossier under `.codeo/done/<N>/` | → **Phase 2 — waiting** |
   | `state` is `open`, dossier back at `.codeo/<N>/` | → **Phase 1 — return from review** |
   | `state` is `closed` and `merged_at` is set | → **Phase 3 — clean up** |
   | `state` is `closed` and `merged_at` is empty, or `HEAD`'s `close.md` ends in a `— abandoned` round while the lock is held | → **Closed unmerged** |

   Where the dossier sits is read from `HEAD`, the committed tree —
   `git ls-tree -d --name-only HEAD .codeo/<N> .codeo/done/<N>` — never from the working tree:
   a rename staged but never committed is not an archive, and origin still carries the live dossier.
   An open pull request with the dossier at `.codeo/<N>/` and no review round in `close.md` — no
   `— review feedback` or `— conflicts with <base>` round after the one recording the pull request —
   is the first open resumed, not a return from review: the pull request exists, so step 4 is
   skipped, and steps 5–7 record and archive it as a first open. A merged pull request cannot be
   stashed or abandoned: on `--stash`, or a request to abandon, with `merged_at` set, say so, and
   Phase 3 runs instead. A `close.md` at `HEAD` whose last round is `— stashed` (or `— abandoned`)
   while the lock is held is an interrupted park, which this run finishes — with or without
   `--stash`, and without asking the closed-unmerged question again.

   A pull request based on anything but `$BASE` (`base_ref`), or more than one pull request for the
   branch, is a stop: name them and ask.
   <!-- rule: close-02 -->
   The lookup cannot see that second case on its own: `pr list-for-branch` resolves to a single
   match, the newest, so an older pull request for the same branch never appears in its output.
   Account for the gap rather than read silence as proof. A pull request number that differs from
   the one `close.md`'s `## Outcome` recorded is a second pull request, and a stop; so is one the
   engineer, the issue or an earlier round names. With nothing recorded and nothing named, say in
   the report that the lookup sees only the newest pull request.

## Phase 1 — open the pull request

2. **The verdict is clear.** Read the latest `### Round <n>` in `.codeo/<N>/qc.md`'s `## Outcome`
   and its last bold `**Verdict: …**` or `**Routing: …**` span, the way `qc-verdict.sh` reads it:
   only that span counts, and the clear form is ``**Verdict: clear — forward to `/codeo:close`.**``.
   A clear verdict — no blocking finding — is the precondition. No `qc.md`, no round, or anything
   other than clear stops this skill: name exactly what is outstanding, route back to `/codeo:qc`,
   and stop. The lease stays held, the dossier stays live under `.codeo/<N>/`, and no card moves;
   never read a failing verdict as a reason to stash. The one way past it is the engineer's: an
   override they state is recorded verbatim in `close.md`, and the pull request may then be opened,
   but where the base branch requires the `qc-verdict` check it keeps that pull request from
   merging, and the route to a merge is a new, clear `/codeo:qc` round
   (`${CLAUDE_PLUGIN_ROOT}/docs/handoff.md → What GitHub enforces`). Never infer an override from
   impatience, and never re-run the checks yourself for a better answer — that is `/codeo:qc`'s.

   <!-- rule: close-03 -->
   After a send-back from this skill, the clear round must be newer than the send-back:
   `/codeo:qc` has to have seen the changes the review or the conflict asked for. Every send-back
   round this skill writes in `close.md` — `— review feedback` and `— conflicts with <base>` alike —
   records the line `qc round at review: <k>`, where `<k>` is the number of the latest `### Round`
   in `qc.md`'s `## Outcome` when it was written. The clear round's number must be greater than the
   highest `<k>` recorded in `close.md`; equal or lower means `/codeo:qc` has not run since the
   send-back, which is a stop routed to `/codeo:qc`.
   Before that stop, `git fetch origin` and `git log --format=%s @{u}..HEAD`: when the send-back's
   own commit (`docs(codeo): close dossier for #<N> — review feedback`, or
   `— conflicts with <base>`) is among the commits ahead, its push failed and `/codeo:implement`
   has never seen the round. `git push`, and on success hand off to `/codeo:implement` as step 11
   (or step 3) does; on failure report it as that step does and stop. Routing this to `/codeo:qc`
   would let a clear round on unchanged code pass the review. With no `qc round at review:` line in
   `close.md` — the first time the pull request is opened — any clear round passes. Compare the
   round numbers only, never dates.

3. **The tree is clean and pushed.**
   <!-- rule: close-04 -->
   `git status --porcelain` prints nothing. The one exception is this skill's own dossier:
   `.codeo/<N>/close.md` modified in place and nothing else — answers the engineer wrote in the
   file, or a round an interrupted invocation wrote — is kept as it stands and goes into this
   step's next dossier commit; step 5 adds no second `— pull request opened` round when one already
   records this pull request's number. A staged rename, or any other path, is still a stop.
   Anything else it prints — uncommitted code, a stray file — stops the skill and asks the engineer
   what it is: this skill commits its own dossier and
   nothing else, bar the clean base-branch merge step 9 makes, and never sweeps someone's work in
   progress into a pull request. A conflict with
   the base branch, below, is never resolved here either: resolving one is writing code, and the
   code is `/codeo:implement`'s.

   The branch has commits `origin/<base>` does not (`git log --oneline origin/<base>..HEAD`); none
   means `/codeo:implement` never landed anything — say so and stop. Then the upstream, after
   `git fetch origin`: `git status -sb` shows nothing ahead of or behind it, since every step pushed
   its own dossier. Commits ahead mean an earlier push never landed; they are pushed only when each
   is this skill's own — a `docs(codeo): close dossier for #<N>` commit touching only `.codeo/`, or
   step 9's base-branch merge — so say so and `git push` them. Any other commit ahead is work
   `/codeo:qc` never judged: name it, stop, and route to `/codeo:qc`. Behind and not ahead — on a return from review, an
   *Update branch* merge GitHub made while the pull request was open — means `git pull --ff-only`
   first, so nothing is committed on a stale tip. Ahead and behind both is a stop: name both sides
   and ask. A branch with no upstream at all is a stop.

   **It still merges.** Other workflows merge to `<base>` while this one runs. Run
   `git fetch origin`, then `git merge-tree --write-tree --name-only origin/<base> HEAD`. Exit 0
   is a clean merge. Exit 1 is a conflict: after the tree's id on the first line, the output lists
   each conflicting file by name, one per line, up to a blank line and git's messages. Any other
   exit is a stop — report what git printed. A conflict is a send-back to `/codeo:implement`, the same as
   review feedback:
   - Add `### Round <n> — conflicts with <base>` to `close.md`'s `## Outcome` — the next round
     after the highest `### Round` already there, or `### Round 1` when there is none — with the
     date as its first line, then each conflicting file and the changes on `<base>` that touched it
     (`git log --first-parent --format='%h %s' $(git merge-base origin/<base> HEAD)..origin/<base> -- <file>`,
     which lists the merges and direct commits on `<base>` itself; their subjects usually carry the
     pull request number), then the `qc round at review: <k>` line
     close-03 above requires.
   - Append this invocation's `## Log` line, ending ` · cost: ` with what
     `bash "${CLAUDE_PLUGIN_ROOT}/scripts/usage.sh" close` prints.
   - Commit `close.md`, staged by name, with the subject
     `docs(codeo): close dossier for #<N> — conflicts with <base>`, and push. A failed push is
     reported loudly and the commit kept, and there is no hand-off until it lands.
   - Hand off to `/codeo:implement` and stop: it merges the base branch and resolves the conflict,
     `/codeo:qc` runs its whole pass again, and this skill comes back to step 2
     (`${CLAUDE_PLUGIN_ROOT}/docs/handoff.md → A send-back`).

   Then `bash "${CLAUDE_PLUGIN_ROOT}/scripts/overlap.sh" <N>`. Each line it prints is an overlap not
   already raised in this issue's dossiers, and becomes a numbered question in `close.md`: quote
   `#M` and the printed `what` verbatim, with the other issue's branch, assignee and step from
   `bash "${CLAUDE_PLUGIN_ROOT}/scripts/inflight.sh"`, and the options *proceed and coordinate* ·
   *sequence after #M* · *re-scope*. The step stops until it is answered: append this invocation's
   `## Log` line with its cost, commit `close.md`, staged by name, with the subject
   `docs(codeo): close dossier for #<N> — Q<a>-Q<b> raised`, push, print the path and the open
   numbers, and end the turn.

4. **Open the pull request** — or, on a return from review, skip this: the pull request exists, and
   the push at step 7 updates it.
   - **Title:** from the issue, in the conventional-commits form the repository's history already
     uses — read `git log --format=%s -20 origin/<base>` and match its types and scopes.
   - **Body:** drawn from the dossiers' `## Outcome` sections and quoted, not re-derived. What
     changed and why (`plan.md` and `implement.md`); each acceptance criterion from `init.md` and
     how it was met, as `qc.md`'s clear round settled it; the verdict it goes out on, quoted with
     its round number; the documentation pages the change touches — under `$DOCS`, and any other
     page `qc.md`'s documentation check named — so a reviewer reads them as part of the change; and
     the line `Closes #<N>`.

   <!-- rule: close-05 -->
   Check for a pull request template in the repository every time, never from memory: if the
   project has one, follow it, filling its sections from the same outcomes.

   Write the body to a file outside the working tree (`mktemp`), so the tree stays clean, and open
   the pull request with
   `bash "${CLAUDE_PLUGIN_ROOT}/scripts/github.sh" pr create <title> <body-file> <branch> "$BASE"`.
   When the engineer asks for a draft, put `--draft` before the title; otherwise the pull request
   opens ready for review.
   It prints `{number, html_url}`; those are what step 5 records. A non-zero exit is a stop: report
   its one line, and nothing below runs.

5. **Record it.** Write `close.md`'s `## Outcome` under `### Round <n> — pull request opened` —
   `### Round 1` when the outcome is empty, otherwise the next after the highest `### Round`
   already there: the pull request's number and URL as the
   response printed them (on a first open resumed, from step 1's lookup), not reconstructed; the `qc.md` round and verdict it went out on; any
   override from step 2, verbatim; and the date. When `## Outcome` already holds a round — a
   conflict send-back from step 3 before the pull request was ever opened — this record goes in as
   the next `### Round <n>` beneath it, never above it or in place of it. A return from review
   likewise adds the next `### Round <n>` beneath the last, saying which review round it answers
   and which `qc.md` round cleared it.
   In the `— pull request opened` round, the date is the round's first line, beneath the heading,
   and the pull request is the line `#<number> <html_url>`, from the two fields `pr create`
   printed (or step 1's lookup, on a first open resumed). It writes no send-back parenthesis, even
   after a `— conflicts with <base>` round from before the pull request existed.
   A return from review is headed `### Round <n> — pull request updated`, with the date as its
   first line and, on the next line, `(send-back from close.md round <m>)` naming the review round
   it answers. So
   `— pull request opened` heads exactly one round, and a re-run that finds a
   `— pull request updated` round after the latest review round adds no second one.

   **Move the card** — with a board — `bash "${CLAUDE_PLUGIN_ROOT}/scripts/board.sh" set <N> "$IN_REVIEW"`,
   once the pull request is open; on a return from review the same call puts it back, since the
   send-back moved it to `$IN_PROGRESS`. Exit 3 (`board: not configured`) skips it. The card is
   handled as the preamble says: never a gate on the pull request or the dossier.

   Append one `## Log` line: the date, what this invocation did, the board result, then ` · cost: `
   with what `bash "${CLAUDE_PLUGIN_ROOT}/scripts/usage.sh" close` prints.

6. **Archive the dossier.** `mkdir -p .codeo/done`, then `git mv .codeo/<N> .codeo/done/<N>` —
   the files are tracked, so git records a rename. The `mkdir` is for a project's first close:
   `git mv` will not create a missing destination directory, and git tracks no empty one, so
   `.codeo/done/` exists only once something has been archived into it. The archive reaches `<base>` with the merge, which is the only way it can:
   nothing is committed to the base branch after the merge. It is also what lets the `qc-verdict`
   check pass, since that check fails closed on a live dossier.

7. **Commit and push.** One commit carrying `close.md` and the rename, staged by name — the
   rename `git mv` staged, and `.codeo/done/<N>/close.md` — with the subject
   `docs(codeo): close dossier for #<N> — PR #<pr>` (`— round <n>` on a return from review, and
   only then: a first open resumed keeps the `— PR #<pr>` subject;
   `${CLAUDE_PLUGIN_ROOT}/docs/dossier.md → Durability`). Then `git push`; the open pull request
   picks it up. A failed push is reported loudly and the commit kept: the pull request does not
   carry the archive until it lands, and step 9's first check pushes it on the next invocation. On
   a return from review — a review round in `close.md`, not a first open resumed — also leave one
   comment on the pull request, only once the push has landed (after a failed push, step 9 posts
   it when its first check pushes the `— round <n>` commit; a re-run into Phase 2 never skips it) —
   `bash "${CLAUDE_PLUGIN_ROOT}/scripts/github.sh" pr comment <PR> <body-file>` — listing,
   for each review point, what changed, quoted from `implement.md`'s latest round, so the reviewer
   does not have to diff to find out. The body file is a `mktemp` file outside the working tree,
   as at step 4, so the tree stays clean for the next invocation's step 3.

8. **Hand the pull request to the engineer, and keep the lock.** Report its URL and say plainly
   that the workflow stays open until it merges, that merging is the engineer's, and that running
   `/codeo:close` again afterwards — in this checkout, or any checkout holding the lock — finishes
   it.

   **Offer a background watch** rather than only ending the turn: the Monitor tool on an
   until-loop,

   ```bash
   until bash "${CLAUDE_PLUGIN_ROOT}/scripts/github.sh" pr list-for-branch <branch> | jq -e '.state != "open" or .review_decision == "APPROVED"' >/dev/null; do sleep 60; done
   ```

   which costs nothing while it waits and notifies the session when it ends. It ends on an approval
   as well as on a merge or a close, so a lease still held is released the moment review is done,
   not whenever someone next runs this skill. When it fires, continue from step 0; after an
   approval with no merge yet, step 10 runs and the watch is offered again for the merge only —
   this condition would fire at once on the approval it already saw:

   ```bash
   until bash "${CLAUDE_PLUGIN_ROOT}/scripts/github.sh" pr list-for-branch <branch> | jq -e '.state != "open"' >/dev/null; do sleep 60; done
   ```

   When the lock's `host` is `web`, the watch is unavailable — background work does not survive the
   hosted session being reclaimed — so say that instead, and offer only running `/codeo:close`
   again to check on the pull request.

## Phase 2 — waiting on the engineer

9. **Report where the pull request stands.** First, step 3's tree and upstream checks, before
   anything else here: anything `git status --porcelain` prints — a staged, uncommitted rename
   included — is step 3's stop. Then `git fetch origin`, and against the upstream: commits ahead
   mean an earlier push never landed — `git push` them only when each is this skill's own, as at
   step 3 (a `docs(codeo): close dossier for #<N>` commit touching only `.codeo/`, or step 9's
   base-branch merge); any other commit ahead is work `/codeo:qc` never judged: name it, stop, and
   route to `/codeo:qc`. When that push carries a `— round <n>` commit, post step 7's review-return
   comment now, on the pull request. Behind and not ahead means an *Update branch* merge GitHub
   made — `git pull --ff-only`, and nothing more; ahead and behind both is a stop. Steps 10 and 11
   then never act on a stale tip. Then `review_decision` from step 1's lookup; the state of
   its checks, from `bash "${CLAUDE_PLUGIN_ROOT}/scripts/github.sh" pr checks <PR>`, which prints
   the head commit's check runs as one array, each with its `name`, `status` and `conclusion`; and
   whether it can merge, from `bash "${CLAUDE_PLUGIN_ROOT}/scripts/github.sh" pr view <PR>`, which
   prints `mergeable` and `mergeStateStatus`. When the config lists the checks the base branch
   requires — `bash "${CLAUDE_PLUGIN_ROOT}/scripts/config.sh" get '.ci.requiredChecks[]?'`, one
   per line, exit 1 when none are listed — report each of those by name first, and a required
   check with no run as missing; with none listed, report every run. Required checks are matched
   against check runs only, so one the base branch requires as a legacy commit status has no run
   here and reads as missing: say it may be a commit status, not that it failed. `mergeable` is
   `null` while GitHub is still working it out: say so, and read it again on the next invocation
   rather than waiting here. Until a send-back at step 11, this phase writes nothing to `close.md`
   — a dossier commit now would be a push onto a review in progress — and nothing in this step
   changes anything, except the first checks above and the two cases below.
   - **`BEHIND`** — the base branch moved since the last push, and where it requires branches to
     be up to date, that blocks the merge. Bringing the branch up to date is mechanical when the
     merge is clean, so it happens here, on the clean, up-to-date tree the first checks left. If
     the pull above already brought in the engineer's *Update branch* merge, it is done. Otherwise
     run `git merge-tree --write-tree --name-only origin/<base> HEAD` as at step 3; on exit 0,
     `git merge --no-edit origin/<base>` and `git push`, which runs the checks again. Exit 1 is a
     conflict, which goes to step 11 like `CONFLICTING` and is never resolved here.
   - **`CONFLICTING`** — a parallel workflow merged first. It is a send-back exactly like step 3's,
     made at step 11.

   Then step 10 runs when the review approved, and step 11 when it asked for changes or the branch
   conflicts. Otherwise stop here, and offer step 8's watch again — after an approval, the
   merge-only one, which ends on `.state != "open"` alone (on a `web` host, only running
   `/codeo:close` again, as step 8 says).

10. **Approved? Release the environment if it is still held.** This runs with `$ENV_RESOURCE`
    set and `review_decision` `APPROVED`. `/codeo:qc` releases the environment at its clear verdict, so
    usually nothing is held; the release lines it wrote into `qc.md` are information, not the
    answer, and this skill never writes them back. The answer is origin's:
    `bash "${CLAUDE_PLUGIN_ROOT}/scripts/intake.sh" lease list`. When it still shows this issue
    holding `$ENV_RESOURCE` — a qc release that failed, or a later round that took it again —
    release it with `bash "${CLAUDE_PLUGIN_ROOT}/scripts/intake.sh" lease release "$ENV_RESOURCE" <N>`,
    which runs the project's revoke hook as well. Not held, there is nothing to release: say so,
    and leave no comment. Without `$ENV_RESOURCE` this step does nothing.

    <!-- rule: close-06 -->
    Record the release in a PR comment, never a commit: a push after approval is noise on a
    finished review, and it runs the checks again for nothing. The comment
    (`bash "${CLAUDE_PLUGIN_ROOT}/scripts/github.sh" pr comment <PR> <body-file>`, the body a
    `mktemp` file outside the working tree) quotes the script's output and says who is waiting for
    the environment — the waiting rows of the same `lease list` — since the first of them can now
    proceed; the report says the same. A release that fails is reported with its one line and
    never retried in a loop: step 14 releases everything this issue holds at the merge. A later
    review round that needs the environment again takes it again, behind whoever is waiting
    (`${CLAUDE_PLUGIN_ROOT}/docs/handoff.md → Parallel workflows`).

11. **Review asked for changes, or the branch conflicts with `<base>`?** When `review_decision` is
    `CHANGES_REQUESTED`, when the engineer says review feedback needs acting on, or when step 9
    found a conflict, this is a send-back to `/codeo:implement`, under the same rule as
    `/codeo:qc`'s: name what must change and stop; **never start the fixing** — not a one-line
    fix, not a suggested patch.
    - Collect the feedback verbatim: `bash "${CLAUDE_PLUGIN_ROOT}/scripts/github.sh" pr reviews <PR>`
      and `bash "${CLAUDE_PLUGIN_ROOT}/scripts/github.sh" pr comments <PR>` for the review
      verdicts and the conversation, and
      `bash "${CLAUDE_PLUGIN_ROOT}/scripts/github.sh" pr review-comments <PR>` for the inline
      comments, each with its `html_url`. For a conflict, collect the files and the changes on
      `<base>` that touched them instead, as at step 3.
    - Add `### Round <n> — review feedback` (or `### Round <n> — conflicts with <base>`) to
      `close.md`'s `## Outcome` — the next round after the highest `### Round` already there —
      with the date as its first line; then each point verbatim with its link (or each file with
      its log); then the line `qc round at review: <k>`, where `<k>` is the number of the latest
      `### Round` in `qc.md`'s `## Outcome` now, which step 2 compares the next clear round
      against. This round is what `/codeo:implement` reads after the send-back.
    - Un-archive: `git mv .codeo/done/<N> .codeo/<N>`. The dossier's place is what tells every
      later invocation that review work is in flight (step 1's table), and a live dossier keeps the
      `qc-verdict` check failing until step 6 archives it again.
    - Move the card back, with a board:
      `bash "${CLAUDE_PLUGIN_ROOT}/scripts/board.sh" set <N> "$IN_PROGRESS"`, handled as the
      preamble says; the send-back carries on whatever it prints.
    - Append this invocation's `## Log` line, ending ` · cost: ` with what
      `bash "${CLAUDE_PLUGIN_ROOT}/scripts/usage.sh" close` prints. Commit, staged by name — the
      rename `git mv` staged, and `.codeo/<N>/close.md` — with the subject
      `docs(codeo): close dossier for #<N> — review feedback` (or `— conflicts with <base>`), and
      push. A failed push is reported loudly and the commit kept, and there is no hand-off until
      it lands: `/codeo:implement` reads the round from origin. Say what failed, and that the
      round reaches `/codeo:implement` once `git push` from this checkout succeeds.
    - Hand off to `/codeo:implement` and stop. It works the feedback, `/codeo:qc` runs its whole
      pass again, and this skill comes back through Phase 1's return path
      (`${CLAUDE_PLUGIN_ROOT}/docs/handoff.md → A send-back`).

## Phase 3 — merged: verify and clean up

12. **Prove the merge before deleting anything.** All of these, from the tools' output in this
    invocation:
    - `state` is `closed` with `merged_at` set, and `base_ref` is `$BASE` (step 1's lookup).
    - `git fetch origin`. If the local tip is behind `origin/<branch>` — `HEAD` is an ancestor of
      it and not equal to it, an *Update branch* merge GitHub made after the last push — run
      `git pull --ff-only` first, so the local branch carries that merge commit too. Then the
      local branch tip equals the pull request's `head_sha` (`git rev-parse <branch>`), and
      `git status --porcelain` prints nothing. A local commit the pull request never had is
      unmerged work: stop and ask.
    - `git merge-base --is-ancestor <merge_commit_sha> origin/<base>`: the base branch has the
      merge. No branch is switched and nothing is checked out.

    <!-- rule: close-07 -->
    A squash or a rebase merge leaves the branch's own commits out of the base branch's history,
    so git's ancestry check cannot tell a squashed branch from an unmerged one: the proof is
    GitHub's `state` and `merged_at` plus the tip match. That is what makes deleting the branch
    below safe; never delete on less. Any of these failing is a stop: name which, and nothing below
    runs.

13. **Check what the merge should have done**, and report anything that did not happen — it is
    evidence, never a blocker:
    - The issue closed: `bash "${CLAUDE_PLUGIN_ROOT}/scripts/github.sh" issue view <N>`, checking
      `state` and `closed_at`. If `Closes #<N>` did not close it, say so and offer to close it —
      the work has landed — but don't on your own. Until it is closed the card stays at In review,
      since Done waits on the closed issue; say so in the report and in step 15's comment.
    - The base branch carries the archive, not a live dossier:
      `git ls-tree -d --name-only origin/<base> .codeo/<N>` prints nothing. If it prints the
      directory, the merge bypassed the `qc-verdict` check: report it loudly — the base branch now
      carries a live `.codeo/<N>/`, and every later pull request's `qc-verdict` check fails closed
      until a pull request of its own archives it. This skill does not commit to the base branch
      to fix it; it names the problem for the engineer.
    - The card is Done, with a board, once the issue is verified closed:
      `bash "${CLAUDE_PLUGIN_ROOT}/scripts/board.sh" set <N> "$DONE"`. The board's own automation
      may have moved it already, and a `→` line from Done to Done is fine. Its `→` line(s) go into
      step 15's comment with `board: <status> on #<n>…`, or `board: failed — <reason>` with `#<N>`
      to move by hand; with no board, the comment says `board: not configured`.
    <!-- point: close/ci-publish-check -->
    - What CI did for the merge commit:
      `bash "${CLAUDE_PLUGIN_ROOT}/scripts/overlay.sh" close ci-publish-check`: on exit 0, the
      printed text names what to look at for `<merge_commit_sha>` — relay it, and read only what
      it names, never running a command it prints that writes anything — often a workflow run, read with
      `bash "${CLAUDE_PLUGIN_ROOT}/scripts/github.sh" run list <workflow-file> <merge_commit_sha>`,
      which prints each run's `status`, `conclusion` and `html_url` — and report what it shows,
      still running with its URL, failed loudly. When `run list` prints nothing, report it as
      no run found for the merge commit — the workflow was not triggered, or is not configured
      for that branch — a finding, not a blocker; on exit 3, there is no such check, and the report
      says nothing about CI; on exit 1, 2 or 4, report the one `codeo:` line it printed and carry
      on. Whatever it shows is reported, never a blocker.

14. **Release what the workflow holds, then confirm and delete the branch.**
    - `bash "${CLAUDE_PLUGIN_ROOT}/scripts/intake.sh" lease release-all <N>` — every lease this
      issue holds and every wait it still has queued: the environment, when neither qc nor the
      approval released it, and any other resource `/codeo:plan` took. A finished workflow keeps
      nothing. Quote what it prints, then confirm with
      `bash "${CLAUDE_PLUGIN_ROOT}/scripts/intake.sh" lease list` that nothing is left under `#<N>`.
      A release that fails is reported with its line and not retried in a loop; the rest of the
      phase still runs, and step 16 keeps the lock.

    <!-- rule: close-08 -->
    - Deleting the branch is the one destructive thing this skill does, so show the evidence from
      step 12 and ask once, in the conversation — a pick-one, delete or keep, recorded in step 15's
      comment. On a yes, delete the remote branch only if it still exists, since the repository may
      delete merged branches itself: `git ls-remote --exit-code --heads origin <branch>`, and on
      exit 0 `git push origin --delete <branch>`; exit 2 means it is already gone, and the report
      says so. Never the base branch, and never a force-push. A deletion that fails is reported
      with what git printed, and step 16 keeps the lock. The local branch stays in this checkout;
      step 17 says what is left of it.

    Declined, the branch is kept and the rest still runs; say so.

15. **Record it on the merged pull request.**
    <!-- rule: close-09 -->
    Nothing is committed to the base branch after the merge — the dossier reached it archived,
    with the merge — so this phase's record is one PR comment, not a dossier edit:
    `bash "${CLAUDE_PLUGIN_ROOT}/scripts/github.sh" pr comment <PR> <body-file>`, the body a
    `mktemp` file outside the working tree. It carries the merge commit and time, each check from
    steps 12 and 13 with its result, the board line, what was released (`release-all`'s output),
    what was deleted and what kept — with the engineer's answer at step 14 — and one line ending
    ` · cost: ` with what `bash "${CLAUDE_PLUGIN_ROOT}/scripts/usage.sh" close` prints. A comment
    that fails to post is reported loudly, with its body in the report, so the engineer can post it
    by hand. A re-run after step 16 kept the lock asks step 14's question again and posts a new
    comment: the earlier comment stands, and the new one records only what is new — the release or
    deletion that failed before, and how it went this time.

16. **Release the lock.**
    <!-- rule: close-10 -->
    Delete `.codeo/active` — last, so a failure anywhere above leaves the workflow intact and
    re-invokable rather than orphaned with no lock. When step 14's release or deletion failed,
    keep it: say what failed, and that running `/codeo:close` again in this checkout finishes the
    close.

17. **Report** that the workflow is finished. Read the lock's `host` line, and its `volume:` or
    `session:` line, before step 16 deletes it, and say what is left of this checkout.
    <!-- point: close/host-workflow -->
    Fetch the project's host workflow with
    `bash "${CLAUDE_PLUGIN_ROOT}/scripts/overlay.sh" close host-workflow`: on exit 0, relay the
    printed text to the engineer as what they do next with this checkout, filling in the lock's
    `volume:` or `session:` line where it asks — it is theirs to run, never this skill's; on exit 3, the default below, by the lock's host;
    on exit 1, 2 or 4, report the one `codeo:` line it printed and use the default.
    - **`host: web`** — nothing to remove: the hosted session is done once the engineer closes it.
    - **`host: container`** — the checkout is a container, which this skill cannot remove from
      inside it. Name the lock's `volume:` line, which identifies the container, and say that the
      container and its volume are the engineer's to remove.
    - **`host: local`** — nothing to remove: the checkout is the engineer's own, the local branch
      still in it, theirs to delete or keep.

    Everything in it is merged or on origin, so nothing is lost either way. Suggest
    `/codeo:triage`: the moment a dossier is archived is when what it noticed but did not file is
    easiest to lose. `superpowers:verification-before-completion` applies to every claim: each
    comes from a tool's output in this invocation — the merge from `github.sh`, the deletion from
    `git ls-remote`, the leases from `lease list`, the lock from `.codeo/active` being gone — never
    from a step having been attempted.

## Stash, and closed unmerged

**Putting the environment back.** A stash or an abandon lets go of the shared environment, and the
next holder deploys onto whatever this branch left there. The put-back runs when `$ENV_RESOURCE`
is set and `.codeo/<N>/implement.md` records a `Deployed revision:`; with no `$ENV_RESOURCE`, or no
revision recorded there, this branch never deployed and there is nothing to put back.

When `bash "${CLAUDE_PLUGIN_ROOT}/scripts/intake.sh" lease list` does not show this issue holding
`$ENV_RESOURCE` — qc released it at the clear verdict, or approval did — take it first:
`bash "${CLAUDE_PLUGIN_ROOT}/scripts/intake.sh" lease take "$ENV_RESOURCE" <N> "put-back"`, behind
any waiter, never with `--override`. A refusal — another holder, a waiter with right of way, a hook,
a stale base — means stop and ask, as a numbered question in `close.md` (step 0): wait, or proceed
without it. Proceeding without it still fetches the put-back below, does only the steps that do not
need the lease, and records every step that needs it as not put back.

On a re-run, when the stash or abandon round already records what the environment carries,
the put-back is done: skip it, and go on to the releases.

What the next deploy cannot repair on its own, and how to restore it to what the base branch
carries, is the project's:
<!-- point: close/put-back -->
fetch it with `bash "${CLAUDE_PLUGIN_ROOT}/scripts/overlay.sh" close put-back`: on exit 0, the
printed text is the put-back's steps in order, each marked irreversible or not — do them in that
order, under the rule below; on exit 3, there is no put-back — nothing is restored, so all of it
counts as not put back below: release what is held, and record what the environment carries;
on exit 1, 2 or 4, report the one `codeo:` line it printed and do as on exit 3.

<!-- rule: close-12 -->
Before anything irreversible — a step the put-back marks irreversible, or one that drops data or
destroys something it cannot recreate — **stop and show it to the engineer**, and do only what
they approve. Whatever was not put back is written into `close.md`'s outcome, beneath the stash or
abandon round, with the latest `Deployed revision:` in `implement.md`, so the next holder knows
what the environment is carrying: whatever was not put back is what the next holder's `/codeo:qc`
will name. A workload or resource this branch added is never removed by this skill, put-back or not: the next holder's `/codeo:qc` names it as an
orphan, a non-blocking finding, so it neither fails anyone's checks nor goes unnoticed. Only then
release.

**Stash** parks the work, deliberately and with a reason: the `--stash` argument, or the engineer
saying to park it.
<!-- rule: close-11 -->
Never infer a stash from a failing verdict — a change that isn't ready is a send-back, not a park;
step 2's stop leaves the lease held, the dossier live and the card where it is.

If the dossier is under `.codeo/done/<N>/`, move it back first — `git mv .codeo/done/<N> .codeo/<N>` —
since parked work is not finished work. Then add the next round to `close.md`'s `## Outcome` (the
next after the highest `### Round` there, or `### Round 1` when there is none), headed exactly:

<!-- example: stash -->
```markdown
### Round <n> — stashed
```

The heading is exactly that, with no date: the date goes in the first line beneath it and in the
`## Log` line. `claim.sh --stash-live` counts these headings, and `/codeo:init` resumes from them;
a date that breaks the `### Round <n> — ` prefix hides the park from it. Beneath the date, say why the work is
parked and what the next person needs to pick it up. Commit `close.md` (and the rename, when there
was one), staged by name, with the subject `docs(codeo): close dossier for #<N> — stashed`, and
push — a re-run that finds this round already at the tip adds no second one. From that push on,
`claim.sh --stash-live` already reads the stash as live; until the steps below finish, the issue
keeps its assignee and its card is not Ready, and those are what `/codeo:init`'s checks gate a
resume on. Then let go of what a parked workflow must not hold, in this order:

- Put the environment back, as above.
- `bash "${CLAUDE_PLUGIN_ROOT}/scripts/intake.sh" lease release-all <N>` — every lease the issue
  holds, the environment's and any other exclusive one, and every wait it still has queued. Quote
  what it prints; a release that fails is reported with its line and not retried in a loop.
- `bash "${CLAUDE_PLUGIN_ROOT}/scripts/github.sh" issue assignee-remove <N>`, so the team sees the
  issue is free. When `bash "${CLAUDE_PLUGIN_ROOT}/scripts/github.sh" user login` prints nothing,
  there is no login to remove: skip the call and say so rather than stopping, the same skip
  `/codeo:init`'s claim makes.
- With a board, `bash "${CLAUDE_PLUGIN_ROOT}/scripts/board.sh" set <N> "$READY"`, so the board
  shows it free too, and so `/codeo:init`, which starts only a Ready issue, can start it again.
  Handled as the preamble says: a failure is written into `close.md`'s outcome with `#<N>` and the
  status to move it to by hand, and never stops the stash.

Then write beneath the round what the environment is left carrying, when a `Deployed revision:`
was recorded, and append this invocation's `## Log` line — the date, the stash, what was released, the board
result, then ` · cost: ` with what `bash "${CLAUDE_PLUGIN_ROOT}/scripts/usage.sh" close` prints —
and commit `close.md`, staged by name, with the same subject, and push. Delete `.codeo/active`
last; when the release or a push failed, keep it, say what failed, and that running
`/codeo:close --stash` again in this checkout finishes the stash. Report that `/codeo:init #<N>`
resumes it, on any machine. Everything is pushed, so this checkout holds nothing the branch lacks:
say what is left of it as step 17 does, by the lock's host, read before the lock goes. An open pull
request stays open; say so.

**Closed unmerged** is the engineer's decision to read, not this skill's: ask, as a numbered
question in `close.md` (step 0), whether to reopen it (theirs to do on GitHub; running
`/codeo:close` again then finds it open), stash the work, or abandon it. Abandoning adds the next
round to `close.md`'s `## Outcome`, headed exactly:

<!-- example: abandon -->
```markdown
### Round <n> — abandoned
```

with the date and then the reason beneath it, never in the heading — it is the heading
`claim.sh --stash-live` reads, so `/codeo:init` stops an abandoned workflow as abandoned instead of
resuming it. Then everything a stash does, in the same order: the dossier back to `.codeo/<N>/` if
it was archived, committed and pushed with the subject
`docs(codeo): close dossier for #<N> — abandoned`; the environment put back; every lease released;
the assignee removed. Bar the board: an abandoned issue is not Ready, so with a board
`bash "${CLAUDE_PLUGIN_ROOT}/scripts/board.sh" set <N> "$BACKLOG"` moves its card there, handled
as a stash's is (`board: Backlog on #<n>…`, or `board: failed — <reason>` with the card left for
the engineer to move by hand). Then the `## Log` line and the last commit and push. It deletes
the branch only if the engineer asks, after the
same confirmation as step 14 — what the branch carries shown, and asked once, saying that
deleting an unmerged branch deletes the only copy of its dossier, `close.md` and the abandon round
included — with the same `git ls-remote` check, never the base branch, and never a force-push.
Work that never merged is kept unless someone says otherwise. Then the lock is deleted last, as a
stash does; a deletion that failed keeps it, as close-10 does on the merge path, and running
`/codeo:close` again finishes the abandon.

<!-- rule: close-13 -->
Never use `superpowers:finishing-a-development-branch`: it looks like this skill's twin and is
not, since it offers to merge locally and to discard work, and re-runs checks `/codeo:qc` already
ran.

## Hand-off

`${CLAUDE_PLUGIN_ROOT}/docs/handoff.md` is the protocol; this is this skill's half of it.

- **Reads** the lock, every dossier file — `qc.md`'s last round above all — and the pull request's
  state, reviews and checks on GitHub.
- **Writes** `.codeo/<N>/close.md` — its questions, its `## Outcome` rounds and one `## Log` line
  per invocation — and the commits carrying it and the archive moves; the clean base-branch merge
  step 9 makes on `BEHIND`, its one commit that is not a dossier commit; the pull request and its
  comments. Nothing else.
- **Deletes** `.codeo/active` and the merged branch on the remote — or, on an abandon, the
  unmerged one, only when the engineer asks — and moves the dossier directory
  in and out of `.codeo/done/`. It is the only skill that may do any of these.
- **Releases** every lease the issue holds at every exit — the merge, a stash, an abandon — and
  the environment at approval when it is still held; `/codeo:qc` normally released that already.
  It takes `$ENV_RESOURCE` only for a put-back, when the issue no longer holds it, and releases it
  with the rest. It removes the issue's assignee on a stash or an abandon, after putting the
  environment back.
- **Moves** the issue's board card through `board.sh`, with a board: In review when the pull
  request opens or is readied again, In progress on a send-back, Ready on a stash, Backlog on an
  abandon, Done once the merge is verified. Each move is part of its step, never a gate on it.
- **Never touches** code, tests, documentation pages, the plan's text, the issue's text, another
  skill's dossier file, or the base branch.
- **Hands off to** `/codeo:implement` when review asks for changes or the branch conflicts with
  the base branch — a send-back; otherwise nobody. The workflow ends when the merged branch is
  cleaned up and the lock released.
- **Spins out subagents** on the configured subagent model (`$SUBAGENT_MODEL`: `models.subagent`,
  sonnet when unset), passed explicitly on every dispatch, and prefers a direct `grep`/`Read` over
  an agent when the target is already known — see
  `${CLAUDE_PLUGIN_ROOT}/docs/handoff.md → Spinning out subagents`.

## Non-goals

- Doesn't merge, approve or review the pull request, and doesn't answer review comments on the
  implementer's behalf beyond step 7's summary of what changed.
- Doesn't re-run the build, the suites or the acceptance criteria — that is `/codeo:qc`'s, and
  re-running them here for a friendlier answer would defeat the gate.
- Doesn't fix anything — not a problem found on the way past, not a review comment. Those are
  send-backs.
- Doesn't delete a branch without GitHub's merged state, a tip that matches the pull request's
  head and the engineer's yes — except on an abandon, when the engineer asks in so many words,
  after the same confirmation — and never deletes the base branch, force-pushes, or rewrites
  history.
- Doesn't commit to the base branch. Its last commit is on the branch, before the merge.
- Doesn't start the next workflow. Releasing the lock is the invitation; `/codeo:init` is still
  the engineer's to run.
- Doesn't remove the checkout it runs in: removing the environment the engineer is looking at is
  theirs to do, and step 17 relays how, from the project's host workflow.
- Doesn't dispatch a workflow (`github.sh workflow dispatch`) or make any write an overlay's text
  prints: what `close/ci-publish-check` and `close/host-workflow` print is relayed and reported,
  never executed.

## Tips

- The pull request body is the last thing most people read about the change, and it is already
  written: the dossiers' outcomes have been accumulating it for four steps. Quote them rather than
  paraphrase them.
- A pull request waiting on review is not a stuck workflow; it is Phase 2. Running this skill again
  to ask "is it merged yet?" is cheap, and exactly what it is for.
- Release the lock last, in every exit. Any other order leaves a failure in which the workflow is
  unreachable and nothing records why.
