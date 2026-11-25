### Description

Once #173, #176, #177 and #179 have all closed, cut release v1.0.10 from `main`: check `README.md` against the code at the release commit and fix every mismatch, a version bump and changelog pull request, a clean-clone test of the merged commit, the `v1.0.10` tag, and a GitHub Release for it. Then move this project's own codeo pin to the new tag so its sessions and dev containers run it.

### Motivation / Context

The latest release is v1.0.9 (tagged 2026-11-24), and this project pins it in `.codeo/config.json` (`plugin.ref`). Since then #171 (README restructure) and #170 (host `codeo` command docs) have merged to `main`, and `CHANGELOG.md` collects them under `## Unreleased`. #173, #176, #177 and #179 are the issues In progress on the board when this was filed; #173, #177 and #179 close documentation leftovers and #176 adds macOS support for the sbx issue sandbox, several of them changing README text. This release waits for them so one version carries them all and the README is checked once they have landed.

### Key Requirements

- The release starts only after #173, #176, #177 and #179 are all closed. That list is fixed: an issue filed or started later, #181 and any leftovers these four produce included, ships in a later version and gets its own release issue. A gating issue closed without merging (stashed or abandoned) counts as closed and its work is simply not in this release.
- The version is v1.0.10, a patch bump as for earlier releases.
- Before tagging, `README.md` is read in full against the code at the release commit (commands, paths, output examples, config keys, and links to `docs/updating.md` and `docs/home-checkout.md`), and every mismatch is fixed in the release pull request. `tests/readme.test.sh` still passes.
- Follow `docs/release-checklist.md` steps 6-8. Tagging is the engineer's own action; an agent does not push the tag.
- The release PR sets `version` in `.claude-plugin/plugin.json`, the installer examples in `README.md` and the stubs of `tests/install.test.sh`, and retitles `## Unreleased` as `## v1.0.10 — <date>`, keeping its `Config schema`, `Shared state` and `Safe to bump mid-workflow` lines accurate for everything merged since v1.0.9.
- The merged commit the tag names is tested from a clean clone.
- A GitHub Release exists for the tag, as for earlier releases.
- Pinning this project to the new tag is a second pull request, because the tag must exist first.
- After the pin merges, this project's dev container and Claude Code sessions run the installed v1.0.10, not the cached v1.0.9.

### Acceptance Criteria
- [ ] #173, #176, #177 and #179 are all closed before the release PR is opened.
- [ ] Every mismatch found between `README.md` and the code at the release commit is fixed in the release PR, and `bash tests/readme.test.sh` passes.
- [ ] `CHANGELOG.md`'s `## v1.0.10 — <date>` section has an entry for each gating issue that merged work to `main` (unless closed without merging), alongside the entries already under `## Unreleased`.
- [ ] `.claude-plugin/plugin.json` says `1.0.10` and `CHANGELOG.md` has a `## v1.0.10 — <date>` section in place of `## Unreleased`, merged to `main` through a pull request.
- [ ] `bash tests/run.sh` run in a clean clone of the merged commit ends `all cases passed`.
- [ ] `git ls-remote --tags origin` lists `v1.0.10` pointing at that merged commit.
- [ ] `gh release view v1.0.10` shows a release for the tag.
- [ ] `.codeo/config.json` `plugin.ref` is `v1.0.10`, merged through its own pull request.
- [ ] After a dev container rebuild or restart, the installed codeo plugin reports v1.0.10.

### Out of Scope

- Any issue other than the four named, and waiting for any other.
- Issues filed after this one, #181 included: they ship in a later release, tracked by their own release issue.
- Changing the release checklist or adding release automation.
- Doing or speeding up the work of the four gating issues.

### Reference

- `docs/release-checklist.md` (steps 6-8); `CHANGELOG.md` `## Unreleased`.
- Previous releases: #61 (v1.0.4), #65 and #66 (v1.0.5), #75 (v1.0.6), #100 (v1.0.7), #146 (v1.0.8), #168 (v1.0.9).
- Gating issues: #173, #176, #177, #179.
- Run in this issue's request: `/codeo:issue` on 2026-11-25; version, gating, README scope and pin decided by the engineer.
