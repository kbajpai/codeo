# Issue #102 — qc

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/102 |
| Branch | `feat/codeo-issue-assign-every-filed` |
| Updated | 2026-11-19 |

## Where this stands

Round 1 done: build and the full suite pass, every criterion is met, the review found nothing blocking. Verdict: clear, forward to /codeo:close.

## Questions

### Q1 — Overlap with #108 on `CHANGELOG.md`, `docs/skills.md`, `glob:CHANGELOG.md` and `glob:docs/skills.md`

**Why it matters:** #108 (`feat/follow-ups-97-left-overlap`, assignee kbajpai, at `init`, waiting on its plan.md Q6-Q7) now has a footprint that lists `CHANGELOG.md` and `docs/skills.md`, the same two pages this branch edits (one entry in `CHANGELOG.md`'s Unreleased list; the `issue` and `doctor` sections of `docs/skills.md`). #108 has no changed files yet. Its plan names `docs/handoff.md`, `skills/init/SKILL.md` and overlap/qc-verdict/board scripts, so its `docs/skills.md` edits are likely in other skills' sections. Whichever merges second resolves the Unreleased list. This is the same shape as #122's overlap, answered *proceed and coordinate* in implement.md Q1.
**Options:** proceed and coordinate · sequence after #108 · re-scope. *Recommended: proceed and coordinate — different sections, #108 has not started building, and this branch is ready for review.*

**Answer:**
Proceed and coordinate. (Answered in the conversation, 2026-11-19.)

## Notes

Step 2 so far: `sync-main.sh --abort-on-conflict` → `sync-main: the branch already contains origin/main`. `overlap.sh 102` printed:

```
108	CHANGELOG.md
108	docs/skills.md
108	glob:CHANGELOG.md
108	glob:docs/skills.md
```

## Outcome

### Round 1 — 2026-11-19

Step 2: `sync-main.sh --abort-on-conflict` → `sync-main: the branch already contains origin/main`. `overlap.sh 102` raised the overlap with #108 (Q1, answered: proceed and coordinate); `overlap.sh --outside 102` printed nothing, so every changed path is in the plan's footprint. `scope.sh origin/main HEAD` → `suite.shell=true` (`.codeo/` dossier files, `.codeo/config.json` and `CHANGELOG.md` are unclassified paths that need the suite). No `deploy=` line: no shared environment is configured.

Build: the `shell` suite's build is `true` → exit 0. Tests: `bash tests/run.sh` → `all cases passed` (exit 0). Focused runs for the criteria: `bash tests/issue-skill.test.sh`, `tests/doctor.test.sh`, `tests/github.test.sh`, `tests/inventory.test.sh` → `all cases passed`; `bash tests/skills.test.sh` → `all cases passed` (two `skipped … check 5 rules (no inventory IDs yet)` lines for `doctor` and `setup`, which have no inventory entries). Live: `bash scripts/github.sh label list | grep '^priority: '` → `priority: blocker`, `priority: high`, `priority: low`, `priority: medium`; `bash scripts/config.sh get .issue.priority` → `true`; `bash scripts/doctor.sh` → twelve lines including `ok priority-labels: all four exist`.

| Criterion | Verdict | Settled by |
|---|---|---|
| With the setting on, a filed issue has exactly one priority label | met | `skills/issue/SKILL.md` step 5 ("propose exactly one of"), step 6 (asks again when none), step 7 (`-f 'labels[]=priority: <name>'`); pinned by `tests/issue-skill.test.sh` |
| The gate's draft shows the proposed priority and a one-line reason; a change is honoured | met | `skills/issue/SKILL.md` step 6 (`Changing it at the gate files the issue with the engineer's choice`); pinned by `tests/issue-skill.test.sh` |
| Setting absent or off: no priority label, no proposal | met | `skills/issue/SKILL.md` step 5 (`When it prints anything else, or nothing, propose no priority and add no priority label`); `tests/doctor.test.sh` off cases (false, `"true"`, null, absent key: eleven lines) |
| An issue filed when `/codeo:triage` delegates gets its priority through the gate | met | `skills/triage/SKILL.md` files through `/codeo:issue` unchanged; `skills/issue/SKILL.md` step 5 (`A priority a calling skill passes along is ignored`) and rule `issue-04`; `tests/issue-skill.test.sh` pins the triage path |
| Setting on and a label missing: filed, number reported, report names the label and the command | met | `skills/issue/SKILL.md` step 7 (`A missing priority label never fails the filing`, `github.sh" label create '<label>'`); `scripts/github.sh` `label create`, `tests/github.test.sh` |
| `/codeo:doctor` fails on missing labels when on, silent when off | met | `scripts/doctor.sh` `priority-labels` check, `tests/doctor.test.sh` `doctor_priority_labels_*` |
| No filing sets Effort | met | rule `issue-07` in `skills/issue/SKILL.md` (`never set \`Effort\``); `docs/skills-inventory.md` `[issue-07]` |
| `issue-07` entry and `docs/skills.md` describe the rule; tests cover on and off | met | `docs/skills-inventory.md:29`, `docs/skills.md` `issue` and `doctor` sections, `tests/issue-skill.test.sh`, `tests/inventory.test.sh` |
| `.codeo/config.json` has the setting on and `gh label list` shows the four labels | met | `.codeo/config.json` `issue.priority: true`; the live label list above |

Documentation check: `docs/skills.md` (`issue`: purpose paragraph and Reads and writes; `doctor`: the check count), `docs/skills-inventory.md` and `CHANGELOG.md` describe the change in the present tense, and the plan named no other page. Two small inaccuracies are findings F1 and F3 below. Rules: the project has no invariants file and its overlay gives no further rules (`invariants-extra`, `wiki-rules` exit 3).

Independent review (opus, handed the criteria and the diff only): no Critical or Important finding; it quotes each criterion to a line, and reports its checks of the doctor shell (quoting, `set -u`, variable reuse) and of `label create` as sound.

Findings, all `non-blocking`:
- F1 (non-blocking, `/codeo:implement`'s) — a string `"true"` is on for the skill and off for doctor. `config.sh get .issue.priority` uses `jq -r`, so `{"issue":{"priority":"true"}}` prints `true` and `skills/issue/SKILL.md:131` proposes priorities, while `scripts/doctor.sh:121` tests `== true` and stays silent; the plan's Global Constraints and Review Focus say a string is off. The skill should read `config.sh get '.issue.priority == true'` and act on `true`.
- F2 (non-blocking, `/codeo:implement`'s) — the generic label pass can add a second priority label. `skills/issue/SKILL.md:128` says to propose labels that exist and fit; with the four priority labels present the generic pass could propose `priority: low` beside the priority pass's `priority: high`. One line telling the generic pass to skip `priority:` labels when the setting is on removes it.
- F3 (non-blocking, `/codeo:implement`'s) — `docs/skills.md` says the skill "Reads the repository's labels when `issue.priority` is on", but step 5 runs `label list` whether the setting is on or off.
- F4 (non-blocking, `/codeo:plan`'s, accepted by the plan) — the gate does not say that the approved priority's label is missing; the engineer learns it from the report (criterion 5 is met).
- F5 (non-blocking, `/codeo:implement`'s) — `scripts/doctor.sh` prints `$CODEO_PLUGIN_ROOT` unquoted in the create command, so a plugin path with a space breaks the printed command; and `skills/issue/SKILL.md` step 6 does not say what to do when the engineer names a priority outside the four.

Carried from implement.md's outcome, already known: the scope sentences ("and that is all it does", "does nothing else") are pinned by tests and omit the label; long unwrapped lines in the skill; the `issue-07 keeps its comment` test pins nothing new. No issue was filed for this pass.

**Verdict: clear — forward to `/codeo:close`.**


## Log

- 2026-11-19 — Q1 raised (overlap with #108), stopped at step 2 · cost: 0m · opus-5-5 211k in + 267k cached / 640 out
- 2026-11-19 — round 1: clear, five non-blocking findings · cost: 17m · opus-5-5 281k in + 1.1M cached / 9k out · sonnet-5-5 26k in + 1.4M cached / 3k out
