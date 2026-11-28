# Issue #207 — init

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/207 |
| Branch | `feat/207-stop-parallel-issues-colliding-shared` |
| Updated | 2026-11-28 |

## Where this stands

Branch `feat/207-stop-parallel-issues-colliding-shared` cut off `main` at `00de557a939e7b7b3477c34c23dff81820ff03ae`, claimed and pushed. Nothing is open; the next step is `/codeo:plan`, run in this issue's own container.

## Questions

None.

## Outcome

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/207 — Stop parallel issues colliding on shared files: changelog fragments, a generated inventory hash, an overlap rule at plan and init, and a rebase before QC |
| State | open · labels `enhancement`, `priority: medium` |
| Branch | `feat/207-stop-parallel-issues-colliding-shared` off `main` at `00de557` |
| Board | Ready → In progress |

**Problem.** Issues worked in parallel keep editing the same shared files (`CHANGELOG.md`, the `close` and `cleanup` skills and their tests, `docs/skills.md`, `README.md`, and the single-valued `tests/fixtures/skills-inventory.rules.sha256`), so their branches conflict at merge, their plans go stale and QC grades against a base that has moved. Plan footprints say `exclusive: none` / `sequenced: none` although they overlap, and nothing acts on overlapping footprints. The issue asks for changelog fragments, a generated inventory hash, an overlap rule at plan and init, and a rebase check before QC.

**Acceptance criteria** — verbatim from the issue, unchecked:
- [ ] Two branches that each add a changelog entry merge without a conflict in `CHANGELOG.md`, and the release step produces the same `CHANGELOG.md` entries the current process does.
- [ ] Two branches that each change an inventory rule merge, and one script run afterwards produces a correct `skills-inventory.rules.sha256`; a test pins it.
- [ ] Starting a second issue whose footprint overlaps an in-flight issue's on a skill file names that issue and the overlapping files, and the footprint records `sequenced:` or `exclusive:`; a test pins it.
- [ ] `/codeo:qc` on a branch behind `origin/main` does not grade until it is rebased, or reports that it is behind; a test pins it.
- [ ] `README.md`, `docs/skills.md` and `CHANGELOG.md` describe the new behaviour; the full suite passes.

**Out of scope.** Collisions between several engineers' shared state (run files, leases, the triage ledger): #194 and #198. Auto-resolving semantic conflicts between two issues that change the same skill's behaviour. Splitting #195, or reordering the four issues now in flight.

**Open at intake.** None stated by the issue.

## Log

- 2026-11-28 — initialized: branch feat/207-stop-parallel-issues-colliding-shared off main at 00de557 · cost: 1m · sonnet-5-5 50k in + 363k cached / 3k out
