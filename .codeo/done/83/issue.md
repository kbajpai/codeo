# Issue #83 — issue

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/83 |
| Branch | none |
| Updated | 2026-11-15 |

## Where this stands

Called from `/codeo:triage` (item `implement:76:haiku-follow-up`). No duplicate: the only Haiku issues are #76 (closed, the trial) and #52 (closed, the desk evaluation). Q1 and Q2 answered; the draft below waits for approval.

## Questions

### Q1 — Which fix does the issue ask for before re-running the trial?

**Why it matters:** the two routes touch different files and make different claims about the result.
**Options:** skill text tells the model to use Read · relax item 1 · leave it to `/codeo:plan`.

**Answer:**
Skill text: tell them to use Read (answered in the conversation).

### Q2 — Is the trial script kept in the repository this time?

**Why it matters:** #76's script lived in a scratchpad and was not committed, so a re-run rebuilds it.
**Options:** keep it out of the repo · commit it · leave it to `/codeo:plan`.

**Answer:**
Keep it out of the repo (answered in the conversation).

## Draft

**Title:** Re-run the Haiku 5.5 trial of `doctor` and `setup` with the closing-block template read through Read
**Issue Type:** none (this repository has no Issue Types)
**Labels:** `enhancement`

### Description

#76's trial kept `doctor` and `setup` on `model: sonnet` because Haiku missed one checklist item: after running the skill's script, all 6 Haiku runs of `doctor` and 1 of 6 of `setup` read the closing-block template (`docs/handoff.md`) through a second Bash call, where all 12 Sonnet runs used the Read tool. Haiku passed every other item on every run. Make `doctor` and `setup` tell the model to read the template with Read, then re-run the trial and switch a skill to `model: haiku` only if every Haiku run passes.

### Motivation / Context

`doctor` and `setup` are the two skills where a cheaper model is plausible (#52's evaluation), and #76 found the only difference to be how the template is read, not what is reported. The skills say only "end with the closing block (`docs/handoff.md → Closing block`)", which does not say which tool reads it. The trial record is https://github.com/kbajpai/codeo/issues/76#issuecomment-6885759871.

### Key Requirements

- `skills/doctor/SKILL.md` and `skills/setup/SKILL.md` say to read the closing-block template with the Read tool.
- Re-run the trial against the same four cases (`doctor` passing and failing, `setup` fresh with `--stack node` and refused), three runs per model, scored on #76's six items with item 1 as "exactly one Bash call". Both plugin copies differ only in the two `model:` lines; the model of each run is read from `modelUsage`.
- A headless run needs `--allowedTools Bash Read --add-dir <plugin copy>`, or the template read is denied: #76's first 24-run pass was discarded for exactly that.
- The trial script stays a throwaway outside the repository, as in #76; the result is recorded on this issue.
- Switch a skill to `model: haiku` only when every Haiku run of both its cases passes every item; otherwise it stays `sonnet` and the issue says how it differed.

### Acceptance Criteria

- [ ] `skills/doctor/SKILL.md` and `skills/setup/SKILL.md` each tell the model to read the closing-block template with the Read tool.
- [ ] A Haiku run and a Sonnet run are compared for each skill, naming what was compared and the result, and recorded on this issue.
- [ ] A skill whose Haiku runs all matched has `model: haiku`; a skill with any miss keeps `model: sonnet`, and the issue says how it differed.
- [ ] `bash tests/run.sh` passes.
- [ ] `CHANGELOG.md` records the change, or the trial's result when nothing switched.

### Out of Scope

- Any skill other than `doctor` and `setup`; the `models.subagent` and `models.reviewer` defaults; `scripts/usage.sh`; pinning explicit model IDs.
- Committing the trial script.

### Reference

- #76 (the trial, closed) and its record: https://github.com/kbajpai/codeo/issues/76#issuecomment-6885759871 ; #52 (the desk evaluation); `docs/plans/2026-11-14-trial-doctor-setup-haiku.md` for the cases, items and method.
- `skills/doctor/SKILL.md` and `skills/setup/SKILL.md`; `CHANGELOG.md:11`.
- Surfaced by `/codeo:triage` run 2026-11-15, item `implement:76:haiku-follow-up`.

## Outcome

Filed as #83: https://github.com/kbajpai/codeo/issues/83 (label enhancement).

## Log

- 2026-11-15 — draft written for review, called from /codeo:triage
- 2026-11-15 — approved at the gate and filed as #83
