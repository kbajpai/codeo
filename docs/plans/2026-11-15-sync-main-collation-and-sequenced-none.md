# sync-main collation and `sequenced: none` Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `sync-main.sh` exits 0 and lists the both-changed paths after a clean merge whatever the locale, and `/codeo:plan`, `docs/dossier.md` and `dossier-check.sh` agree that a footprint always carries `sequenced:`, `none` when nothing was sequenced.

**Architecture:** Two independent fixes in one branch (issue #98 consolidates #92 and #95). The script fix pins byte order (`LC_ALL=C`) on the one `sort | sort | comm` line, so both sides of `comm` agree whatever the locale or coreutils. The wording fix changes the plan skill's step 8 and step 10 and the dossier protocol page to say what `dossier-check.sh` already enforces; the checker is not touched.

**Tech Stack:** bash, git, the repo's `tests/*.test.sh` harness (`bash tests/run.sh [pattern]`).

**Spec:** `.codeo/98/init.md` (`## Outcome`: the issue restated and its acceptance criteria) and `.codeo/98/plan.md` (`## Notes`: the cause, as reproduced). No standing reference doc: nothing here is a decision to be read later.

## Global Constraints

- No invariants document is configured, so there is no invariant to check; no shared environment, so no task carries `Needs lease:` and every task runs in this checkout; no `wiki` module, no `resources[]`.
- Out of scope, verbatim from the issue: any other script's use of `sort` or `comm`; the merge, conflict and abort logic of `sync-main.sh`; running `dossier-check.sh` earlier in qc or CI; fixing archived plans that lack the key; the re-planned footprint rule. `scripts/dossier-check.sh` and every fixture stay as they are.
- The change is one line of `scripts/sync-main.sh` (plus a comment): do not `export LC_ALL=C` for the whole script, because `git merge` would then run in a different locale.
- The `shell` suite has no `filter`, so each task's proof of done is the whole `bash tests/run.sh`; the narrower `bash tests/run.sh <pattern>` is used only for the red and green steps.
- **Documentation moved.** `docs/dossier.md → The footprint` (Task 2) and `CHANGELOG.md` (Task 3). `docs/handoff.md` names `sync-main.sh` but not its ordering, so it does not move. No `wiki` pages.
- **Overlap with #70 (Q1, proceed and coordinate).** #70 also changes `skills/plan/SKILL.md` (its `plan-03` paragraph in step 4, which this plan does not touch), `tests/plan-skill.test.sh` and `CHANGELOG.md`. Task 3 merges `origin/main` first, with `scripts/sync-main.sh` itself (fixed by Task 1), and keeps every existing line and bullet of both files if #70 has landed. `sequenced:` stays `none`.

## Review Focus

- A locale that is not installed: the new case must not fail a machine without `en_US.UTF-8` (Task 1 prints `skip:` and passes).
- A path changed on one side only must not appear in the `also changed on` list (the existing case `clean merge reports both-changed files` keeps pinning that; Task 1 leaves it as it is).
- No both-changed path at all: `comm` then prints nothing and exits 0, so the script still exits 0 (the same existing case's `a.txt` and `c.txt` assertions, and the `already contains` case, cover the nearest shapes).
- A footprint with `sequenced:` absent must still fail (`lacks: sequenced`): Task 2 runs `bash tests/run.sh dossier-check`, whose `bad-footprint` case pins it.

---

### Task 1: `sync-main.sh` exits 0 and lists both-changed paths whatever the collation

**Files:**
- Modify: `tests/sync-main.test.sh` (a new case, placed before the `base=develop` block)
- Modify: `scripts/sync-main.sh:51` (and one comment line above it)

**Interfaces:**
- Consumes: the test's existing helpers `setup`, `commit_in <repo> <file> <line1-text> <message>`, `run_sync [args]` (sets `status`, `out`, `err`), `assert_eq`, `assert_contains`, and the variables `origin`, `clone`, `scratch_root`, `case_desc`.
- Produces: nothing a later task uses.

Proof of done: `bash tests/run.sh` prints `all cases passed` and exits 0.

- [ ] **Step 1: Write the failing test.** A case named `clean merge under a collation that sorts paths differently from comm`, placed after the `dirty tree refused` case. Shape:
  - Skip when the locale is missing: `locale -a 2>/dev/null | grep -qix 'en_US\.utf-\?8'` fails, then `echo "skip: $case_desc — no en_US.UTF-8 locale installed"` and the case ends there (an `if`/`else`, not an `exit`).
  - `setup`, then in `origin` add `.codeo/x`, `.devcontainer/y` and `CHANGELOG.md`, each holding `one`/`two`/`three` on three lines, commit them, and bring the clone up to date with `git -C "$clone" fetch -q origin` and `git -C "$clone" merge -q --ff-only origin/main`.
  - On origin, `commit_in` line 1 of each of the three files (`main-x`, `main-y`, `main-c`); on the clone, rewrite line 3 of each (`sed -i '3s/.*/feat/' …`), `git add` and commit, as the existing both-changed case does for `b.txt`. No file conflicts.
  - A byte-order `comm`, which is what this container's `comm` always is and what makes the case fail on GNU coreutils too: `bindir=$scratch_root/bin`, `mkdir -p "$bindir"`, then `printf '#!/usr/bin/env bash\nLC_ALL=C exec %q "$@"\n' "$(command -v comm)" > "$bindir/comm"` and `chmod +x`.
  - Run it: `PATH="$bindir:$PATH" LC_ALL=en_US.UTF-8 run_sync`, then:

```bash
assert_eq "exit" 0 "$status"
assert_eq "stderr" "" "$err"
assert_eq "one line per both-changed path" 3 "$(grep -c 'sync-main: also changed on main:' <<<"$out")"
for p in .codeo/x .devcontainer/y CHANGELOG.md; do
    assert_contains "$p reported" "sync-main: also changed on main: $p" "$out"
done
```

- [ ] **Step 2: Run it to see it fail.** `bash tests/run.sh sync-main`. Expected: exit 1, with `FAIL: clean merge under a collation that sorts paths differently from comm — exit: want [0] got [1]` and a `stderr` failure whose text holds `comm: file 1 is not in sorted order`. (Tried in a scratch copy: three `also changed on main:` lines are printed, then exit 1 with three `comm:` lines on stderr.)

- [ ] **Step 3: Fix `scripts/sync-main.sh:51`.** Run both `sort` calls and the `comm` under `LC_ALL=C`, and say why in one comment line above it: `# Byte order on both sides: sort follows the locale, and some comm (uutils) always compares bytes.` The line becomes `LC_ALL=C comm -12 <(git diff … | LC_ALL=C sort) <(git diff … | LC_ALL=C sort) |` with its two `git diff` commands and the `while` loop on the next line unchanged.

- [ ] **Step 4: Run it to see it pass.** `bash tests/run.sh sync-main` → `all cases passed`, exit 0. Then `bash tests/run.sh` → `all cases passed`.

- [ ] **Step 5: Commit.**

```bash
git add scripts/sync-main.sh tests/sync-main.test.sh
git commit -m "fix: sync-main.sh exits 0 after a clean merge whatever the locale (#98)"
```

---

### Task 2: `sequenced:` is the fourth footprint key everywhere it is described

**Files:**
- Modify: `tests/plan-skill.test.sh` (new `must_contain` lines at the end of the list, and two `docs/dossier.md` checks)
- Modify: `skills/plan/SKILL.md` (step 8, the line `A key with nothing under it says \`none\`. Then run`; step 10 sub-step 1, the clause `(with a \`sequenced:\` line when an overlap question was answered that way)`)
- Modify: `docs/dossier.md:237` (the `sequenced` bullet under *The footprint*)

**Interfaces:**
- Consumes: `must_contain <case> <fixed string>` and `fail <message>` in `tests/plan-skill.test.sh`; `$plugin_root`.
- Produces: nothing a later task uses.

Proof of done: `bash tests/run.sh` prints `all cases passed` and exits 0.

- [ ] **Step 1: Write the failing tests** at the end of the list in `tests/plan-skill.test.sh`:

```bash
must_contain 'step 8 lists sequenced as the fourth key, none when nothing was sequenced' 'is the fourth key and reads `none` when nothing was sequenced'
must_contain 'step 8 says a footprint without the key fails' 'fails a footprint that lacks any of the four'
must_contain 'step 10 keeps sequenced none when nothing was sequenced' 'stays `none` otherwise'

dossier="$plugin_root/docs/dossier.md"
grep -qF -- 'only when an overlap question was answered that way' "$dossier" &&
    fail 'docs/dossier.md still says sequenced is written only when something was sequenced'
grep -qF -- '`sequenced` — `none` unless an overlap question was answered *sequence after #M*' "$dossier" ||
    fail 'docs/dossier.md does not say sequenced reads none unless something was sequenced'
```

- [ ] **Step 2: Run them to see them fail.** `bash tests/run.sh plan-skill` → exit 1, with the three `no […]` lines and the two `docs/dossier.md` lines.

- [ ] **Step 3: Edit `skills/plan/SKILL.md`.** Step 8: replace the line `A key with nothing under it says \`none\`. Then run` with this sentence, wrapped to the file's width, each needle on a single line: "`sequenced:` is the fourth key and reads `none` when nothing was sequenced; step 10 fills it in when an overlap question is answered *sequence after #M*. A key with nothing under it says `none`, and `dossier-check.sh` fails a footprint that lacks any of the four. Then run". Step 10 sub-step 1: replace "(with a `sequenced:` line when an overlap question was answered that way)" with "(its `sequenced:` line names the issue when an overlap question was answered that way, and stays `none` otherwise)", reflowed. Neither edit touches the `plan-03` paragraph (#70's).

- [ ] **Step 4: Edit `docs/dossier.md:237`.** The bullet becomes: "`sequenced` — `none` unless an overlap question was answered *sequence after #M*; then which issue this waits for, why, and the question that decided it. It is never left out: `dossier-check.sh` fails a block without it." The paragraph after the list (a key with nothing under it says `none`) already agrees and stays.

- [ ] **Step 5: Run the tests.** `bash tests/run.sh plan-skill` → `all cases passed`. Then `bash tests/run.sh dossier-check` → `all cases passed`: this is also the evidence for the two fixture criteria, with nothing new added, because `good-open-pending/plan.md` (a footprint drafted under `## Notes` with `sequenced:  none`) prints nothing and `bad-footprint` prints `lacks: sequenced`.

- [ ] **Step 6: Commit.**

```bash
git add tests/plan-skill.test.sh skills/plan/SKILL.md docs/dossier.md
git commit -m "fix: plan and dossier docs agree that sequenced reads none when nothing was sequenced (#98)"
```

---

### Task 3: Merge `origin/main`, record the change in `CHANGELOG.md`, and run the suite

**Files:**
- Modify: `CHANGELOG.md` (one bullet at the end of the `## Unreleased` list)

**Interfaces:**
- Consumes: Tasks 1 and 2 committed (the merge below runs the fixed `scripts/sync-main.sh`).
- Produces: nothing.

Proof of done: `bash tests/run.sh` prints `all cases passed` and exits 0; `git diff origin/main -- CHANGELOG.md` shows the new bullet and no removed line.

- [ ] **Step 1: Bring in `origin/main`.** `bash scripts/sync-main.sh` from the repo root, with the tree clean. Expected: exit 0, either `the branch already contains origin/main` or `merged origin/main` followed by its `also changed on main:` lines (which Task 3 copies into the round's `implement.md` entry, as the skill says). On exit 2, resolve every conflict by keeping both sides of `CHANGELOG.md` and `tests/plan-skill.test.sh` (#70's lines and this plan's) and commit.

- [ ] **Step 2: Add the bullet** to `CHANGELOG.md`, last in the `## Unreleased` list, in the file's existing style and ending `(#98)`: it says that `sync-main.sh` no longer exits 1 after a clean merge when `sort` and `comm` order the changed paths differently (the cause: a locale-collating `sort` against the byte-comparing `comm` of the 26.04 container's uutils coreutils, which printed `comm: file 1 is not in sorted order`, and `pipefail` ended the script after the merge, so the `also changed on <base>:` lines were lost and the round read as a stop); that both now run under `LC_ALL=C`; that `tests/sync-main.test.sh` reproduces it on any coreutils with a byte-order `comm` first on `PATH` and skips where `en_US.UTF-8` is not installed; that `/codeo:plan` step 8 and `docs/dossier.md → The footprint` now say `sequenced:` is the fourth key and reads `none` when nothing was sequenced, so a drafted footprint passes `dossier-check.sh`, which still fails one without the key; and that nothing in `lib/` or `hooks/` changes (#92, #95, #98).

- [ ] **Step 3: Run the whole suite.** `bash tests/run.sh` → `all cases passed`, exit 0.

- [ ] **Step 4: Commit.**

```bash
git add CHANGELOG.md
git commit -m "docs: record the sync-main collation fix and sequenced: none in the changelog (#98)"
```

---

## Self-review

- **Criteria.** 1-3 → Task 1 steps 1-4 (the case exits 0, prints the three lines, empty stderr; it fails on the unfixed script); 4 and 9 → each task's proof and Task 3 step 3; 5 → Task 3; 6 → Task 2 step 3; 7 → Task 2 step 4; 8 → Task 2 step 5 and the existing `good-open-pending` and `bad-footprint` fixtures.
- **Names.** `case_desc`, `run_sync`, `commit_in`, `must_contain`, `fail` are the files' own; the new needles in Task 2 step 1 are the ones Task 2 step 3 writes.
- **Proportion.** Three tasks, one line of script, three sentences of documentation, one test case and five test lines.

## Decisions and rejected options

- **Chosen:** `LC_ALL=C` on that one line, so both sides compare bytes. **Rejected:** `export LC_ALL=C` at the top, as `overlap.sh` does (it would run `git merge` in another locale, and the merge logic is out of scope); replacing `comm` with `grep -Fxf` (a bigger change than the bug).
- **Chosen:** the test puts a byte-order `comm` on `PATH` (Q2 b), so the case fails on GNU coreutils too. **Rejected:** real tools only (Q2 a), which CI could not use to catch the bug coming back.
- **Chosen:** change the plan skill and the dossier page to match the checker. **Rejected:** loosening `dossier-check.sh` to accept a missing `sequenced:` (out of scope, and a missing key is how a plan that never looked is told from one that found nothing).
- **Chosen:** no new fixture for the `sequenced:` criterion; the two existing ones already show both outcomes. **Rejected:** a new fixture (a copy of one that exists).
