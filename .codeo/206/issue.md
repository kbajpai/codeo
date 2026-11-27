# Issue #206 — issue

## Where this stands

Filed on the engineer's "Go ahead with the & file the issue" after the 2026-11-27 `/codeo:cleanup` run, consolidating two `cleanup.sh` problems into one issue. The draft is below and waits for approval. No question is open.

## Questions

### Q1 — Approve the consolidated draft?

**Options:** approve · change

**Answer:**

## Draft

**Title:** `/codeo:cleanup` prints `codeo rm {N}` unexpanded and lists issues again after their containers were removed

**Issue Type:** none (no Issue Types in this repository). **Labels:** `bug`. **Priority** (`issue.priority` is on): `priority: medium`, because there is a workaround (read the number from the line's first column, ignore issues already removed) and no committed work waits on it.

### Description
`scripts/cleanup.sh` has two faults seen in one run on 2026-11-27: it prints the removal command with the `{N}` placeholder still in it, and it prints every finished issue again whatever was removed before.

### Motivation / Context
Observed with installed plugin 1.0.8 in the home checkout: all 64 lines were `<N>\tproven\tcodeo rm {N}`. The project's overlay (`.codeo/overlays/cleanup.md`, `## removal-command`) gives `name: codeo-{N}`, `pattern: ^codeo-[0-9]+$` and `command: codeo rm {N}`. The script's own header describes `command:` as a template with `{name}`, and `cleanup.sh:93-95` expands `{N}` in `name` and `{name}` in `command` only, so the overlay and the script disagree about which placeholder `command:` may use, and the printed line cannot be run as it stands.

Second, the engineer ran the removal on all hosts and recorded it (`.codeo/intake/cleanup/2026-11-27-2.md`), but `cleanup.sh` never reads earlier records or any ledger of removals. It rebuilds its list from every `.codeo/done/<N>` on the base branch plus the `origin` proofs, so the same 64 issues will print as proven on the next run, and the list grows with every merge.

### Key Requirements
- The command a project's overlay gives prints runnable: every placeholder the overlay documents, or the project's own overlay uses, is expanded, or the script refuses with a message when one is left. Whether the fix is in the script or in the overlay text is for `/codeo:plan`.
- An engineer can record that an issue's removal was done, and `/codeo:cleanup` does not print that issue again.
- The record does not weaken the proofs: an issue still prints as not proven when a proof fails, and a recorded removal never turns a failed proof into a pass.
- The record lives on the intake branch beside the existing cleanup records, so it follows the engineer between machines, and is shared across engineers' machines without one engineer's run overwriting another's.
- The skill still prints only what the script prints and never runs a container command.

### Acceptance Criteria
- [ ] With the project's current overlay, no printed line contains `{` or `}`.
- [ ] An overlay whose command keeps a placeholder the script does not expand makes the script exit non-zero with a `cleanup:` line, or the placeholder is expanded; a test pins it.
- [ ] After an issue's removal is recorded, a later run does not list it as proven or not proven.
- [ ] An issue whose proof fails is listed as not proven whether or not a removal was recorded.
- [ ] Two engineers recording removals do not lose each other's entries on merge.
- [ ] `skills/cleanup/SKILL.md`, `docs/skills.md` and the README describe how to record a removal.
- [ ] The full suite passes.

### Out of Scope
- Running or building a removal command in the skill.
- Detecting whether a container still exists on a host; nothing on `origin` records that.
- The old finding about the overlay's `{N}` wording closed in #163.

### Reference
- `scripts/cleanup.sh` (lines 18-22 header, 87-106 command expansion), `skills/cleanup/SKILL.md`
- `.codeo/overlays/cleanup.md`, `## removal-command`
- `.codeo/intake/cleanup/2026-11-27.md` and `2026-11-27-2.md` on the intake branch
- Related: #163 (cleanup overlay `{N}`), #199 (container ownership and `rm`)

## Outcome

Approved by the engineer and filed as #206.

## Log

2026-11-27 — draft written from the cleanup run, two faults consolidated into one issue
2026-11-27 — approved and filed as #206
