---
name: close
description: End a codeo workflow — open the pull request, wait for the engineer to merge it, route review feedback or a conflict with the base branch back through /codeo:implement and /codeo:qc, release the shared environment at approval when it is still held, then prove the merge, delete the remote branch on the engineer's yes, release every lease and the lock. Also the way to stash a workflow (park it, Ready to start again) or abandon it (back to the backlog). Trigger on "close", "close the workflow", "open the PR", "it's merged", "clean up", "stash this", "abandon this", or right after /codeo:qc returns a clear verdict. Never merges the PR and never writes code.
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
   | `--stash`, or the engineer parking the work | → **Stash** |
   | No pull request for the branch (`number` is null) | → **Phase 1 — open** |
   | `state` is `open`, dossier under `.codeo/done/<N>/` | → **Phase 2 — waiting** |
   | `state` is `open`, dossier back at `.codeo/<N>/` | → **Phase 1 — return from review** |
   | `state` is `closed` and `merged_at` is set | → **Phase 3 — clean up** |
   | `state` is `closed` and `merged_at` is empty | → **Closed unmerged** |

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
   send-back, which is a stop routed to `/codeo:qc`. Compare the round numbers only, never dates.

3. **The tree is clean and pushed.**
   <!-- rule: close-04 -->
   `git status --porcelain` prints nothing. Anything it does print — uncommitted code, a stray
   file — stops the skill and asks the engineer what it is: this skill commits its own dossier and
   nothing else, and never sweeps someone's work in progress into a pull request. A conflict with
   the base branch, below, is never resolved here either: resolving one is writing code, and the
   code is `/codeo:implement`'s.

   The branch has commits `origin/<base>` does not (`git log --oneline origin/<base>..HEAD`); none
   means `/codeo:implement` never landed anything — say so and stop. `git status -sb` shows nothing
   ahead of upstream, since every step pushed its own dossier; commits ahead mean an earlier push
   never landed, so say so and `git push` them (they are committed work, not swept work), and a
   branch with no upstream at all is a stop.

   **It still merges.** Other workflows merge to `<base>` while this one runs. Run
   `git fetch origin`, then `git merge-tree --write-tree origin/<base> HEAD`. Exit 0 is a clean
   merge. Exit 1 is a conflict, and its output lists the conflicting files; any other exit is a
   stop — report what git printed. A conflict is a send-back to `/codeo:implement`, the same as
   review feedback:
   - Add `### Round <n> — conflicts with <base>` to `close.md`'s `## Outcome` — the next round
     after the highest `### Round` already there, or `### Round 1` when there is none — with the
     date as its first line, then each conflicting file and the changes on `<base>` that touched it
     (`git log --format='%h %s' $(git merge-base origin/<base> HEAD)..origin/<base> -- <file>`;
     their subjects usually carry the pull request number), then the `qc round at review: <k>` line
     close-03 above requires.
   - Append this invocation's `## Log` line, ending ` · cost: ` with what
     `bash "${CLAUDE_PLUGIN_ROOT}/scripts/usage.sh" close` prints.
   - Commit `close.md`, staged by name, with the subject
     `docs(codeo): close dossier for #<N> — conflicts with <base>`, and push.
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
   It prints `{number, html_url}`; those are what step 5 records. A non-zero exit is a stop: report
   its one line, and nothing below runs.

5. **Record it.** Write `close.md`'s `## Outcome`: the pull request's number and URL as the
   response printed them, not reconstructed; the `qc.md` round and verdict it went out on; any
   override from step 2, verbatim; and the date. A return from review instead adds the next
   `### Round <n>` beneath the last, saying which review round it answers and which `qc.md` round
   cleared it.

   **Move the card** — with a board — `bash "${CLAUDE_PLUGIN_ROOT}/scripts/board.sh" set <N> "$IN_REVIEW"`,
   once the pull request is open; on a return from review the same call puts it back, since the
   send-back moved it to `$IN_PROGRESS`. Exit 3 (`board: not configured`) skips it. The card is
   handled as the preamble says: never a gate on the pull request or the dossier.

   Append one `## Log` line: the date, what this invocation did, the board result, then ` · cost: `
   with what `bash "${CLAUDE_PLUGIN_ROOT}/scripts/usage.sh" close` prints.

6. **Archive the dossier.** `git mv .codeo/<N> .codeo/done/<N>` — the files are tracked, so git
   records a rename. The archive reaches `<base>` with the merge, which is the only way it can:
   nothing is committed to the base branch after the merge. It is also what lets the `qc-verdict`
   check pass, since that check fails closed on a live dossier.

7. **Commit and push.** One commit carrying `close.md` and the rename, staged by name — the
   rename `git mv` staged, and `.codeo/done/<N>/close.md` — with the subject
   `docs(codeo): close dossier for #<N> — PR #<pr>` (`— round <n>` on a return from review;
   `${CLAUDE_PLUGIN_ROOT}/docs/dossier.md → Durability`). Then `git push`; the open pull request
   picks it up. A failed push is reported loudly and the commit kept: the pull request does not
   carry the archive until it lands. On a return from review, also leave one comment on the pull
   request — `bash "${CLAUDE_PLUGIN_ROOT}/scripts/github.sh" pr comment <PR> <body-file>` — listing,
   for each review point, what changed, quoted from `implement.md`'s latest round, so the reviewer
   does not have to diff to find out.

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
   approval with no merge yet, step 10 runs and the watch is offered again for the merge.

   When the lock's `host` is `web`, the watch is unavailable — background work does not survive the
   hosted session being reclaimed — so say that instead, and offer only running `/codeo:close`
   again to check on the pull request.

<!-- steps 9-17, stash and abandon, hand-off and non-goals are added by the next tasks -->
