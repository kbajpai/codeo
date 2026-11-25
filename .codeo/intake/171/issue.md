# Issue #171 — issue

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/171 |
| Branch | none |
| Updated | 2026-11-25 |

## Where this stands

Filed as #171.

## Problem as restated

The root `README.md` (510 lines) is meant to be the one place a new user learns to install codeo, set a project up, run a workflow and get unstuck. It already has sections for each, but it does not read as a complete guide: *Installing* and *Updating* are dominated by replace-and-restore mechanics, *Your first workflow* is a summary list rather than a walk-through, the config is never described as a whole, and *Troubleshooting* covers only `/codeo:doctor` checks and two installer errors, not problems met during a workflow. Open issues #170 and #163 also touch the README.

## Questions

### Q1 — What does "complete" fall short of today?

**Answer:** Just make it more informative, easier to read and follow. (The gaps listed stand as the working list.)

### Q2 — Who is the reader?

**Answer:** Your recommendation: a first-time user in a new project.

### Q3 — How do #170 and #163's README items relate?

**Answer:** Your recommendation: leave #170 and #163 separate; this issue builds on them.

### Q4 — Restructure, or keep the sections and fill them?

**Answer:** Your recommendation: free to restructure (order, table of contents, update and restore detail moved out), with the tests that pin README wording updated to match.

### Q5 — Do containers and the host command belong in the root README?

**Answer:** Your recommendation: the root README covers the plugin workflow and links to `.devcontainer/README.md` for containers.

### Q6 — All in `README.md`, or may detail move to `docs/`?

**Answer:** Your recommendation: README is the guide; reference detail may move to `docs/` with links.

## Draft

**Title:** Make the README a complete, easy-to-follow guide to installing, setting up, using and troubleshooting codeo

**Type:** none (no Issue Types). **Labels:** documentation

### Description
The README has sections for installing, setting a project up, a first workflow, updating, uninstalling and troubleshooting, but it does not yet read as a guide a first-time user can follow from start to finish. Make it more informative and easier to read and follow, for a first-time user setting codeo up in a new project.

### Motivation / Context
Install and update text is dominated by replace-and-restore mechanics, so the common path is buried. The first workflow is a summary list, not a walk-through. The project config (`suites`, `board`, `resources`, `codename`, `ci.requiredChecks`, `models`) is never described as a whole. Troubleshooting covers `/codeo:doctor` checks and two installer errors only, not problems met mid-workflow (a role-guard refusal, a stuck lock, an interrupted step, a card that is not Ready).

### Key Requirements
- A reader can go from nothing installed to one merged pull request by following the README in order, with a short table of contents and a clear "start here" path.
- The common install path comes first; update, replace and restore detail is separated from it, and may move to `docs/` with links.
- The first workflow is a walk-through: what to type, what each step asks, what file it writes, and what to expect.
- The project config is described: what each key does, which are optional, with an example.
- Troubleshooting covers workflow problems as well as `/codeo:doctor` checks: each entry gives the symptom, the cause and the fix.
- Containers and the `codeo` host command are linked to `.devcontainer/README.md`, not duplicated.
- Existing commands, output samples and links stay accurate; the README may be reordered and tests that pin its wording are updated to match.

### Acceptance Criteria
- [ ] The README opens with a short summary and a table of contents, and a "start here" path from install to a merged pull request.
- [ ] Install, update/replace/restore and uninstall are separate sections, the common install first.
- [ ] The first workflow walks through all six steps with the command, what it asks, the file it writes and what comes next.
- [ ] A section describes every key of `.codeo/config.json` that the plugin reads, which are optional, and shows an example.
- [ ] Troubleshooting has entries for a role-guard refusal, a stuck or foreign lock, an interrupted step, and a card that is not Ready, each with symptom, cause and fix, besides the existing doctor entries.
- [ ] Every command, path and link the README names exists and is spelled as in the repo.
- [ ] `bash tests/run.sh` passes, with any wording pins updated.

### Out of Scope
- The #170 items (the `codeo` host command installs separately, macOS `flock` and keychain) and #163's README wording fixes: they stay their own issues.
- Rewriting `.devcontainer/README.md`, `docs/skills.md` or other reference pages beyond links and any moved detail.
- Changing how codeo behaves.

### Reference
README.md. Closed #151 (wrote the install, update and use sections). Open #170 and #163 also edit README.md, so the three may touch the same lines.

## Notes

- Related: #151 (closed), #170 (open), #163 (open).

## Outcome

_Pending — written at the hand-off._
