# Issue #97 — implement

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/97 |
| Branch | `docs/docs-skill-wording-test-guard` |
| Updated | 2026-11-15 |

## Where this stands

Round 1. Tasks 1-8 are built and reviewed (commits ce0b13d..63e6a50); `origin/main` (with #98) is merged in. Q1 and Q2 are answered; Q3 (#70's glob pairing with `tests/close-skill.test.sh`) is open, so Tasks 9-10 wait. The task ledger is in `.superpowers/sdd/` (git-ignored).

## Questions

### Q1 — #70 has now changed `skills/plan/SKILL.md`, `skills/triage/SKILL.md` and `tests/plan-skill.test.sh` on its branch. Proceed, sequence or re-scope?

**Why it matters:** #70 (`feat/guard-home-only-skills-against`, assigned to kbajpai, now at `implement`, working) has added a role-guard step to the head of `## Workflow` and a sentence to step 4 in `skills/plan/SKILL.md`, ten lines to `skills/triage/SKILL.md`, and four lines to `tests/plan-skill.test.sh`. The overlap check names it as `#70` with `skills/plan/SKILL.md`, `skills/triage/SKILL.md` and `tests/plan-skill.test.sh`. This issue's Task 3 changes one line of `skills/triage/SKILL.md` (the "adds the issue to the board" sentence, ~220), and Task 9 rewrites step 8's host-task paragraph and step 10's send-back paragraph in `skills/plan/SKILL.md` and their pins in `tests/plan-skill.test.sh`. The hunks are in different places, so the second branch to merge should rebase cleanly; sequencing would make Task 9 wait for #70 on top of its existing wait for #98 (now at `qc`). Q3 of the plan already answered *proceed and coordinate* for #70's wider overlap; this is the same pair with three more paths.
**Options:** proceed and coordinate · sequence after #70 · re-scope. **Recommendation:** proceed and coordinate, as Q3 did: build Tasks 1-8 now, and read both #98's and #70's merged text before Task 9.

**Answer:**
Proceed and coordinate (engineer, in the conversation, 2026-11-15: "go with the recommendation").

### Q2 — #70's footprint now covers four more test files this issue has changed. Proceed, sequence or re-scope?

**Why it matters:** raised by the overlap check run after Task 6 and the merge of `origin/main` (which brought in #98). #70 (`feat/guard-home-only-skills-against`, assigned to kbajpai, now at `qc`, working) prints as `#70` with `tests/board.test.sh`, `tests/overlap.test.sh`, `tests/qc-verdict.test.sh` and `tests/skills-doc.test.sh`. None of the four is changed on #70's branch: they are paired only because #70's `files` list has the glob `tests/**` and Tasks 1, 3, 4, 5 and 6 here changed them. Q3 of the plan and Q1 here already answered *proceed and coordinate* for #70 and `tests/**`, and its qc is nearly done, so the second to merge rebases. No sequencing is needed unless #70's QC adds edits to those four files.
**Options:** proceed and coordinate · sequence after #70 · re-scope. **Recommendation:** proceed and coordinate, as Q1.

**Answer:**
Proceed and coordinate (engineer, in the conversation, 2026-11-15).

### Q3 — #70's `tests/**` glob now pairs with `tests/close-skill.test.sh`, which Task 7 changed. Proceed, sequence or re-scope?

**Why it matters:** raised by the overlap check run before Task 9. #70 (`feat/guard-home-only-skills-against`, assigned to kbajpai, at `qc`, working) prints as `#70` with `tests/close-skill.test.sh`. Task 7 added pins for close step 17's lead and the two abandon blocks there; #70's `files` list has the glob `tests/**`, and its branch also changes `skills/close/SKILL.md`, so a pin in this file could collide with one #70 adds for its own step 17 text. Q1 and Q2 answered *proceed and coordinate* for #70's other paths. The remaining tasks (9, 10) change only `skills/plan/SKILL.md`, `tests/plan-skill.test.sh`, `docs/dossier.md` and `CHANGELOG.md`, each already named in an answered question, so no further pairing with #70 is expected.
**Options:** proceed and coordinate · sequence after #70 · re-scope. **Recommendation:** proceed and coordinate, as Q1 and Q2.

**Answer:**

## Notes

## Outcome

_Pending — written at the hand-off._

## Log

- 2026-11-15 — Q1 raised before dispatch · cost: 3m · sonnet-5-5 11k in + 1M cached / 2k out
- 2026-11-15 — Tasks 1-6 built and reviewed, origin/main merged; Q2 raised before Task 7 · cost: 17m · sonnet-5-5 525k in + 20.2M cached / 80k out
- 2026-11-15 — Tasks 7-8 built and reviewed; Q3 raised before Task 9 · cost: 32m · sonnet-5-5 694k in + 26.8M cached / 114k out
