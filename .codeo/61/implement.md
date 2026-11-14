# Issue #61 — implement

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/61 |
| Branch | `chore/release-v1-0-4-main` |
| Plan | `docs/plans/2026-11-14-release-v1-0-4.md` |
| Updated | 2026-11-14 |

## Where this stands

Round 1, paused at Task 6 for the engineer's container rebuild. Tasks 1-5 are done. Task 4, checked 2026-11-14: `git ls-remote --tags origin 'v1.0.4' 'v1.0.4^{}'` printed `032b435f9b401c699328a5aa3ec9186300444d8f	refs/tags/v1.0.4` and `cf4618eed5d3c5f083db6b8f723ec4f02f5a7f38	refs/tags/v1.0.4^{}`, so the tag is annotated and names the merge commit. `gh release view v1.0.4` shows `release: v1.0.4`, not a draft, published 2026-11-14T01:28:38Z, with the changelog section and generated notes. The engineer's `git push origin v1.0.4` was rejected because the tag already existed on the remote; the engineer's checkout also has a local `v1.0.4` made by that command, which may be a different tag object from the remote's. Task 5: `.codeo/config.json` `plugin.ref` is `v1.0.4`, the only change, committed, and `bash tests/run.sh` ended `all cases passed`.

Earlier: Tasks 1-3 are done. Release PR #62 merged as `cf4618eed5d3c5f083db6b8f723ec4f02f5a7f38`, which is also the tip of `origin/main`. The release worktree is removed. The clean-clone test at that commit (fresh `git clone`, `git checkout --detach`) printed the commit, `1.0.4`, `## v1.0.4 — 2026-11-14` as the newest changelog heading, and ended `all cases passed`.

Next: the engineer tags and publishes the Release (Task 4) → I check criteria 3 and 4 and pin `.codeo/config.json` (Task 5) → the engineer rebuilds the container and I check the version and the board (Task 6).

## Questions

None.

## Notes

- Task 1 evidence: before the edit `jq -e '.version == "1.0.4"'` printed `false` and exited 1. After it: `true`, one `## v1.0.4 — 2026-11-14` heading, no `## Unreleased`, `git diff --name-only` listed exactly the two files, and `bash tests/run.sh` in the release worktree ended `all cases passed`. `gh pr view 62` printed `["main",[".claude-plugin/plugin.json","CHANGELOG.md"]]`.
- `sync-main.sh` reported the branch already contains `origin/main`; `overlap.sh 61` printed nothing.

## Outcome

_Pending — written at the hand-off._

## Log

- 2026-11-14 — Task 1 done, PR #62 opened, waiting for the engineer's merge · cost: 6m · sonnet-5-5 20k in + 1.1M cached / 3k out
- 2026-11-14 — Tasks 2-3 done: #62 merged as cf4618e, clean-clone test passed, waiting for the engineer's tag and Release · cost: 2m · sonnet-5-5
- 2026-11-14 — Tasks 4-5 done: v1.0.4 tag and Release verified, plugin.ref pinned to v1.0.4, waiting for the container rebuild · cost: 3m · sonnet-5-5
