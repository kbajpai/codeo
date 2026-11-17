# Follow-ups #116, QC round 1 fixes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Close the six findings of `/codeo:qc` round 1 on issue #116, so that criterion 3 is met (no generic sentence names an "issue container") and the documentation and two tests say exactly what the code does.

**Architecture:** Wording edits in three skills and three documentation files, each pinned by a check in the test file that already guards it, and two test-only tightenings. No script changes.

**Tech Stack:** bash, `bash tests/run.sh` (the `shell` suite).

**Spec:** `.codeo/116/qc.md` (`### Round 1`, findings F1-F6) and `.codeo/116/init.md` (the acceptance criteria). This plan follows `docs/plans/2026-11-16-follow-ups-70-71-104-107.md`, whose ten tasks are built and stay as they are.

## Global Constraints

- **Scope.** Only F1-F6. Criterion 13 stays dropped (plan Q4). No script under `scripts/`, `hooks/` or `.devcontainer/scripts/` changes.
- **F1 wording.** The parenthetical "(the skill is running in an issue container)" is removed outright, in all four places; the sentence then opens "When the project's role check refuses the call, record the finding…". Nothing replaces it: the role check is the project's, and so is its reason.
- **F3 (document, not fix).** `role.sh` keeps treating any `/run/.containerenv` as a container; the README names toolbox and distrobox.
- **Overlap (plan Q5, proceed and coordinate).** #113 also edits `.devcontainer/README.md` and `CHANGELOG.md`. Task 2 runs `bash scripts/sync-main.sh` first and edits each once.
- **Documentation this change moves:** `docs/handoff.md` (the refused-call sentence, the live-signal diagram), `.devcontainer/README.md` (the guard paragraph), `CHANGELOG.md` (the #70 bullet). Pages say what the system does: present tense, no issue number, no "now". No wiki module. **Invariants:** none configured.
- **Suite.** The `shell` suite has no `filter`: a task's proof is the test file it touches (`bash tests/<file>.test.sh`, ending `all cases passed`), then `bash tests/run.sh`, ending `all cases passed`. No task carries `Needs lease:` or `Runs on:`.

## Review Focus

- A re-wrap of the stash or abandon paragraph in `skills/close/SKILL.md` must not fail `tests/close-skill.test.sh` (Task 3).
- An overlay that fails to load must fail `an_exported_removal_override_changes_nothing`, not pass it with `-` on both sides (Task 3).
- "issue container" must stay allowed where it is the project's own fact: `.devcontainer/README.md`, `.codeo/overlays/`, test comments (Task 1 pins only the four generic files).

---

### Task 1: The refused-call sentence names no container (F1)

**Files:**
- Modify: `skills/plan/SKILL.md:113`, `skills/implement/SKILL.md:17`, `skills/qc/SKILL.md:513`, `docs/handoff.md:379`
- Test: `tests/plan-skill.test.sh`, `tests/implement-skill.test.sh`, `tests/qc-skill.test.sh`

- [ ] **Step 1: Write the failing tests.** In each of the three test files, beside the existing `must_lack 'no home-container claim in generic text' 'in the home container'`, add `must_lack 'no issue-container claim in generic text' 'issue container'`. In `tests/plan-skill.test.sh` also add, on the next line, a check that `docs/handoff.md` (addressed through the file's existing repository-root variable) has no line containing `issue container`, failing with `handoff.md — still has [issue container]`.
- [ ] **Step 2: Run the three files.** Expected: each prints `FAIL … still has [issue container]`; `plan-skill` prints the `handoff.md` line too.
- [ ] **Step 3: Edit the four sentences.** "When the project's role check refuses the call (the skill is running in an issue container)," becomes "When the project's role check refuses the call,". Re-wrap nothing else.
- [ ] **Step 4: Proof of done:** `bash tests/plan-skill.test.sh`, `bash tests/implement-skill.test.sh` and `bash tests/qc-skill.test.sh` each print `all cases passed`; `grep -n 'issue container' skills/plan/SKILL.md skills/implement/SKILL.md skills/qc/SKILL.md docs/handoff.md` prints nothing; `bash tests/run.sh` prints `all cases passed`.
- [ ] **Step 5: Commit** `docs: the refused-call sentence names no container (#116)`.

### Task 2: The diagram, the README and the #70 bullet say what the code does (F2, F3, F4)

**Files:**
- Modify: `docs/handoff.md` (the live-signal sequence diagram), `.devcontainer/README.md:49`, `CHANGELOG.md:16`
- Test: `tests/live-signal.test.sh`

- [ ] **Step 1: Sync.** `bash scripts/sync-main.sh`; expected exit 0, or exit 2 naming files, which are resolved by keeping both sides.
- [ ] **Step 2: Write the failing test.** In `docs_state_the_live_signal_limits` (`tests/live-signal.test.sh`) add: `docs/handoff.md` contains the fixed string `S->>O: /codeo:close runs live.sh clear and deletes the lock in one command`, and contains neither `S->>H: /codeo:close deletes the lock` nor `H->>O: clear in the same command`.
- [ ] **Step 3: Run `bash tests/live-signal.test.sh`.** Expected: three `FAIL docs_state_the_live_signal_limits` lines.
- [ ] **Step 4: Edit.**
  - `docs/handoff.md` diagram: the two lines `S->>H: /codeo:close deletes the lock` and `H->>O: clear in the same command` become the one line `S->>O: /codeo:close runs live.sh clear and deletes the lock in one command`, in the same position (before `S->>H: SessionEnd`).
  - `.devcontainer/README.md`, the paragraph beginning "The guard applies only when all of these hold": append "A toolbox or distrobox container also has `/run/.containerenv`, so a clone there in a folder named `codeo-home` or `codeo-<digits>` is guarded too."
  - `CHANGELOG.md`, the #70 bullet: "(`/.dockerenv` exists," becomes "(`/.dockerenv` or `/run/.containerenv` exists,".
- [ ] **Step 5: Proof of done:** `bash tests/live-signal.test.sh` prints `all cases passed`; `grep -c 'toolbox or distrobox' .devcontainer/README.md` prints `1`; `grep -c '/.dockerenv` or `/run/.containerenv` exists' CHANGELOG.md` prints `1`; `bash tests/run.sh` prints `all cases passed`.
- [ ] **Step 6: Commit** `docs: close clears the signal itself in the diagram; the Podman marker's reach (#116)`.

### Task 3: Two tests pin what they name (F5, F6)

**Files:**
- Test: `tests/cleanup.test.sh` (`an_exported_removal_override_changes_nothing`), `tests/close-skill.test.sh:313-314`

- [ ] **Step 1: `tests/cleanup.test.sh`.** Directly after `plain=$(run_cleanup)` add `assert_eq "line with an overlay, before the export" "12${tab}proven${tab}docker rm -f codeo-12" "$plain"`.
- [ ] **Step 2: Prove it can fail.** In a scratch copy (`m=$(mktemp -d) && cp -a . "$m" && (cd "$m" && <the edit> && bash tests/cleanup.test.sh); rm -rf "$m"`), change that case's `set_overlay $'name: codeo-{N}…'` to `set_overlay ""`. Expected: `FAIL an_exported_removal_override_changes_nothing: line with an overlay, before the export`.
- [ ] **Step 3: `tests/close-skill.test.sh`.** Add a helper `section_contains_flat <description> <section> <needle>`: as `section_contains`, but the section text is flattened first (`tr '\n' ' ' | tr -s ' '`), so a needle may span a line break. Replace the two `section_contains` lines at 313-314 with `section_contains_flat` and these needles: stash, ``Delete `.codeo/active` last, as step 16 does, with the signal cleared``; abandon, `the lock is deleted last, as a stash does, as step 16 does, with the signal cleared`. If either needle is not in the flattened section as written, use the skill's exact words for that clause (the skill's text does not change in this task) and say so in the report.
- [ ] **Step 4: Prove the pins are distinct and wrap-independent.** In a scratch copy, join the stash sentence's two lines into one in `skills/close/SKILL.md`: `bash tests/close-skill.test.sh` still prints `all cases passed`. In a second scratch copy, delete ", as step 16 does, with the signal cleared" from the abandon sentence only: expected `FAIL … an abandon clears the signal with the lock`, and no stash `FAIL`.
- [ ] **Step 5: Proof of done:** `bash tests/cleanup.test.sh` and `bash tests/close-skill.test.sh` each print `all cases passed`, Steps 2 and 4 printed what they expect, and `bash tests/run.sh` prints `all cases passed`.
- [ ] **Step 6: Commit** `test: the cleanup override case and the close pins assert what they name (#116)`.
