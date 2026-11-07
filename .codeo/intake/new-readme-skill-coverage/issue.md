# Issue (new-readme-skill-coverage) — issue

| | |
|---|---|
| Issue | not filed yet |
| Branch | none |
| Updated | 2026-11-07 |

## Where this stands

Round 1. The engineer asked for an issue so that every skill under `skills/` is covered in the
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

### Q2 — What should each skill's description cover?

**Why it matters:** sets the acceptance criteria per skill.
**Options:** purpose and when to use it (trigger phrases) · what it reads and writes (its dossier file, branches, board, GitHub) · what it hands off to and what it never does · its extension points · any mix.

**Answer:**

### Q3 — Should the three deferred README gaps be folded into this issue?

**Why it matters:** if yes, the triage ledger rows become "already #N" at the next triage instead of separate items.
**Options:** yes, fold them in · no, keep them separate.

**Answer:**

### Q4 — Should a test guard coverage, so a new skill without a description fails CI?

**Why it matters:** without one, the docs drift again the next time a skill is added; with one, it is a requirement on the change, not just docs.
**Options:** yes, a test · no, docs only.

**Answer:**

## Notes

Proposed type: none (user-owned repository; `issue-types` printed nothing). Proposed label: `documentation`.

## Outcome

_Pending — written at the hand-off._

## Log

- 2026-11-07 — Q1-Q4 raised · cost: 1m · opus-5-5 99k in + 424k cached / 2k out
