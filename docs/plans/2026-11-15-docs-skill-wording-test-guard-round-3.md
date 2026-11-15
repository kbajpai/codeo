# Docs, skill wording and test-guard follow-ups (#97), round 3 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Close the one blocking finding `/codeo:qc` raised on round 2 (`.codeo/97/qc.md`, F11): the new `qc-verdict` footprint rule must judge only the archive a pull request itself delivers. Take the non-blocking findings that sit beside it (F12-F15).

**Architecture:** Rounds 1 and 2 are built and stay as they are. `qc-verdict.sh` narrows its footprint check from "every archive the diff touches" to "every archive whose `plan.md` the diff adds or renames", which is what `/codeo:close`'s archive commit produces; a pull request that merely edits an old archive is no longer compared with it. `overlap.sh` stops hiding an unresolvable `--base`/`--head`, so the required check cannot pass on a failed diff. Three skill and changelog sentences are corrected.

**Tech Stack:** bash, git; tests are `tests/*.test.sh` run by `bash tests/run.sh [name-fragment]`.

**Spec:** GitHub issue #97 and `.codeo/97/init.md`; round 2's findings in `.codeo/97/qc.md` (`### Round 2`); decisions in `.codeo/97/plan.md` (Q1-Q7).

## Global Constraints

- One suite, `shell`: build `true`, test `bash tests/run.sh`. A task's proof is `bash tests/run.sh <fragment>`; the last task runs the whole suite. No invariants document, wiki module, shared environment or `resources[]`: no `Needs lease:`, no `Runs on:`, no wiki page.
- Tests print `FAIL: <what>` and exit non-zero, and `all cases passed` on success. A pinned phrase sits on one line of the skill it pins (the pins are line-based `grep -F`).
- `qc-verdict` is a required check: it must never fail a pull request for something that pull request did not deliver, and it must fail closed, by name, when its own footprint check cannot run.
- `overlap.sh` without `--base`/`--head`, and in pair mode (`overlap.sh <N>`), behaves exactly as before.
- Documentation describes what the system does now: present tense, no issue numbers (the changelog's own `(#97)` ref excepted).
- Other workflows: #70 edits `skills/close/SKILL.md`, `docs/handoff.md`, `docs/skills.md` and `tests/**`; #71 edits `tests/closing-exits.test.sh`. Both were answered *proceed and coordinate*. Keep each edit to the lines a task names.
- Out of scope, recorded in `qc.md` for `/codeo:triage`: F8 (a paging `gh` stub), F10 (`skills/init/SKILL.md` after a `lock: TODO`), the unanchored `^## Outcome` match in `qc-verdict.sh`.
- Documentation moved by this round: `docs/handoff.md` (the required-check sentence), `skills/qc/SKILL.md`, `skills/close/SKILL.md`, `scripts/qc-verdict.sh` and `scripts/overlap.sh` header comments, `CHANGELOG.md`. Each has its own task.

## Review Focus

- A pull request that only edits an old re-planned archive (a typo in `done/7/qc.md`) and adds ordinary code must pass (Task 1).
- A pull request that archives its own re-planned dossier with a gap must still fail, including when the archive arrives as a rename from `.codeo/<N>/` (Task 1).
- An unresolvable `--base` or `--head` must make `overlap.sh --outside` exit non-zero, and `qc-verdict` report it by name; no-flag behaviour unchanged (Task 2).

## File Structure

| File | Responsibility | Tasks |
|---|---|---|
| `scripts/qc-verdict.sh`, `tests/qc-verdict.test.sh`, `docs/handoff.md` | the footprint rule judges only the archive the pull request delivers | 1 |
| `scripts/overlap.sh`, `tests/overlap.test.sh` | a given ref that does not resolve is an error | 2 |
| `skills/qc/SKILL.md`, `tests/qc-skill.test.sh` | whose a round-2 footprint gap is, and how a second round is recognised | 3 |
| `skills/close/SKILL.md`, `tests/closing-exits.test.sh`, `tests/close-skill.test.sh` | the abandon text when the branch was deleted | 4 |
| `CHANGELOG.md` | the #97 entry's wording | 5 |

---

### Task 1: Judge only the archive the pull request delivers (F11)

**Files:**
- Modify: `scripts/qc-verdict.sh`, `tests/qc-verdict.test.sh`, `docs/handoff.md` (the required-checks sentence)

**Interfaces:**
- Consumes: `overlap.sh --outside <N> --base <ref> --head <ref>`; the test helpers `new_repo`, `qc_md`, `run_case`, `assert_*`, `replan_repo`.
- Produces: the footprint check runs for archive `<N>` only when `<state>/done/<N>/plan.md` is among the paths `git diff --name-only --diff-filter=AR <base> <head>` prints (added, or renamed into place).

- [ ] **Step 1: Write the failing cases** in `tests/qc-verdict.test.sh`, after the existing replan cases:
  - `an old re-planned archive that is only touched is not checked`: a scratch repo whose **base** commit already holds `.codeo/config.json` and `.codeo/done/7/` with a clear `qc.md` and a `plan.md` whose `## Outcome` has `### Round 2` and whose footprint lists `files: b.txt`; the head appends a line to `.codeo/done/7/qc.md` and adds `c.txt`. Assert exit 0 and that the output lacks `footprint omits`.
  - `an archive renamed into place is checked`: base holds `.codeo/7/plan.md` (same content, footprint `b.txt`) and `.codeo/7/qc.md` (clear); the head `git mv`s `.codeo/7` to `.codeo/done/7` and adds `a.txt` and `b.txt`. Assert exit 1 and that stderr contains `.codeo/done/7/plan.md` and `round 2 footprint omits: a.txt`.
  The existing `replan footprint omits a changed path` case (the head adds `done/7/plan.md`) must keep failing with exit 1.

- [ ] **Step 2: Run** `bash tests/run.sh qc-verdict`. Expected: FAIL on the first new case (exit 1, `footprint omits: c.txt`); the rename case passes or fails depending on git's rename detection, and must pass after Step 3.

- [ ] **Step 3: Implement.** Compute the set of delivered archives once, beside `touched`: the numeric `<N>` of every `$state_rel/done/<N>/plan.md` in `git diff --name-only --diff-filter=AR "$base" "$head_ref" -- ":(glob)$state_rel/done/*/plan.md"`. In the `for n in $touched` loop, run the footprint check only when `<N>` is in that set. Update the header comment: the rule applies to an archive this pull request adds or renames into place.

- [ ] **Step 4: Edit `docs/handoff.md`** (the required-checks bullet): "It also fails a pull request whose archived `plan.md` has a `### Round 2` or later and whose footprint omits a path `overlap.sh --outside` prints for the branch." becomes "It also fails a pull request that archives a `plan.md` with a `### Round 2` or later whose footprint omits a path `overlap.sh --outside` prints for the branch; an archive the pull request only edits is not judged."

- [ ] **Step 5: Run** `bash tests/run.sh qc-verdict`, `bash tests/run.sh replay`, `bash tests/run.sh closing-exits`. Expected: `all cases passed` each.

- [ ] **Step 6: Commit** the three files — `fix: judge only the archive a pull request delivers in qc-verdict's footprint rule (#97)`.

### Task 2: Make an unresolvable `--base` or `--head` an error in `overlap.sh` (F14)

**Files:**
- Modify: `scripts/overlap.sh`, `tests/overlap.test.sh`

**Interfaces:**
- Produces: with `--base <ref>` or `--head <ref>` given, `overlap.sh --outside` exits 1 and prints `overlap: cannot resolve <ref>` on stderr when `git rev-parse --verify --quiet "<ref>^{commit}"` fails. With neither flag, nothing changes.

- [ ] **Step 1: Write the failing cases** in `tests/overlap.test.sh`, beside the `--base`/`--head` cases: `--outside 7 --base main --head no-such-ref` and `--outside 7 --base no-such-ref --head <branch>` each exit 1 with `cannot resolve` on stderr and nothing on stdout; and the existing no-flag `--outside` cases still pass unchanged.

- [ ] **Step 2: Run** `bash tests/run.sh overlap`. Expected: FAIL on the two new cases (exit 0, empty output).

- [ ] **Step 3: Implement** the check right after argument parsing, for a given ref only. Add one line to the header's `--outside` block: "A given ref that does not resolve to a commit is an error (exit 1)."

- [ ] **Step 4: Run** `bash tests/run.sh overlap` and `bash tests/run.sh qc-verdict`. Expected: `all cases passed` each (the `failed footprint check is reported by name` case in `qc-verdict` still passes).

- [ ] **Step 5: Commit** `scripts/overlap.sh tests/overlap.test.sh` — `fix: fail overlap.sh --outside on a base or head that does not resolve (#97)`.

### Task 3: Say whose a round-2 footprint gap is, and how to recognise a second round (F13)

**Files:**
- Modify: `skills/qc/SKILL.md` (step 6), `tests/qc-skill.test.sh`

**Interfaces:**
- Consumes: `must_contain` and the "still says X" `if grep … fail` form in `tests/qc-skill.test.sh`; `QC_SKILL` for the bite proof.

- [ ] **Step 1: Write the failing pins:** `must_contain` of `Whose it is follows step 8`; `must_contain` of ``A second round shows as a `### Round <n>` heading``; and a check that fails while `a footprint can only be corrected by a new plan round` is present. Keep round 2's two pins (`On a first-round plan it is not blocking by rule`; ``Once `plan.md`'s `## Outcome` has a `### Round 2` or later it is blocking``). Run `bash tests/run.sh qc-skill`; expected: FAIL on the three.

- [ ] **Step 2: Edit step 6.** Replace the sentence that begins "Once `plan.md`'s `## Outcome` has a `### Round 2` or later it is blocking, and `/codeo:plan`'s:" through "…before any pull request exists." with: "Once `plan.md`'s `## Outcome` has a `### Round 2` or later it is blocking: the `qc-verdict` check fails the pull request that archives the dossier on the same paths. Whose it is follows step 8: `/codeo:implement`'s when the code strayed into a file the plan never called for, where reverting it clears the gap, and `/codeo:plan`'s when the work needs the file and the footprint left it out, where only a new plan round can add it. A second round shows as a `### Round <n>` heading, n ≥ 2, under `plan.md`'s `## Outcome`." Wrap so each pinned phrase stays on one line.

- [ ] **Step 3: Run** `bash tests/run.sh qc-skill` and `bash tests/run.sh skills-doc`. Expected: `all cases passed` each. Bite proof: `git show origin/main:skills/qc/SKILL.md > "$TMPDIR/old-qc.md"; QC_SKILL="$TMPDIR/old-qc.md" bash tests/qc-skill.test.sh`; expected: FAIL lines for the new pins, exit 1.

- [ ] **Step 4: Commit** `skills/qc/SKILL.md tests/qc-skill.test.sh` — `fix: say whose a round-2 footprint gap is and how qc recognises a second round (#97)`.

### Task 4: Make the abandon text true when the branch was deleted (F12)

**Files:**
- Modify: `skills/close/SKILL.md` (the sentence before the abandon blocks, and the abandon-finished block), `tests/closing-exits.test.sh` (`case_abandon_finished`), `tests/close-skill.test.sh`

**Interfaces:** none.

- [ ] **Step 1: Write the failing assertions:** in `case_abandon_finished`, `has "$p" 'the last copy'`; in `tests/close-skill.test.sh`, `must_contain` of `the local branch is the only copy of the work and its dossier`. Run `bash tests/run.sh closing-exits` and `bash tests/run.sh close-skill`; expected: FAIL on both.

- [ ] **Step 2: Edit `skills/close/SKILL.md`.**
  - Replace "Once the lock is gone the checkout holds nothing the branch lacks: say what is left of it as step 17 does, by the lock's host, read before the lock goes." with "Once the lock is gone, say what is left of the checkout as step 17 does, by the lock's host, read before the lock goes. With the branch kept, the checkout holds nothing the branch lacks. When the engineer had the branch deleted, the local branch is the only copy of the work and its dossier: say so, and do not call the checkout safe to remove."
  - In the abandon-finished block, "then the host's checkout clean-up as step 17 relays it." becomes "then the host's checkout clean-up as step 17 relays it, unless the branch was deleted: the checkout is then the last copy, the engineer's to keep or to remove knowingly."
  - The block must still contain neither `/codeo:init #<N>` nor `/codeo:close --stash`, and still say `with no board` and name `/codeo:triage` first. Keep `tests/closing-exits.test.sh` at mode 100755.

- [ ] **Step 3: Run** `bash tests/run.sh closing-exits` and `bash tests/run.sh close-skill`. Expected: `all cases passed` each (`bites` included).

- [ ] **Step 4: Commit** the three files — `fix: make close's abandon text true when the branch was deleted (#97)`.

### Task 5: Correct the changelog entry's wording (F15, F11)

**Files:**
- Modify: `CHANGELOG.md` (the `## Unreleased` bullet ending `(#97)` only)

**Interfaces:** none.

- [ ] **Step 1: Edit the bullet.**
  - "`qc-verdict` now fails a pull request whose archived `plan.md` has a second or later round and whose footprint omits a path the branch changes; a pull request still in its first round is not affected." becomes "`qc-verdict` now fails a pull request that archives a `plan.md` with a second or later round whose footprint omits a path the branch changes; a first-round plan, and an older archive a pull request merely edits, are not judged."
  - "`/codeo:plan` marks the tasks the engineer runs on their own host (when the lock's host is not `local`, or is `local` on Windows) and writes their commands shell-neutral; a command that cannot be neutral is asked about as a numbered question and labelled `Shell: <name>`." becomes "`/codeo:plan`'s rule for tasks the engineer runs on their own host is stated consistently: such a task (the lock's host is not `local`, or is `local` on Windows) is marked and its command written shell-neutral, and a command that cannot be neutral is asked about as a numbered question and labelled `Shell: <name>`."
  - Touch nothing else in the file.

- [ ] **Step 2: Prove it.** `grep -cF 'merely edits' CHANGELOG.md` (Expected: `1`); `grep -cF 'Shell: <name>' CHANGELOG.md` (Expected: at least `1`); then the whole suite, `bash tests/run.sh` (Expected: `all cases passed`).

- [ ] **Step 3: Commit** `CHANGELOG.md` — `docs: correct the #97 changelog entry for the footprint rule's scope and the host-task rule (#97)`.

---

## Self-Review

- **Round 2's findings.** F11 → Task 1 (and the changelog in Task 5); F12 → Task 4; F13 → Task 3 (with the note on recognising a second round); F14 → Task 2; F15 → Task 5. F8, F10 and the unanchored `## Outcome` match stay out of scope, as Global Constraints says.
- **Pins.** Task 3 keeps round 2's two pins and removes only the sentence its new check forbids; Task 4 keeps every assertion of `case_abandon_finished` (`/codeo:triage`, `with no board`, the two forbidden commands) and the label pins in `tests/close-skill.test.sh`.
- **Consistency.** "an archive the pull request adds or renames into place" is the same condition in `qc-verdict.sh`, `docs/handoff.md`, `skills/qc/SKILL.md` ("the pull request that archives the dossier") and `CHANGELOG.md`.
