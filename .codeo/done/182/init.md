# Issue #182 — init

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/182 |
| Branch | `feat/182-release-v1-0-10-once` |
| Updated | 2026-11-26 |

## Where this stands

Initialized: branch `feat/182-release-v1-0-10-once` cut off `origin/main` at `89789dde2ff14ef65b66897a5daf5d843139687b`, and pushed. Next step: `/codeo:plan` in the issue's container.

## Questions

None.

## Outcome

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/182 — Release v1.0.10 once #173, #176, #177 and #179 are closed, check the README, and pin codeo to it |
| State | open · labels `enhancement`, `priority: medium` |
| Branch | `feat/182-release-v1-0-10-once` off `main` at `89789dde2ff14ef65b66897a5daf5d843139687b` |
| Board | Ready → In progress |

**Problem.** The latest release is v1.0.9; `main` now carries #170, #171, #173, #176, #177 and #179, collected under `CHANGELOG.md`'s `## Unreleased`. Cut v1.0.10: read `README.md` against the code and fix every mismatch, bump the version and retitle the changelog through a pull request, test the merged commit from a clean clone, tag it (the engineer's own action), publish a GitHub Release, then move this project's `plugin.ref` pin to v1.0.10 in a second pull request.

**Acceptance criteria** — verbatim from the issue, unchecked:
- [ ] #173, #176, #177 and #179 are all closed before the release PR is opened.
- [ ] Every mismatch found between `README.md` and the code at the release commit is fixed in the release PR, and `bash tests/readme.test.sh` passes.
- [ ] `CHANGELOG.md`'s `## v1.0.10 — <date>` section has an entry for each gating issue that merged work to `main` (unless closed without merging), alongside the entries already under `## Unreleased`.
- [ ] `.claude-plugin/plugin.json` says `1.0.10` and `CHANGELOG.md` has a `## v1.0.10 — <date>` section in place of `## Unreleased`, merged to `main` through a pull request.
- [ ] `bash tests/run.sh` run in a clean clone of the merged commit ends `all cases passed`.
- [ ] `git ls-remote --tags origin` lists `v1.0.10` pointing at that merged commit.
- [ ] `gh release view v1.0.10` shows a release for the tag.
- [ ] `.codeo/config.json` `plugin.ref` is `v1.0.10`, merged through its own pull request.
- [ ] After a dev container rebuild or restart, the installed codeo plugin reports v1.0.10.

**Out of scope.** Any issue other than the four named, and waiting for any other; issues filed after this one, #181 included (and #185, #188), which ship in a later release; changing the release checklist or adding release automation; doing or speeding up the gating issues' work.

**Open at intake.** None. Gate check: #173, #176, #177 and #179 are all Done on the board and merged to `main` (#184, #183, #186, #187).

## Log

- 2026-11-26 — initialized: branch feat/182-release-v1-0-10-once off main at 89789dde2ff14ef65b66897a5daf5d843139687b · cost: unavailable
