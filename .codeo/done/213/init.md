# Init — #213

| | |
|---|---|
| Issue | #213 |
| Step | init |

## Where this stands

Approved. Branch `feat/213-release-v1-0-11-main` off `main` at `3857710f1421e38c4bc632ea225385c8a81fa2bc`, claimed with the create-only push. Next: `/codeo:plan`, in the issue's container.

## Questions

None.

## Outcome

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/213 — Release v1.0.11 from main, check the README, and pin codeo to it |
| State | open · labels `enhancement`, `priority: medium` |
| Branch | `feat/213-release-v1-0-11-main` off `main` at `3857710f1421e38c4bc632ea225385c8a81fa2bc` |
| Board | Ready → In progress |

**Problem.** The latest release is v1.0.10 (2026-11-26) and this project pins it. #188, #190, #192, #195, #204, #206 and #211 have merged since and sit under `## Unreleased` in `CHANGELOG.md`, including a Shared state change. They reach no session or container until v1.0.11 is cut from `main` (README checked against the code, version and changelog PR, clean-clone test, tag, GitHub Release) and the pin in `.codeo/config.json` moves to it in a second PR.

**Acceptance criteria** — verbatim from the issue, unchecked:
- [ ] Every mismatch between `README.md` and the code at the release commit is fixed in the release PR, and `bash tests/readme.test.sh` passes.
- [ ] `.claude-plugin/plugin.json` says `1.0.11` and `CHANGELOG.md` has a `## v1.0.11 — <date>` section in place of `## Unreleased`, with an entry for each of #188, #190, #192, #195, #204 and #206, merged through a pull request.
- [ ] `bash tests/run.sh` in a clean clone of the merged commit ends `all cases passed`.
- [ ] `git ls-remote --tags origin` lists `v1.0.11` pointing at that merged commit.
- [ ] `gh release view v1.0.11` shows a release for the tag.
- [ ] `.codeo/config.json` `plugin.ref` is `v1.0.11`, merged through its own pull request.
- [ ] After a dev container rebuild or restart, the installed codeo plugin reports v1.0.11.

**Out of scope.** Waiting for #205, #207 or any other issue, and issues filed after #213; pins other than this project's `.codeo/config.json`; changing the release checklist or adding release automation.

**Open at intake.** None.

## Log

- 2026-11-27 — initialized: branch feat/213-release-v1-0-11-main off main at 3857710f1421e38c4bc632ea225385c8a81fa2bc · cost: unavailable
