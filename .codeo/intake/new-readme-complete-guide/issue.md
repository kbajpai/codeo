# Issue: README as a complete guide to installing, setting up, using and troubleshooting codeo — issue

| | |
|---|---|
| Issue | not filed yet |
| Branch | none |
| Updated | 2026-11-25 |

## Where this stands

Round 1: questions open; no draft yet.

## Problem as restated

The root `README.md` (510 lines) is meant to be the one place a new user learns to install codeo, set a project up, run a workflow and get unstuck. It already has sections for each (*Installing*, *Setting a project up*, *Your first workflow*, *The skills*, *Updating*, *Uninstalling*, *Troubleshooting*), but it does not yet read as a complete guide: *Installing* and *Updating* are dominated by replace-and-restore mechanics, *Your first workflow* is a summary list rather than a walk-through someone can follow, the config (`suites`, `board`, `resources`, `codename`, `ci.requiredChecks`, `models`) is never described as a whole, and *Troubleshooting* covers only `/codeo:doctor` checks and two installer errors, not problems met during a workflow (a guard refusal, a stuck lock, an interrupted step, a board card not Ready). The request is to make the README complete for those four jobs. Two open issues already touch it: #170 (host `codeo` command installs separately; macOS `flock` and keychain) and #163 (four README wording fixes, F16-F19, plus upkeep of Claude Code and `gh`).

## Questions

### Q1 — What does "complete" fall short of today, in your experience?

**Why it matters:** decides whether this is a restructure or a set of additions. My read from the file is the gaps above (no config reference, workflow troubleshooting missing, walk-through too thin, install section heavy on update mechanics). Are those the gaps, or did you hit something else (a step a new user could not follow)?
**Options:** the gaps listed · those plus others (name them) · something different.

**Answer:**

### Q2 — Who is the reader?

**Why it matters:** sets the depth. A first-time user installing codeo in their own project needs a linear path; a teammate joining a project that already uses codeo needs less install and more workflow.
**Options:** first-time user in a new project (recommended) · teammate on an existing codeo project · both, with a section each.

**Answer:**

### Q3 — How do #170 and #163's README items relate to this issue?

**Why it matters:** both change the same file. Folding them in avoids three PRs editing `README.md`; keeping them separate keeps this one smaller.
**Options:** leave #170 and #163 separate, this issue builds on them (recommended) · absorb their README items here and narrow them · supersede them entirely.

**Answer:**

### Q4 — Restructure, or keep the current sections and fill them?

**Why it matters:** a restructure (new order, table of contents, update/replace mechanics moved to their own section or doc) makes the README read as a guide but moves text that doc-pin tests in `tests/` may assert on; filling in keeps the layout and the tests stable.
**Options:** free to restructure, tests updated to match · keep the sections, add and tighten · you decide in `/codeo:plan`.

**Answer:**

### Q5 — Does "use codeo" include the host `codeo` command and the dev containers / sandboxes?

**Why it matters:** today those live in `.devcontainer/README.md`. Including them in the root README makes it long; leaving them out means the root README links out for running an issue in a container.
**Options:** root README covers the plugin workflow and links to `.devcontainer/README.md` for containers (recommended) · root README covers containers too.

**Answer:**

### Q6 — Should everything stay in `README.md`, or may detail move to `docs/`?

**Why it matters:** "complete" in one file may mean 800+ lines. Moving e.g. the config reference or the update/restore detail to `docs/` keeps the README a guide that links to reference pages.
**Options:** README is the guide, reference detail may go to `docs/` with links (recommended) · everything in `README.md`.

**Answer:**

## Notes

- Related: #151 (closed, wrote the install/update/use README), #170 (open), #163 (open).
- `docs/skills.md`, `docs/extension-points.md`, `docs/dossier.md`, `docs/handoff.md` already hold per-skill and protocol reference.

## Outcome

_Pending — written at the hand-off._
