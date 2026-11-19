# Issue #102 — plan

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/102 |
| Branch | `feat/codeo-issue-assign-every-filed` |
| Updated | 2026-11-19 |

## Where this stands

Round 1 done. The plan is approved and written; Q1-Q5 are answered, no lock is needed and no overlap was found. Next step: /codeo:implement.

## Questions

### Q1 — What is the setting called, and is it a switch or a mapping?

**Why it matters:** it is the key the skill reads at step 5, the key `doctor.sh` reads, a new line in `lib/env.sh`'s header (the skills lint fails a `config.sh get` filter the header does not name), and what this project's `.codeo/config.json` gains. A switch means one read and fixed label names; a mapping means the skill and doctor resolve four names each time, as `board.statuses` does.
**Options:**
- `issue.priority: true` — a boolean under a new `issue` object; absent or `false` is off; label names are fixed by the plugin (Q2). *Recommended: the issue asks for an on/off setting, and nothing yet needs other names.*
- `issue.priority: true` plus an optional `issue.priorityLabels{blocker,high,medium,low}` mapping to the repository's own label names, each defaulting to the plugin's name. For a project that already ranks with `P0`-`P3`.
- A top-level `priority{...}` object whose presence turns it on.

**Answer:**
As recommended. (Answered in the conversation, 2026-11-19.)

### Q2 — What are the four labels called on GitHub?

**Why it matters:** these are the names the skill sends at filing, the names doctor looks for, and the labels created on `kbajpai/codeo`. The repository has none today (its labels are GitHub's defaults: `bug`, `enhancement`, `documentation` and so on). "Exactly one priority label" also has to be checkable, by the skill and by `/codeo:qc`, which a shared prefix makes a one-line filter.
**Options:**
- `priority: blocker`, `priority: high`, `priority: medium`, `priority: low` — prefixed, sorts together in the label picker, and cannot be mistaken for another label. *Recommended.*
- `priority/blocker` … `priority/low` — the same with no space, so the name needs no quoting in a shell command.
- Bare `blocker`, `high`, `medium`, `low` — the issue's own words, but `high` alone says nothing on an issue's label row.

**Answer:**
As recommended. (Answered in the conversation, 2026-11-19.)

### Q3 — What does the skill propose a priority from?

**Why it matters:** rule `issue-07` exists because the skill "has no basis" to rank. The rewritten rule needs one, written into step 5, or two sessions will rank the same finding differently and the one-line reason will be decoration. The plan writes this text into the skill, and the tests pin it.
**Options:**
- A fixed four-line rubric in the skill, the reason quoting the line that applied. *Recommended*, with this wording to edit:
  - **blocker** — work already in flight cannot continue, or the base branch or a release is broken, until this is fixed.
  - **high** — a defect or gap that affects normal use and has no acceptable workaround, or work a committed piece of work depends on.
  - **medium** — worth doing; there is a workaround, or the effect is limited. The default when nothing above applies and the issue is not `low`.
  - **low** — polish, cleanup, or a follow-up nobody is waiting on.
- The same rubric as the default, plus a new `issue/priority-rubric` extension point so a project's overlay can narrow it. Adds a row to `lib/extension-points.tsv` and a section to `docs/extension-points.md`.
- No rubric: the skill judges from the issue's content alone.

**Answer:**
As recommended. (Answered in the conversation, 2026-11-19.)

### Q4 — With the setting off, does `/codeo:doctor` print a line for the priority check?

**Why it matters:** the criterion says doctor "says nothing about them when it is off". Every other check prints a line either way (`ok board: no board configured`), and `doctor.test.sh` counts one line per check. Read literally the new check prints nothing when off and the count stays eleven for every existing project; read by the house pattern it prints `ok priority-labels: not enabled` and the count becomes twelve everywhere. `/codeo:qc` will grade whichever the plan states.
**Options:**
- No line when off; when on, `ok priority-labels: all four exist` or `fail priority-labels: missing: <names>; create with: <command>`. *Recommended: it is what the criterion says, and an opted-out project's doctor output does not change.*
- A line always, `ok priority-labels: not enabled` when off.

**Answer:**
As recommended. (Answered in the conversation, 2026-11-19.)

### Q5 — Who creates the four labels on `kbajpai/codeo`, and with which command?

**Why it matters:** the last criterion needs the labels to exist, and creating them changes the repository for everyone, outside any diff. The same command is what the filing report and doctor's failure line print for a missing label, so it has to be decided once. The plugin makes every other GitHub call through `scripts/github.sh`, which today has `label list` only.
**Options:**
- Add `github.sh label create <name>` (plain REST, so it works in a web session too; GitHub's default colour, since a colour is per-project taste). The report and doctor print that command, and a plan task has `/codeo:implement` run it four times for this repository after you have approved the plan. *Recommended.*
- The same verb, but the plan marks the four creations as yours to run and the criterion is checked afterwards.
- No new verb: the report prints a raw `gh api repos/<owner>/<name>/labels -f name=…` line, and you create the labels by hand.

**Answer:**
As recommended. (Answered in the conversation, 2026-11-19.)

## Notes

Decisions taken without a question, each stated in the draft for you to overrule at the review gate:

- Rule `issue-07` is rewritten in place and keeps its number; the inventory still has nine `issue` rules, and its pinned hash fixture is regenerated in the same task.
- The skill decides a missing label from the `label list` it already runs at step 5 and leaves that label out of the filing call. It never relies on GitHub's handling of an unknown label name, which differs with the caller's access.
- One pull request. Effort stays forbidden; delegated filings take the same gate (rule `issue-04` already says the caller supplies no answers).
- This project pins plugin `v1.0.7`, so turning the setting on in `.codeo/config.json` takes effect here only once a release carrying this change is pinned. The criterion asks for the config and the labels, not the release.
- Other workflows in flight (#108, #122) are at `init` with no footprint and no changed files, so there is nothing to compare yet; the check runs again before the hand-off.

## Outcome

Plan: `docs/plans/2026-11-19-issue-priority-label-102.md` (approved 2026-11-19; left unstaged for the engineer). Shape: a scoped, executable plan under `$PLANS`; no reference doc, since the behaviour is documented in `docs/skills.md` and the inventory.

**Decisions** (Q1-Q5, all answered "as recommended"):
- Setting: `issue.priority: true`, a boolean under a new `issue` object, off for anything else. Rejected: a label-name mapping, and a top-level `priority{}` object.
- Labels: `priority: blocker`, `priority: high`, `priority: medium`, `priority: low`. Rejected: `priority/<x>`, and bare names.
- Proposal from a fixed four-line rubric in the skill, the reason quoting the line applied. Rejected: a new `issue/priority-rubric` extension point, and no rubric.
- Doctor prints a `priority-labels` line only when the setting is on, nothing when off. Rejected: a line always.
- A new `github.sh label create <name>` verb is the one command the report, doctor and the plan use; the four labels on `kbajpai/codeo` are created by Task 5 after approval. Rejected: engineer-run creation, and a raw `gh api` line.
- Taken without a question: `issue-07` is rewritten in place (still nine `issue` rules); a label missing from the `label list` is left out of the filing call and named in the report; one pull request; triage needs no change.

**Documentation the plan changes:** `docs/skills.md` (issue and doctor sections), `docs/skills-inventory.md` (`issue-07`), `CHANGELOG.md`; header comments of `scripts/github.sh`, `scripts/doctor.sh`, `lib/env.sh`. No wiki module.

**Intake question resolved:** the setting's name and shape (open at intake) is Q1 above; `init.md` still records it as open at intake. The labels on GitHub are the plan's Task 5, confirmed by approving the plan.

### Footprint

```
files:      scripts/github.sh, scripts/doctor.sh, lib/env.sh, skills/issue/SKILL.md, docs/skills-inventory.md, docs/skills.md, CHANGELOG.md, tests/fixtures/skills-inventory.rules.sha256, tests/github.test.sh, tests/doctor.test.sh, tests/issue-skill.test.sh, .codeo/config.json, docs/plans/2026-11-19-issue-priority-label-102.md
wiki:       none
exclusive:  none
sequenced:  none
```

## Log

- 2026-11-19 — Q1-Q5 raised · cost: 2m · fable-5-2 88k in + 598k cached / 8k out
- 2026-11-19 — planned: docs/plans/2026-11-19-issue-priority-label-102.md · cost: 145m · fable-5-2 92k in + 834k cached / 9k out · sonnet-5-5 234k in + 834k cached / 14k out
