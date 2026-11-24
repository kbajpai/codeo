# Live-signal leftovers, round 3 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `/codeo:close` says everywhere what it deletes: the issue's `codeo-live/<issue>/*` live-signal branches go without a question, and the passages that still say it deletes only the merged branch on the engineer's yes name that exception. The cleanup script and the changelog say what the code already does.

**Architecture:** Words only; no script changes behaviour. `skills/close/SKILL.md` already runs `live.sh sweep` at step 16, in a stash and in an abandon. Three passages of the same skill (the frontmatter description, the Hand-off section's **Deletes** bullet, the Non-goals) and two of `docs/skills.md` (the `close` purpose paragraph and its non-goal line) gain the exception and its reason: a live-signal branch holds one parentless commit on the empty tree, so deleting it loses no work. `scripts/cleanup.sh`'s header and `skills/cleanup/SKILL.md` step 1 say a proven issue can print a second line. `CHANGELOG.md`'s `Shared state` line says a hosted web session's close deletes nothing.

**Tech Stack:** Markdown, bash 4.3+ comments, the `shell` suite (`bash tests/run.sh`).

**Spec:** `.codeo/157/qc.md` round 2 (F6, F7, F9). Builds on `docs/plans/2026-11-23-live-signal-leftovers-157.md` and `docs/plans/2026-11-23-live-signal-leftovers-157-round-2.md`, both implemented.

## Global Constraints

- No invariants document, no shared environment: no `Needs lease:`; every task is proved in this checkout.
- Out of scope: F24 and which ref namespace a web session writes, as in rounds 1 and 2.
- No behaviour changes: `scripts/live.sh` is not touched, and in `scripts/cleanup.sh` only header comment lines change.
- The rule comments in the skills (`<!-- rule: close-10 -->`, `<!-- rule: cleanup-02 -->` and the rest) and the sentences under them stay as they are.
- Existing pinned strings stay: the Non-goals keep `except on an abandon, when the engineer asks in so many words` and `force-push`; the description keeps `stash` and `closed unmerged`.
- Docs describe the system in the present tense, with no issue numbers other than the `(#157)` suffix `CHANGELOG.md` entries carry.
- Proof is `bash tests/run.sh <file pattern>` (the `shell` suite has no single-test filter); the last task runs the whole suite.
- Pages that move: `skills/close/SKILL.md`, `docs/skills.md` (`close`), `scripts/cleanup.sh` header, `skills/cleanup/SKILL.md`, `CHANGELOG.md`.
- Left as they are, on purpose (`qc.md` round 2): F8 (`cleanup.sh` prints no leftover command when the `name` proof failed; rule `cleanup-02` says an issue that failed a proof gets no command, and the manual command in `docs/handoff.md` covers it), F10 (a saved label from the `hostname` fallback) and F11 (branch names with more path segments, covered by the manual command).

## Review Focus

- An agent reading only close's Non-goals must find the sweep allowed: task 1 pins the exception inside that section, not merely somewhere in the file.
- The exception must not read as wider than it is: only `codeo-live/<issue>/*` of the lock's issue, and never the work branch. Task 1's wording names both limits.
- The skill listing shows only the frontmatter description: task 1 pins the sweep there.
- `docs/skills.md` mirrors the skill; a fix in one and not the other leaves the same contradiction one page over: task 1 pins both.
- The cleanup script's header must not contradict itself on how many lines an issue prints: task 2 pins the header's sentence.

### Task 1: `/codeo:close` names the sweep wherever it says what it deletes (F6)

**Files:**
- Modify: `skills/close/SKILL.md` (frontmatter `description`, the **Deletes** bullet under `## Hand-off`, the branch-deletion bullet under `## Non-goals`)
- Modify: `docs/skills.md` (`## close`: the purpose paragraph, and the non-goal line "Does not delete a branch without …")
- Test: `tests/close-skill.test.sh`, `tests/live-signal.test.sh`

**Interfaces:**
- Consumes: step 16's existing text and `live.sh sweep`, unchanged.
- Produces: the phrase `live-signal branches` in the description; the token `codeo-live/<issue>/*` in the `Hand-off` and `Non-goals` sections; the phrase `without asking` beside it in both.

- [ ] **Step 1: Write the failing tests.** In `tests/close-skill.test.sh`, after the existing description checks (about line 129) add: the description contains `live-signal branches`, failing with `the description does not name the live-signal sweep`. After the existing Non-goals checks (about line 282) add:
  - `section_contains "the hand-off names the swept branches" Hand-off 'codeo-live/<issue>/*'`
  - `section_contains_flat "the hand-off says the sweep does not ask" Hand-off 'without asking'`
  - `section_contains "the non-goals except the swept branches" Non-goals 'codeo-live/<issue>/*'`
  - `section_contains_flat "the non-goals say the sweep does not ask" Non-goals 'without asking'`

  In `tests/live-signal.test.sh`, add a case `skills_doc_states_the_sweep_exception` in the style of `changelog_and_skills_state_the_saved_label`: read `docs/skills.md`, take the text from the line `## close` up to the line `## triage`, and fail unless it contains `sweeps the issue's leftover live-signal branches` and `deletes without asking`.
- [ ] **Step 2: Run them to see them fail.** `bash tests/run.sh close-skill` fails the five new checks; `bash tests/run.sh live-signal` fails `skills_doc_states_the_sweep_exception`.
- [ ] **Step 3: Edit `skills/close/SKILL.md`.**
  - Description: `…then prove the merge, delete the remote branch on the engineer's yes, sweep the issue's leftover live-signal branches, release every lease and the lock.` The rest of the line is unchanged.
  - **Deletes** bullet: ``- **Deletes** `.codeo/active`; the issue's `codeo-live/<issue>/*` live-signal branches on the remote, through `live.sh sweep` and without asking, since each holds only an empty signal commit and no work; and the merged branch on the remote — or, on an abandon, the unmerged one, only when the engineer asks — and moves the dossier directory in and out of `.codeo/done/`. It is the only skill that may do any of these.``
  - Non-goals bullet: ``- Doesn't delete a branch without GitHub's merged state, a tip that matches the pull request's head and the engineer's yes — except on an abandon, when the engineer asks in so many words, after the same confirmation, and except the issue's own `codeo-live/<issue>/*` live-signal branches, which step 16's `live.sh sweep` deletes without asking: they hold an empty signal commit, never work — and never deletes the base branch, force-pushes, or rewrites history.``
- [ ] **Step 4: Edit `docs/skills.md`, `## close`.**
  - Purpose paragraph: `…then proves the merge, deletes the remote branch on the engineer's yes, sweeps the issue's leftover live-signal branches, and releases every lease and the lock.`
  - Non-goal line: ``- Does not delete a branch without GitHub's merged state, a tip that matches the pull request's head and the engineer's yes (on an abandon, the engineer must ask in so many words, after the same confirmation). The one exception is the issue's own `codeo-live/<issue>/*` live-signal branches, which it deletes without asking: each holds an empty signal commit and no work. It never deletes the base branch, force-pushes, or rewrites history.``
- [ ] **Step 5: Prove it.** Run: `bash tests/run.sh close-skill` then `bash tests/run.sh live-signal` then `bash tests/run.sh skills-doc`. Expected: each prints no `FAIL` line and exits 0.
- [ ] **Step 6: Commit.** `git add skills/close/SKILL.md docs/skills.md tests/close-skill.test.sh tests/live-signal.test.sh` and commit as `docs: close names the live-signal sweep wherever it says what it deletes`.

### Task 2: The cleanup output and the changelog say what the code does (F7, F9)

**Files:**
- Modify: `scripts/cleanup.sh` (header comment, lines 6-7 only)
- Modify: `skills/cleanup/SKILL.md` (step 1's first sentence)
- Modify: `CHANGELOG.md` (`## Unreleased`, the `Shared state` line)
- Test: `tests/cleanup-skill.test.sh`, `tests/live-signal.test.sh`

**Interfaces:**
- Consumes: the `leftover` line `cleanup.sh` already prints, unchanged.
- Produces: the sentence fragment `a second line, `leftover`` in the script header and the skill; `a hosted web session's close deletes none` in the changelog.

- [ ] **Step 1: Write the failing tests.** In `tests/cleanup-skill.test.sh`, beside the existing `leftover` checks (about line 22) add two checks in the same `grep -qF … || check_fail` style: the skill contains ``a second line, `leftover` `` (message `step 1 does not say a proven issue can print two lines`), and `$repo/scripts/cleanup.sh` contains the same fragment (message `the script header does not say a proven issue can print two lines`). In `tests/live-signal.test.sh`, inside `changelog_and_skills_state_the_saved_label`, add: the changelog contains `a hosted web session's close deletes none`.
- [ ] **Step 2: Run them to see them fail.** `bash tests/run.sh cleanup-skill` and `bash tests/run.sh live-signal` each fail the new checks.
- [ ] **Step 3: Edit the three files.**
  - `scripts/cleanup.sh` header: `…lists the .codeo/done/<N> directories on origin/<baseBranch>, and prints one tab-separated line per issue, in ascending N, and after a proven issue with leftover branches a second line, `leftover`:` The three row descriptions beneath stay.
  - `skills/cleanup/SKILL.md` step 1: after the sentence that ends `or `<N>`, `failed` and the first proof that failed.` add: ``A proven issue whose web live-signal branches are still on `origin` gets a second line, `leftover`, right after its own.``
  - `CHANGELOG.md` `Shared state` line: `…`/codeo:close` deletes the issue's `codeo-live/<issue>/*` branches on origin (a hosted web session's close deletes none, since it cannot delete a branch), and readers keep web signals in the local `refs/codeo/live-web/*``.
- [ ] **Step 4: Prove it.** Run: `bash tests/run.sh cleanup` then `bash tests/run.sh live-signal`. Expected: each prints no `FAIL` line and exits 0.
- [ ] **Step 5: Commit.** `git add scripts/cleanup.sh skills/cleanup/SKILL.md CHANGELOG.md tests/cleanup-skill.test.sh tests/live-signal.test.sh` and commit as `docs: cleanup's second line and the web-session close in the changelog`.

### Task 3: The whole suite

**Files:** none.

- [ ] **Step 1: Run the suite.** Run: `bash tests/run.sh`. Expected: `all cases passed`, exit 0.
- [ ] **Step 2: Run the build.** Run: `true`. Expected: exit 0.
