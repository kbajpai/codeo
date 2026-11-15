# Issue #98 — implement

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/98 |
| Branch | `fix/fix-sync-main-sh-exiting` |
| Plan | `docs/plans/2026-11-15-sync-main-collation-and-sequenced-none.md` |
| Updated | 2026-11-15 |

## Where this stands

Round 1 done: the plan's three tasks are built, each passed its own spec-and-quality review, and a whole-branch review found nothing to fix. The build step (the `shell` suite's `build`, `true`) exits 0. No open question. Next is `/codeo:qc`, which runs the suite, the acceptance criteria and the independent code review.

## Questions

None.

## Notes

- `sync-main.sh` found the branch already contained `origin/main`; `overlap.sh 98` printed nothing, so there are no `also changed on main:` lines to re-check. #70 has not merged yet (Q1, proceed and coordinate): whichever branch merges second keeps both sets of lines in `CHANGELOG.md` and `tests/plan-skill.test.sh`.
- No shared environment is configured, so no lease was taken and nothing was deployed.
- The pre-flight scan of the plan found no conflicts and needed no rulings.

## Outcome

2026-11-15

**Built.** All three checklist tasks of the plan, each on its own commit, on the subagent model (`sonnet`):

- Task 1, `4242d60`: `scripts/sync-main.sh:51-52` runs both `sort` calls and the `comm` under `LC_ALL=C`, with one comment line above. A new case in `tests/sync-main.test.sh`, `clean merge under a collation that sorts paths differently from comm`, merges changes to `.codeo/x`, `.devcontainer/y` and `CHANGELOG.md` under `en_US.UTF-8` with a byte-order `comm` first on `PATH`; it asserts exit 0, empty stderr, three `also changed on main:` lines and each path, and prints `skip:` where the locale is missing. Written first and shown failing (exit want [0] got [1], `comm: file 1 is not in sorted order`); the controller re-ran it against the pre-fix script and it fails there too.
- Task 2, `83ffe18`: `skills/plan/SKILL.md` step 8 lists `sequenced:` as the fourth key, reading `none` when nothing was sequenced, and says `dossier-check.sh` fails a footprint without any of the four; step 10 sub-step 1 says the line stays `none` otherwise. `docs/dossier.md`'s `sequenced` bullet says the same and no longer says "only when". `tests/plan-skill.test.sh` pins the three skill needles and both `docs/dossier.md` checks. Written first and shown failing. `dossier-check.sh` and every fixture are untouched; `good-open-pending` and `bad-footprint` already show both outcomes.
- Task 3, `646046f`: one bullet last under `## Unreleased` in `CHANGELOG.md` (`#92, #95, #98`). The merge of `origin/main` was a no-op.

**Documentation pages changed.** `docs/dossier.md` (*The footprint*), `skills/plan/SKILL.md`, `CHANGELOG.md`.

**Build.** The `shell` suite's `build` is `true`: exit 0. Each implementer ran `bash tests/run.sh` (`all cases passed`); grading it is `/codeo:qc`'s.

**Deviations from the plan.** None.

**Review.** Task reviews: all three clean, no Critical or Important finding. The whole-branch review (on `sonnet`, as the project's subagent model never escalates) returned *ready to merge: yes*, with only cosmetic minors, none fixed: a ragged wrap at `skills/plan/SKILL.md:275-277` and a note that the test's `comm` shim assumes an external binary.

## Log

- 2026-11-15 — round 1: Tasks 1-3 built and reviewed, build exits 0 · cost: 33m · sonnet-5-5 260k in + 6.2M cached / 33k out
