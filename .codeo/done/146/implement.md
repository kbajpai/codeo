# Issue #146 — implement

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/146 |
| Branch | `feat/release-v1-0-8-once` |
| Updated | 2026-11-22 |

## Where this stands

Round 1 is done and written up under `## Outcome`: Tasks 1-7 are complete and nothing is open. The next step is `/codeo:qc`.

## Questions

None.

## Notes

Task 1 was done directly rather than through a subagent: it is a handful of mechanical edits and `gh` calls in a worktree, as Tasks 1, 3 and 5 were for #100. The plan's own proofs were run.

## Outcome

### Round 1

**Built.** Release PR #158 (`release/v1.0.8`: `plugin.json` version 1.0.8; `CHANGELOG.md` retitled `## v1.0.8 — 2026-11-22`, its `Config schema` line naming the optional `issue.priority` key, the #118 bullet moved out of `## v1.0.7` to the end of `## v1.0.8`; `README.md` and `tests/install.test.sh` moved one version up) merged as `ee0c02069817ffffde4a884c420ded16b76ee4f2`. A clean clone at that commit reports `1.0.8` and `bash tests/run.sh` ends `all cases passed`. The engineer pushed the lightweight tag `v1.0.8` at that commit (`git ls-remote --tags origin v1.0.8` prints `ee0c020…	refs/tags/v1.0.8`, no `^{}` line). Release https://github.com/kbajpai/codeo/releases/tag/v1.0.8 is published, titled `v1.0.8`, `Latest`, notes the changelog section only (13 bullets, no generated notes). `.codeo/config.json` `plugin.ref` is `v1.0.8` on this branch, which `/codeo:close` opens as its own PR (criterion 7).

**Task 7 (criterion 8).** After the container was rebuilt, `claude plugin list` shows `codeo@codeo` `Version: 1.0.8` for both the user-scope and the project-scope entry, enabled. No finding.

**Base branch.** This round's `sync-main.sh` merged `origin/main` (one commit, the release merge `ee0c020`), so this branch now contains the release; against `main` it differs only by the pin, the plan and the dossier. `overlap.sh` printed nothing.

**Build.** The one configured suite (`shell`) has build command `true`; it exited 0. No shared environment is configured, so there is no lease and no deployment.

**Documentation pages changed:** `README.md` (its installer examples, in the release PR), as planned.

**Deviations from the plan:** Tasks 1, 3 and 5 were done directly rather than through a subagent (see Notes); the plan's own proofs were run. The release PR's `tests` check was still running when it was opened and was green when the engineer merged it.

## Log

- 2026-11-22 — Task 1 done, release PR #158 opened; waiting at Task 2 for the engineer's merge · cost: see the last line
- 2026-11-22 — Tasks 2-3 done (merged as ee0c020, clean-clone suite passed); waiting at Task 4 for the engineer's tag · cost: see the last line
- 2026-11-22 — Tasks 4-6 done (tag v1.0.8 at ee0c020, Release v1.0.8 published, pin set); waiting at Task 7 for the engineer's rebuild · cost: see the last line
- 2026-11-22 — Task 7 verified (both scopes report 1.0.8); Round 1 written up; built: ok · cost: 0m · sonnet-5-5 21k in + 379k cached / 836 out
