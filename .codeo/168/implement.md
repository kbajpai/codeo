# Issue #168 — implement

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/168 |
| Branch | `feat/release-v1-0-9-once` |
| Updated | 2026-11-25 |

## Where this stands

Plan: `docs/plans/2026-11-25-release-v1-0-9.md` (committed, `d71d60f`). Task 1 is done: the release PR is #174, https://github.com/kbajpai/codeo/pull/174, from `release/v1.0.9` (worktree `../codeo-168-release`), cut from `origin/main` at `24577ac`. Its proof held: base `main`, exactly the four files, `qc-verdict` passing; `tests` was still running when this was written. Task 2 done: #174 merged as `6e6628336c9bd40037c1cd7c80c8694f0ecddc21`. Task 3 done: a clean clone at that commit has `HEAD` equal to that SHA, version `1.0.9`, and `bash tests/run.sh` ends `all cases passed` (the clone is kept for Task 5). Task 4 done: `git ls-remote --tags origin v1.0.9` prints `6e6628336c9bd40037c1cd7c80c8694f0ecddc21	refs/tags/v1.0.9` (lightweight). Task 5 done: Release v1.0.9 published, marked Latest, not draft, 12 bullets, first line `Config schema: 1 (unchanged)`. Task 6 done: `.codeo/config.json` `plugin.ref` is `v1.0.9` and the suite ends `all cases passed`. **Waiting at Task 7: the engineer rebuilds or restarts the dev container and starts a new session; then `claude plugin list` must show `codeo@codeo` at `1.0.9`.**

Round 1 ran inline (`superpowers:executing-plans`), no subagents, because the plan's agent work is a few shell steps.

## Questions

None.

## Notes

- Step 6's `grep -c 'refs/tags/v1.0.8' tests/install.test.sh` printed `9`, not the plan's `2`. The plan's count was wrong: the 1.0.7 → 1.0.8 shift writes that string into other tests. The intent holds: lines 236 and 520 (the two skipped stubs) read as on `main`. Every other Step 6 result matched, including `bash tests/run.sh` → `all cases passed`.

## Outcome

_Pending — written at the hand-off._

## Log

- 2026-11-25 — Task 1 done, release PR #174 opened; stopped at Task 2 (the engineer's merge) · cost: 5m · sonnet-5-5 151k in + 1.2M cached / 4k out
