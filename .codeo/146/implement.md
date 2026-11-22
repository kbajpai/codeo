# Issue #146 — implement

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/146 |
| Branch | `feat/release-v1-0-8-once` |
| Updated | 2026-11-22 |

## Where this stands

Plan `docs/plans/2026-11-22-release-v1-0-8.md` (committed and pushed at the engineer's confirmation that it is final). `sync-main.sh`: the branch already contains `origin/main` (`6ccd510`); `overlap.sh` printed nothing.

Task 1 is done: release PR https://github.com/kbajpai/codeo/pull/158 (`release/v1.0.8`, one commit off `6ccd510`) changes exactly `.claude-plugin/plugin.json`, `CHANGELOG.md`, `README.md` and `tests/install.test.sh`. The plan's Step 6 values all matched (13 bullets under `## v1.0.8`, 18 under `## v1.0.7`, the #118 bullet once under `## v1.0.8`, no `1.0.6` left in the README or the test), and `bash tests/run.sh` in the release worktree ended `all cases passed`. On the PR, `qc-verdict` passes and `tests` was still running when this was written.

Task 2 done: you merged PR #158 as `ee0c02069817ffffde4a884c420ded16b76ee4f2` (`release: v1.0.8 (#158)`, the tip of `main`); the release worktree is removed. Task 3 done: in a clean clone checked out at that commit, `git rev-parse HEAD` is `ee0c02069817ffffde4a884c420ded16b76ee4f2`, `.claude-plugin/plugin.json` says `1.0.8` and `bash tests/run.sh` ends `all cases passed`.

Task 4 done: you pushed the lightweight tag; `git ls-remote --tags origin v1.0.8` prints `ee0c02069817ffffde4a884c420ded16b76ee4f2	refs/tags/v1.0.8` and no `^{}` line. Task 5 done: Release https://github.com/kbajpai/codeo/releases/tag/v1.0.8, title `v1.0.8`, `Latest`, not a draft or prerelease, notes the changelog section only (first line `Config schema: 1 (adds …`, 13 bullets, no generated notes). Task 6 done: `.codeo/config.json` `plugin.ref` is `v1.0.8` on this branch; `bash tests/run.sh` ends `all cases passed`.

**Waiting at Task 7 (yours):** rebuild or restart this dev container, start a new Claude Code session, and run `claude plugin list`; `codeo@codeo` should show `Version: 1.0.8`. Then run `/codeo:implement` again (or tell me) and I record it and hand off to `/codeo:qc`.
## Questions

None.

## Notes

Task 1 was done directly rather than through a subagent: it is a handful of mechanical edits and `gh` calls in a worktree, as Tasks 1, 3 and 5 were for #100. The plan's own proofs were run.

## Outcome

_Pending — written at the hand-off._

## Log

- 2026-11-22 — Task 1 done, release PR #158 opened; waiting at Task 2 for the engineer's merge · cost: unavailable until the hand-off
- 2026-11-22 — Tasks 2-3 done (merged as ee0c020, clean-clone suite passed); waiting at Task 4 for the engineer's tag · cost: unavailable until the hand-off
- 2026-11-22 — Tasks 4-6 done (tag v1.0.8 at ee0c020, Release v1.0.8 published, pin set); waiting at Task 7 for the engineer's rebuild · cost: unavailable until the hand-off
