# Issue #71 — plan

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/71 |
| Branch | `feat/file-new-issues-straight-board` |
| Updated | 2026-11-15 |

## Where this stands

Q1-Q4 are answered (all as recommended). The plan is drafted at .codeo/71/plan-draft.md and awaits the engineer's approval; nothing is open.
The overlaps with #70, #96 and #98 were answered *proceed and coordinate*, so the footprint
carries no `sequenced:` line.

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

### Footprint

```
files:      skills/issue/SKILL.md, skills/triage/SKILL.md, scripts/board.sh, tests/issue-skill.test.sh, tests/triage-skill.test.sh, tests/closing-exits.test.sh, tests/inventory.test.sh, tests/board.test.sh, tests/fixtures/skills-inventory.rules.sha256, docs/handoff.md, docs/skills.md, docs/skills-inventory.md, CHANGELOG.md, docs/plans/2026-11-15-file-new-issues-into-backlog.md
wiki:       none
exclusive:  none
sequenced:  none
```

## Outcome

_Pending — written at the hand-off._

## Log

- 2026-11-15 — Q1-Q4 raised; draft footprint under Notes · cost: 2m · fable-5-2 106k in + 770k cached / 11k out
