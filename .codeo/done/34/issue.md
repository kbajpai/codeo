# Issue #34 — issue

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/34 |
| Branch | none |
| Updated | 2026-11-07 |

## Where this stands

Round 1, Q1-Q4 answered in the conversation; draft below awaits review.
Round 1 opened: The engineer asked for an issue so that every skill under `skills/` is covered in the
user-facing docs with a comprehensive description. Today `README.md` gives each pipeline skill one
table row and `/codeo:setup` and `/codeo:doctor` one sentence between them. Three gaps already
deferred in the triage ledger (`doc:README.md:six-steps-vs-seven-skills`,
`doc:README.md:setup-docs-plans`, `doc:README.md:doctor-checks`) are symptoms of this.
`docs/skills-inventory.md` is not a duplicate: it is a maintainer-facing list of hard rules for
the seven pipeline skills, pinned by `tests/inventory.test.sh`, and omits setup and doctor.
No existing issue covers this (searched "README", "skills", "documentation").

## Questions

### Q1 — Where should the comprehensive descriptions live?

**Why it matters:** expanding the README makes it much longer; a separate page keeps the README a
summary but adds a file to keep in step.
**Options:** expand README's Skills section · new `docs/skills.md` with the README table linking to it · you pick.

**Answer:**
New `docs/skills.md`; README keeps its summary table and links to it.

### Q2 — What should each skill's description cover?

**Why it matters:** sets the acceptance criteria per skill.
**Options:** purpose and when to use it (trigger phrases) · what it reads and writes (its dossier file, branches, board, GitHub) · what it hands off to and what it never does · its extension points · any mix.

**Answer:**
All four: purpose and when to use it; what it reads and writes; hand-offs and what it never does; its extension points.

### Q3 — Should the three deferred README gaps be folded into this issue?

**Why it matters:** if yes, the triage ledger rows become "already #N" at the next triage instead of separate items.
**Options:** yes, fold them in · no, keep them separate.

**Answer:**
Yes, fold them in.

### Q4 — Should a test guard coverage, so a new skill without a description fails CI?

**Why it matters:** without one, the docs drift again the next time a skill is added; with one, it is a requirement on the change, not just docs.
**Options:** yes, a test · no, docs only.

**Answer:**
Yes, add a test.

## Notes

### Draft

**Title:** Describe every codeo skill in docs/skills.md and guard coverage with a test
**Type:** none (user-owned repository)
**Labels:** documentation

### Description

The user-facing docs do not describe codeo's skills in enough depth to use them without reading each `SKILL.md`. `README.md`'s Skills section gives each pipeline skill one table row, and `/codeo:setup` and `/codeo:doctor` share one sentence. Three gaps follow from that:

- Line 3 says the pipeline is "six steps", while the Skills table lists seven rows; `triage` runs outside the lock, which only line 25 explains.
- `/codeo:setup` is described as writing `.codeo/config.json`; it also creates `docs/plans/`.
- `/codeo:doctor` is described as checking overlay files and `codename`; it also checks the GitHub login and scopes, the board, the branch ruleset, the suite commands and the dependencies.

`docs/skills-inventory.md` does not fill this gap: it lists the hard rules each of the seven pipeline skills must keep, for maintainers, and omits `setup` and `doctor`.

### Motivation / Context

A new adopter, or an engineer deciding which skill to run next, has to open every `SKILL.md` to learn what a skill touches and what it will not do. Found while checking whether the README covers every skill under `skills/`.

### Key Requirements

- A new `docs/skills.md` describes every skill under `skills/` — today `issue`, `init`, `plan`, `implement`, `qc`, `close`, `triage`, `setup` and `doctor`.
- Each skill's description covers:
  - its purpose and when to use it, including the situations or phrases that trigger it;
  - what it reads and what it writes (its dossier file, branches, the lock, leases, the board, GitHub issues and pull requests);
  - what it hands off to, who calls it, and what it never does;
  - its extension points, linked to `docs/extension-points.md` (or "none").
- `README.md` keeps a short summary table of the skills and links to `docs/skills.md` for the detail.
- The README's three gaps above are fixed: the pipeline-versus-`triage` wording is unambiguous, and the `setup` and `doctor` summaries match what the skills do.
- A test fails when a directory under `skills/` has no description in `docs/skills.md`, and runs under `bash tests/run.sh`.

### Acceptance Criteria

- [ ] `docs/skills.md` has a section for each of the nine skills under `skills/`.
- [ ] Each section states purpose and triggers, reads and writes, hand-offs and non-goals, and extension points.
- [ ] Every extension point listed in `docs/skills.md` matches the `point:` markers in that skill's `SKILL.md` and the entries in `docs/extension-points.md`.
- [ ] `README.md` links to `docs/skills.md` from its Skills section.
- [ ] `README.md` no longer calls the pipeline "six steps" in a way that conflicts with its seven-row table.
- [ ] `README.md`'s `setup` summary mentions `docs/plans/`; its `doctor` summary names every check `doctor.sh` runs, or says it checks the whole setup and links to the detail.
- [ ] Adding a directory under `skills/` with no section in `docs/skills.md` makes `bash tests/run.sh` fail.
- [ ] `bash tests/run.sh` passes.

### Out of Scope

- Changing any skill's behaviour or its `SKILL.md`, including the frontmatter `description`.
- `docs/skills-inventory.md` and its pinned rule list.
- `docs/extension-points.md`, `docs/dossier.md` and `docs/handoff.md`, beyond linking to them.

### Reference

- `README.md` — Skills section (lines 11-28).
- `skills/*/SKILL.md` — the source for each description.
- `docs/extension-points.md`, `docs/skills-inventory.md`.
- Triage ledger on `codeo/intake`: `doc:README.md:six-steps-vs-seven-skills`, `doc:README.md:setup-docs-plans`, `doc:README.md:doctor-checks`.

Proposed type: none (user-owned repository; `issue-types` printed nothing). Proposed label: `documentation`.

## Outcome

Filed as #34 on 2026-11-07 with label `documentation`, no Issue Type. Q1-Q4 answered: docs/skills.md, all four coverage areas, fold in the three deferred README gaps, add a guard test.

## Log

- 2026-11-07 — Q1-Q4 raised · cost: 1m · opus-5-5 99k in + 424k cached / 2k out
- 2026-11-07 — Q1-Q4 answered, draft written for review · cost: 3m · opus-5-5 102k in + 826k cached / 5k out
- 2026-11-07 — draft approved, filed as #34 · cost: 4m · opus-5-5 105k in + 1.1M cached / 8k out · sonnet-5-5 104k in + 36k cached / 359 out
