# Issue #75 — init

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/75 |
| Branch | `chore/release-v1-0-6-main` |
| Updated | 2026-11-14 |

## Where this stands

Initialized. Branch `chore/release-v1-0-6-main` cut off `main` at 2a86915a1e4c282a1cc14a38013107ae7a23373e; the engineer approved the draft. Next: `/codeo:plan` in the issue's container, reading this file first.

## Questions

None.

## Outcome

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/75 — Release v1.0.6 from main and pin codeo to it |
| State | open · labels none |
| Branch | `chore/release-v1-0-6-main` off `main` at `2a86915` |
| Board | Ready → In progress |

**Problem.** v1.0.5 is the latest release (2026-11-14). #68 (dev container on ubuntu:26.04, #67) and #72 (closing blocks name only a command that can run, #69) have merged to `main` since and sit under `## Unreleased` in `CHANGELOG.md`. This project still pins `v1.0.5`. Cut v1.0.6 from `main` as it stands when the release PR is opened (version bump and changelog PR, clean-clone test, tag, GitHub Release), then move the pin to it in a second PR.

**Acceptance criteria** — verbatim from the issue, unchecked:
- [ ] `.claude-plugin/plugin.json` says `1.0.6` and `CHANGELOG.md` has a `## v1.0.6 — <date>` section in place of `## Unreleased`, merged to `main` through a pull request.
- [ ] `bash tests/run.sh` run in a clean clone of the merged commit ends `all cases passed`.
- [ ] `git ls-remote --tags origin` lists `v1.0.6` pointing at that merged commit.
- [ ] `gh release view v1.0.6` shows a release for the tag.
- [ ] `.codeo/config.json` `plugin.ref` is `v1.0.6`, merged through its own pull request.
- [ ] After a dev container rebuild or restart, the installed codeo plugin reports v1.0.6.

**Out of scope.** Releasing any currently open issue's work, and waiting for it. Changing the release checklist or adding release automation.

**Open at intake.** None. Q1-Q3 (version v1.0.6, release `main` at the time the release PR is opened, one issue with two PRs) were answered at filing.

## Log
- 2026-11-14 — initialized: branch chore/release-v1-0-6-main off main at 2a86915a1e4c282a1cc14a38013107ae7a23373e · cost: 1m · sonnet-5-5 14k in + 450k cached / 3k out
