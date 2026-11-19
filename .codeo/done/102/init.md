# Issue #102 — init

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/102 |
| Branch | `feat/codeo-issue-assign-every-filed` |
| Updated | 2026-11-19 |

## Where this stands

Initialized: branch `feat/codeo-issue-assign-every-filed` cut off `origin/main` at `4a4572e9624bad14b5753a3f455190a31789b290` and pushed. Next step: `/codeo:plan` in the issue's container.

## Questions

None.

## Outcome

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/102 — `/codeo:issue`: assign every filed issue a priority (blocker, high, medium, low) when the project opts in |
| State | open |
| Branch | `feat/codeo-issue-assign-every-filed` off `main` at `4a4572e` |
| Board | Ready → In progress |

**Problem.** `/codeo:issue` sets no priority today: rule `issue-07` forbids it, so every filed issue reaches the backlog unranked. The issue adds a `.codeo/config.json` setting that, when on, makes the skill propose exactly one of `blocker`, `high`, `medium` or `low` with a one-line reason, shown at the review gate with the title, body, type and labels, and recorded as a label once the engineer approves or changes it. Off or absent, nothing changes. A missing label does not block filing (the report names it and the command to create it), `/codeo:doctor` reports missing labels when the setting is on, and `issue-07` plus `docs/skills-inventory.md` and `docs/skills.md` are rewritten to match. This project turns the setting on.

**Acceptance criteria** — verbatim from the issue, unchecked:
- [ ] With the setting on, an issue filed through `/codeo:issue` has exactly one priority label: blocker, high, medium or low.
- [ ] With the setting on, the review gate's draft shows the proposed priority and a one-line reason before anything is filed. Changing it at the gate files the issue with the engineer's choice.
- [ ] With the setting absent or off, a filed issue has no priority label and the draft proposes none.
- [ ] An issue filed when `/codeo:triage` delegates gets its priority the same way, through the gate.
- [ ] With the setting on and a priority label missing, the issue is still filed, its number is reported, and the report names the missing label and how to create it.
- [ ] `/codeo:doctor` fails on missing priority labels when the setting is on, and says nothing about them when it is off.
- [ ] No filing sets Effort, with the setting on or off.
- [ ] `docs/skills-inventory.md`'s `issue-07` entry and `docs/skills.md` describe the new rule, and the skill tests cover the on and off paths.
- [ ] `kbajpai/codeo`'s `.codeo/config.json` has the setting on, and `gh label list` shows the four priority labels.

**Out of scope.** Setting Effort or any other triage field; a Priority field on the project board and keeping it in sync with the label; adding a priority to existing open issues; changing a priority after filing (`/codeo:triage` reprioritising is a separate follow-up).

**Open at intake.** The setting's name and shape in `.codeo/config.json` are not specified; `/codeo:plan` chooses them. The issue notes #71 also edits `skills/issue/SKILL.md`; #71 has since merged, so plan against the current file. The last acceptance criterion creates four labels on GitHub, which is a repository change for the engineer to confirm at plan or close.

## Log

- 2026-11-19 — initialized: branch feat/codeo-issue-assign-every-filed off main at 4a4572e · cost: 2m · sonnet-5-5 16k in + 388k cached / 2k out
