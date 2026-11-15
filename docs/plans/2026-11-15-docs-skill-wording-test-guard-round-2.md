# Docs, skill wording and test-guard follow-ups (#97), round 2 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Close the three blocking findings `/codeo:qc` raised on round 1 (`.codeo/97/qc.md`, F1-F3) and take the small non-blocking ones that sit in files this round already edits (F4-F7, F9).

**Architecture:** Round 1's plan (`docs/plans/2026-11-15-docs-skill-wording-test-guard.md`) is built and stays as it is; this plan adds only what the send-back asks for. The #74 guards are widened to the old sentences the issue names and shown to bite when they are restored as they were originally wrapped. `/codeo:qc`'s footprint rule is made to agree with the `qc-verdict` check round 1 added: a path outside the footprint is blocking once the plan has a second round (Q7 (a)).

**Tech Stack:** bash; tests are `tests/*.test.sh` run by `bash tests/run.sh [name-fragment]`.

**Spec:** GitHub issue #97 and `.codeo/97/init.md`; round 1's findings in `.codeo/97/qc.md` (`### Round 1`); decisions in `.codeo/97/plan.md` (Q1-Q7).

## Global Constraints

- One suite, `shell`: build `true`, test `bash tests/run.sh`. A task's proof is `bash tests/run.sh <fragment>`; the last task runs the whole suite. No invariants document, wiki module, shared environment or `resources[]` is configured: no `Needs lease:`, no `Runs on:`, no wiki page.
- Tests print `FAIL: <what>` and exit non-zero, and `all cases passed` on success. A guard is shown to bite: the task restores the old text in a scratch copy **as it was originally wrapped**, and the test must then fail by name.
- Closing blocks name only a command that can run in the state the exit leaves; a block forbidden to name a command must not contain its text (`docs/handoff.md → Closing block`).
- Documentation describes what the system does now: present tense, no issue numbers (the changelog's own `(#97)` ref excepted).
- Other workflows: #70 also edits `skills/close/SKILL.md`, `docs/skills.md` and `tests/**`; #71 edits `scripts/board.sh` and `tests/closing-exits.test.sh`. Both were answered *proceed and coordinate* (round 1, Q1-Q6; `implement.md` Q1-Q3). Keep each edit to the lines a task names so the second branch to merge rebases cleanly.
- Out of scope, taken to `/codeo:triage` rather than done: F8 (a paging `gh` stub; a larger rewrite of `tests/board.test.sh`, which #71 edits, and the `--paginate` assertion already bites) and F10 (`skills/init/SKILL.md` says "there is no lock" after any `lock: TODO`, which is `init`'s behaviour question). The minors carried from `implement.md` stay recorded there.
- Documentation moved by this round: `docs/skills.md` (`qc` entry), `skills/qc/SKILL.md`, `skills/plan/SKILL.md`, `skills/close/SKILL.md`, `scripts/overlap.sh`'s header comment, `CHANGELOG.md`. Each has its own task.

## Review Focus

- The step 17 and stash guards must catch the old sentences with a line break in the middle, not only on one line (Task 1).
- A first-round plan keeps the non-blocking rule for a path outside its footprint; only a plan with `### Round 2` or later blocks (Task 3).
- No pin may be left matching text that Tasks 2-4 reword (Tasks 2-4).

## File Structure

| File | Responsibility | Tasks |
|---|---|---|
| `tests/closing-exits.test.sh` | closing-block guards and their scratch-copy bite proofs | 1, 2 |
| `skills/close/SKILL.md` | abandon-finished block wording | 2 |
| `skills/qc/SKILL.md`, `tests/qc-skill.test.sh`, `docs/skills.md` | the footprint-gap finding is blocking from plan round 2 | 3 |
| `skills/plan/SKILL.md`, `tests/plan-skill.test.sh` | step 8's no-known-language case, step 10's repeated sentence | 4 |
| `scripts/overlap.sh`, `CHANGELOG.md` | header comment for `--base` alone, the entry's trigger condition | 5 |

---

### Task 1: Guard the sentences #74 names, as they were wrapped (F1, F2)

**Files:**
- Modify: `tests/closing-exits.test.sh`

**Interfaces:**
- Consumes: `step <file> <n>`, `has`/`lacks`, `fail`, `CLOSING_EXITS_ROOT` and the scratch-copy pattern of `case_bites` (round 1, Task 7).
- Produces: `flat <text>` — prints the text with newlines joined and runs of spaces squeezed to one (`tr '\n' ' ' | tr -s ' '`), so a phrase wrapped over lines still matches a fixed string; `case_close_step17_lead` and `case_stash_prose` use it; `case_bites` gains the two original-wrapping mutations below.

- [ ] **Step 1: Write the failing bite cases.** In `case_bites`, after the two existing mutations, add (each restoring `$pristine` first and asserting `! cmp -s` as the existing ones do, then running the named case against the copy with `2>&1`, failing the bite unless the inner run exits non-zero **and** names the case):
  - *step 17's old ending, wrapped as it was* (`2a86915^`, lines 524-525): in the copy, replace the line `    from a step having been attempted. End with the closing block for the exit step 16 took:` with two lines, `    from a step having been attempted. End with the closing block: the goal is the loose ends found,` and `    the first step \`/codeo:triage\`, then the host's checkout clean-up above.`; expect `close-step17-lead` to fail.
  - *the stash sentence, wrapped as it was* (`2a86915^`, lines 607-611): in the copy, insert before `**Closed unmerged**` the lines `` Report that `/codeo:init #<N>` `` and `resumes it, on any machine.`, then a blank line; expect `stash-prose` to fail.
  - *the stash ending, wrapped as it was*: insert before `**Closed unmerged**` the lines `request stays open; say so. End with the closing block: the goal is resuming the work, the first` and `` step `/codeo:init #<N>`. ``, then a blank line; expect `stash-prose` to fail.

- [ ] **Step 2: Run** `bash tests/run.sh closing-exits`. Expected: FAIL for each of the three mutations (`the old step 17 ending passed close-step17-lead`, `the old stash sentence passed stash-prose`, `the old stash ending passed stash-prose`).

- [ ] **Step 3: Widen the guards.** Define `flat()` beside `step()`. In `case_close_step17_lead`, keep the lead check and add `lacks "$(flat "$s")" 'End with the closing block: the goal is the loose ends found'`. In `case_stash_prose`, run both existing and new `lacks` on `$(flat "$text")`: `` Report that `/codeo:init #<N>` resumes it `` and `End with the closing block: the goal is resuming the work`. Update the scratch mutation helper so the existing one-line mutations keep working (they must still fail their cases).

- [ ] **Step 4: Run** `bash tests/run.sh closing-exits`. Expected: `all cases passed`. Then `bash tests/run.sh close-skill` and `bash tests/run.sh closing-block`. Expected: `all cases passed` each.

- [ ] **Step 5: Commit** `tests/closing-exits.test.sh` — `test: guard step 17's old ending and the stash prose as they were wrapped (#97)`.

### Task 2: Let the abandon-finished block allow for no board (F6)

**Files:**
- Modify: `skills/close/SKILL.md` (the `**Closing block — abandon finished:**` paragraph), `tests/closing-exits.test.sh`

**Interfaces:** none.

- [ ] **Step 1: Write the failing assertion** in `case_abandon_finished`: `has "$p" 'with no board'`, and keep its `has` of `/codeo:triage` and its `lacks` of `/codeo:init #<N>` and `/codeo:close --stash`. Run `bash tests/run.sh closing-exits`; expected: FAIL `no [with no board]`.

- [ ] **Step 2: Edit the paragraph** so its first sentence reads: "`.codeo/active` is deleted. With a board the card is at `$BACKLOG` (or the board move failed: say so, the card is the engineer's to move by hand); with no board there is no card." Keep the rest unchanged (the goal, the `/codeo:triage` first step, the host clean-up, the sentence that no command resuming or stashing the work is named). The paragraph must still contain neither `/codeo:init #<N>` nor `/codeo:close --stash`.

- [ ] **Step 3: Run** `bash tests/run.sh closing-exits` and `bash tests/run.sh close-skill`. Expected: `all cases passed` each.

- [ ] **Step 4: Commit** `skills/close/SKILL.md tests/closing-exits.test.sh` — `fix: let close's abandon-finished block allow for no board (#97)`.

### Task 3: Make `qc` block a footprint gap once the plan has a second round (F3, Q7 (a))

**Files:**
- Modify: `skills/qc/SKILL.md` (step 6), `tests/qc-skill.test.sh`, `docs/skills.md` (`qc` entry)

**Interfaces:**
- Consumes: the `qc-verdict.sh` rule from round 1 (a `### Round <k>`, k ≥ 2, under `plan.md`'s `## Outcome`).

- [ ] **Step 1: Write the failing pins** in `tests/qc-skill.test.sh`, next to the step 6 `must_contain` for `overlap.sh" --outside <N>`: a `must_contain` of `On a first-round plan it is not blocking by rule`; a `must_contain` of ``Once `plan.md`'s `## Outcome` has a `### Round 2` or later it is blocking``; and a check, in the file's own style for "still says X", that fails when the old phrase `and not blocking by rule:` is present. Run `bash tests/run.sh qc-skill`; expected: FAIL on the first two and on the old phrase.

- [ ] **Step 2: Edit `skills/qc/SKILL.md` step 6.** Replace "classified at step 8 like any other, and not blocking by rule: the footprint is what other workflows were told this one would touch, so the engineer should hear about the gap, but the change may still be right." with: "classified at step 8 like any other. On a first-round plan it is not blocking by rule: the footprint is what other workflows were told this one would touch, so the engineer should hear about the gap, but the change may still be right. Once `plan.md`'s `## Outcome` has a `### Round 2` or later it is blocking, and `/codeo:plan`'s: the `qc-verdict` check fails the pull request on the same paths, and a footprint can only be corrected by a new plan round, so the finding goes back to `/codeo:plan` before any pull request exists." Keep each pinned phrase on one line.

- [ ] **Step 3: Edit `docs/skills.md`'s `qc` entry** (`### Hand-offs and non-goals`): add the bullet "- A changed path outside the plan's footprint is a finding: non-blocking on a first-round plan, blocking once the plan has a second round, because the `qc-verdict` check fails the pull request on it." The page must still pass the coverage guard.

- [ ] **Step 4: Run** `bash tests/run.sh qc-skill` and `bash tests/run.sh skills-doc`. Expected: `all cases passed` each. Prove the pins bite: `git show origin/main:skills/qc/SKILL.md > "$TMPDIR/old-qc.md"` and run the qc-skill test against it with the file's override variable if it has one (otherwise copy the file into a scratch tree as `case_bites` does); expected: FAIL naming the new pins.

- [ ] **Step 5: Commit** the three files — `fix: make qc block a footprint gap once the plan has a second round (#97)`.

### Task 4: Restore step 8's no-known-language case, and drop step 10's repeated sentence (F4, F5)

**Files:**
- Modify: `skills/plan/SKILL.md` (step 8's host-task paragraph; step 10 sub-step 1), `tests/plan-skill.test.sh`

**Interfaces:**
- Consumes: `must_contain`, `must_lack`, `must_order` in `tests/plan-skill.test.sh`.

- [ ] **Step 1: Write the failing pins:** `must_contain` of `Where none is known, the script cannot be neutral`; `must_lack` of `The draft footprint goes under \`## Notes\` again all the same`; and replace the existing pin of `footprint goes under \`## Notes\` again all the same` (round 1's 'the draft footprint goes under Notes again') with that `must_lack`. Run `bash tests/run.sh plan-skill`; expected: FAIL on both.

- [ ] **Step 2: Edit step 8.** After "in a language the engineer's host is known to have." add, on its own line so the pin stays on one line: "Where none is known, the script cannot be neutral: it is asked about and labelled like any other command that cannot be neutral." Keep the following sentence ("A command that cannot be neutral is asked about and then labelled: …").

- [ ] **Step 3: Edit step 10 sub-step 1.** Delete the sentence "The draft footprint goes under `## Notes` again all the same." and nothing else in that paragraph; re-read sub-steps 1-4 and check no step requires `## Outcome` to be both written and pending, and that the paragraph still says where the draft goes (its first sentence, "puts the draft under `## Notes`").

- [ ] **Step 4: Run** `bash tests/run.sh plan-skill`, `bash tests/run.sh dossier-check`, `bash tests/run.sh skills`. Expected: `all cases passed` each. Prove the new pins bite against `origin/main`'s copy: `PLAN_SKILL="$TMPDIR/old-plan.md" bash tests/plan-skill.test.sh` after `git show origin/main:skills/plan/SKILL.md > "$TMPDIR/old-plan.md"`; expected: FAIL lines for the new pins, exit 1.

- [ ] **Step 5: Commit** `skills/plan/SKILL.md tests/plan-skill.test.sh` — `fix: restore step 8's no-known-language case and drop step 10's repeated sentence (#97)`.

### Task 5: Say what `--base` alone does, and when the host-task rule applies (F7, F9)

**Files:**
- Modify: `scripts/overlap.sh` (header comment only), `CHANGELOG.md` (the `## Unreleased` #97 bullet only)

**Interfaces:** none.

- [ ] **Step 1: Confirm the behaviour first.** Read `scripts/overlap.sh`: with `--base <ref>` and no `--head`, the diff is `git diff --name-only <ref>...HEAD` and the plan is read from the working tree. Quote the lines that show it in your report; if the code does something else, write what it does.

- [ ] **Step 2: Edit the header** of `scripts/overlap.sh` (the `--outside` block): after "--base and --head are valid only with --outside." add "Given alone, --base changes only the diff base: `git diff --name-only <base>...HEAD`, with the plan read from the working tree." No code changes.

- [ ] **Step 3: Edit the #97 bullet** in `CHANGELOG.md`: change "`/codeo:plan` marks the tasks the engineer runs on their own host and writes their commands shell-neutral;" to "`/codeo:plan` marks the tasks the engineer runs on their own host (when the lock's host is not `local`, or is `local` on Windows) and writes their commands shell-neutral;" and add, before the final sentence about `docs/skills.md`, "`/codeo:qc` treats a changed path outside the footprint as blocking once a plan has a second round, as the `qc-verdict` check does." Touch nothing else in the file.

- [ ] **Step 4: Prove it.** `bash tests/run.sh overlap` (Expected: `all cases passed`); `grep -cF 'or is \`local\` on Windows' CHANGELOG.md` (Expected: at least `1`); then the whole suite, `bash tests/run.sh` (Expected: `all cases passed`).

- [ ] **Step 5: Commit** `scripts/overlap.sh CHANGELOG.md` — `docs: say what overlap.sh --base does alone and when the host-task rule applies (#97)`.

---

## Self-Review

- **Round 1's findings.** F1, F2 → Task 1; F3 → Task 3 (Q7 (a)); F4, F5 → Task 4; F6 → Task 2; F7, F9 → Task 5; F8 and F10 are out of scope with reasons under Global Constraints.
- **Pins.** Tasks 2, 3 and 4 reword text that round 1's pins read: Task 3 removes "and not blocking by rule:" (no round-1 pin reads it, only `overlap.sh" --outside <N>`), Task 4 replaces the one pin on the repeated sentence, and Task 2 keeps every `has`/`lacks` of round 1's `case_abandon_finished`.
- **Type consistency.** `flat`, `case_close_step17_lead`, `case_stash_prose`, `case_bites` and the label `abandon finished` are used identically in Tasks 1 and 2.
