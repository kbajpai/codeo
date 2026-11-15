# Issue #87 — implement

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/87 |
| Branch | `fix/dev-container-start-script-reports` |
| Plan | `docs/plans/2026-11-15-report-lock-file-naming-no-issue.md` |
| Updated | 2026-11-15 |

## Where this stands

Round 1 done: both plan tasks built and each passed its own spec-and-quality review. The build step (the `shell` suite's `build`, `true`) exits 0. No open question. Next is `/codeo:qc`, which runs the suite, the acceptance criteria and the independent code review.

## Questions

None.

## Notes

- `sync-main.sh` found the branch already contained `origin/main`; `overlap.sh 87` printed nothing.
- No shared environment is configured, so no lease was taken and nothing was deployed.

## Outcome

2026-11-15

**Built.** Both checklist tasks of the plan, each on its own commit, on the subagent model (`sonnet`):

- Task 1, `ea0b502`: step 3a of `.devcontainer/scripts/devcontainer-start.sh` has a new first arm. A regular, non-empty `.codeo/active` with no line matching `^issue:[[:space:]]*#*[0-9]+` adds one TODO (`.codeo/active names no issue, so it holds no usable lock: look at it, remove it if it is not yours, then re-run this script`), takes no lock and leaves the file as it is, on any branch. Seven new cases in `tests/devcontainer.test.sh` (newline only and text without an `issue:` line on an issue branch and on the base branch, `issue: none`, a detached HEAD, `issue: #55` as a held lock, a directory), written first and shown failing, plus one assertion added to `start_nonempty_lock_file_is_left_alone`. The file is compared byte for byte with `cmp`.
- Task 2, `9b5c9c7`: `.devcontainer/README.md` (*What the start script does*) and a bullet last under `## Unreleased` in `CHANGELOG.md`. The TODO sentence appears once in each of the three files, as the plan's proof asks.

**Documentation pages changed.** `.devcontainer/README.md`, `CHANGELOG.md`.

**Build.** The `shell` suite's `build` is `true`: exit 0. Each implementer ran `bash tests/run.sh` (`all cases passed`); grading it is `/codeo:qc`'s.

**Deviations from the plan.** None. The plan's Step 1 merge of `origin/main` in Task 2 was `Already up to date.`, so #83's CHANGELOG bullet is not in this tree yet; whichever branch merges second keeps both (plan.md Q1).

**Review.** Task reviews: both clean. Two non-blocking minors on Task 1, not fixed: `start_hash_issue_line_is_a_held_lock` relies implicitly on `DS_REPO` after the folder rename, and the `-f &&` before `-s` in the new arm, which excludes a directory on purpose, has no comment saying so. No separate whole-branch review was run: the diff is two commits and the independent review of the whole change is `/codeo:qc`'s.

## Log

- 2026-11-15 — round 1: Tasks 1-2 built and reviewed, build exits 0 · cost: 12m · sonnet-5-5 197k in + 3.9M cached / 23k out
