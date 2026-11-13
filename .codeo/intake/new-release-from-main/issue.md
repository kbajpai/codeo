# Issue — release from `main`

| | |
|---|---|
| Issue | not yet filed |
| Updated | 2026-11-13 |

## Where this stands

Q1-Q4 answered (1A, 2C, 3A, 4A). Draft below awaits approval.

**Problem.** The latest release is v1.0.3 (tag `8e3605a`, 2026-11-07). Ten commits have merged to `main` since then (#34, #35, #36, #39, #44, #45, #47, #50, #55, #58), and `CHANGELOG.md` collects them under `## Unreleased`. Projects pinned to v1.0.3, including this one (`.codeo/config.json` `plugin.ref: v1.0.3`), still run the `board.sh set` that rejects `ready` (fixed by #39 on `main`, seen failing in triage 2026-11-13 Q2). A release cut from `main` ships those changes.

**What exploration found.**
- `docs/release-checklist.md` steps 6-7 are the process: a PR that sets `.claude-plugin/plugin.json` `version` and retitles `## Unreleased` as `## vX.Y.Z — YYYY-MM-DD`; then `bash tests/run.sh` on the merged commit from a clean clone; then `git tag vX.Y.Z && git push origin vX.Y.Z`. The checklist says "Nothing here is done by an agent". The `v*` tag ruleset limits tags to an admin.
- v1.0.0, v1.0.2 and v1.0.3 each also have a GitHub Release object (`gh release list`); the checklist does not mention one.
- The `## Unreleased` header already states `Config schema: 1`, `Shared state: unchanged from v1.0.3`, `Safe to bump mid-workflow: yes`.
- Of the ten changes, only #39 changes a shipped script (`scripts/board.sh`); #34 adds a doc and a test; the rest touch `.devcontainer/`, `.codeo/` and docs.
- No existing issue covers a release. The repo has no Issue Types and no labels.

## Questions

### Q1 — which version?

#39 changes `board.sh set`'s accepted input (a fix plus new accepted keys); everything else is the dev container, docs and tests.
- **A** — `v1.0.4`: a patch, matching how v1.0.3 was cut.
- **B** — `v1.1.0`: a minor, because `board.sh set` accepts new inputs and the repository gained the dev container.
- **C** — leave the number to `/codeo:plan`.

**Answer:**
A — v1.0.4.

### Q2 — what counts as done?

- **A** — the release PR is merged and the clean-clone test passes; tagging stays the engineer's (checklist step 7).
- **B** — A, plus the tag `vX.Y.Z` is pushed.
- **C** — B, plus a GitHub Release object for the tag, like v1.0.3's.

**Answer:**
C — merged PR, clean-clone test, tag, and a GitHub Release.

### Q3 — bump this project's own pin?

`.codeo/config.json` pins `plugin.ref: v1.0.3`, which the dev container installs.
- **A** — in scope: after the tag exists, `plugin.ref` moves to it (its own PR, since the tag must exist first).
- **B** — out of scope: a follow-up.

**Answer:**
A — in scope, as a second PR.

### Q4 — release now, or wait for open work?

Open: #57 and #54 (dev container follow-ups), #43 (`board.sh set` messages and tests), #41, #40, #51, #52.
- **A** — release `main` as it stands; open issues ship in a later version.
- **B** — wait for named issues first (say which).

**Answer:**
A — release main as it stands.

## Outcome

### Draft (awaiting approval)

Title: Release v1.0.4 from main
Issue Type: none (repository has none). Labels: none (none exist).

### Description

Cut release v1.0.4 from `main`: version bump and changelog PR, a clean-clone test of the merged commit, the `v1.0.4` tag, and a GitHub Release for it. Then make this project's own codeo installation run it: move the plugin pin to the new tag and update the installed plugin.

### Motivation / Context

The latest release is v1.0.3 (2026-11-07). Ten PRs have merged to `main` since (#34, #35, #36, #39, #44, #45, #47, #50, #55, #58) and `CHANGELOG.md` collects them under `## Unreleased`. Projects pinned to v1.0.3, including this one (`.codeo/config.json` `plugin.ref`), still run the `board.sh set` that rejects `ready` and other logical status keys; #39 fixed it on `main` only.

### Key Requirements

- Follow `docs/release-checklist.md` steps 6-7. Tagging is the engineer's own action; an agent does not push the tag.
- The release PR sets `version` in `.claude-plugin/plugin.json` only, and retitles `## Unreleased` as `## v1.0.4 — <date>`, keeping its `Config schema`, `Shared state` and `Safe to bump mid-workflow` lines accurate.
- The merged commit the tag names is tested from a clean clone.
- A GitHub Release exists for the tag, as for v1.0.0, v1.0.2 and v1.0.3.
- Pinning this project to the new tag is a second pull request, because the tag must exist first.
- This project's dev container and Claude Code sessions run the installed v1.0.4, not the cached v1.0.3: the start script installs at the pin, and the session sees the new plugin version after a restart.
- `main` is released as it stands; open issues (#40, #41, #43, #51, #52, #54, #57) ship in a later version.

### Acceptance Criteria

- [ ] `.claude-plugin/plugin.json` says `1.0.4` and `CHANGELOG.md` has a `## v1.0.4 — <date>` section in place of `## Unreleased`, merged to `main` through a pull request.
- [ ] `bash tests/run.sh` run in a clean clone of the merged commit ends `all cases passed`.
- [ ] `git ls-remote --tags origin` lists `v1.0.4` pointing at that merged commit.
- [ ] `gh release view v1.0.4` shows a release for the tag.
- [ ] `.codeo/config.json` `plugin.ref` is `v1.0.4`, merged through its own pull request.
- [ ] After a dev container rebuild or restart, the installed codeo plugin reports v1.0.4 and `bash "$CODEO_ROOT/scripts/board.sh" set <N> ready` (lowercase) is accepted instead of failing with `no option 'ready'`.

### Out of Scope

- Releasing any currently open issue's work, and waiting for it.
- Changing the release checklist or adding release automation.

### Reference

- `docs/release-checklist.md` (steps 6-7); `CHANGELOG.md` `## Unreleased`.
- #39 (the `board.sh set` fix); triage run 2026-11-13, Q3.

## Log

2026-11-13 — dossier opened; Q1-Q4 raised
2026-11-13 — Q1-Q4 answered; draft recorded, awaiting approval
2026-11-13 — scope widened: this project must run the new release; draft updated, awaiting approval
