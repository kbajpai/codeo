# Issue #98 — qc

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/98 |
| Branch | `fix/fix-sync-main-sh-exiting` |
| Plan | `docs/plans/2026-11-15-sync-main-collation-and-sequenced-none.md` |
| Updated | 2026-11-15 |

## Where this stands

Round 1, stopped at step 2 on Q2: a re-sync after Q1 was answered showed a new overlap with #97 on four files. Q1 (#71, `CHANGELOG.md`) is answered: proceed and coordinate. Build, focused runs and the independent review were started before the overlap appeared; they are recorded under Notes, and the verdict waits for Q2.

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

_Pending — written at the hand-off._

## Log

- 2026-11-15 — Q1 raised (#71, CHANGELOG.md, glob:CHANGELOG.md) · cost: 0m · opus-5-5 183k in + 233k cached / 778 out
- 2026-11-15 — Q1 answered (proceed and coordinate); Q2 raised (#97, CHANGELOG.md, docs/dossier.md, skills/plan/SKILL.md, tests/plan-skill.test.sh) · cost: 2m · opus-5-5 44k in + 34k cached / 570 out · sonnet-5-5 38k in + 1.9M cached / 8k out
