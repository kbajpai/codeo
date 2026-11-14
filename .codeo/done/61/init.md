# Init — #61

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/61 |
| Updated | 2026-11-14 |

## Where this stands

Branch `chore/release-v1-0-4-main` off `main` at `f3a39d3`. Approved and claimed 2026-11-14; next is `/codeo:plan`.

## Questions

None.

## Outcome

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/61 — Release v1.0.4 from main |
| State | open · labels none |
| Branch | `chore/release-v1-0-4-main` off `main` at `f3a39d3` |
| Board | Ready → In progress |

**Problem.** The latest release is v1.0.3; ten PRs have merged to `main` since, collected under `## Unreleased` in `CHANGELOG.md`. Projects pinned to v1.0.3, this one included, still run the `board.sh set` that rejects lowercase `ready` (fixed by #39 on `main` only). Cut v1.0.4 from `main` (PR, clean-clone test, tag, GitHub Release), then pin this project to it in a second PR so its container and sessions run the new plugin.

**Acceptance criteria** — verbatim from the issue, unchecked:
- [ ] `.claude-plugin/plugin.json` says `1.0.4` and `CHANGELOG.md` has a `## v1.0.4 — <date>` section in place of `## Unreleased`, merged to `main` through a pull request.
- [ ] `bash tests/run.sh` run in a clean clone of the merged commit ends `all cases passed`.
- [ ] `git ls-remote --tags origin` lists `v1.0.4` pointing at that merged commit.
- [ ] `gh release view v1.0.4` shows a release for the tag.
- [ ] `.codeo/config.json` `plugin.ref` is `v1.0.4`, merged through its own pull request.
- [ ] After a dev container rebuild or restart, the installed codeo plugin reports v1.0.4 and `bash "$CODEO_ROOT/scripts/board.sh" set <N> ready` (lowercase) is accepted instead of failing with `no option 'ready'`.

**Out of scope.** Releasing any currently open issue's work, and waiting for it; changing the release checklist or adding release automation.

**Open at intake.** None. Note: the checklist says an agent does not tag, and the `v*` tag ruleset limits tags to an admin, so the tag push and the GitHub Release are the engineer's.

## Log

- 2026-11-14 — drafted, approved
- 2026-11-14 — initialized: branch chore/release-v1-0-4-main off main at f3a39d3 · cost: unavailable
