# Issue #75 — implement

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/75 |
| Branch | `chore/release-v1-0-6-main` |
| Plan | `docs/plans/2026-11-14-release-v1-0-6.md` |
| Updated | 2026-11-14 |

## Where this stands

Tasks 1-6 done: #77 merged as `041446924a2b81331b9b7cb22e073d590e85a4cc`; tag `v1.0.6` on origin names it; Releases v1.0.6 (Latest) and v1.0.5 published; `plugin.ref` is `v1.0.6` on this branch. **Waiting for the engineer to rebuild the dev container and start a new session (Task 7).**

## Questions

None.

## Notes

- Task 1 evidence: before the edit `jq -e '.version == "1.0.6"'` printed `false` and exited 1. After it: `true`, one `## v1.0.6 — 2026-11-14` heading, no `## Unreleased`, `git diff --name-only origin/main` listed exactly `.claude-plugin/plugin.json` and `CHANGELOG.md`, and `bash tests/run.sh` in the release worktree ended `all cases passed`. `gh pr view 77` printed `["main",[".claude-plugin/plugin.json","CHANGELOG.md"]]`. Release branch cut from `origin/main` at `2a86915`; worktree `../codeo-75-release`.
- The PR body carries the #51/#52 changelog coordination note (plan Q1, Q2, Q5).

- Task 2-3 evidence: `gh pr view 77` → `["MERGED","041446924a2b81331b9b7cb22e073d590e85a4cc"]`; worktree removed. Clean clone, `git rev-parse HEAD` printed that SHA, version `1.0.6`, `bash tests/run.sh | tail -1` printed `all cases passed`. `origin/main` tip is that commit.

- Task 4-5 evidence: `git ls-remote --tags origin v1.0.6` → `041446924a2b81331b9b7cb22e073d590e85a4cc	refs/tags/v1.0.6` (lightweight). Before: `gh release view` v1.0.6 and v1.0.5 both `release not found`. After: `gh release list` shows `release: v1.0.6` Latest above `release: v1.0.5` and `release: v1.0.4`; `gh release view v1.0.6` → `["v1.0.6","release: v1.0.6",false,false]`. Notes came from the changelog sections at the merge commit; v1.0.6 also has `--generate-notes`, v1.0.5 was `--latest=false`.
- Task 6 evidence: `jq -e '.plugin.ref == "v1.0.6"'` printed `false` before, `true` after; the diff is the one line; `bash tests/run.sh` ended `all cases passed`.

## Outcome

_Pending — written at the hand-off._

## Log

- 2026-11-14 — Task 1 done, PR #77 opened, waiting for the engineer's merge · cost: 3m · sonnet-5-5 15k in + 843k cached / 4k out
- 2026-11-14 — Tasks 2-3 done: #77 merged, clean-clone test passed, waiting for the engineer's tag
- 2026-11-14 — Tasks 4-6 done: tag verified, Releases v1.0.6 and v1.0.5 published, plugin.ref pinned, waiting for the container rebuild
