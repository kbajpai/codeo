# Issue #97 — implement

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/97 |
| Branch | `docs/docs-skill-wording-test-guard` |
| Updated | 2026-11-15 |

## Where this stands

Round 1. Q1 is answered (proceed and coordinate with #70). Building the plan task by task; tasks 1-8 first, then #98 and #70 are re-read before Task 9.

## Questions

### Q1 — #70 has now changed `skills/plan/SKILL.md`, `skills/triage/SKILL.md` and `tests/plan-skill.test.sh` on its branch. Proceed, sequence or re-scope?

**Why it matters:** #70 (`feat/guard-home-only-skills-against`, assigned to kbajpai, now at `implement`, working) has added a role-guard step to the head of `## Workflow` and a sentence to step 4 in `skills/plan/SKILL.md`, ten lines to `skills/triage/SKILL.md`, and four lines to `tests/plan-skill.test.sh`. The overlap check names it as `#70` with `skills/plan/SKILL.md`, `skills/triage/SKILL.md` and `tests/plan-skill.test.sh`. This issue's Task 3 changes one line of `skills/triage/SKILL.md` (the "adds the issue to the board" sentence, ~220), and Task 9 rewrites step 8's host-task paragraph and step 10's send-back paragraph in `skills/plan/SKILL.md` and their pins in `tests/plan-skill.test.sh`. The hunks are in different places, so the second branch to merge should rebase cleanly; sequencing would make Task 9 wait for #70 on top of its existing wait for #98 (now at `qc`). Q3 of the plan already answered *proceed and coordinate* for #70's wider overlap; this is the same pair with three more paths.
**Options:** proceed and coordinate · sequence after #70 · re-scope. **Recommendation:** proceed and coordinate, as Q3 did: build Tasks 1-8 now, and read both #98's and #70's merged text before Task 9.

**Answer:**
Proceed and coordinate (engineer, in the conversation, 2026-11-15: "go with the recommendation").

## Notes

## Outcome

_Pending — written at the hand-off._

## Log

- 2026-11-15 — Q1 raised before dispatch · cost: 3m · sonnet-5-5 11k in + 1M cached / 2k out
