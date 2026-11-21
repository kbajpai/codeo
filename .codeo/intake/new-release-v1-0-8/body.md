### Description

Once #143, #144 and #145 have all closed, cut release v1.0.8 from `main`: a version bump and changelog pull request, a clean-clone test of the merged commit, the `v1.0.8` tag, and a GitHub Release for it. Then move this project's own codeo pin to the new tag so its sessions and dev containers run it.

### Motivation / Context

The latest release is v1.0.7 (2026-11-18), and this project pins it in `.codeo/config.json` (`plugin.ref`). Since then #102, #108, #112, #122, #126, #131 (with #123 and #125) and #133 have merged to `main`, and `CHANGELOG.md` collects them under `## Unreleased`. #133 adds the `codeo` host command, whose `codeo rm` deletes containers, volumes and sandboxes; #143 closes the findings that can remove unpushed work or print false advice, so the first release carrying `codeo rm` should include it. #144 and #145 are in flight too, so this release waits for those three and one version carries them all. #131's sandbox-lock change reaches a real sandbox only after a release carries it and the pin moves.

### Key Requirements

- The release starts only after #143, #144 and #145 are all closed. That list is fixed: an issue filed or started later, and #138 (in Backlog today), ships in a later version. A gating issue closed without merging (stashed or abandoned) counts as closed and its work is simply not in this release.
- Follow `docs/release-checklist.md` steps 6-8. Tagging is the engineer's own action; an agent does not push the tag.
- The version is v1.0.8, a patch bump as for earlier releases, even though #133 adds a host command and #102 an optional config key.
- The release PR sets `version` in `.claude-plugin/plugin.json` only, and retitles `## Unreleased` as `## v1.0.8 — <date>`, keeping its `Config schema`, `Shared state` and `Safe to bump mid-workflow` lines accurate for everything merged since v1.0.7, including the new optional `issue.priority` key.
- The merged commit the tag names is tested from a clean clone.
- A GitHub Release exists for the tag, as for earlier releases.
- Pinning this project to the new tag is a second pull request, because the tag must exist first.
- After the pin merges, this project's dev container and Claude Code sessions run the installed v1.0.8, not the cached v1.0.7.

### Acceptance Criteria
- [ ] #143, #144 and #145 are all closed before the release PR is opened.
- [ ] `CHANGELOG.md`'s `## v1.0.8 — <date>` section has an entry for each of the three that merged work to `main`, alongside the entries already under `## Unreleased`.
- [ ] `.claude-plugin/plugin.json` says `1.0.8` and `CHANGELOG.md` has a `## v1.0.8 — <date>` section in place of `## Unreleased`, merged to `main` through a pull request.
- [ ] `bash tests/run.sh` run in a clean clone of the merged commit ends `all cases passed`.
- [ ] `git ls-remote --tags origin` lists `v1.0.8` pointing at that merged commit.
- [ ] `gh release view v1.0.8` shows a release for the tag.
- [ ] `.codeo/config.json` `plugin.ref` is `v1.0.8`, merged through its own pull request.
- [ ] After a dev container rebuild or restart, the installed codeo plugin reports v1.0.8.

### Out of Scope

- #138 and any issue other than the three named, and waiting for them.
- Changing the release checklist or adding release automation.
- Doing or speeding up the work of the three gating issues.

### Reference

- `docs/release-checklist.md` (steps 6-8); `CHANGELOG.md` `## Unreleased`.
- Previous releases: #61 (v1.0.4), #65 and #66 (v1.0.5), #75 (v1.0.6), #100 (v1.0.7).
- Gating issues: #143, #144, #145.
- Run in this issue's request: `/codeo:issue` on 2026-11-21; version, gating and pin decided by the engineer.
