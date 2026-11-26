# Issue #168 — init

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/168 |
| Branch | `feat/release-v1-0-9-once` |
| Updated | 2026-11-25 |

## Where this stands

Initialized: branch `feat/release-v1-0-9-once` cut off `origin/main` at `24577accbc2271bcf7c8681f87e00c12d03c9392`, and pushed. Next step: `/codeo:plan` in the issue's container.

## Questions

None.

## Notes

2026-11-25 (added by #177): #161 had no bullet under ## Unreleased when the Outcome's Problem paragraph says it sat there; plan.md Q2 and its Intake note record the correction.

## Outcome

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/168 — Release v1.0.9 once #163 and #166 are closed, and pin codeo to it |
| State | open · labels `enhancement` |
| Branch | `feat/release-v1-0-9-once` off `main` at `24577accbc2271bcf7c8681f87e00c12d03c9392` |
| Board | Ready → In progress |

**Problem.** Cut release v1.0.9 from `main` and pin this project's own codeo to it. #154, #152, #157 and #161 have merged since v1.0.8 and sit under `## Unreleased` in `CHANGELOG.md`; the gating issues #163 and #166 are now both closed, so the release can start. It is two pull requests, because the tag must exist before the pin: a version bump and changelog PR, then the `plugin.ref` pin.

**Acceptance criteria** — verbatim from the issue, unchecked:
- [ ] #163 and #166 are both closed before the release PR is opened.
- [ ] `CHANGELOG.md`'s `## v1.0.9 — <date>` section has an entry for each gating issue that merged work to `main` (#163 and #166, unless closed without merging), alongside the entries already under `## Unreleased`.
- [ ] `.claude-plugin/plugin.json` says `1.0.9` and `CHANGELOG.md` has a `## v1.0.9 — <date>` section in place of `## Unreleased`, merged to `main` through a pull request.
- [ ] `bash tests/run.sh` run in a clean clone of the merged commit ends `all cases passed`.
- [ ] `git ls-remote --tags origin` lists `v1.0.9` pointing at that merged commit.
- [ ] `gh release view v1.0.9` shows a release for the tag.
- [ ] `.codeo/config.json` `plugin.ref` is `v1.0.9`, merged through its own pull request.
- [ ] After a dev container rebuild or restart, the installed codeo plugin reports v1.0.9.

**Out of scope.** Any issue other than the two named, and waiting for them; issues filed after this one (they ship in a later release with their own release issue); changing the release checklist or adding release automation; doing or speeding up the work of the two gating issues.

**Open at intake.** None. The issue records that the gating list is fixed, tagging is the engineer's own action (an agent does not push the tag), and the version is a patch bump.

## Log

- 2026-11-25 — initialized: branch feat/release-v1-0-9-once off main at 24577accbc2271bcf7c8681f87e00c12d03c9392 · 2m · sonnet-5-5 18k in + 806k cached / 4k out
