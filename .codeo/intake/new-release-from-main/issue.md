# Issue — release from `main`

| | |
|---|---|
| Issue | not yet filed |
| Updated | 2026-11-13 |

## Where this stands

Problem restated and explored; Q1-Q4 open. No draft yet.

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

### Q2 — what counts as done?

- **A** — the release PR is merged and the clean-clone test passes; tagging stays the engineer's (checklist step 7).
- **B** — A, plus the tag `vX.Y.Z` is pushed.
- **C** — B, plus a GitHub Release object for the tag, like v1.0.3's.

**Answer:**

### Q3 — bump this project's own pin?

`.codeo/config.json` pins `plugin.ref: v1.0.3`, which the dev container installs.
- **A** — in scope: after the tag exists, `plugin.ref` moves to it (its own PR, since the tag must exist first).
- **B** — out of scope: a follow-up.

**Answer:**

### Q4 — release now, or wait for open work?

Open: #57 and #54 (dev container follow-ups), #43 (`board.sh set` messages and tests), #41, #40, #51, #52.
- **A** — release `main` as it stands; open issues ship in a later version.
- **B** — wait for named issues first (say which).

**Answer:**

## Outcome

(pending)

## Log

2026-11-13 — dossier opened; Q1-Q4 raised
