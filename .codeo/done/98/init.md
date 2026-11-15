# Issue #98 — init

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/98 |
| Branch | `fix/fix-sync-main-sh-exiting` |
| Updated | 2026-11-15 |

## Where this stands

Branch `fix/fix-sync-main-sh-exiting` cut off `main` at 90075d4, claimed and pushed. Nothing is open; the next step is `/codeo:plan`, run in this issue's own container.

## Questions

None.

## Outcome

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/98 — Fix sync-main.sh exiting 1 after a clean merge, and make /codeo:plan write sequenced: none (consolidates #92, #95) |
| State | open · labels `bug` |
| Branch | `fix/fix-sync-main-sh-exiting` off `main` at `90075d4` |
| Board | Ready → In progress |

**Problem.** Two small bugs, consolidated from #92 and #95. `scripts/sync-main.sh` exits 1 after a clean merge when `sort` and `comm` order the changed paths differently (locale), so a successful merge reads as a stop and the shared-files listing is lost. `/codeo:plan` writes a footprint without `sequenced:` when nothing was sequenced, which `scripts/dossier-check.sh` rejects (`lacks: sequenced`); the plan skill and `docs/dossier.md` disagree about it. Each part has its own requirements and tests; the criteria below are the union of both.

**Acceptance criteria** — verbatim from the issue, unchecked:
- [ ] In a scratch repo whose merge touches paths that `sort` and `comm` order differently under `en_US.UTF-8` (for example `.codeo/…` or `.devcontainer/…` beside `CHANGELOG.md`), `sync-main.sh` exits 0 after the clean merge and prints one `also changed on <base>:` line for each path changed on both sides.
- [ ] The same run prints no `comm:` warning.
- [ ] A case in `tests/sync-main.test.sh` fails on the current script and passes on the fix.
- [ ] `bash tests/run.sh` passes.
- [ ] `CHANGELOG.md` records the change.
- [ ] `skills/plan/SKILL.md` step 8 lists `sequenced:` with the other three keys and says it reads `none` when nothing was sequenced.
- [ ] `docs/dossier.md → The footprint` no longer says `sequenced` is written only when something was sequenced, and agrees with the plan skill.
- [ ] A test or fixture shows a footprint drafted with `sequenced:  none` passes `dossier-check.sh`, and one without the key still fails with `lacks: sequenced`.
- [ ] `bash tests/run.sh` passes.

**Out of scope.** Any other script's use of `sort` or `comm`; the merge, conflict and abort logic of `sync-main.sh`; running `dossier-check.sh` earlier in qc or CI; fixing archived plans that lack the key; the re-planned footprint rule.

**Open at intake.** #92's open question — whether the cause is only locale collation or also a `sort`/`comm` comparison difference — is settled by `/codeo:plan`.

## Log

- 2026-11-15 — initialized: branch fix/fix-sync-main-sh-exiting off main at 90075d4 · cost: unavailable
