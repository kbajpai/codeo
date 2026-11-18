# Issue #100 — init

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/100 |
| Branch | `chore/release-v1-0-7-once` |
| Updated | 2026-11-18 |

## Where this stands

Branch `chore/release-v1-0-7-once` cut off `main` at `2dabf1f2ceaa783fa1cdfb0ca6503931aaa15ee5`, claimed and pushed. Nothing is open; the next step is `/codeo:plan`, run in this issue's own container.

## Questions

None.

## Outcome

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/100 — Release v1.0.7 once #70, #71, #96, #97 and #98 are closed, and pin codeo to it |
| State | open · no labels |
| Branch | `chore/release-v1-0-7-once` off `main` at `2dabf1f` |
| Board | Ready → In progress |

**Problem.** Cut release v1.0.7 from `main` now that the gating issues #70, #71, #96, #97 and #98 are all closed: a version bump and changelog pull request, a clean-clone test of the merged commit, the `v1.0.7` tag (the engineer's own action, never an agent's) and a GitHub Release. Then move this project's own codeo pin (`.codeo/config.json` `plugin.ref`, v1.0.6 today) to v1.0.7 in a second pull request, because the tag must exist first.

**Acceptance criteria** — verbatim from the issue, unchecked:
- [ ] #70, #71, #96, #97 and #98 are all closed before the release PR is opened.
- [ ] `CHANGELOG.md`'s `## v1.0.7 — <date>` section has an entry for each of the five that merged work to `main`, alongside the entries already under `## Unreleased`.
- [ ] `.claude-plugin/plugin.json` says `1.0.7` and `CHANGELOG.md` has a `## v1.0.7 — <date>` section in place of `## Unreleased`, merged to `main` through a pull request.
- [ ] `bash tests/run.sh` run in a clean clone of the merged commit ends `all cases passed`.
- [ ] `git ls-remote --tags origin` lists `v1.0.7` pointing at that merged commit.
- [ ] `gh release view v1.0.7` shows a release for the tag.
- [ ] `.codeo/config.json` `plugin.ref` is `v1.0.7`, merged through its own pull request.
- [ ] After a dev container rebuild or restart, the installed codeo plugin reports v1.0.7.

**Out of scope.** #99 and any issue other than the five named, and waiting for them. Changing the release checklist or adding release automation. Doing or speeding up the work of the five gating issues.

**Open at intake.** None. The issue's gate was met at this start: #70, #71, #96, #97 and #98 read `closed`.

**Scope decision at init.** #99 merged as #124 (`2dabf1f`) after the issue was written, and its CHANGELOG entry is already under `## Unreleased`. The engineer said to include #99 in v1.0.7, so the issue's "#99 … ships in a later version" and "that list is fixed" no longer apply to #99. The issue text is unchanged; `/codeo:plan` treats #99 as in this release.

## Notes

- 2026-11-18 — engineer: "go ahead with the init for #100 & include #99 also in it"

## Log

- 2026-11-18 — initialized: branch chore/release-v1-0-7-once off main at 2dabf1f2ceaa783fa1cdfb0ca6503931aaa15ee5 · cost: unavailable
