# Issue #81 — issue

## Questions

None open. The engineer chose to file the findings together (triage run 9, Q2 and Q3: "file it", then "Consolidate into one issue"). The delegating skill passed the findings; the engineer reviews the draft at the gate. One nobody can answer yet goes into the draft as content: whether VS Code writes the host `~/.gitconfig` copy in one step.

## Findings from the exploration

- `.devcontainer/scripts/devcontainer-start.sh:253` waits `while [[ ! -e $HOME/.gitconfig ]]`: it stops when the file exists, not when it has content (F4). Line 262 reads the keys with `git config --file "$HOME/.gitconfig"`, which ignores `[include]` / `[includeIf]` (F6). `.devcontainer/README.md:29` describes the seeding without saying only values written directly in `~/.gitconfig` count.
- `CHANGELOG.md` on `origin/main`: #52's bullet is still under `## Unreleased` (line 10), v1.0.6 is out above it, so the omission is still fixable before release.
- Release bodies: v1.0.5 and v1.0.6 both start with a blank line. The difference is the tail: v1.0.6's body has GitHub's auto-generated `## What's Changed` and `**Full Changelog**: …/compare/v1.0.5...v1.0.6` appended after the changelog section; v1.0.5's is the changelog section only. The finding as passed said the blank first line was the difference; it is not.
- No existing issue covers any of it (#51 is closed; searches for "gitconfig", "release body" found nothing else).

## Draft

**Title:** Small follow-ups from #51, #52 and #75: git-identity wait edges and two wording gaps
**Issue Type:** none (this repository has no Issue Types)
**Labels:** `enhancement`

### Description

Four small, non-blocking findings from the QC of #51, #52 and #75 were recorded in their archived dossiers and never fixed or filed. Two concern the dev container's git-identity seeding, one is a changelog clause, and one is the body of the v1.0.6 GitHub Release.

### Motivation / Context

Found by `/codeo:qc` and triaged in `/codeo:triage` run 9, where the engineer chose to file them together. None breaks anything: each is a rare first-start edge or a wording gap.

### Key Requirements

- **Half-written host copy (#51 F4).** The start script waits for `~/.gitconfig` to exist, not to have content. A copy created and then written could be read half-done, and with `GIT_AUTHOR_*` set the environment's value would then fill the `codeo-git` volume and, never being overwritten, keep the host's value out. The window is a few milliseconds on a first start. Whether VS Code writes the copy in one step is unverified; settle that first, and close the window only if it exists.
- **Includes not followed (#51 F6).** `[include]` and `[includeIf]` in the host file are ignored because the script reads it with `git config --file`. An engineer who keeps their identity in an included file gets the environment's value or the TODO. The README should say that only values written directly in `~/.gitconfig` count, or the script should follow includes.
- **Changelog clause (#52 F2).** `CHANGELOG.md`'s `#52` bullet under `## Unreleased` says "the two tests that use model IDs as input" and omits `tests/replay.test.sh`'s `sed`, which also changed to keep matching the renamed fixture. The bullet should name it.
- **Release body (#75 F1).** The v1.0.6 Release body has GitHub's auto-generated `## What's Changed` and `**Full Changelog**` lines appended after the changelog section; v1.0.5's is the changelog section only. Make v1.0.6's match, and say in `docs/release-checklist.md` how a Release is created if the checklist leaves it open.

### Acceptance Criteria

- [ ] The issue records whether VS Code writes `~/.gitconfig` in one step; if it does not, the start script no longer reads a half-written copy, and a test covers it.
- [ ] An identity kept in an `[include]`d file is either followed or documented as not counting, in `.devcontainer/README.md`.
- [ ] `CHANGELOG.md`'s `#52` bullet names `tests/replay.test.sh`'s `sed`.
- [ ] The v1.0.6 Release body is the changelog section only, like v1.0.5's, or the checklist says why it is not.
- [ ] `bash tests/run.sh` passes.

### Out of Scope

- The plan files that quote old model names or an invalid `gh` command (#52 F1, F3): archived and merged records.
- The blank first line of the Release bodies (both releases have it).
- #76, #74 and #57, which carry other follow-ups.

### Reference

- `.codeo/done/51/qc.md` (rounds 2-3, F4 and F6); `.devcontainer/scripts/devcontainer-start.sh:253` and `:262`; `.devcontainer/README.md:29`; PR #78.
- `.codeo/done/52/qc.md` (round 1, F2); `CHANGELOG.md:10`; PR #80.
- `.codeo/done/75/qc.md` (F1); Releases v1.0.5 and v1.0.6; PR #77.
- Triage run `.codeo/intake/triage/2026-11-14-9.md`, Q2 and Q3.

## Outcome

Filed as #81: https://github.com/kbajpai/codeo/issues/81 (label enhancement).

## Log

- 2026-11-14 — draft written for review, delegated from /codeo:triage run 9
- 2026-11-14 — approved at the gate and filed as #81
