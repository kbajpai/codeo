---
name: triage
description: Find the loose ends development left behind — non-blocking QC findings and implementation deviations nobody filed, stashed or abandoned workflows, branches with no PR, issue drafts never filed, issues never started, unresolved review threads on merged PRs — check each against existing issues, and ask the engineer what to do with each one; anything worth filing goes through /codeo:issue, and a filed issue the engineer calls workable moves to Ready on the project board. Trigger on "triage", "what did we forget", "any loose ends", "anything we should file", or after /codeo:close finishes a merge. Standalone and nearly read-only — its one write outside its ledger is a board card moved to Ready or Backlog on the engineer's say-so; never files an issue itself, never deletes or changes a branch.
argument-hint: "[optional: --docs to also scan Not-built lists in the project's docs and wiki, --todos for TODO/FIXME comments, --all for both]"
model: sonnet
---

Project overlay text adds to or narrows a step; it never overrides a rule marked with a "rule" comment in this file.

# Triage

Every step of the pipeline notices things that are real but not its job: `/codeo:qc` records
non-blocking findings, `/codeo:implement` records deviations and plan gaps, `/codeo:close`
stashes and abandons, and review threads get merged past. Nothing downstream picks those up — once
a dossier is archived, what it noticed is out of sight. This skill gathers them, checks each
against the issues that already exist, and asks the engineer, item by item, what to do.

**It decides nothing and changes nothing but its own ledger and, on the engineer's answer, the
board.** Filing goes through `/codeo:issue`, which stays the only author of issues and still
runs its own questions with the engineer. Resuming, stashing or deleting a branch is named as the
command to run, never run.

**It is what makes an issue startable.** `/codeo:init` starts only an issue whose Status on
the project board is **Ready** (when a board is configured), and this skill is where the engineer
says an issue is: *mark Ready* runs `bash "${CLAUDE_PLUGIN_ROOT}/scripts/board.sh" set <N> ready`. Its other card move is
*leave in the backlog* (`set <N> backlog`). Those card moves are the only changes it makes outside
its ledger, each only while acting on the engineer's answer. When the project has no board
(`board.sh` exits 3 and prints `board: not configured`), there is nothing to mark: say once, at the
start of the run, that the board is not configured and that Ready marking and the backlog move are
skipped, and carry on with every other step.

**It runs outside the workflow lock**, like `/codeo:issue`: it neither needs nor touches
`.codeo/active`, writes nothing into a running workflow's dossiers, and never commits to the
checked-out branch. It can run in the middle of another issue without disturbing it.

The repository is read from the project's config, never typed into a command:
`bash "${CLAUDE_PLUGIN_ROOT}/scripts/config.sh" get .repo.owner` and
`bash "${CLAUDE_PLUGIN_ROOT}/scripts/config.sh" get .repo.name`.

## Where it keeps its record

`.codeo/intake/triage/`, committed to the `codeo/intake` branch through
`bash "${CLAUDE_PLUGIN_ROOT}/scripts/intake.sh" commit triage "<message>"` — the same mechanism and
the same reasons as `/codeo:issue`'s dossiers (`${CLAUDE_PLUGIN_ROOT}/docs/dossier.md → Intake`):

- **`ledger.md`** — every item ever triaged and what was decided, so a run shows only what is new.
  <!-- rule: triage-01 -->
  The copy on the intake branch is authoritative: read it with
  `git show <intake tip>:.codeo/intake/triage/ledger.md`, never trust a stale local copy, and
  write the new version from that content. Another engineer's triage may land in between.
  `intake.sh commit triage` merges the two ledgers row by row on fingerprint, the later date
  winning, so neither run's decisions are lost.
- **`<YYYY-MM-DD>.md`** — one run's dossier: the items found, each a numbered question in
  `${CLAUDE_PLUGIN_ROOT}/docs/dossier.md`'s format, with its `## Outcome` and `## Log`. A second
  run on the same day adds `-2`.

The ledger's shape:

```markdown
| Fingerprint | Item | Decision | Date |
|---|---|---|---|
| `qc:12:P1` | The retry loop never caps its attempts | filed #15 | 2026-01-14 |
| `branch:spike/player` | Pushed, no PR, last commit 2025-12-30 | dismissed — throwaway spike | 2026-01-14 |
| `review:13:4417` | "Is this timeout meant to be configurable?" — unresolved | deferred | 2026-01-14 |
| `issue:17` | Filed 2026-01-08, no branch, board Status `Backlog` | ready | 2026-01-14 |
```

<!-- rule: triage-02 -->
**A fingerprint must survive the code moving**, so it names where the item came from, never a line
number: `qc:<N>:<finding id>` (`N1`, `P1`, … as the dossier numbers them, else a slug of the
finding's first words), `implement:<N>:<slug>`, `stash:<N>`, `branch:<name>`,
`intake:<dir>`, `issue:<N>`, `lease:<resource>:<N>`, `unclosed:<N>`, `review:<PR>:<comment id>`,
`doc:<path>:<slug>`, `todo:<path>:<slug of the comment>`.

## Workflow

0. **Resume or start.** `bash "${CLAUDE_PLUGIN_ROOT}/scripts/intake.sh" restore triage` brings the
   folder to a clone that lacks it; an error saying there is no intake branch, or that it has no
   `triage` directory, means a first run: start a new run. A run file with an open question is a
   run in progress: resume it at step 5 rather than starting another. Otherwise start a new run.

1. **Collect**, from what is pushed rather than what happens to be checked out:
   <!-- rule: triage-03 -->
   `git fetch origin`, then read other branches' files with `git show origin/<branch>:<path>` and
   `git ls-tree`, never by switching branches. By default the first three sources; the flags add
   the other two.

   1. **What the dossiers noticed and nobody filed** — under `.codeo/done/*/` on `origin/<base
      branch>` (the base branch is `bash "${CLAUDE_PLUGIN_ROOT}/scripts/config.sh" get .baseBranch`):
      - `qc.md`: every finding classified *not blocking*, every "follow-up" or "out of scope" item,
        every recommendation to open an issue.
      - `implement.md`: deviations from the plan and the plan gaps it reported.
      - any `## Outcome` or `## Notes` line promising later work without an issue number next to it.
   2. **Parked work:**
      - `bash "${CLAUDE_PLUGIN_ROOT}/scripts/inflight.sh"` for every workflow on a pushed branch,
        with its last step and assignee. One whose last step is weeks old, or assigned to nobody,
        is worth asking about.
      - `bash "${CLAUDE_PLUGIN_ROOT}/scripts/intake.sh" lease list`. The lease on the config's
        environment resource (`bash "${CLAUDE_PLUGIN_ROOT}/scripts/config.sh" get .environment.resource`)
        is held more than a day, or by an issue whose last `qc.md` round is clear or whose PR is
        approved or merged, is blocking every issue listed as waiting behind it — name them. A wait
        that has outlived its right of way is a finding too: the queue drops it at the next take,
        so the nudge is to take the lease. Releasing it is `/codeo:qc`'s, at its clear verdict, in
        the holder's checkout, never this skill's. These criteria apply only to that lease; when no
        environment resource is configured they do not apply at all. Every other lease is held
        from plan until close, so holding one for days is normal: flag it only when its holder's PR
        has merged or closed, or the holder has no workflow in flight, and say `/codeo:close` (its
        `lease release-all`) is what releases it. The fingerprint is `lease:<resource>:<N>`, and the
        options are *ask the holder* · *dismiss (why)*.
      - A workflow whose PR has merged but whose dossier is still at `.codeo/<N>/` on its
        branch, or whose branch is still on origin, never finished `/codeo:close` — and its
        checkout is probably still open on someone's machine. Fingerprint `unclosed:<N>`; options
        *finish it* (`/codeo:close` in that checkout, named) · *dismiss (why)*.
      - Branches on origin other than the base branch and `codeo/intake`, each looked up with
        `bash "${CLAUDE_PLUGIN_ROOT}/scripts/github.sh" pr list-for-branch <branch>`: no PR
        (`number` is null), or a PR closed unmerged (`state` is `closed` with `merged_at` empty),
        is parked. A `.codeo/<N>/close.md` on it recording a stash or an abandon says why. `pr
        list-for-branch` itself resolves to a single (the newest) match, so a branch carrying more
        than one PR — an older one still open against a base other than the base branch, shadowed
        by a newer closed-unmerged one — is not fully covered by this check; this is the same gap
        `/codeo:close` documents, not one this step closes.
      - On `codeo/intake`: a `new-<slug>/` directory is a draft never filed; an `<N>/` whose
        issue is open with no branch or PR is filed and never started.
      - Open issues with no branch or PR at all
        (`bash "${CLAUDE_PLUGIN_ROOT}/scripts/github.sh" issue list-all`, filtered to
        `state == "open"`), for the same reason. For each,
        `bash "${CLAUDE_PLUGIN_ROOT}/scripts/board.sh" status <N>`: one whose Status is already the
        Ready status (the option `board.statuses.ready` names, else `Ready`) is waiting
        on `/codeo:init`, not on a decision, and is listed as such rather than asked about.
        <!-- rule: triage-07 -->
        A source that is unavailable in a hosted web session is reported, never skipped silently:
        when the board is not configured, or the read is `unavailable` there, list the issue
        without that classification — as an ordinary item to ask about, since there is no board
        Status to tell it apart from one still undecided — and note in the run's `## Outcome` that
        board-status enrichment was unavailable, the same way source 1.3 reports itself skipped.
   3. **Unresolved review threads on merged PRs** — merged since the ledger's last run, or the last
      twenty on a first run.
      This one has no REST form: the session's proxy refuses GraphQL outside a pinned set of PR
      operations regardless of token, so a web-session run reports "review threads: skipped, run
      from a local checkout for this source" in its `## Outcome` and continues with every other
      source; a local checkout runs it as follows, with the owner and name read from the config as
      above:

      ```bash
      OWNER=$(bash "${CLAUDE_PLUGIN_ROOT}/scripts/config.sh" get .repo.owner)
      NAME=$(bash "${CLAUDE_PLUGIN_ROOT}/scripts/config.sh" get .repo.name)
      gh api graphql -f o="$OWNER" -f r="$NAME" -f query='
        query($o:String!,$r:String!){repository(owner:$o,name:$r){
          pullRequests(states:MERGED,last:20,orderBy:{field:UPDATED_AT,direction:ASC}){nodes{
            number mergedAt reviewThreads(first:50){nodes{isResolved
              comments(first:1){nodes{databaseId url path body}}}}}}}}'
      ```

   4. **`--docs`** — the *Not built*, *Open questions* and follow-up lists in the project's docs
      directory (`bash "${CLAUDE_PLUGIN_ROOT}/scripts/config.sh" get '.docsDir // "docs"'`) and,
      only when `wiki` is among the config's `modules`
      (`bash "${CLAUDE_PLUGIN_ROOT}/scripts/config.sh" get '.modules // []'`), its wiki pages, as
      they stand on `origin/<base branch>`: each bullet with no `#<N>` next to it.
   5. **`--todos`** —
      `git grep -n -E '\b(TODO|FIXME|HACK|XXX)\b' origin/<base branch> -- <pathspec exclusions>`.
      The weakest signal here: most are notes to self, which is why it is opt-in. The exclusions
      are the project's to name:

      <!-- point: triage/todo-excludes -->
      Fetch them with `bash "${CLAUDE_PLUGIN_ROOT}/scripts/overlay.sh" triage todo-excludes`: on
      exit 0, add the printed pathspecs (each as `':!<glob>'`) to the command; on exit 3, use the
      default: scan tracked files only, with no exclusions. On exit 1, 2 or 4 the script prints one `codeo:`
      line: report it to the engineer in the run's `## Outcome` and use the default.

   Collecting is lookup work — delegate a source to a subagent only when it is too large to read
   directly, and then on the configured subagent model (`models.subagent`, sonnet when unset),
   passed explicitly (`${CLAUDE_PLUGIN_ROOT}/docs/handoff.md → Spinning out subagents`).

2. **Drop what is already decided.** Fingerprint every item and look it up in the ledger. Filed,
   dismissed and already-tracked items are not shown again. Deferred ones are shown again, marked
   as such, with the date they were deferred.

3. **Check each against the issues that exist.** Fetch them once —
   `bash "${CLAUDE_PLUGIN_ROOT}/scripts/github.sh" issue list-all` — and match on meaning, not just
   words: a finding whose substance an issue already covers is
   <!-- rule: triage-04 -->
   "possibly #N", with the line of the issue that covers it. Say "possibly": the engineer confirms.

4. **Write the run's dossier and stop.** One numbered question per item, most actionable first —
   a real defect before a stale doc line before a parked branch. Each question carries:
   - **What** — the item in a sentence, and the evidence:
     <!-- rule: triage-09 -->
     quote the evidence, don't summarise it — the dossier line quoted, the branch and its last
     commit, the review comment's link. A finding that several dossiers mention is one item with
     several sources, not several items.
   - **Why it matters** — what goes wrong if it is left, in a sentence. If nothing does, say so;
     that is an argument for dismissing it.
   - **Options** that fit the kind of item:
     - a finding or a review thread: *file it* · *already #N* · *dismiss (why)* · *defer*;
     - parked work: *resume* (with a board, `board.sh set <N> ready` at step 5, then `/codeo:init #<N>` or
       `/codeo:close` on its branch — named, never run) · *file it* · *dismiss (why)* · *defer*.
       Deleting a branch is never an option here; it is the engineer's to do.
     - a filed issue never started: *mark Ready* (`board.sh set <N> ready`, run at step 5) ·
       *leave in the backlog* (the card moves to Backlog, run at step 5) —
       <!-- rule: triage-05 -->
       a backlog decision is recorded once and not shown again, because an issue on the tracker
       is not lost, and a report that re-lists the backlog every run stops being read. Say the
       issue's current board Status in the question. An issue already Ready is not asked about;
       the report names `/codeo:init #<N>` for it. With no board configured the options are instead
       *start it* (`/codeo:init #<N>`, named, never run) · *leave in the backlog* (recorded once in
       the ledger, no card move, no `board.sh` call) · *dismiss (why)*.

   Commit it — `bash "${CLAUDE_PLUGIN_ROOT}/scripts/intake.sh" commit triage "docs(codeo): triage dossier for <date> — Q1-Q<n> raised"`
   — then print the path and the numbers, and end the turn. Three items or fewer may go to the
   engineer in the conversation instead, as `${CLAUDE_PLUGIN_ROOT}/docs/dossier.md → Asking in the conversation instead`
   allows; record the answers in the file either way. A run that finds nothing new says so and
   writes only its `## Log` line.

5. **Act on the answers.** Re-read the file; follow-ups get new numbers, as in any dossier. Then,
   for each answered item:
   - **File it** → call `/codeo:issue` with the item and its evidence. It is a call, not a
     hand-off: `/codeo:issue` asks the engineer its own questions and returns a number. One at
     a time, in the order the engineer ranked them. Then ask, as a follow-up question, whether the
     new issue is ready to work on (with a board); yes is a *mark Ready*.
   - **Mark Ready** → `bash "${CLAUDE_PLUGIN_ROOT}/scripts/board.sh" set <N> ready`, which adds the
     issue to the board if it is not on it. Record `ready` and quote the line the script prints (it reports the old status, the new option and the project) in
     the run's `## Outcome`.
     <!-- rule: triage-06 -->
     A script failure — the `project` token scope is the likely one, and the script names the
     fix — is reported, the item stays unrecorded, and it comes back next run.
   - **Already #N** → record the number.
   - **Dismiss** → record the reason in the engineer's words.
   - **Defer** → record it; it comes back next run.
   - **Leave in the backlog** → with no board configured, only record it in the ledger (no
     `board.sh` call). With a board, `bash "${CLAUDE_PLUGIN_ROOT}/scripts/board.sh" set <N> backlog`.
     Record it, quoting the script's output line in the run's `## Outcome`, and note the backlog move (or its failure and the reason) in the
     `## Log` line; it does not come back. A
     script failure is reported, and the decision is still recorded — the issue is on the tracker
     either way.
   - **Resume** → with a board, `bash "${CLAUDE_PLUGIN_ROOT}/scripts/board.sh" set <N> ready` — the stash already
     set it, but a lost checkout may not have — recorded the same way, then name the command in the
     report. A script failure is reported and the resume still named.

6. **Record and report.** Append every decision to the ledger — built from the intake branch's
   copy, as above — write the run's `## Outcome` (what was found, what was decided, the issue
   numbers filed, the issues moved to Ready) and its `## Log` line
   (`<date> — <event> · cost: <output of bash "${CLAUDE_PLUGIN_ROOT}/scripts/usage.sh" triage>`, or
   `cost: unavailable`), and commit both through `intake.sh`. Report the issues filed, the issues
   moved to Ready (each with `/codeo:init #<N>` as its next step), the commands the engineer chose
   to run, and what was deferred. `superpowers:verification-before-completion` applies: each issue
   number comes from `/codeo:issue`'s result, each "Ready" from `board.sh`'s output, and
   "committed" from `intake.sh`'s output.

## Hand-off

`${CLAUDE_PLUGIN_ROOT}/docs/handoff.md` is the protocol; this is this skill's half of it.

- **Reads** anything: every branch's dossiers, the intake branch, issues, pull requests and their
  review threads, and — with the flags — the project's docs, its wiki pages and the code.
- **Writes** `.codeo/intake/triage/` — the ledger and the run files — committed to
  `codeo/intake` through `intake.sh`, never to the checked-out branch; and an issue's board
  Status, to **Ready** or **Backlog** only, only through `board.sh`, only on the engineer's *mark
  Ready*, *resume* or *leave in the backlog*.
- **Never touches** the issues themselves, any other board Status, any branch, the lock, the
  project's docs or wiki, code, or any other skill's dossier — including the archived ones it reads.
- **Calls** `/codeo:issue` for every item the engineer chooses to file, and records the number
  it returns. **Hands off to** nobody: what to resume, and when, is the engineer's.
- **Spins out subagents** on the configured subagent model (`models.subagent`, sonnet when unset),
  passed explicitly, and prefers a direct `grep`/`Read`/`git show` over an agent when the target is
  already known — see `${CLAUDE_PLUGIN_ROOT}/docs/handoff.md → Spinning out subagents`.

## Non-goals

- Doesn't file, edit, label or close issues — `/codeo:issue` files; the rest is the
  engineer's. Its board writes are Ready and Backlog: In progress is `/codeo:init`'s, and
  In review and Done are `/codeo:close`'s.
- Doesn't resume, stash, rebase or delete a branch, and doesn't open or close a PR. It names the
  command.
- Doesn't fix anything it finds, however small. A stale doc line is still an issue or a dismissal.
- <!-- rule: triage-08 -->
  Doesn't re-judge a finding `/codeo:qc` already classified — it asks whether the finding
  still deserves an issue, not whether it was right.
- Doesn't decide what is noise. It ranks and says why something might not matter; the engineer
  dismisses.

## Tips

- The ledger is what makes this worth running twice. A run that re-shows last week's dismissals
  gets skimmed, and then stops being run.
- Evidence beats summary: "qc.md for #12, *Not blocking — plan-level*, P1: the retry loop never caps
  its attempts" can be decided in seconds. "a retry concern" cannot.
