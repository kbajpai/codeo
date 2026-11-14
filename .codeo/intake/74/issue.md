# Issue #74 — issue

| | |
|---|---|
| Source | `/codeo:triage` run 2026-11-14-6, Q1-Q5, engineer: "File all of them & try to combine them in one issue" |
| Updated | 2026-11-14 |

## Where this stands

Approved and filed as #74 (https://github.com/kbajpai/codeo/issues/74). The problem restated: #69 (merged as PR #72) made every closing block name only a command that can run, but its QC left five non-blocking groups of follow-ups. The one that matters is that `/codeo:close`'s abandon exit still has no closing block and borrows the stash blocks by analogy, so the rule #69 wrote does not cover every `/codeo:close` exit. The rest are test guards that miss a partial revert, two incomplete rows in `docs/handoff.md`'s exceptions table, wording gaps in `skills/plan/SKILL.md` and `CHANGELOG.md`, and left minors. No duplicate: searches for the abandon block, the closing-exits test, the exceptions table and the shell-neutral rule found only #69 itself (closed).

## Questions

### Q1 — How does this issue relate to #70, which edits the same `/codeo:close` text?

**Why it matters:** #70 ("Guard the home-only skills …, print removal commands at close …", Ready) edits `skills/close/SKILL.md` step 17 and `docs/handoff.md`, and this issue adds blocks to the same skill and rows to the same table. Whichever is planned second has to reconcile with the first. It changes whether the issue states a sequence or leaves it to `/codeo:plan`'s overlap check.
**Options:**
- **A — independent; name the shared files under Reference (recommended).** No sequencing is promised. `/codeo:plan`'s footprint check raises the overlap when the second one is planned, which is what that check is for.
- **B — this issue waits for #70.** It then builds on #70's step 17 text, but blocks starting until #70 merges.
- **C — fold the abandon exit into #70.** #70 is already large and is a different concern (home-only guard, cleanup commands).

**Answer:**
A — independent; name the shared files under Reference (answered in the conversation: "A and A, as recommended").

### Q2 — Are the left minors (item 5) requirements or a list to address?

**Why it matters:** items 1-4 are defects or gaps with a clear done-state. Item 5 is seven small things a reviewer left unfixed (FAIL lines to stdout, long lines in `skills/issue/SKILL.md`, `docs/skills.md` lines that do not enumerate every exit, step 17's unconditional lead "Report that the workflow is finished", Task 10's wrapping, a missing-row message, an empty-`step` guard). Written as acceptance criteria, each becomes a hard gate; as a list, `/codeo:plan` decides.
**Options:**
- **A — a list the plan takes or dismisses, each with a reason (recommended).** One acceptance criterion: every item in the list is fixed or dismissed in `plan.md` with a reason; the step-17 lead and the empty-`step` guard are named as the two worth fixing.
- **B — every minor is its own acceptance criterion.** Nothing is left unfixed, at the cost of a longer issue and a larger pull request.

**Answer:**
A — a list the plan takes or dismisses, each with a reason (answered in the conversation: "A and A, as recommended").

## Outcome

Filed as #74, Issue Type none, labels `enhancement` and `documentation`. Status on the board: not yet read.

## Log

- 2026-11-14 — filed from triage Q1-Q5; Q1-Q2 raised · cost: pending

## Draft for review

**Title:** Close the follow-ups #69 left: the abandon exit's closing block, guards that miss a partial revert, and wording gaps

**Issue Type:** none (the repository has no Issue Types)
**Labels:** `enhancement`, `documentation`

### Description

#69 made every `/codeo:close`, `/codeo:init`, `/codeo:issue` and stash closing block name only a command that can run, and wrote that rule once in `docs/handoff.md → Closing block`. Its QC (`.codeo/done/69/qc.md`, round 2) left follow-ups that did not block the merge. The one that matters: `/codeo:close`'s abandon exit still has no closing block and borrows the stash blocks by analogy, so the rule does not cover every `/codeo:close` exit. The others are test guards that miss a partial revert, two incomplete rows in `docs/handoff.md`'s exceptions table, wording gaps in `skills/plan/SKILL.md` and `CHANGELOG.md`, and minors the reviewers left unfixed. This issue gathers them.

### Motivation / Context

- **The abandon exit.** `skills/close/SKILL.md`, *Closed unmerged* (about lines 634-659), says "Then everything a stash does, in the same order … Then the lock is deleted last, as a stash does; a deletion that failed keeps it, as close-10 does on the merge path, and running `/codeo:close` again finishes the abandon." It names no closing block. A reader can end with `/codeo:init #<N>`, which refuses an abandoned workflow, or with `/codeo:close --stash`, which would turn the abandon into a stash. `docs/handoff.md` still lists close's exits as "waiting on a merge, sent back, finished or stashed", and its "Exits whose next command is not the default" table has no abandon row.
- **Guards that miss a partial revert.** `tests/closing-exits.test.sh` reads each skill's labelled `**Closing block — <exit>:**` paragraph, so an old sentence restored beside it passes: the stash line "Report that `/codeo:init #<N>` resumes it", and step 17's unconditional "End with the closing block: … the first step `/codeo:triage`, then the host clean-up". `/codeo:init` already has such a guard (a `lacks` check on step 11 for "Either way, end with the closing block"); close step 17 and the stash prose do not, and `tests/close-skill.test.sh` covers step 17 only in part.
- **The exceptions table.** In `docs/handoff.md`, the `init — no lock` row says "then `lock.sh take local` again" unconditionally, but with a host workflow the recovery is what the host's text names (`skills/init/SKILL.md`, step 11), and on `host: container` `scripts/lock.sh` can print a `lock: TODO` line after taking the lock. And there is no row for `/codeo:issue`'s "Status unreadable" exit, whose first step (the fix its line names) is not the default.
- **Plan skill wording.** `skills/plan/SKILL.md` step 8, the host-task paragraph: it defines a host task as one run "outside this session's checkout" and then includes `host: local` on Windows, which is the same checkout; it says to label `Shell: <name>` and then ask, where the working order is ask, then label; and its "neutral" list leaves out single-quoted arguments, globs, `~` and `./script`, which also differ between bash, PowerShell and cmd. `CHANGELOG.md`'s #69 entry says commands are written shell-neutral and omits the other branch: a command that cannot be neutral is asked about and labelled `Shell: <name>`.
- **Left minors.** Left unfixed by the implementers' and reviewers' passes (`.codeo/done/69/implement.md`): `tests/closing-exits.test.sh` prints FAIL lines to stdout where `tests/closing-block.test.sh` uses stderr; long single lines in `skills/issue/SKILL.md`; `docs/skills.md` lines that do not enumerate every exit; step 17's lead "Report that the workflow is finished" is unconditional; the host-task paragraph's ragged wrapping and its overlap on the `Shell: <name>` label; in `tests/closing-exits.test.sh`, a missing `init — no lock` row fails with a message that does not say the row is gone, and `case_init_no_lock`'s step-11 guard passes on an empty `step` result (`issue_step8` guards that).

### Key Requirements

- Every `/codeo:close` exit that ends in a closing block names a command that can run in the state it leaves. The abandon exit gets its own labelled blocks for both outcomes: the abandon finished (the lock deleted) and the abandon interrupted (the lock kept, because the branch deletion failed), the latter naming `/codeo:close` first and neither naming `/codeo:init #<N>` or `/codeo:close --stash`.
- `docs/handoff.md`'s closing-block text lists the abandon among close's exits, and its exceptions table has a row for each new abandon exit and for `/codeo:issue`'s "Status unreadable"; the `init — no lock` row says the recovery is the fix the `lock: TODO` line names (and, with a host workflow, what the host's text names), not `lock.sh take local` unconditionally.
- A test fails when an old unconditional sentence is restored beside the labelled paragraphs in close step 17 and in the stash prose, as it already does for init step 11; the new abandon blocks are read by `tests/closing-exits.test.sh` like the others.
- `skills/plan/SKILL.md`'s host-task paragraph is consistent: what counts as a host task covers `host: local` on Windows without calling it outside the checkout, the shell is asked and then labelled, and the "neutral" list covers what differs between bash, PowerShell and cmd. `CHANGELOG.md` says both branches of the rule.
- The left minors are a list `/codeo:plan` takes or dismisses, each with a reason in `plan.md`. The step-17 lead "Report that the workflow is finished" (unconditional) and the empty-`step` guard in `case_init_no_lock` are the two worth fixing.

### Acceptance Criteria

- [ ] `/codeo:close`'s abandon exit ends with a closing block: after a finished abandon, the next goal and first step name a command that can run with the lock gone; after an abandon that kept the lock, the first step is `/codeo:close`, and neither block names `/codeo:init #<N>` or `/codeo:close --stash`.
- [ ] `docs/handoff.md` lists the abandon among close's exits and has an exceptions-table row for each new abandon exit and for `/codeo:issue`'s "Status unreadable" exit, and its `init — no lock` row no longer names `lock.sh take local` unconditionally.
- [ ] `tests/closing-exits.test.sh` has a case for each new abandon block, and a check that fails when the old unconditional sentences are put back in close step 17 and in the stash prose (the case is shown to bite against a copy with the sentence restored).
- [ ] `skills/plan/SKILL.md`'s host-task paragraph no longer contradicts itself on `host: local` on Windows or on the order of asking and labelling, its "neutral" list names single-quoted arguments, globs, `~` and `./script`, and `tests/plan-skill.test.sh` pins the changes.
- [ ] `CHANGELOG.md` has an `## Unreleased` entry for this change that says both branches of the host-task rule.
- [ ] Every left minor listed above is fixed or dismissed with a reason in `plan.md`, and step 17's unconditional lead and the empty-`step` guard are fixed.
- [ ] `bash tests/run.sh` passes.

### Out of Scope

- #70 (home-only skill guard, close-time removal commands, a print-only `/codeo:cleanup`). It also edits `skills/close/SKILL.md` step 17 and `docs/handoff.md`, so the two overlap; no sequence is promised here, and `/codeo:plan`'s footprint check raises the overlap when the second one is planned.
- Closing blocks for `/codeo:close`'s other stops that predate #69 and were not named there (step 12's merge-proof stop, a stash's failed assignee removal).
- Whether `/codeo:implement` should treat a `Runs on: the engineer's host` task differently.
- The open dev container follow-ups #40, #51, #54 and #57.

### Reference

- Surfaced by `/codeo:qc` round 2 of #69 (`.codeo/done/69/qc.md`, G1-G7) and `.codeo/done/69/implement.md` (left minors), merged as PR #72; filed from `/codeo:triage` run 2026-11-14-6, Q1-Q5.
- `docs/handoff.md → Closing block`; `skills/close/SKILL.md` (step 17, *Stash*, *Closed unmerged*); `skills/init/SKILL.md` (step 11); `skills/plan/SKILL.md` (step 8); `tests/closing-exits.test.sh`; `tests/close-skill.test.sh`; `tests/plan-skill.test.sh`; `scripts/lock.sh`.
- #70, the overlapping open issue; #69, closed.
- 2026-11-14 — approved and filed as #74 · cost: 4m · sonnet-5-5 18k in + 2.5M cached / 11k out
