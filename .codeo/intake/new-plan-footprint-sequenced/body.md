### Description

`/codeo:plan` writes the `### Footprint` block of a plan dossier without a `sequenced:` line when nothing was sequenced, and `scripts/dossier-check.sh` then reports the plan as failing. The plan skill and the dossier format disagree about whether the key is written when it is empty. This issue makes the plan skill write all four keys, `sequenced:  none` included.

### Motivation / Context

- `scripts/dossier-check.sh` requires all four footprint keys: `for key in files wiki exclusive sequenced`. For #73 it printed `FAIL plan.md [footprint] ### Footprint at line 100 lacks: sequenced`, and `/codeo:qc` carried the same finding (F12) through four rounds.
- `docs/dossier.md → The footprint` says `sequenced` is "only when an overlap question was answered that way", and also "A key with nothing under it says `none` rather than disappearing, so a missing line means the plan never looked, not that it found nothing."
- `skills/plan/SKILL.md` step 8 names the sources of `files:`, `wiki:` and `exclusive:` and says "A key with nothing under it says `none`", but never names `sequenced:`; step 10 sub-step 1 mentions a `sequenced:` line only "when an overlap question was answered that way".
- It recurs. Of nine archived plans checked, `.codeo/done/58`, `61`, `67` and `76` have a footprint block with no `sequenced:` line; `57`, `69`, `75`, `83` and `87` have one.

### Key Requirements

- The plan skill's footprint step names all four keys and says `sequenced:` is written as `none` when no overlap question was answered by sequencing, so a block written from the skill's text passes `dossier-check.sh`.
- `docs/dossier.md → The footprint` and the plan skill say the same thing about `sequenced`: written always, `none` when empty, a value only when something was sequenced.
- The dossier checker, `inflight.sh` and `overlap.sh` keep reading the key as they do.

### Acceptance Criteria
- [ ] `skills/plan/SKILL.md` step 8 lists `sequenced:` with the other three keys and says it reads `none` when nothing was sequenced.
- [ ] `docs/dossier.md → The footprint` no longer says `sequenced` is written only when something was sequenced, and agrees with the plan skill.
- [ ] A test or fixture shows a footprint drafted with `sequenced:  none` passes `dossier-check.sh`, and one without the key still fails with `lacks: sequenced`.
- [ ] `bash tests/run.sh` passes.

### Out of Scope

- Making `/codeo:qc` or CI run `dossier-check.sh` on the plan dossier earlier.
- Fixing existing archived plans that lack the key.
- The re-planned footprint rule (#43) and `sync-main.sh` (#92).

### Reference
- `skills/plan/SKILL.md` steps 8 and 10; `docs/dossier.md → The footprint`; `scripts/dossier-check.sh` (the key loop); `tests/dossier-check.test.sh`, fixture `tests/fixtures/dossiers/bad-footprint-absent`.
- `.codeo/done/73/qc.md` (F12, rounds 1-4); archived plans `.codeo/done/58`, `61`, `67`, `76` (no `sequenced:`) and `57`, `69`, `75`, `83`, `87` (with it).
- Surfaced by `/codeo:triage` run 6 (`.codeo/intake/triage/2026-11-15-6.md`).
