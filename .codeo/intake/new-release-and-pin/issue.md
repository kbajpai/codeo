# new-release-and-pin — issue

| | |
|---|---|
| Issue | not filed yet |
| Updated | 2026-11-27 |

## Where this stands

All questions answered ("go with your picks"); draft awaiting approval at the review gate.

## Questions

1. **Version.** v1.0.11 (patch) or v1.1.0 (minor)?
   **Answer:** v1.0.11 — a patch bump, as every earlier release including v1.0.10 (which also carried features).

2. **Gating.** Release what is on `main` now, or wait?
   **Answer:** Release what is on `main` now; no gating issues. #205, #207 and later work ship in a later release.

3. **Scope as in #182?**
   **Answer:** Yes: README checked against the code, release PR, clean-clone test, tag, GitHub Release, then a second PR pinning this project's `.codeo/config.json` only.

## Draft

Title: Release v1.0.11 from main, check the README, and pin codeo to it
Type: none (user-owned repo, no Issue Types). Labels: `enhancement`, `priority: medium` (rubric: worth doing, nothing blocked, the default).

### Description

Cut release v1.0.11 from `main`: check `README.md` against the code at the release commit and fix every mismatch, a version bump and changelog pull request, a clean-clone test of the merged commit, the `v1.0.11` tag, and a GitHub Release for it. Then move this project's own codeo pin to the new tag so its sessions and dev containers run it.

### Motivation / Context

The latest release is v1.0.10 (tagged 2026-11-26) and `.codeo/config.json` pins it (`plugin.ref`). Since then #188, #190, #192, #195, #204, #206 and #211 have merged to `main`; `CHANGELOG.md` collects them under `## Unreleased`, including a `Shared state` change (#195's `| Owner |` row, lock `user:` line and `override:` line; #206's `cleanup/removed/<N>.md` intake file). None of it reaches this project's sessions or dev containers until it is released and pinned.

### Key Requirements

- Release what is on `main` when work starts; no gating issues. Open issues such as #205 and #207, and anything filed later, ship in a later version.
- The version is v1.0.11, a patch bump as for earlier releases.
- Before tagging, `README.md` is read in full against the code at the release commit (commands, paths, output examples, config keys, links) and every mismatch is fixed in the release PR. `tests/readme.test.sh` still passes.
- Follow `docs/release-checklist.md` steps 6-8. Tagging is the engineer's own action; an agent does not push the tag.
- The release PR sets the version where the checklist says (`.claude-plugin/plugin.json`, the `README.md` installer examples, the `tests/install.test.sh` stubs, `docs/updating.md`) and retitles `## Unreleased` as `## v1.0.11 — <date>`, keeping its `Config schema`, `Shared state` and `Safe to bump mid-workflow` lines accurate for everything merged since v1.0.10.
- The merged commit the tag names is tested from a clean clone.
- A GitHub Release exists for the tag.
- Pinning is a second pull request (the tag must exist first), and covers only this project's `.codeo/config.json`.
- After the pin merges, this project's dev container and Claude Code sessions run the installed v1.0.11.

### Acceptance Criteria
- [ ] Every mismatch between `README.md` and the code at the release commit is fixed in the release PR, and `bash tests/readme.test.sh` passes.
- [ ] `.claude-plugin/plugin.json` says `1.0.11` and `CHANGELOG.md` has a `## v1.0.11 — <date>` section in place of `## Unreleased`, with an entry for each of #188, #190, #192, #195, #204 and #206, merged through a pull request.
- [ ] `bash tests/run.sh` in a clean clone of the merged commit ends `all cases passed`.
- [ ] `git ls-remote --tags origin` lists `v1.0.11` pointing at that merged commit.
- [ ] `gh release view v1.0.11` shows a release for the tag.
- [ ] `.codeo/config.json` `plugin.ref` is `v1.0.11`, merged through its own pull request.
- [ ] After a dev container rebuild or restart, the installed codeo plugin reports v1.0.11.

### Out of Scope

- Waiting for #205, #207 or any other issue; issues filed after this one.
- Pins other than this project's `.codeo/config.json`.
- Changing the release checklist or adding release automation.

### Reference

- `docs/release-checklist.md` (steps 6-8); `CHANGELOG.md` `## Unreleased`.
- Previous releases: #182 (v1.0.10), #168 (v1.0.9), #146 (v1.0.8), #100 (v1.0.7), #75 (v1.0.6).
- Merged since v1.0.10: #188, #190, #192, #195, #204, #206, #211.
- Run in this issue's request: `/codeo:issue` on 2026-11-27; version, gating and scope chosen by the assistant on the engineer's "go with your picks".

## Log

- 2026-11-27 — dossier opened; questions 1-3 answered with the assistant's picks; draft recorded for review.
