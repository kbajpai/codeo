# Issue #76 — issue

## Questions

None open. The scope was settled by #52's plan Q2 (answered A): record the evaluation, change nothing in #52, file the trial as its own issue. The delegating skill, `/codeo:implement`, passed the finding; the engineer reviews the draft below at the gate.

## Draft

**Title:** Trial `doctor` and `setup` on Haiku 5.5
**Issue Type:** none (this repository has no Issue Types)
**Labels:** `enhancement`

### Description

`doctor` and `setup` run on `model: sonnet`. Both run one script and report its output, so they may not need Sonnet. Run each on `model: haiku` (`claude-haiku-5-5` in Claude Code 2.1.325) on real runs, compare it with the Sonnet run, and change the two `model:` lines only if the results are equal.

### Motivation / Context

#52 checked that codeo's aliases resolve to the latest models and recorded a desk evaluation of Haiku 5.5 ([comment](https://github.com/kbajpai/codeo/issues/52#issuecomment-6882746316)): `doctor` and `setup` are the two skills where a cheaper model is plausible. `init`, `close` and `triage` are long, rule-heavy flows that push branches, move board cards, open pull requests and judge duplicates, and the `models.subagent` default writes the code in `/codeo:implement`; they stay on Sonnet. The evaluation was from reading the skills, not from running them, so it needs a trial before anything switches.

### Key Requirements

- Run `doctor` and `setup` each on Haiku 5.5 and on Sonnet 5.5, against the same project and config.
- Compare the runs on what each reports: the same checks, the same pass and fail verdicts, the same files written by `setup`, and the same closing block.
- Switch a skill's `model:` line to `haiku` only when its Haiku run matches the Sonnet run; record the comparison either way.

### Acceptance Criteria

- [ ] A comparison of a Haiku run and a Sonnet run is recorded for `doctor`, and another for `setup`, naming what was compared and the result.
- [ ] A skill whose Haiku run matched has `model: haiku`; a skill whose Haiku run differed keeps `model: sonnet`, and the issue says how it differed.
- [ ] `bash tests/run.sh` passes.
- [ ] `CHANGELOG.md` records the change, or the trial's result when nothing switched.

### Out of Scope

- Pinning explicit model IDs in place of aliases.
- Any skill other than `doctor` and `setup`; the `models.subagent` and `models.reviewer` defaults.
- `scripts/usage.sh`.

### Reference

- #52, and its plan `docs/plans/2026-11-14-latest-claude-models.md`.
- `skills/doctor/SKILL.md` and `skills/setup/SKILL.md` (the `model:` line); `tests/skills.test.sh` already accepts `model: haiku`.

## Outcome

Filed as #76: https://github.com/kbajpai/codeo/issues/76 (label enhancement).

## Log

- 2026-11-14 — draft written for review, delegated from /codeo:implement for #52
- 2026-11-14 — approved at the gate and filed as #76
