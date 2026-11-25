### Description

Once #163 and #166 have both closed, cut release v1.0.9 from `main`: a version bump and changelog pull request, a clean-clone test of the merged commit, the `v1.0.9` tag, and a GitHub Release for it. Then move this project's own codeo pin to the new tag so its sessions and dev containers run it.

### Motivation / Context

The latest release is v1.0.8 (2026-11-22), and this project pins it in `.codeo/config.json` (`plugin.ref`). Since then #154, #152 and #157 (with #161) have merged to `main`, and `CHANGELOG.md` collects them under `## Unreleased`. #152 changes the role guard (a new `stray` role, lock skills refused in `home`) and adds the tracking comment and `codeo-track.sh`, so a release carries them to users. #163 and #166 are the only issues open when this was filed, both in progress; they close the #152 and #157 leftovers, so this release waits for them and one version carries them all.

### Key Requirements

- The release starts only after #163 and #166 are both closed. That list is fixed: an issue filed or started later, including any leftovers those two produce, ships in a later version and gets its own release issue. A gating issue closed without merging (stashed or abandoned) counts as closed and its work is simply not in this release.
- Follow `docs/release-checklist.md` steps 6-8. Tagging is the engineer's own action; an agent does not push the tag.
- The version is v1.0.9, a patch bump as for earlier releases.
- The release PR sets `version` in `.claude-plugin/plugin.json` only, and retitles `## Unreleased` as `## v1.0.9 — <date>`, keeping its `Config schema`, `Shared state` and `Safe to bump mid-workflow` lines accurate for everything merged since v1.0.8, including whatever #163 and #166 change.
- The merged commit the tag names is tested from a clean clone.
- A GitHub Release exists for the tag, as for earlier releases.
- Pinning this project to the new tag is a second pull request, because the tag must exist first.
- After the pin merges, this project's dev container and Claude Code sessions run the installed v1.0.9, not the cached v1.0.8.

### Acceptance Criteria
- [ ] #163 and #166 are both closed before the release PR is opened.
- [ ] `CHANGELOG.md`'s `## v1.0.9 — <date>` section has an entry for each gating issue that merged work to `main` (#163 and #166, unless closed without merging), alongside the entries already under `## Unreleased`.
- [ ] `.claude-plugin/plugin.json` says `1.0.9` and `CHANGELOG.md` has a `## v1.0.9 — <date>` section in place of `## Unreleased`, merged to `main` through a pull request.
- [ ] `bash tests/run.sh` run in a clean clone of the merged commit ends `all cases passed`.
- [ ] `git ls-remote --tags origin` lists `v1.0.9` pointing at that merged commit.
- [ ] `gh release view v1.0.9` shows a release for the tag.
- [ ] `.codeo/config.json` `plugin.ref` is `v1.0.9`, merged through its own pull request.
- [ ] After a dev container rebuild or restart, the installed codeo plugin reports v1.0.9.

### Out of Scope

- Any issue other than the two named, and waiting for them.
- Issues filed after this one: they ship in a later release, tracked by their own release issue.
- Changing the release checklist or adding release automation.
- Doing or speeding up the work of the two gating issues.

### Reference

- `docs/release-checklist.md` (steps 6-8); `CHANGELOG.md` `## Unreleased`.
- Previous releases: #61 (v1.0.4), #65 and #66 (v1.0.5), #75 (v1.0.6), #100 (v1.0.7), #146 (v1.0.8).
- Gating issues: #163, #166.
- Run in this issue's request: `/codeo:issue` on 2026-11-25; version, gating and pin decided by the engineer.
