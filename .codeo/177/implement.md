# Issue #177 — implement

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/177 |
| Branch | `docs/177-close-163-166-168-leftovers` |
| Updated | 2026-11-25 |

## Where this stands

Round 1 is done: all nine plan tasks are built, reviewed and committed on the branch (`docs/plans/2026-11-25-close-163-166-168-leftovers-177.md`), the build and the whole `shell` suite pass, and Q1 is answered. Nothing is open. Next step: `/codeo:qc`.

## Questions

### Q1 — #179 overlaps on `glob:docs/handoff.md`, `glob:docs/home-checkout.md` and `glob:tests/readme.test.sh`

`overlap.sh 177` printed `179	glob:docs/handoff.md`, `179	glob:docs/home-checkout.md` and `179	glob:tests/readme.test.sh`. #179 is branch `docs/179-close-171-leftovers-readme-wording`, assignee kbajpai, step `init` (waits for `/codeo:plan`), and its footprint lists those three files plus `README.md`, `docs/extension-points.md`, `docs/updating.md`. At plan time it had no footprint, so `plan.md` Notes only said it might reach `docs/home-checkout.md`. This plan's Task 1 edits `docs/home-checkout.md:9` and `:66` and `tests/readme.test.sh`; Tasks 3-4 edit `docs/handoff.md` only if a sentence states the old behaviour.

**Why it matters:** *sequence after #179* holds this step until #179 merges, so my edits start from its text; *proceed and coordinate* starts now and whoever merges second rebases `docs/home-checkout.md` and `tests/readme.test.sh` (both likely to touch the same paragraphs: the `jq` sentence at `:9` is README-wording territory); *re-scope* drops Task 1 here and leaves it to #179.
**Options:** proceed and coordinate (my pick: #179 is still before its plan, so it is likely to merge after this, and the two edits are different sentences) · sequence after #179 · re-scope.

**Answer:**
Proceed and coordinate. (Engineer, in the conversation: "go with your picks".)

## Notes

None.

## Outcome

Round 1.

**Built** (Tasks 1-8; Task 9 is the check below). The build command of suite `shell` is `true` (exit 0); `bash tests/run.sh` ends `all cases passed` at the merged head and again after the last fix.

| Task | What | Commit |
|---|---|---|
| 1 | `docs/home-checkout.md`: doctor reports `config` first and `deps: missing: jq` later; `live.sh` still publishes without `jq`; a sandbox asks about a local container where the container script refuses; three pins in `tests/readme.test.sh` | `400308c` |
| 2 | `.codeo/overlays/cleanup.md` and `close.md`: `git status` before the removal commands, the sandbox clause complete, the row marked after each removal succeeds and by `end` only when `codeo-track.sh` sits beside it; pins in `tests/cleanup-skill.test.sh` and `tests/close-removal.test.sh` (one fix round made the close pin discriminating) | `125a7f8`, `f450442` |
| 3 | `skills/cleanup/SKILL.md` step 4 counts a `leftover` line as a command to run; a pin | `b27f1d7` |
| 4 | `skills/close/SKILL.md` step 17 reads `codeo-live/<issue>/*` from origin, prints one exact delete per allowlisted branch, says none is there, skips and names an unexpected name, and falls back to the `codeo-live-machine` form; six pins in `tests/close-skill.test.sh` | `7aee87d`, `0ff7c30` |
| 5 | `CHANGELOG.md`: three v1.0.9 lines corrected and a `(#177)` bullet under `## Unreleased` | `2ec26d3` |
| 6 | `tests/track.test.sh` restores `TMPDIR` | `4555328` |
| 7 | `docs/release-checklist.md` step 6 names the UTC date | `3b004b7` |
| 8 | dated notes in `.codeo/done/168/plan.md` and `init.md` | `4275529` |

**Documentation pages changed:** `docs/home-checkout.md`, `docs/release-checklist.md`, `CHANGELOG.md`; `docs/skills.md` and `docs/handoff.md` were read and needed no change. No wiki module.

**Deviations from the plan.**
- Task 1: the plan, from QC #163 F3, said `live.sh` fails sourcing `lib/env.sh` without `jq`. It does not: `lib/env.sh` calls `jq` only inside functions, `live.sh` reads the base branch with `|| base=` and its one `jq` call is `|| true`. A reviewer ran `live.sh beat --force` without `jq` against a scratch origin and the signal was published. The page says that, and the pin matches it, as the plan allowed.
- Task 8: the plan proved it with no `FAIL` from `bash scripts/dossier-check.sh .codeo/done/168`. That archive already printed two `log-cost` FAILs (`issue.md` and `init.md`) before the edit and prints the same after; the edit adds no finding. Neither is #177's to fix.
- Tasks 5-8 were one implementer in four commits and one review of the range, not four dispatches.
- Task 6's red run used an existing `TMPDIR` (`/var/tmp/x`): `TMPDIR=/x` makes `mktemp` fail 57 unrelated cases.

**Base.** `sync-main.sh` merged `origin/main` (#176, `86b030c`) in `8e1c8d2`; nothing it changed makes a new sentence stale (`track_confirm` in `.sbx/codeo-sandbox.sh` is as the page says). `overlap.sh 177` and `overlap.sh --outside 177` print nothing.

**Deferred minors** (none blocks): `skills/cleanup/SKILL.md` step 4's first sentence is one long line; `docs/release-checklist.md` step 6 has a short wrapped line; the `(#177)` bullet and one overlay line are long.

## Log

- 2026-11-25 — Q1 raised (#179 overlap) · cost: 0m · sonnet-5-5 12k in + 552k cached / 993 out
- 2026-11-25 — Q1 answered; built the plan's nine tasks, the suite passes · cost: 71m · sonnet-5-5 520k in + 19.2M cached / 77k out
