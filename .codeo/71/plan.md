# Issue #71 — plan

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/71 |
| Branch | `feat/file-new-issues-straight-board` |
| Updated | 2026-11-15 |

## Where this stands

Q1-Q5 are answered (all as recommended). The plan was approved and written to
`docs/plans/2026-11-15-file-new-issues-into-backlog.md` (unstaged, for review). Nothing is open
and no lock is needed. Next: `/codeo:implement`.

## Questions

### Q1 — When triage files an issue and you answer "not ready yet" to its follow-up, is that the one time triage asks about it?

**Why it matters:** `/codeo:triage` step 5 files an item through `/codeo:issue` and then asks
"is the new issue ready to work on?". Yes is a *mark Ready*, recorded as `issue:<N>` → `ready`.
The skill says nothing about a no. The original item's row says `filed #<N>`, but there is no
`issue:<N>` row, so today the next run finds an open, never-started issue with no ledger row
and asks again. After this change that issue is already in Backlog when the follow-up is asked.
The issue's answer was "triage asks once". This decides whether the follow-up counts as that
once, and so what step 5 records on a no.
**Options:**
- **A — a no is a *leave in the backlog* decision (recommended).** Triage records `issue:<N>` →
  `backlog` in the ledger, makes no `board.sh` call (the card is already in Backlog) and does not
  show the issue again. You were asked once, in the run that filed it.
- **B — a no records nothing.** The issue comes back in the next triage run as "filed, never
  started, board Status `Backlog`", and is decided there. You are asked twice about an issue you
  filed minutes earlier, but a no given in passing never hides it.

**Answer:**
A — a no is a *leave in the backlog* decision (answered in the conversation: "as recommended for all four").

### Q2 — #70 plans to edit the same skills, tests and docs: proceed alongside it, wait for it, or re-scope?

**Why it matters:** #70 (`feat/guard-home-only-skills-against`, assignee kbajpai, step `plan
(working)`; its dossier says the plan is approved and `/codeo:implement` is next) declares a
footprint that covers most of this one. `overlap.sh 71` prints, for #70: `glob:skills/**`,
`glob:tests/**`, `glob:docs/handoff.md`, `glob:docs/skills.md`, `glob:docs/skills-inventory.md`
and `glob:CHANGELOG.md`. Its branch has changed only its own plan file so far. From its plan,
#70 adds a guard step and an extension point to each of eight skills, `issue` and `triage`
included, and their entries in the three docs. This plan edits step 8 of `issue`, steps 4-5 and
the hand-off text of `triage`, the board paragraphs of `docs/handoff.md` and the `issue` and
`triage` sections of `docs/skills.md`. The two changes are in the same files but, as far as the
plans show, not the same paragraphs; `docs/skills-inventory.md` and `CHANGELOG.md` will each
take a line from both. The answer decides whether this plan carries a `sequenced:` line and
waits, or is built now and rebased by whichever branch merges second.
**Options:**
- **Proceed and coordinate (recommended).** Build now. Whichever of #70 and #71 merges second
  rebases; the expected conflicts are adjacent lines in `CHANGELOG.md` and
  `docs/skills-inventory.md`. This change is small, so it is the cheaper one to rebase if #70
  lands first.
- **Sequence after #70.** The footprint records `sequenced: after #70`, and `/codeo:implement`
  waits for #70 to merge. No rebase, but a small change waits behind a large one.
- **Re-scope.** Nothing in this issue can be dropped to avoid `skills/issue/SKILL.md` or
  `skills/triage/SKILL.md`, so this would mean handing the work to #70. Not recommended.

**Answer:**
Proceed and coordinate (answered in the conversation: "as recommended for all four").

### Q3 — #96 also adds a `CHANGELOG.md` entry: proceed and coordinate?

**Why it matters:** #96 (`feat/dev-container-follow-ups-40`, assignee kbajpai, step `plan
(working)`) names `CHANGELOG.md` in its footprint; `overlap.sh 71` prints `glob:CHANGELOG.md`
for #96. Nothing else overlaps. Both add a bullet under `## Unreleased`, so the second to merge
gets a conflict that is resolved by keeping both bullets.
**Options:** proceed and coordinate (recommended) · sequence after #96 · re-scope (not
possible: the release checklist wants every change in the changelog).

**Answer:**
Proceed and coordinate (answered in the conversation: "as recommended for all four").

### Q4 — #98 has already changed `CHANGELOG.md`: proceed and coordinate?

**Why it matters:** #98 (`fix/fix-sync-main-sh-exiting`, assignee kbajpai, step `implement
(working)`) names `CHANGELOG.md` in its footprint and its branch has changed the file;
`overlap.sh 71` prints both `CHANGELOG.md` and `glob:CHANGELOG.md` for #98. Nothing else
overlaps: its other files are `scripts/sync-main.sh`, `skills/plan/SKILL.md`, `docs/dossier.md`
and their tests. Same conflict as Q3, one bullet each under `## Unreleased`.
**Options:** proceed and coordinate (recommended) · sequence after #98 · re-scope (not
possible, as in Q3).

**Answer:**
Proceed and coordinate (answered in the conversation: "as recommended for all four").

### Q5 — #97 declares seven of the same files, `scripts/board.sh` among them: proceed and coordinate, sequence after #97, or re-scope?

**Why it matters:** #97 (`docs/docs-skill-wording-test-guard`, assignee kbajpai, step `init
(working)`; its branch has changed nothing yet) was pushed after Q2-Q4 were asked, so it was not in
that comparison. `overlap.sh 71` prints, for #97: `glob:CHANGELOG.md`, `glob:docs/handoff.md`,
`glob:docs/skills.md`, `glob:scripts/board.sh`, `glob:skills/triage/SKILL.md`,
`glob:tests/board.test.sh` and `glob:tests/closing-exits.test.sh`. #97 consolidates doc and
test-guard follow-ups from #34, #39 and #69, including a `board.sh set` message fix and edits to
`docs/skills.md`, `docs/handoff.md` and the triage skill. This plan touches the same files in
different places: a header comment in `scripts/board.sh` (no code), one added case in
`tests/board.test.sh`, one added case in `tests/closing-exits.test.sh`, the triage skill's
backlog wording, and the `issue` and `triage` sections of `docs/skills.md` and the board bullet
and tables of `docs/handoff.md`. The one real risk is `board.sh`: #97 changes its output, this
plan changes only its comment. The answer decides whether the plan carries a `sequenced:` line,
and whether two small edits are dropped to shrink the overlap.
**Options:**
- **Proceed and coordinate (recommended).** Build now; whichever of #97 and #71 merges second
  rebases. The overlaps are adjacent-line conflicts in the docs and test files; `scripts/board.sh`
  is a comment against a code change, so it merges cleanly unless #97 edits the same header lines.
- **Sequence after #97.** The footprint records `sequenced: after #97`, and `/codeo:implement`
  waits for #97 to merge. No rebase, but #97 is still at `init`, so the wait has no end in sight.
- **Re-scope.** Drop Task 3 (the `board.test.sh` pin, which only restates existing behaviour) and
  the `scripts/board.sh` header edit from Task 6. That removes two of the seven overlaps and loses
  nothing the acceptance criteria need.

**Answer:**
Proceed and coordinate (answered in the conversation: "as recommended").

## Notes

- Decided by the plan, no question needed:
  - **One pull request.** One issue, one branch; the change is skill text, its tests and the pages
    that restate it.
  - **Where the move goes.** `skills/issue/SKILL.md` step 8, after the dossier rename is committed
    and before the existing `board.sh status <N>` read: with a board,
    `board.sh set <N> backlog`. The status read and the three closing blocks stay as #69 left
    them, so the block is still chosen by what the board says: `Backlog` gives the *not Ready*
    block; a failed move is quoted with the fix the script names, and the read that follows
    decides the block (a missing `project` scope fails both and gives *Status unreadable*; a web
    session gives `unavailable`). With no board, no `board.sh` call at all.
  - **A new rule, `issue-08`:** a failed Backlog move never fails the filing; the number is still
    reported and returned to a caller. Listed in `docs/skills-inventory.md`.
  - **Triage's *leave in the backlog* on a card already in Backlog** records the decision and
    makes no `board.sh` call, as the issue says ("no card move needed"). Any other Status
    (`none`, `unset`, another column) still gets `board.sh set <N> backlog`, which also repairs a
    filing whose move failed. Triage's text gains the sentence that being in Backlog is not a
    triage decision: only a ledger row is.
  - **Tests are wording tests**, the form every skill test here has: new cases in
    `tests/issue-skill.test.sh` and `tests/closing-exits.test.sh` for the board step and the
    no-board path, and a new `tests/triage-skill.test.sh` for the triage wording.
- Shape: a plan under `docs/plans/`. No overlay for `plan-shape`, `proof-of-done` or
  `wiki-rules`; the `shell` suite has no `filter`, so a task's proof is its own test file run
  directly and the suite's `bash tests/run.sh` at the end. No invariants document, no shared
  environment, no `wiki` module, no exclusive resources.
- Pages the change moves: `docs/handoff.md` (the board bullet, its transition table and the
  ownership table), `docs/skills.md` (the `issue` and `triage` sections),
  `docs/skills-inventory.md`, the header comment of `scripts/board.sh`, `CHANGELOG.md`.

## Outcome

**Plan:** `docs/plans/2026-11-15-file-new-issues-into-backlog.md` — approved 2026-11-15, left unstaged for the engineer's review. Shape: an executable plan under `$PLANS` (six tasks, each test-first with its own proof), no separate reference doc; the decisions live in this dossier and in `docs/handoff.md`.

**Decisions.**
- Q1 = A: a "no, not ready yet" after triage files an issue is a *leave in the backlog* decision, recorded as `issue:<N>` → `backlog` with no board call, so it is asked once. Rejected: B, record nothing, which asks twice.
- Q2-Q5 = proceed and coordinate, for #70, #96, #98 and #97. Rejected: sequencing after each (#97 is still at `init`, so the wait has no end) and re-scoping (dropping the `board.test.sh` pin and the `board.sh` header edit would cut two of #97's seven overlaps). Whichever branch merges second rebases; on a conflict in `tests/fixtures/skills-inventory.rules.sha256`, regenerate it with `bash tests/inventory.test.sh --update`.
- One pull request. The Backlog move sits in `/codeo:issue` step 8, between the dossier commit and the status read; a failed move never fails the filing (new rule `issue-08`); with no board there is no `board.sh` call. `/codeo:triage` keeps asking about a Backlog issue with no ledger row and makes no `board.sh set` call for a card already in Backlog. `board.sh` itself is unchanged apart from its header comment.
- Proofs: wording tests in the `shell` suite (`bash tests/run.sh`); the first two acceptance criteria need a live board, so QC reports them `untestable` in the suite.

**Documentation the plan changes:** `docs/handoff.md` (the board bullet, its transition table, the ownership table), `docs/skills.md` (the `issue` and `triage` sections), `docs/skills-inventory.md` (`issue-08`), the header comment of `scripts/board.sh` and `CHANGELOG.md`. No intake question was resolved by this skill, and no `/codeo:issue` was filed.

### Footprint

```
files:      skills/issue/SKILL.md, skills/triage/SKILL.md, scripts/board.sh, tests/issue-skill.test.sh, tests/triage-skill.test.sh, tests/closing-exits.test.sh, tests/inventory.test.sh, tests/board.test.sh, tests/fixtures/skills-inventory.rules.sha256, docs/handoff.md, docs/skills.md, docs/skills-inventory.md, CHANGELOG.md, docs/plans/2026-11-15-file-new-issues-into-backlog.md
wiki:       none
exclusive:  none
sequenced:  none
```

## Log

- 2026-11-15 — Q1-Q4 raised; draft footprint under Notes · cost: 2m · fable-5-2 106k in + 770k cached / 11k out
- 2026-11-15 — Q1-Q4 answered; plan approved and written; Q5 raised (overlap with #97) · cost: 11m · fable-5-2 109k in + 902k cached / 12k out · sonnet-5-5 143k in + 1.7M cached / 25k out
- 2026-11-15 — planned: docs/plans/2026-11-15-file-new-issues-into-backlog.md · cost: 12m · fable-5-2 109k in + 902k cached / 12k out · sonnet-5-5 150k in + 2.4M cached / 29k out
