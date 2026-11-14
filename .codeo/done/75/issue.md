# Issue #75 — issue

| | |
|---|---|
| Source | Engineer: "Create issue to generate another release for the top of main & update the plugin version to latest." |
| Updated | 2026-11-14 |

## Where this stands

Approved and filed as #75 (https://github.com/kbajpai/codeo/issues/75). The problem restated: v1.0.5 (2026-11-14) is the latest release. Two PRs have merged to `main` since — #68 (dev container on `ubuntu:26.04`, #67) and #72 (closing blocks name only a command that can run, #69) — and `CHANGELOG.md` collects them under `## Unreleased` (Config schema 1, shared state unchanged, safe to bump mid-workflow). This project's own pin (`.codeo/config.json` `plugin.ref`) is still `v1.0.5`, so its sessions and dev containers run without #69's closing-block fixes. The ask is to cut the next release from `main` and move the pin to it, the same shape as #61 (v1.0.4) and #65/#66 (v1.0.5). No duplicate: the only release issue, #61, is closed; no open issue covers a release or the pin.


## Questions

### Q1 — Which version number?

**Why it matters:** sets the tag, the `plugin.json` version, the changelog heading, and the pin.
**Options:**
- **A — v1.0.6 (recommended).** Matches precedent: v1.0.5 shipped a `feat:` as a patch, and `## Unreleased` says config schema 1, shared state unchanged, safe to bump mid-workflow.
- **B — v1.1.0.** If you want the two `feat:`/behaviour changes to read as a minor.

**Answer:**
A — v1.0.6 (answered in the conversation: "A, A, A, approved")

### Q2 — Release `main` as it stands, or wait for open work?

**Why it matters:** "top of main" can mean today's `2a86915` or whatever `main` is when the release PR is opened. Open issues #40, #41, #43, #51, #52, #54, #57, #70, #71, #73, #74 would otherwise be candidates to wait for.
**Options:**
- **A — `main` at the time the release PR is opened; open issues ship later (recommended).** Whatever has merged by then is in `## Unreleased` and ships; nothing is waited for.
- **B — exactly `2a86915`.** Anything merged after filing waits for the next release.

**Answer:**
A — `main` at the time the release PR is opened; open issues ship later (answered in the conversation: "A, A, A, approved")

### Q3 — One issue for the release and the pin, or two?

**Why it matters:** the pin needs the tag to exist first, so it is a second pull request either way.
**Options:**
- **A — one issue, two PRs (recommended).** As #61 did: release PR, tag, GitHub Release, then the pin PR.
- **B — two issues.** The pin is filed separately and started after the tag exists.

**Answer:**
A — one issue, two PRs (answered in the conversation: "A, A, A, approved")

## Notes

### Provisional draft (assumes Q1 A, Q2 A, Q3 A)

**Title:** Release v1.0.6 from main and pin codeo to it

**Issue Type:** none (user-owned repository; `issue-types` printed nothing)
**Labels:** none proposed (#61 carried none; no existing label fits a release)

```markdown
### Description

Cut release v1.0.6 from `main`: a version bump and changelog pull request, a clean-clone test of the merged commit, the `v1.0.6` tag, and a GitHub Release for it. Then move this project's own codeo pin to the new tag so its sessions and dev containers run it.

### Motivation / Context

The latest release is v1.0.5 (2026-11-14). Since then #68 (dev container on `ubuntu:26.04`, #67) and #72 (closing blocks name only a command that can run; plan host commands shell-neutral, #69) have merged to `main`, and `CHANGELOG.md` collects them under `## Unreleased`. This project pins `v1.0.5` in `.codeo/config.json` (`plugin.ref`), so its own skills still name commands that cannot run in some exits — the defect #69 fixed on `main` only.

### Key Requirements

- Follow `docs/release-checklist.md` steps 6-7. Tagging is the engineer's own action; an agent does not push the tag.
- The release PR sets `version` in `.claude-plugin/plugin.json` only, and retitles `## Unreleased` as `## v1.0.6 — <date>`, keeping its `Config schema`, `Shared state` and `Safe to bump mid-workflow` lines accurate.
- `main` is released as it stands when the release PR is opened; open issues ship in a later version.
- The merged commit the tag names is tested from a clean clone.
- A GitHub Release exists for the tag, as for earlier releases.
- Pinning this project to the new tag is a second pull request, because the tag must exist first.
- After the pin merges, this project's dev container and Claude Code sessions run the installed v1.0.6, not the cached v1.0.5.

### Acceptance Criteria

- [ ] `.claude-plugin/plugin.json` says `1.0.6` and `CHANGELOG.md` has a `## v1.0.6 — <date>` section in place of `## Unreleased`, merged to `main` through a pull request.
- [ ] `bash tests/run.sh` run in a clean clone of the merged commit ends `all cases passed`.
- [ ] `git ls-remote --tags origin` lists `v1.0.6` pointing at that merged commit.
- [ ] `gh release view v1.0.6` shows a release for the tag.
- [ ] `.codeo/config.json` `plugin.ref` is `v1.0.6`, merged through its own pull request.
- [ ] After a dev container rebuild or restart, the installed codeo plugin reports v1.0.6.

### Out of Scope

- Releasing any currently open issue's work, and waiting for it.
- Changing the release checklist or adding release automation.

### Reference

- `docs/release-checklist.md` (steps 6-7); `CHANGELOG.md` `## Unreleased`.
- Previous releases: #61 (v1.0.4), #65 and #66 (v1.0.5).
- Shipped in this release: #67 / PR #68, #69 / PR #72.
```

## Outcome

Filed as #75, Issue Type none, no labels. Approved as drafted.

## Log

- 2026-11-14 — Q1-Q3 raised, provisional draft written
- 2026-11-14 — Q1-Q3 answered A/A/A, draft approved, filed as #75
