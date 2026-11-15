# Issue #98 — qc

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/98 |
| Branch | `fix/fix-sync-main-sh-exiting` |
| Plan | `docs/plans/2026-11-15-sync-main-collation-and-sequenced-none.md` |
| Updated | 2026-11-15 |

## Where this stands

Round 1, done. Q1 (#71) and Q2 (#97) are answered, proceed and coordinate; the build, the whole suite and the independent review found no blocking finding. The verdict is clear and the route is `/codeo:close`.

## Questions

### Q1 — Overlap with #71 on `CHANGELOG.md` and `glob:CHANGELOG.md`: proceed and coordinate, sequence after #71, or re-scope?

**Why it matters:** #71 (branch `feat/file-new-issues-straight-board`, assignee kbajpai, step `init`, working) declares `CHANGELOG.md` in its footprint; its branch has changed nothing yet. This branch adds one bullet last under `## Unreleased` in `CHANGELOG.md` (commit `646046f`). If both add a bullet there, whichever merges second gets a small conflict in that list, resolved by keeping both bullets — the same arrangement plan.md Q1 made with #70. What overlaps is the path `CHANGELOG.md` and nothing else. *Proceed* lets this pass continue and this branch merge as it is; *sequence* would hold this branch until #71 merges, which has not started implementing; *re-scope* would drop the CHANGELOG entry, which acceptance criterion 5 does not allow.

**Options:** proceed and coordinate (recommended) · sequence after #71 · re-scope.

**Answer:**
Proceed and coordinate (engineer, in the conversation, 2026-11-15).


### Q2 — Overlap with #97 on `CHANGELOG.md`, `docs/dossier.md`, `skills/plan/SKILL.md` and `tests/plan-skill.test.sh`: proceed and coordinate, sequence after #97, or re-scope?

**Why it matters:** #97 (branch `docs/docs-skill-wording-test-guard`, assignee kbajpai, step `init`, working) appeared in `inflight.sh` after Q1 was answered and now declares a footprint that includes four files this branch changes: `CHANGELOG.md`, `docs/dossier.md`, `skills/plan/SKILL.md` and `tests/plan-skill.test.sh` (`overlap.sh 98` printed `97 CHANGELOG.md`, `97 docs/dossier.md`, `97 skills/plan/SKILL.md`, `97 tests/plan-skill.test.sh` `97 glob:CHANGELOG.md`, `97 glob:docs/dossier.md`, `97 glob:skills/plan/SKILL.md` and `97 glob:tests/plan-skill.test.sh`). Its branch has changed only its own dossier files so far (`changed: none`), and its plan has Q1-Q5 open. This branch's changes there are small and local: one bullet in `CHANGELOG.md`, one bullet in `docs/dossier.md`'s *The footprint*, two paragraphs of `skills/plan/SKILL.md` (steps 8 and 10), and new lines at the end of `tests/plan-skill.test.sh`. If #97 edits the same paragraphs, whichever branch merges second gets a conflict there. *Proceed* lets this branch merge as it is, with the second branch to merge keeping both sides; *sequence* would hold this branch until #97 has merged, which has not begun implementing; *re-scope* would drop part of acceptance criteria 5-8.

**Options:** proceed and coordinate (recommended: this branch is finished and #97 has not started implementing) · sequence after #97 · re-scope.

**Answer:**
Proceed and coordinate (engineer, in the conversation, 2026-11-15).

## Notes

Step 2 so far:

- `sync-main.sh --abort-on-conflict`: `sync-main: the branch already contains origin/main` (exit 0).
- `overlap.sh 98`:

  ```
  71	CHANGELOG.md
  71	glob:CHANGELOG.md
  ```

- No shared environment, no invariants file, no `wiki` module; the `qc` overlays `invariants-extra` and `wiki-rules` both exit 3.
- `scope.sh origin/main HEAD`: `scope: suite shell needed for unclassified paths: .codeo/98/implement.md, .codeo/98/init.md, .codeo/98/plan.md, CHANGELOG.md` then `suite.shell=true`.
- Step 3, build: the `shell` suite's `build` is `true`; exit 0.
- Step 4, focused runs on the pass's tree: `bash tests/run.sh sync-main`, `bash tests/run.sh plan-skill` and `bash tests/run.sh dossier-check` each printed `all cases passed`. The whole `bash tests/run.sh` was started in the background and the independent review (opus, `QC review:`) was dispatched on `git diff origin/main...HEAD` without `.codeo/` and `docs/plans/`; neither had reported when this stopped, so neither is quoted here as evidence. The next invocation starts the pass again from step 2 (`/home/dev/.claude/plugins/cache/codeo/codeo/1.0.6/docs/handoff.md`, qc-12) and runs both afresh.
- `overlap.sh --outside 98` printed nothing: the branch changed no file outside its footprint.

## Outcome

### Round 1 — 2026-11-15

**Commands run and their output**, on `HEAD` `659e94c` (the branch contains `origin/main`; the diff outside `.codeo/` and `docs/plans/` is 6 files, +54 −6):

- `bash scripts/sync-main.sh --abort-on-conflict` → `sync-main: the branch already contains origin/main`, exit 0. `overlap.sh 98` printed nothing, Q1 (#71) and Q2 (#97) having been answered *proceed and coordinate*. `overlap.sh --outside 98` printed nothing.
- `scope.sh origin/main HEAD` → `scope: suite shell needed for unclassified paths: .codeo/98/implement.md, .codeo/98/init.md, .codeo/98/plan.md, CHANGELOG.md` and `suite.shell=true`. No `deploy=` line: no environment is configured.
- Build: the `shell` suite's `build` is `true` → exit 0.
- Test: the `shell` suite's `test` is `bash tests/run.sh`, run whole → `all cases passed`, `suite exit=0`. Then `bash tests/run.sh sync-main`, `bash tests/run.sh plan-skill` and `bash tests/run.sh dossier-check` → each `all cases passed`.
- The new `sync-main` case against the pre-fix script (`git show origin/main:scripts/sync-main.sh` in a scratch copy of the tree) → `FAIL: clean merge under a collation that sorts paths differently from comm — exit: want [0] got [1]` and a stderr failure holding `comm: file 1 is not in sorted order`, `comm: file 2 is not in sorted order`.

**Criteria**

| # | Criterion | Verdict | Settled by |
|---|---|---|---|
| 1 | In a scratch repo whose merge touches paths that `sort` and `comm` order differently under `en_US.UTF-8`, `sync-main.sh` exits 0 and prints one `also changed on <base>:` line for each path changed on both sides | met | `tests/sync-main.test.sh` case `clean merge under a collation that sorts paths differently from comm`: asserts exit 0, exactly 3 such lines and each of `.codeo/x`, `.devcontainer/y`, `CHANGELOG.md`; passes on `HEAD`, output above |
| 2 | The same run prints no `comm:` warning | met | the same case asserts empty stderr; the pre-fix run above shows the `comm:` lines it would otherwise carry |
| 3 | A case in `tests/sync-main.test.sh` fails on the current script and passes on the fix | met | pre-fix run above fails (exit want [0] got [1]); `bash tests/run.sh sync-main` passes on `HEAD` |
| 4 | `bash tests/run.sh` passes | met | whole suite: `all cases passed`, exit 0 |
| 5 | `CHANGELOG.md` records the change | met | `CHANGELOG.md` diff: one bullet last under `## Unreleased` (`+1` line, no removals) |
| 6 | `skills/plan/SKILL.md` step 8 lists `sequenced:` with the other three keys and says it reads `none` when nothing was sequenced | met | `skills/plan/SKILL.md:232-234`; pinned by `tests/plan-skill.test.sh` (passes) |
| 7 | `docs/dossier.md → The footprint` no longer says `sequenced` is written only when something was sequenced, and agrees with the plan skill | met | `docs/dossier.md:237-239`; `grep -rn "only when an overlap question" docs skills scripts` finds nothing outside `docs/plans/`; pinned by `tests/plan-skill.test.sh` |
| 8 | A test or fixture shows a footprint drafted with `sequenced:  none` passes `dossier-check.sh`, and one without the key still fails with `lacks: sequenced` | met | existing fixtures: `good-open-pending/plan.md:36` (`sequenced:  none`, a drafted footprint under `## Notes`) prints nothing, and `bad-footprint` is expected to print `lacks: sequenced` at `tests/dossier-check.test.sh:54`; `bash tests/run.sh dossier-check` passes |
| 9 | `bash tests/run.sh` passes | met | as criterion 4 |

**Documentation check.** The change moves what two pages say: `docs/dossier.md → The footprint` (now agrees with the checker and the plan skill) and `skills/plan/SKILL.md` steps 8 and 10 (the skill's own text, which `tests/plan-skill.test.sh` pins). `docs/handoff.md` names `sync-main.sh` but not the ordering it uses, so no page describes the old behaviour; the plan's claim that no other page moves holds. Neither changed passage names an issue or says "now" or "no longer"; the `CHANGELOG.md` bullet names its issues, as the bullets there do. No `wiki` module, no `wiki-rules` overlay (exit 3), no diagram.

**Independent review** (opus, `QC review:`, given the criteria and the diff without `.codeo/` and `docs/plans/`; it also ran the new case against the pre-fix script and the whole suite). In its words: no Critical or Important defect, and "ready to merge: yes". It found the fix correct under `set -euo pipefail` when no path changed on both sides, the test isolated (shim on `PATH` for the one call only, scratch `HOME`), and the documents in agreement with `dossier-check.sh:35-36,339`. Its two minors are F1 and F2.

**Findings**

- F1 — non-blocking, `/codeo:implement`'s, polish: `skills/plan/SKILL.md:232-233` says "step 10 fills it in" when an overlap question is answered *sequence after #M*. Overlap questions are raised at step 8 as well, and their answers amend the draft before step 10 sub-step 1 writes it down, so step 10 is still where the line is written; the sentence is imprecise, not wrong.
- F2 — non-blocking, informational: the test's `comm` shim has no effect in this container, whose `comm` (uutils 0.10.0) already compares bytes; it matters on GNU coreutils, which is what it is for. Nothing to change.
- Recapped, not raised: the implement round's own minors (a ragged wrap at `skills/plan/SKILL.md:275-277`; `%q` quoting of the shim path assumes an external `comm`) were non-blocking and are not re-judged.

Issues filed for this pass: none.

**Verdict: clear — forward to `/codeo:close`.**

## Log

- 2026-11-15 — Q1 raised (#71, CHANGELOG.md, glob:CHANGELOG.md) · cost: 0m · opus-5-5 183k in + 233k cached / 778 out
- 2026-11-15 — Q1 answered (proceed and coordinate); Q2 raised (#97, CHANGELOG.md, docs/dossier.md, skills/plan/SKILL.md, tests/plan-skill.test.sh) · cost: 2m · opus-5-5 44k in + 34k cached / 570 out · sonnet-5-5 38k in + 1.9M cached / 8k out
- 2026-11-15 — round 1: build, suite and review pass, verdict clear · cost: 3m · opus-5-5 674 in + 59k cached / 2k out · sonnet-5-5 9k in + 2.1M cached / 4k out
