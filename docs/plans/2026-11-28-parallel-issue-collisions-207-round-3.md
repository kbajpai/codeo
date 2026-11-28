# Parallel Issue Collisions, Round 3 Implementation Plan (#207)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix what `/codeo:qc` round 2 found: the `Graded base:` line can name a commit QC never merged (F7), a slightly mis-formatted line switches `/codeo:close`'s check off silently (F8), and the release tool drops a second "yes, with a step" note (F9); plus the small items F10 and F11.

**Architecture:** Rounds 1 and 2 stand and are built (`docs/plans/2026-11-28-parallel-issue-collisions-207.md` and `…-round-2.md`). This round changes three places and tidies their edges; it adds no mechanism.

| Task | Finding | Change | Lives in |
|---|---|---|---|
| 1 | F7, F8 | QC records `git merge-base HEAD origin/<base>`; `base-moved.sh` reads a tolerant line and compares from `git merge-base <sha> HEAD`; an *Update branch* test | `skills/qc/SKILL.md` (qc-16), `scripts/base-moved.sh`, `tests/base-moved.test.sh`, `docs/dossier.md` |
| 2 | F9, F10, part of F11 | `yes` notes joined; `Config schema:` from the newest section; header blank lines; version and date checked; a missing `CHANGELOG.md` | `tools/changelog.sh`, `tests/changelog.test.sh` |
| 3 | rest of F11, carried minors | text only: close step 9 exit 1 and step 11's heading precedence; plan-11's separator and the suffix for a file directly under a glob's directory; init's failure wording | `skills/close/SKILL.md`, `skills/plan/SKILL.md`, `skills/init/SKILL.md`, `docs/dossier.md` |
| 4 | docs | the pages and the release entry | `README.md`, `docs/skills.md`, `CONTRIBUTING.md`, `docs/release-checklist.md`, `changelog.d/207.md` |
| 5 | all | the whole suite and the footprint | |

**Tech Stack:** bash (4.3+), `git`; tests in the `shell` suite (`bash tests/run.sh [pattern]`).

**Spec:** the issue (https://github.com/kbajpai/codeo/issues/207), `.codeo/207/plan.md` (Q1-Q11) and `.codeo/207/qc.md` round 2 (F7-F11).

**How each task is proved.** The one suite is `shell`; it has no single-test filter, but `tests/run.sh <pattern>` runs the files whose name contains the pattern, so a task's proof is `bash tests/run.sh <pattern>` and the last task's is `bash tests/run.sh` (ending `all cases passed`).

## Global Constraints

- **Decisions taken (dossier):** Q11 the fragment `changelog.d/207.md` is this issue's changelog entry; `CHANGELOG.md` is not edited on this branch. F7-F10 as in `plan.md`'s round-3 notes.
- **No new `dossier-check.sh` check** for `Graded base:`: a new finding would break adopters' golden replays; the reader is made tolerant instead.
- **Rules touched:** `qc-16` changes text (Task 1); Task 1 runs `bash tests/inventory.test.sh --update` and commits the pin. `docs/skills-inventory.md` keeps one blank line between rule bullets. `plan-11` and `close-18` keep their text (Task 3 edits sentences around them, not the rules).
- **Reach.** Skill text applies in this repository after the next release and pin bump; `scripts/base-moved.sh` and `tools/changelog.sh` take effect when they merge.
- **Documentation moved:** `docs/dossier.md` (Tasks 1, 3), `README.md`, `docs/skills.md`, `CONTRIBUTING.md`, `docs/release-checklist.md`, `changelog.d/207.md` (Task 4). Present tense, no issue numbers, no history words.
- **No invariants document and no shared environment are configured**: no `Needs lease:` task, none runs on the engineer's host.
- **This round's footprint is round 2's plus this plan file.** No new path outside it.
- **Not done, by decision:** a stripped caution reason may keep punctuation (`No.`); long lines in `skills/close/SKILL.md` step 11 are not re-wrapped; the inflight test asserts only the `/codeo:implement` leg.

---

### Task 1: The graded base is the commit the graded tree contains (F7, F8)

`skills/qc/SKILL.md` rule qc-16 records `Graded base: <sha>` from `git rev-parse origin/<base>`. The same pass can fetch again, so that ref can be newer than what was merged and graded; `scripts/base-moved.sh` then misses the commits in between. And the reader, `sed -n 's/^Graded base: *\([^[:space:]]*\).*$/\1/p'` (line 33), matches a bare line only: `- Graded base: <sha>` or a backticked sha gives exit 4, and close merges.

**Files:** `docs/skills-inventory.md` (`qc-16`), `skills/qc/SKILL.md`, `scripts/base-moved.sh`, `tests/base-moved.test.sh`, `tests/qc-skill.test.sh`, `docs/dossier.md`, the pin.

New `qc-16` text: "Each round that was graded records the base commit its tree contains, `git merge-base HEAD origin/<base>`, on a `Graded base:` line, and a round that merged base commits first says how many."

- [ ] **Step 1 — failing tests** in `tests/base-moved.test.sh` (its scratch helpers exist; read them first):
  - `list_item_and_backticks_are_read`: `- Graded base: <sha>`, `Graded base: \`<sha>\`` and `- Graded base: \`<sha>\`` each resolve the sha (assert exit 3 and the path, as the bare-line case does).
  - `a_sha_newer_than_the_graded_tree_cannot_hide_changes`: the branch merged the base at commit B1 (its tree contains B1); the base then gains B2 touching a branch-changed file; `qc.md` records B2 as `Graded base:` (the false record). Expected: exit 3 and the path, because the comparison starts from `git merge-base <sha> HEAD` (= B1), not from the recorded sha.
  - `update_branch_state`: HEAD already contains the new base (an *Update branch* merge) whose commits touched a branch-changed file since the graded sha: exit 3 and the path; and with base commits touching only other files: exit 0.
  - Run `bash tests/run.sh base-moved`. Expected: the first two fail (exit 4, and exit 0).
- [ ] **Step 2 — the script.** In `scripts/base-moved.sh`: read the last line matching `^[[:space:]]*(- )?Graded base:` and take the sha with any surrounding backticks stripped; after validating it as a commit, set `from=$(git merge-base "$sha" HEAD)` (when there is no merge base, keep `$sha`) and diff `"$from"` against `origin/<base>`; update the header comment (the line forms accepted, the merge-base rule, and that the exit-1 and exit-4 lines go to stderr).
- [ ] **Step 3 — the skill and the page.** Update `qc-16` in `docs/skills-inventory.md`; in `skills/qc/SKILL.md` the qc-16 paragraph: the sha is `git merge-base HEAD origin/<base>`, taken straight after the sync exits 0, written as a bare line (no bullet, no backticks); the rest of the paragraph stands. `docs/dossier.md` (*What a round graded*): the same definition. Pins in `tests/qc-skill.test.sh` for `git merge-base HEAD origin/<base>` and "bare line" (RED first: `bash tests/run.sh qc-skill` fails on them). Run `bash tests/inventory.test.sh --update`; commit the pin (one line, `qc-16`, changes).
- [ ] **Step 4 — prove it.** `bash tests/run.sh base-moved`, `qc-skill`, `skills`, `inventory`, `dossier-check` → each ends `all cases passed`.

**Proof of done:** `bash tests/run.sh base-moved` → `all cases passed`.

### Task 2: The release tool keeps every note (F9, F10, F11)

**Files:** `tools/changelog.sh`, `tests/changelog.test.sh`.

Today (`tools/changelog.sh` lines 83-116): the first value beginning with the word `yes` is kept and later ones dropped; `Config schema:` defaults to the literal `1 (unchanged)` (line 120).

- [ ] **Step 1 — failing cases** in `tests/changelog.test.sh`:
  - `yes_notes_are_all_kept`: `yes, with one step: run codeo update` and `yes, after you restart sessions` assemble to `Safe to bump mid-workflow: yes, with one step: run codeo update; yes, after you restart sessions` (values that begin with `yes` and carry text, distinct, in fragment-number order, joined with `; `); a bare `yes` beside one note gives the note alone; two identical notes give it once; bare `yes` values only, or none, give `yes`; any caution still wins as before (`yes, with a step` + `no — a` → `no — a`).
  - `config_schema_follows_the_newest_section`: with no `Config schema:` header in any fragment and a `CHANGELOG.md` whose newest section says `Config schema: 2 (adds x)`, the new section says `Config schema: 2 (unchanged)`; with the fixture's `Config schema: 1 (unchanged)` it says `1 (unchanged)`; with no readable `Config schema:` line in the newest section, exit 1 with `changelog: cannot read Config schema from CHANGELOG.md; say it in a fragment` and nothing written or deleted.
  - `blank_lines_after_the_header_do_not_leak`: a fragment with three blank lines between its header and its first bullet leaves no blank line between the previous fragment's bullets and its own.
  - `bad_version_or_date`: `assemble 1.0.12 2026-12-01`, `assemble v1.0 2026-12-01` and `assemble v1.0.12 12/01/2026` exit 2 with the usage line and write nothing; `no_changelog_file`: exit 1 with `changelog: no CHANGELOG.md here`.
  - Run `bash tests/run.sh changelog`. Expected: the new cases fail.
- [ ] **Step 2 — implement** to that behaviour; the existing cases must pass unchanged, except the one named "Yes with a note is a yes", which gets a real note.
- [ ] **Step 3 — prove it.** `bash tests/run.sh changelog` → `all cases passed`.

**Proof of done:** `bash tests/run.sh changelog` → `all cases passed`.

### Task 3: Text the skills left open (F11 and carried minors)

Text only. Each sentence gets a pin first.

**Files:** `skills/close/SKILL.md`, `skills/plan/SKILL.md`, `skills/init/SKILL.md`, `docs/dossier.md`, `tests/close-skill.test.sh`, `tests/plan-skill.test.sh`, `tests/init-skill.test.sh`.

- [ ] **Step 1 — failing pins**, then the text:
  - `skills/close/SKILL.md` step 9, exit 1 of `base-moved.sh`: after quoting the stderr line, name the way on: when the line says the sha is not a commit, `git fetch --unshallow` (a shallow clone) or `git fetch origin` and run the step again; still failing, run `/codeo:qc` again, which records a new `Graded base:`.
  - `skills/close/SKILL.md` step 11: when review feedback and a moved base arrive in the same pass, the round is headed `— review feedback` and lists the moved paths after the review's points under the words `Base moved under graded files:`; one round, one send-back.
  - `skills/plan/SKILL.md` and `docs/dossier.md` (*The footprint*): several clauses on the `sequenced:` line are separated by `; `.
  - `skills/plan/SKILL.md` step 8, the suffix rule: a path with no directory segment where the wildcard stands (a file directly under `skills/`) names no lease and is not listed under `exclusive:`.
  - `skills/init/SKILL.md` step 3: drop "no resources configured" from the failures of the lease read (it prints nothing and exits 0); keep "origin unreachable" and "a non-zero exit".
  - Do not change the rule texts in `docs/skills-inventory.md`; `bash tests/inventory.test.sh` must pass with no `--update`.
- [ ] **Step 2 — prove it.** `bash tests/run.sh close-skill`, `plan-skill`, `init-skill`, `skills`, `inventory`, `dossier-check` → each ends `all cases passed`.

**Proof of done:** `bash tests/run.sh close-skill` → `all cases passed`.

### Task 4: The pages and the release entry

Documentation-only; proved by the documentation checks and by every link resolving.

- [ ] **Step 1 — the pages:**
  - `README.md` and `docs/skills.md`, the `/codeo:qc` entries: `Graded base:` is the base commit the graded tree contains; the `/codeo:close` entries: add that exit 4 says in one line that the QC round predates `Graded base:`.
  - `CONTRIBUTING.md` (*Changelog entries*): `yes` values that carry a note are all kept and joined with `; `; `Config schema:` defaults to the newest section's number with `(unchanged)`; a fragment that changes the schema says so.
  - `docs/release-checklist.md` step 6: read the assembled `Config schema:` line; `assemble` takes a `vX.Y.Z` version and a `YYYY-MM-DD` date.
  - `changelog.d/207.md`: correct the bullets and the `Shared state:` line where this round changed behaviour (`Graded base:` is a merge base; nothing else moves).
- [ ] **Step 2 — prove it.** `bash tests/run.sh readme`, `skills-doc`, `changelog`, `dossier-check` → each ends `all cases passed`; grep the added lines of the pages for issue numbers and `now`, `no longer`, `previously`: none.

**Proof of done:** `bash tests/run.sh skills-doc` → `all cases passed`.

### Task 5: The whole suite and the footprint

- [ ] **Step 1.** `bash tests/inventory.test.sh --update`; commit the fixture only if it changed.
- [ ] **Step 2.** `bash tests/run.sh` → ends `all cases passed`; `bash scripts/overlap.sh --outside 207` → prints nothing; `git diff --summary` over the round shows no mode change.
- [ ] **Step 3 — the findings, each by its proof.** F7 and F8 `bash tests/run.sh base-moved` and `qc-skill`; F9 and F10 `bash tests/run.sh changelog`; F11 `bash tests/run.sh close-skill`, `plan-skill`, `init-skill`.
- [ ] **Step 4 — F9 by hand.** In a scratch copy (never in the repository): two fragments `yes, with one step: run codeo update` and `yes, after you restart sessions`; `bash tools/changelog.sh assemble v9.9.9 2026-12-01`; the `Safe to bump mid-workflow:` line holds both notes.

**Proof of done:** `bash tests/run.sh` → `all cases passed`.

## Self-review

- Every blocking finding of `qc.md` round 2 (F7-F9) has a task and a proof; F10 and the F11 items are Tasks 2 and 3; the items left are listed under Global Constraints.
- The fifth acceptance criterion is settled by Q11: the fragment is the entry.
