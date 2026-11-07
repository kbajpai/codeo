# Issue #34 — init

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/34 |
| Branch | `chore/describe-every-codeo-skill-docs` |
| Updated | 2026-11-07 |

## Where this stands

Initialized: branch `chore/describe-every-codeo-skill-docs` off `main` at `8e3605a`, pushed and claimed. Next: /codeo:plan.

## Questions

None.

## Outcome

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/34 — Describe every codeo skill in docs/skills.md and guard coverage with a test |
| State | open · labels `documentation` |
| Branch | `chore/describe-every-codeo-skill-docs` off `main` at `8e3605a` |
| Board | not configured |

**Problem.** The user-facing docs do not describe codeo's skills in enough depth to use them without reading each `SKILL.md`. `README.md` gives each pipeline skill one table row and `setup` and `doctor` one shared sentence, which leaves three gaps: "six steps" against a seven-row table, `setup` also creating `docs/plans/`, and `doctor` running more checks than the README names. The fix is a new `docs/skills.md` covering all nine skills under `skills/` (purpose and triggers, reads and writes, hand-offs and non-goals, extension points), a README that summarises and links to it, and a test that fails when a skill has no section.

**Acceptance criteria** — verbatim from the issue, unchecked:
- [ ] `docs/skills.md` has a section for each of the nine skills under `skills/`.
- [ ] Each section states purpose and triggers, reads and writes, hand-offs and non-goals, and extension points.
- [ ] Every extension point listed in `docs/skills.md` matches the `point:` markers in that skill's `SKILL.md` and the entries in `docs/extension-points.md`.
- [ ] `README.md` links to `docs/skills.md` from its Skills section.
- [ ] `README.md` no longer calls the pipeline "six steps" in a way that conflicts with its seven-row table.
- [ ] `README.md`'s `setup` summary mentions `docs/plans/`; its `doctor` summary names every check `doctor.sh` runs, or says it checks the whole setup and links to the detail.
- [ ] Adding a directory under `skills/` with no section in `docs/skills.md` makes `bash tests/run.sh` fail.
- [ ] `bash tests/run.sh` passes.

**Out of scope.**
- Changing any skill's behaviour or its `SKILL.md`, including the frontmatter `description`.
- `docs/skills-inventory.md` and its pinned rule list.
- `docs/extension-points.md`, `docs/dossier.md` and `docs/handoff.md`, beyond linking to them.

**Open at intake.** None.

## Log

- 2026-11-07 — drafted for the review gate · cost: 1m · sonnet-5-5 13k in + 435k cached / 1k out
- 2026-11-07 — initialized: branch chore/describe-every-codeo-skill-docs off main at 8e3605a · cost: 1m · sonnet-5-5 16k in + 743k cached / 3k out
