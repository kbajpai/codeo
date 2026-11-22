# Issue #146 — init

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/146 |
| Branch | `feat/release-v1-0-8-once` |
| Updated | 2026-11-22 |

## Where this stands

Branch `feat/release-v1-0-8-once` cut off `main` at `6ccd510909712e8525bceec5f29d8fcdcd4cdeb1`, claimed and pushed. Nothing is open; the next step is `/codeo:plan`, run in this issue's own container.

## Questions

None.

## Outcome

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/146 — Release v1.0.8 once #143, #144, #145, #138, #149 and #151 are closed, and pin codeo to it |
| State | open · labels `enhancement` |
| Branch | `feat/release-v1-0-8-once` off `main` at `6ccd510` |
| Board | Ready → In progress |

**Problem.** The six gating issues (#143, #144, #145, #138, #149, #151) are all closed, so v1.0.8 can be cut from `main`: a version-bump and changelog pull request (`version` in `.claude-plugin/plugin.json` only; `## Unreleased` retitled `## v1.0.8 — <date>` with its `Config schema`, `Shared state` and `Safe to bump mid-workflow` lines accurate, including the new optional `issue.priority` key), a clean-clone test of the merged commit, the `v1.0.8` tag (the engineer's own action, never an agent's), and a GitHub Release. A second pull request then moves this project's `.codeo/config.json` `plugin.ref` to `v1.0.8`, because the tag must exist first. Follows `docs/release-checklist.md` steps 6-8.

**Acceptance criteria** — verbatim from the issue, unchecked:
- [ ] #143, #144, #145, #138, #149 and #151 are all closed before the release PR is opened.
- [ ] `CHANGELOG.md`'s `## v1.0.8 — <date>` section has an entry for each gating issue that merged work to `main` (#143, #144, #145, #138, #149 and #151, unless closed without merging), alongside the entries already under `## Unreleased`.
- [ ] `.claude-plugin/plugin.json` says `1.0.8` and `CHANGELOG.md` has a `## v1.0.8 — <date>` section in place of `## Unreleased`, merged to `main` through a pull request.
- [ ] `bash tests/run.sh` run in a clean clone of the merged commit ends `all cases passed`.
- [ ] `git ls-remote --tags origin` lists `v1.0.8` pointing at that merged commit.
- [ ] `gh release view v1.0.8` shows a release for the tag.
- [ ] `.codeo/config.json` `plugin.ref` is `v1.0.8`, merged through its own pull request.
- [ ] After a dev container rebuild or restart, the installed codeo plugin reports v1.0.8.

**Out of scope.** Any issue other than the six named, and waiting for them; changing the release checklist or adding release automation; doing or speeding up the work of the six gating issues.

**Open at intake.** None. Version (v1.0.8), gating list and the second pin PR were decided by the engineer at filing.

## Log

- 2026-11-22 — initialized: branch feat/release-v1-0-8-once off main at 6ccd510909712e8525bceec5f29d8fcdcd4cdeb1 · cost: 0m · sonnet-5-5 17k in + 470k cached / 3k out
