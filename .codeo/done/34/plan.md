# Issue #34 — plan

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/34 |
| Branch | `chore/describe-every-codeo-skill-docs` |
| Updated | 2026-11-07 |

## Where this stands

Round 1 complete: plan approved and written to `docs/plans/2026-11-07-describe-every-skill.md` (unstaged — the engineer commits it). Next: `/codeo:implement`. What exploration found:

- The seven pipeline skills each end with `## Hand-off` (Reads / Writes / Never touches / Hands off to) and `## Non-goals` sections, so most of the material for `docs/skills.md` already exists in a fixed shape. `setup` and `doctor` are 12-line skills that run `scripts/setup.sh` and `scripts/doctor.sh`; their descriptions come from those scripts' headers.
- `lib/extension-points.tsv` is the machine-readable registry of the 14 extension points, already checked against each `SKILL.md` and `docs/extension-points.md` by `tests/skills.test.sh` check 4.
- `tests/inventory.test.sh` is the precedent for a standalone test that checks one doc's shape against the skills list; `tests/skills.test.sh` + `tests/skills-lint.test.sh` is the precedent for a lint check with a scratch-tree self-test.
- No `docs/plans/` exists yet; no invariants, shared environment or wiki module is configured. One suite, `shell` (`bash tests/run.sh`, no `filter`).

## Questions

### Q1 — How should each skill's description be written?

**Why it matters:** decides the author's work and how the doc ages. The pipeline skills' `## Hand-off` sections already state reads, writes and hand-offs in a fixed shape; `docs/skills.md` can quote them closely (stays in step with `SKILL.md`, reads like a spec) or restate them for a reader who has never opened a `SKILL.md` (reads better, drifts sooner). Nothing tests prose, so drift is caught only by review either way.
**Options:** closely follow the `## Hand-off` and `## Non-goals` wording, rephrased only where needed · fresh prose written for a newcomer, using `SKILL.md` as the source but not its wording · no preference, you pick.

**Answer:**
Follow the `## Hand-off` and `## Non-goals` wording closely, rephrasing only where needed.

### Q2 — How strict should the guard test be?

**Why it matters:** sets what the test actually proves, and so what a future skill author is forced to write. Each level is cheap; the question is how much shape to pin.
**Options:** (a) heading only — every `skills/*/` has a `## <skill>` section in `docs/skills.md`, and no section names a skill that does not exist · (b) heading plus the four required sub-parts (purpose/triggers, reads/writes, hand-offs/non-goals, extension points) present under each · (c) b, and the extension points each section lists match `lib/extension-points.tsv` exactly · no preference, you pick.

I'd recommend (c): the extension-point check is exact and cheap, and it is the one thing in the doc that can be verified mechanically. Placement is my call either way: a standalone `tests/skills-doc.test.sh` on the `inventory.test.sh` precedent, not a seventh check in `skills.test.sh`, so `skills-lint.test.sh`'s scratch tree is untouched.

**Answer:**
(c): headings, the four sub-parts, and the extension points matched exactly against `lib/extension-points.tsv`. Standalone `tests/skills-doc.test.sh`.

### Q3 — What happens to the README's Skills table?

**Why it matters:** the table's *Extension points* column duplicates what `docs/skills.md` will carry in full; the issue only requires a link.
**Options:** keep the table as is and add the link · drop the *Extension points* column, keep Skill and Purpose, link each row to its `docs/skills.md` section · replace the table with a short list plus one link · no preference, you pick.

**Answer:**
Drop the *Extension points* column; keep Skill and Purpose; link each row to its `docs/skills.md` section.

## Notes

Decisions I intend to make in the plan unless told otherwise (marked as my calls there):

- `docs/skills.md` orders sections as the pipeline runs — issue, init, plan, implement, qc, close — then triage, setup, doctor.
- The README's "six steps" line becomes: six pipeline steps (issue, init, plan, implement, QC, close) plus `triage`, which runs outside the workflow lock; `setup` and `doctor` are stated as the two set-up skills.
- The README's `setup` line mentions `docs/plans/`; its `doctor` line says it checks the whole set-up and links to the detail, rather than listing every check (the list is `doctor.sh`'s header, and would drift).
- One PR; a `CHANGELOG.md` Unreleased entry, as every change here gets.
- Tasks follow TDD: the guard test first, failing because `docs/skills.md` does not exist, then the doc, then the README.

## Outcome

**Plan.** `docs/plans/2026-11-07-describe-every-skill.md` — an executable plan (Goal / Architecture / Tech Stack / Spec / Global Constraints / Review Focus, three checkbox tasks). Approved by the engineer; left unstaged for them to commit.

**Shape chosen.** A plan under `docs/plans/`, not a reference doc: the deliverable (`docs/skills.md`) is itself the standing reference, and the plan is the build order for it.

**Tasks.** (1) `tests/skills-doc.test.sh` — the guard, with eleven scratch-tree cases, written first and failing with `FAIL doc-missing`; (2) `docs/skills.md` — nine sections in the fixed four-part shape; (3) `README.md` Skills section and a `CHANGELOG.md` Unreleased entry.

**Decisions** (Q1–Q3, answered by the engineer): descriptions follow each `SKILL.md`'s `## Hand-off` and `## Non-goals` wording closely (rejected: fresh newcomer prose); the guard checks headings, the four sub-parts and the extension points exactly against `lib/extension-points.tsv` (rejected: headings only, headings plus parts); the README table drops its *Extension points* column and links each row to its section (rejected: keep as is, short list).

**My calls, marked in the plan.** One test file rather than the lint's two-file split; standalone test, not a seventh `skills.test.sh` check, so `skills-lint.test.sh`'s scratch trees are untouched; `None.` is the exact text for a skill with no points; the doctor check list lives in `docs/skills.md`, not the README; CI is the suite's verdict because nine unrelated tests already fail on Windows checkouts.

**Options rejected** are tabulated in the plan's *Options considered*.

**Documentation the plan changes.** `README.md` (Skills section) and the new `docs/skills.md`. No wiki module. `docs/extension-points.md` and `docs/skills-inventory.md` are untouched (issue's Out of Scope).

**Intake questions resolved.** None; `init.md` left none open. No `/codeo:issue` filed; no optional skill unavailable (the `engineering` skills were not needed — no technology choice or new component).

### Footprint

```
files:      docs/skills.md, tests/skills-doc.test.sh, README.md, CHANGELOG.md
wiki:       none
exclusive:  none
sequenced:  none
```

## Log

- 2026-11-07 — Q1-Q3 raised · cost: 1m · fable-5-1 167k in + 235k cached / 335 out
- 2026-11-07 — Q1-Q3 answered · cost: 3m · fable-5-1 175k in + 641k cached / 6k out
- 2026-11-07 — planned: docs/plans/2026-11-07-describe-every-skill.md · cost: 8m · fable-5-1 197k in + 1.7M cached / 21k out · sonnet-5-5 197k in + 36k cached / 924 out
