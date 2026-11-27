### Description
Issues worked in parallel keep changing the same shared files, so their branches conflict at merge, their plans go stale, and QC is graded against a base that has since moved. Nothing in the workflow orders overlapping work or removes the files that every branch has to edit.

### Motivation / Context
Observed 2026-11-27 with #204, #195, #188 and #206 in progress at once (`git diff origin/main...origin/<branch>` for each):
- `CHANGELOG.md` is changed by all four.
- `skills/close/SKILL.md`, `tests/close-skill.test.sh`, `docs/skills.md` and `README.md` are changed by three each.
- `docs/handoff.md`, `docs/dossier.md`, `docs/skills-inventory.md`, `skills/init/SKILL.md`, `tests/inventory.test.sh`, `skills/cleanup/SKILL.md` and `tests/cleanup-skill.test.sh` by two each.
- `tests/fixtures/skills-inventory.rules.sha256` holds one value, so two branches that change it can never merge cleanly (#204 and #195 both do).

Every plan's footprint says `exclusive: none` and `sequenced: none`, although #195 declares `skills/**` and `tests/**`. #188, #195 and #206 were each sent back to `/codeo:plan` at QC round 1. #95 and #98 made `/codeo:plan` write the `sequenced:` line, but nothing acts on overlapping footprints, and nothing removes the shared files. Three of the four issues change the `close` skill and two change `cleanup`, so some conflicts are semantic and a textual merge will not show them.

### Key Requirements
- A change no longer has to edit `CHANGELOG.md` on its own branch: each issue's changelog entry lives in a file of its own and is assembled into `CHANGELOG.md` at release.
- `tests/fixtures/skills-inventory.rules.sha256` is produced by a script, not edited by hand, and can be regenerated after a rebase without a conflict.
- When an issue's footprint overlaps the footprint of a workflow in flight on the shared skill files, `/codeo:plan` or `/codeo:init` says so and sequences it behind that workflow or blocks it until the engineer decides; the decision is recorded in the footprint's `sequenced:` or `exclusive:` line.
- `/codeo:qc` grades a branch that is current with `origin/main`: it requires the rebase first, or reports that the branch is behind.

### Acceptance Criteria
- [ ] Two branches that each add a changelog entry merge without a conflict in `CHANGELOG.md`, and the release step produces the same `CHANGELOG.md` entries the current process does.
- [ ] Two branches that each change an inventory rule merge, and one script run afterwards produces a correct `skills-inventory.rules.sha256`; a test pins it.
- [ ] Starting a second issue whose footprint overlaps an in-flight issue's on a skill file names that issue and the overlapping files, and the footprint records `sequenced:` or `exclusive:`; a test pins it.
- [ ] `/codeo:qc` on a branch behind `origin/main` does not grade until it is rebased, or reports that it is behind; a test pins it.
- [ ] `README.md`, `docs/skills.md` and `CHANGELOG.md` describe the new behaviour; the full suite passes.

### Out of Scope
- Collisions between several engineers' shared state (run files, leases, the triage ledger): #194 and #198.
- Auto-resolving semantic conflicts between two issues that change the same skill's behaviour.
- Splitting #195, or reordering the four issues now in flight.

### Reference
- `/codeo:triage` run of 2026-11-27 (collision analysis from `inflight.sh` and `git diff origin/main...origin/<branch>` for #204, #195, #188, #206).
- #95 and #98: `/codeo:plan` writes `sequenced:`. #194 and #198: the multi-engineer tracker.
