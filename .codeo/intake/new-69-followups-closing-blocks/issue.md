# Issue (new) — Close #69's follow-ups: the abandon exit's closing block, the guards that miss a partial revert, and the wording gaps

| | |
|---|---|
| Source | `/codeo:triage` run 2026-11-14-6, Q1-Q5, engineer: "File all of them & try to combine them in one issue" |
| Updated | 2026-11-14 |

## Where this stands

Two questions are open before the draft goes to review. The problem restated: #69 (merged as PR #72) made every closing block name only a command that can run, but its QC left five non-blocking groups of follow-ups. The one that matters is that `/codeo:close`'s abandon exit still has no closing block and borrows the stash blocks by analogy, so the rule #69 wrote does not cover every `/codeo:close` exit. The rest are test guards that miss a partial revert, two incomplete rows in `docs/handoff.md`'s exceptions table, wording gaps in `skills/plan/SKILL.md` and `CHANGELOG.md`, and left minors. No duplicate: searches for the abandon block, the closing-exits test, the exceptions table and the shell-neutral rule found only #69 itself (closed).

## Questions

### Q1 — How does this issue relate to #70, which edits the same `/codeo:close` text?

**Why it matters:** #70 ("Guard the home-only skills …, print removal commands at close …", Ready) edits `skills/close/SKILL.md` step 17 and `docs/handoff.md`, and this issue adds blocks to the same skill and rows to the same table. Whichever is planned second has to reconcile with the first. It changes whether the issue states a sequence or leaves it to `/codeo:plan`'s overlap check.
**Options:**
- **A — independent; name the shared files under Reference (recommended).** No sequencing is promised. `/codeo:plan`'s footprint check raises the overlap when the second one is planned, which is what that check is for.
- **B — this issue waits for #70.** It then builds on #70's step 17 text, but blocks starting until #70 merges.
- **C — fold the abandon exit into #70.** #70 is already large and is a different concern (home-only guard, cleanup commands).

**Answer:**
_Pending._

### Q2 — Are the left minors (item 5) requirements or a list to address?

**Why it matters:** items 1-4 are defects or gaps with a clear done-state. Item 5 is seven small things a reviewer left unfixed (FAIL lines to stdout, long lines in `skills/issue/SKILL.md`, `docs/skills.md` lines that do not enumerate every exit, step 17's unconditional lead "Report that the workflow is finished", Task 10's wrapping, a missing-row message, an empty-`step` guard). Written as acceptance criteria, each becomes a hard gate; as a list, `/codeo:plan` decides.
**Options:**
- **A — a list the plan takes or dismisses, each with a reason (recommended).** One acceptance criterion: every item in the list is fixed or dismissed in `plan.md` with a reason; the step-17 lead and the empty-`step` guard are named as the two worth fixing.
- **B — every minor is its own acceptance criterion.** Nothing is left unfixed, at the cost of a longer issue and a larger pull request.

**Answer:**
_Pending._

## Outcome

_Pending — written at the hand-off._

## Log

- 2026-11-14 — filed from triage Q1-Q5; Q1-Q2 raised · cost: pending
