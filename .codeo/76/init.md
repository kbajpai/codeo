# Issue #76 — init

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/76 |
| Branch | `feat/trial-doctor-setup-haiku-5` |
| Updated | 2026-11-14 |

## Where this stands

Branch `feat/trial-doctor-setup-haiku-5` cut off `main` at 09e3013, claimed and pushed. Nothing is open; the next step is `/codeo:plan`.

## Questions

None.

## Outcome

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/76 — Trial `doctor` and `setup` on Haiku 5.5 |
| State | open · labels `enhancement` |
| Branch | `feat/trial-doctor-setup-haiku-5` off `main` at `09e3013` |
| Board | Ready → In progress |

**Problem.** `doctor` and `setup` run on `model: sonnet`. Both run one script and report its output, so they may not need Sonnet. #52's desk evaluation of Haiku 5.5 found them the only candidates; this issue trials each on `model: haiku` (`claude-haiku-5-5` in Claude Code 2.1.325) on real runs against Sonnet, and changes the two `model:` lines only where the results are equal. The comparison is recorded either way.

**Acceptance criteria** — verbatim from the issue, unchecked:
- [ ] A comparison of a Haiku run and a Sonnet run is recorded for `doctor`, and another for `setup`, naming what was compared and the result.
- [ ] A skill whose Haiku run matched has `model: haiku`; a skill whose Haiku run differed keeps `model: sonnet`, and the issue says how it differed.
- [ ] `bash tests/run.sh` passes.
- [ ] `CHANGELOG.md` records the change, or the trial's result when nothing switched.

**Out of scope.** Pinning explicit model IDs in place of aliases; any skill other than `doctor` and `setup`; the `models.subagent` and `models.reviewer` defaults; `scripts/usage.sh`.

**Open at intake.** Nothing the issue leaves open as a question. How to run `setup` on both models against the same project without changing the project (it writes `.codeo/` and `docs/plans/`) is for `/codeo:plan`.

## Log

- 2026-11-14 — initialized: branch feat/trial-doctor-setup-haiku-5 off main at 09e3013 · cost: 1m · sonnet-5-5 16k in + 1.6M cached / 4k out
