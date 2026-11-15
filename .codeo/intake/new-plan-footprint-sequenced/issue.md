# Issue new-plan-footprint-sequenced — issue

## Questions

1. **Which side of the contradiction moves.** `skills/plan/SKILL.md` step 8 tells the plan to draft `### Footprint` from three sources (`files:` from the File Structure, `wiki:`, `exclusive:`) and never names `sequenced:`; step 10 sub-step 1 mentions a `sequenced:` line only "when an overlap question was answered that way". `docs/dossier.md → The footprint` says `sequenced` is "only when an overlap question was answered that way" yet also "A key with nothing under it says `none` rather than disappearing, so a missing line means the plan never looked", and `scripts/dossier-check.sh:339` requires all four keys (`for key in files wiki exclusive sequenced`). **Options:** (A) the plan skill drafts all four keys and writes `sequenced:  none` when nothing was sequenced, keeping the checker as it is; (B) the checker treats `sequenced` as optional; (C) both documents are reconciled by whichever the engineer names.
   **Answer:** _open_

2. **Whether a check should catch it earlier.** No CI job runs `dossier-check.sh`, and `/codeo:qc` does not run it, so a footprint without the key is found only by hand. **Options:** (A) in scope — `/codeo:qc` or CI runs the checker on the plan dossier; (B) out of scope — only the footprint wording is fixed.
   **Answer:** _open_

## Notes

Called from `/codeo:triage` run 6 (`.codeo/intake/triage/2026-11-15-6.md`), for `qc:73:F12`. Duplicate search (`footprint sequenced`, `dossier-check footprint`, `plan footprint key`): #39 (closed) and #43 (open, "enforce the re-planned footprint rule") are about the re-planned footprint rule, not this key; #11 (closed) is about `## Outcome`/`## Questions`. No duplicate.

Evidence that it recurs, not a one-off: of the nine archived plans checked, `.codeo/done/58`, `61`, `67` and `76` have a footprint block with no `sequenced:` line; `57`, `69`, `75`, `83`, `87` have it. `tests/fixtures/dossiers/bad-footprint-absent` and `dossier-check.test.sh:54` pin the checker's message: `FAIL plan.md [footprint] ### Footprint at line 35 lacks: sequenced`.

## Outcome

_Pending._

## Log

- 2026-11-15 — questions raised · cost: unavailable
