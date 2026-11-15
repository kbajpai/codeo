# Issue #83 — init

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/83 |
| Branch | `feat/re-run-haiku-5-5` |
| Updated | 2026-11-15 |

## Where this stands

Branch `feat/re-run-haiku-5-5` cut off `main` at `dfa8b10`, claimed and pushed. Nothing is open; the next step is `/codeo:plan`.

## Questions

None.

## Outcome

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/83 — Re-run the Haiku 5.5 trial of `doctor` and `setup` with the closing-block template read through Read |
| State | open · labels `enhancement` |
| Branch | `feat/re-run-haiku-5-5` off `main` at `dfa8b10` |
| Board | Ready → In progress |

**Problem.** #76's trial kept `doctor` and `setup` on `model: sonnet` because Haiku 5.5 missed one checklist item: after running the skill's script, all 6 Haiku runs of `doctor` and 1 of 6 of `setup` read the closing-block template (`docs/handoff.md`) through a second Bash call, where all 12 Sonnet runs used the Read tool. Haiku passed every other item on every run. The skills say only "end with the closing block (`docs/handoff.md → Closing block`)", which does not say which tool reads it. This issue makes both skills say to use Read, re-runs the trial, and switches a skill to `model: haiku` only if every Haiku run passes.

**Acceptance criteria** — verbatim from the issue, unchecked:
- [ ] `skills/doctor/SKILL.md` and `skills/setup/SKILL.md` each tell the model to read the closing-block template with the Read tool.
- [ ] A Haiku run and a Sonnet run are compared for each skill, naming what was compared and the result, and recorded on this issue.
- [ ] A skill whose Haiku runs all matched has `model: haiku`; a skill with any miss keeps `model: sonnet`, and the issue says how it differed.
- [ ] `bash tests/run.sh` passes.
- [ ] `CHANGELOG.md` records the change, or the trial's result when nothing switched.

**Out of scope.** Any skill other than `doctor` and `setup`; the `models.subagent` and `models.reviewer` defaults; `scripts/usage.sh`; pinning explicit model IDs; committing the trial script.

**Open at intake.** Nothing the issue leaves open as a question. Settled when it was filed: the fix is skill text that says to use Read, and the trial script stays a throwaway outside the repository, as in #76. The method (the four cases, three runs per model, the six items with item 1 as "exactly one Bash call", `--allowedTools Bash Read --add-dir`) is in `docs/plans/2026-11-14-trial-doctor-setup-haiku.md` and #76's comment.

## Log

- 2026-11-15 — initialized: branch feat/re-run-haiku-5-5 off main at dfa8b10 · cost: 1m · sonnet-5-5 3k in + 2M cached / 4k out
