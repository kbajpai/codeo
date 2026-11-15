# New issue — /codeo:issue assigns a priority to every issue it files

| | |
|---|---|
| Issue | _not filed yet_ |
| Branch | _none — intake_ |
| Updated | 2026-11-15 |

## Where this stands

Draft written and presented for approval. Q1-Q3 answered in the conversation and recorded below.

## Questions

### Q1 — Every project, or opt-in?

**Why it matters:** rule issue-07 forbids setting Priority; an overlay cannot override a rule, so the change is in the plugin either way. Decides whether issue-07 is removed or becomes conditional.
**Options:** opt-in via config · every project, always.

**Answer:**
Opt-in via config. (Answered in the conversation, 2026-11-15.)

### Q2 — Where is the priority stored?

**Why it matters:** this repo has no priority labels and board #3 has no Priority field; labels work without a board, a field does not.
**Options:** labels · board field · both.

**Answer:**
Labels. (Answered in the conversation, 2026-11-15.)

### Q3 — Who chooses it?

**Why it matters:** decides whether the draft carries a proposal or the skill asks a new question every time.
**Options:** skill proposes, engineer confirms at the gate · always ask the engineer.

**Answer:**
Skill proposes with a one-line reason; the engineer confirms or changes it at the review gate, including when another skill delegated. (Answered in the conversation, 2026-11-15.)

## Notes

Defaults taken without asking (stated in the draft): Effort stays forbidden; no backfill of existing issues; a missing priority label does not fail the filing; this project turns the setting on. Overlaps #71 (in progress), which also edits skills/issue/SKILL.md. Not in #100's gate list.

## Draft

**Title:** `/codeo:issue`: assign every filed issue a priority (blocker, high, medium, low) when the project opts in

**Issue Type:** none (repository has no Issue Types) · **Labels:** `enhancement`

### Description

Add a project setting that makes `/codeo:issue` give every issue it files exactly one priority, `blocker`, `high`, `medium` or `low`, recorded as a label. The skill proposes the priority in its draft with a one-line reason, next to the Issue Type and labels, and the engineer confirms or changes it at the review gate. Projects that don't turn the setting on keep today's behaviour, where no priority is set.

### Motivation / Context

Issues filed through `/codeo:issue` carry no priority today. Rule `issue-07` in `skills/issue/SKILL.md` forbids it ("Do not set `Priority` or `Effort` custom fields — that's human triage judgment this skill has no basis to make"), and `docs/skills-inventory.md` lists it as a hard rule. So every issue reaches the backlog unranked, and the engineer has to add a priority by hand afterwards or go without one. The review gate already puts a human in front of every filing, so the priority can be the engineer's call made there, rather than a separate step later. A project overlay can't do this, because overlays may not override a rule, so the change belongs in the plugin.

### Key Requirements

- A setting in `.codeo/config.json` turns the behaviour on. When the setting is absent or off, `/codeo:issue` sets no priority, exactly as today.
- When it's on, every issue the skill files gets exactly one of four priorities: blocker, high, medium or low. The priority is recorded as a label on the issue, so it works whether or not a board is configured. No board field is added or written.
- The draft proposes the priority with a one-line reason, and the review gate shows it with the title, body, type and labels. Nothing is filed until the engineer approves or changes it. This is the same whether a human invoked the skill or `/codeo:triage`, `/codeo:plan` or `/codeo:implement` delegated to it. The caller supplies the finding, not the priority (rule `issue-04`).
- Rule `issue-07` is changed to match. Priority is set only under the setting and only with the engineer's approval at the gate. Effort is still never set. `docs/skills-inventory.md` and `docs/skills.md` describe the new rule.
- If a priority label doesn't exist in the repository, the filing still succeeds. The report names the missing label and the command that creates it. `/codeo:doctor` reports missing priority labels when the setting is on.
- This project (`kbajpai/codeo`) turns the setting on, and its repository has the four priority labels.

### Acceptance Criteria

- [ ] With the setting on, an issue filed through `/codeo:issue` has exactly one priority label: blocker, high, medium or low.
- [ ] With the setting on, the review gate's draft shows the proposed priority and a one-line reason before anything is filed. Changing it at the gate files the issue with the engineer's choice.
- [ ] With the setting absent or off, a filed issue has no priority label and the draft proposes none.
- [ ] An issue filed when `/codeo:triage` delegates gets its priority the same way, through the gate.
- [ ] With the setting on and a priority label missing, the issue is still filed, its number is reported, and the report names the missing label and how to create it.
- [ ] `/codeo:doctor` fails on missing priority labels when the setting is on, and says nothing about them when it is off.
- [ ] No filing sets Effort, with the setting on or off.
- [ ] `docs/skills-inventory.md`'s `issue-07` entry and `docs/skills.md` describe the new rule, and the skill tests cover the on and off paths.
- [ ] `kbajpai/codeo`'s `.codeo/config.json` has the setting on, and `gh label list` shows the four priority labels.

### Out of Scope

- Setting Effort, or any other triage field.
- A Priority field on the project board, and keeping a field in sync with the label.
- Adding a priority to existing open issues.
- Changing a priority after filing. `/codeo:triage` reprioritising is a separate follow-up.

### Reference

- `skills/issue/SKILL.md` step 5, rule `issue-07`; `docs/skills-inventory.md` (`[issue-07]`); `docs/skills.md`.
- #71 (in progress) also edits `skills/issue/SKILL.md`, adding a board step at filing.

## Outcome

_Pending — written at filing._

## Log

- 2026-11-15 — Q1-Q3 asked and answered in conversation; draft written
