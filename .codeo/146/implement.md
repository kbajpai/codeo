# Issue #146 — implement

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/146 |
| Branch | `feat/release-v1-0-8-once` |
| Updated | 2026-11-22 |

## Where this stands

Plan `docs/plans/2026-11-22-release-v1-0-8.md` (committed and pushed at the engineer's confirmation that it is final). `sync-main.sh`: the branch already contains `origin/main` (`6ccd510`); `overlap.sh` printed nothing.

Task 1 is done: release PR https://github.com/kbajpai/codeo/pull/158 (`release/v1.0.8`, one commit off `6ccd510`) changes exactly `.claude-plugin/plugin.json`, `CHANGELOG.md`, `README.md` and `tests/install.test.sh`. The plan's Step 6 values all matched (13 bullets under `## v1.0.8`, 18 under `## v1.0.7`, the #118 bullet once under `## v1.0.8`, no `1.0.6` left in the README or the test), and `bash tests/run.sh` in the release worktree ended `all cases passed`. On the PR, `qc-verdict` passes and `tests` was still running when this was written.

**Waiting at Task 2 (yours):** merge PR #158 once its `tests` check is green. Then say it is merged; I read the merge commit, run Task 3 (clean-clone test) and hand you the three tag commands for Task 4. The release worktree `../codeo-146-release` stays until then.

## Questions

None.

## Notes

Task 1 was done directly rather than through a subagent: it is a handful of mechanical edits and `gh` calls in a worktree, as Tasks 1, 3 and 5 were for #100. The plan's own proofs were run.

## Outcome

_Pending — written at the hand-off._

## Log

- 2026-11-22 — Task 1 done, release PR #158 opened; waiting at Task 2 for the engineer's merge · cost: unavailable until the hand-off
