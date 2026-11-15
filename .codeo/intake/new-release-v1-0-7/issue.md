# New issue — release v1.0.7 after the in-progress issues

| | |
|---|---|
| Issue | _not filed yet_ |
| Branch | _none — intake_ |
| Updated | 2026-11-15 |

## Where this stands

Draft written and presented for approval. Q1-Q2 answered in the conversation and recorded below.

## Questions

### Q1 — Which issues does the release wait for?

**Why it matters:** decides whether the issue names a fixed list (checkable) or a moving board state, and whether #99 (Backlog) is in it.
**Options:** fixed list #70, #71, #96, #97, #98 · those plus #99 · whatever is In progress at release time.

**Answer:**
Fixed list: #70, #71, #96, #97, #98. (Answered in the conversation, 2026-11-15.)

### Q2 — Which version number?

**Why it matters:** #70 adds a new skill (`/codeo:cleanup`); every release so far was a patch bump.
**Options:** v1.0.7 · v1.1.0 · decide at release time.

**Answer:**
v1.0.7. (Answered in the conversation, 2026-11-15.)

## Notes

Precedent: #61 (v1.0.4), #75 (v1.0.6) — same shape, two PRs (release, then pin). Repo has no Issue Types; earlier release issues carried no labels.

## Draft

**Title:** Release v1.0.7 once #70, #71, #96, #97 and #98 are closed, and pin codeo to it

**Issue Type:** none (repository has no Issue Types) · **Labels:** none

### Description

Once #70, #71, #96, #97 and #98 have all closed, cut release v1.0.7 from `main`: a version bump and changelog pull request, a clean-clone test of the merged commit, the `v1.0.7` tag, and a GitHub Release for it. Then move this project's own codeo pin to the new tag so its sessions and dev containers run it.

### Motivation / Context

The latest release is v1.0.6 (2026-11-14), and this project pins it in `.codeo/config.json` (`plugin.ref`). Since then #51, #52, #57, #73, #76, #83 and #87 have merged to `main` (PRs #78, #80, #82, #84, #89, #90, #93), and `CHANGELOG.md` collects them under `## Unreleased`. Five more issues are in progress on the board — #70, #71, #96, #97, #98 — and include fixes this project's own workflow needs (#98: `sync-main.sh` exiting 1 after a clean merge; `/codeo:plan` writing `sequenced: none`). Rather than release now and again shortly after, this release waits for those five so one version carries them all.

### Key Requirements

- The release starts only after #70, #71, #96, #97 and #98 are all closed. That list is fixed: an issue filed or started later, and #99 (in Backlog today), ships in a later version. A gating issue closed without merging (stashed or abandoned) counts as closed and its work is simply not in this release.
- Follow `docs/release-checklist.md` steps 6-7. Tagging is the engineer's own action; an agent does not push the tag.
- The version is v1.0.7, a patch bump as for earlier releases, even though #70 adds a skill.
- The release PR sets `version` in `.claude-plugin/plugin.json` only, and retitles `## Unreleased` as `## v1.0.7 — <date>`, keeping its `Config schema`, `Shared state` and `Safe to bump mid-workflow` lines accurate for everything the five issues changed.
- The merged commit the tag names is tested from a clean clone.
- A GitHub Release exists for the tag, as for earlier releases.
- Pinning this project to the new tag is a second pull request, because the tag must exist first.
- After the pin merges, this project's dev container and Claude Code sessions run the installed v1.0.7, not the cached v1.0.6.

### Acceptance Criteria

- [ ] #70, #71, #96, #97 and #98 are all closed before the release PR is opened.
- [ ] `CHANGELOG.md`'s `## v1.0.7 — <date>` section has an entry for each of the five that merged work to `main`, alongside the entries already under `## Unreleased`.
- [ ] `.claude-plugin/plugin.json` says `1.0.7` and `CHANGELOG.md` has a `## v1.0.7 — <date>` section in place of `## Unreleased`, merged to `main` through a pull request.
- [ ] `bash tests/run.sh` run in a clean clone of the merged commit ends `all cases passed`.
- [ ] `git ls-remote --tags origin` lists `v1.0.7` pointing at that merged commit.
- [ ] `gh release view v1.0.7` shows a release for the tag.
- [ ] `.codeo/config.json` `plugin.ref` is `v1.0.7`, merged through its own pull request.
- [ ] After a dev container rebuild or restart, the installed codeo plugin reports v1.0.7.

### Out of Scope

- #99 and any issue other than the five named, and waiting for them.
- Changing the release checklist or adding release automation.
- Doing or speeding up the work of the five gating issues.

### Reference

- `docs/release-checklist.md` (steps 6-7); `CHANGELOG.md` `## Unreleased`.
- Previous releases: #61 (v1.0.4), #65 and #66 (v1.0.5), #75 (v1.0.6).
- Gating issues: #70, #71, #96, #97, #98.

## Outcome

_Pending — written at filing._

## Log

- 2026-11-15 — Q1-Q2 asked and answered in conversation; draft written
