# Issue #83 — plan

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/83 |
| Branch | `feat/re-run-haiku-5-5` |
| Updated | 2026-11-15 |

## Where this stands

Read `init.md`, `issue.md`, #76's plan and dossiers, both skills, `docs/handoff.md`'s closing-block
section and the tests. Q1-Q3 are answered (A, A, proceed and coordinate). The draft is in
`docs/plans/2026-11-15-rerun-haiku-doctor-setup.md`, approved and unstaged. Q4 (the overlap with #57) is
answered. Nothing is open; the next step is `/codeo:implement`.

## Questions

### Q1 — If Haiku still misses item 1 with the new sentence, is that the result, or may the sentence be reworded and the trial run again?

**Why it matters:** the sentence is the thing under test. With one wording fixed in advance, a miss
means the skill stays on `model: sonnet` and the plan has one trial task (24 runs, roughly $2-3).
If rewording is allowed, the plan needs a loop with a stated limit, each further pass costs about
the same again, and a pass reached on the third wording is weaker evidence: three runs per case is
a small sample, and trying wordings until one passes is how a small sample gets fooled. The issue
says "re-run the trial" and does not say how many times.

The wording I would use, in both skills, in place of today's "then end with the closing block
(`${CLAUDE_PLUGIN_ROOT}/docs/handoff.md → Closing block`)":

> then end with the closing block. Its template is the *Closing block* section of
> `${CLAUDE_PLUGIN_ROOT}/docs/handoff.md`: read that file with the Read tool, not with a Bash
> command.

It names Bash as well as Read because a Bash read is exactly what Haiku did in #76. The citation
`docs/handoff.md → Closing block` that `tests/closing-block.test.sh` requires stays in the sentence.

**Options:**
- **A — one wording, one trial (recommended).** The sentence above is fixed before any run. A Haiku
  miss on any item keeps that skill on `sonnet`; the sentence stays in the skill either way
  (criterion 1 does not depend on the result), and the issue records how the runs differed.
- **B — one revision allowed.** If Haiku misses item 1, reword once and run the Haiku half again
  (12 runs); the record names both wordings and both results. A second miss ends it.
- **C — reword until it passes, up to a limit you name.**

**Answer:**
A (answered in the conversation).

### Q2 — Does the repository get a test that fails when the Read sentence is dropped from `doctor` or `setup`?

**Why it matters:** if a skill switches to `model: haiku`, that switch rests on one sentence of
skill text. Nothing in `tests/` would notice a later edit removing it, and the skill would go back
to failing the item it was switched on, with no trial to show it. With a test, the plan's first task
is test-first (the assertion fails on today's text, then the edit makes it pass) and the footprint
gains `tests/closing-block.test.sh`. Without one, the task's proof is a `grep` the plan names and
`bash tests/run.sh`, and the footprint is the two skills and `CHANGELOG.md` only. The issue's
criteria ask for the text, not for a guard.

**Options:**
- **A — add the assertion to `tests/closing-block.test.sh` (recommended):** `doctor` and `setup`
  must each say "with the Read tool". Two lines in an existing test; kept whether or not a skill
  switches.
- **B — add it only for a skill that switches to `haiku`.** The guard exists only where something
  depends on it; the plan's test task then comes after the trial.
- **C — no test.** The sentence is checked once, by `grep`, in this change.

**Answer:**
A (answered in the conversation).

### Q3 — `CHANGELOG.md` is also changed by #57. Proceed and coordinate, sequence after #57, or re-scope?

**Why it matters:** #57 (branch `feat/dev-container-follow-ups-55`, assignee kbajpai, step `close`,
working) lists `CHANGELOG.md` in its footprint and has changed it on its branch. This plan adds one
bullet under `## Unreleased` in the same file, so whichever merges second may have to resolve a
conflict in that list. Sequencing would hold this change until #57 merges; proceeding means the
second to merge rebases one bullet. The same overlap between #57 and #76 was answered *proceed and
coordinate*. No other overlap: #73 (`docs/evaluate-docker-sandboxes-sbx-against`, at `plan`) shares
no file with this plan, and no exclusive resource is configured.

**Options:** proceed and coordinate (recommended: #57 is already at `close`, and the conflict is
one added bullet) · sequence after #57 · re-scope (leave `CHANGELOG.md` out, which criterion 5 does
not allow).

**Answer:**
Proceed and coordinate (A; answered in the conversation).

### Q4 — `overlap.sh` reports `#57` and `glob:CHANGELOG.md`: proceed and coordinate, sequence after #57, or re-scope?

**Why it matters:** this is the overlap Q3 already answered *proceed and coordinate*, raised again
only because `overlap.sh` recognises a pair as raised when a question quotes the token it prints,
`glob:CHANGELOG.md`, and Q3 did not. The footprint's `files:` line lists `CHANGELOG.md`, which #57
(branch `feat/dev-container-follow-ups-55`, assignee kbajpai, step `close`, working) also changes.
Confirming Q3's answer lets the outcome be written; sequencing would hold Task 5 until #57 merges.

**Options:** proceed and coordinate (recommended, as in Q3: one added bullet under `## Unreleased`)
· sequence after #57 · re-scope (leave `CHANGELOG.md` out, which criterion 5 does not allow).

**Answer:**
Proceed and coordinate (answered in the conversation).

## Notes

**What the issue already settles, so it is not asked.** The fix is skill text (not a relaxed item
1); the four cases, three runs per model, 24 runs; the six items with item 1 as "exactly one Bash
call"; `--allowedTools Bash Read --add-dir <plugin copy>`; both plugin copies carry the new sentence
and differ only in the two `model:` lines; the model of each run is read from `modelUsage`; a skill
switches only when every Haiku run of both its cases passes every item; the trial script is a
throwaway outside the repository; the record is a comment on #83.

**My calls, unless you say otherwise.**
- The trial script is rebuilt: #76's scratchpad is gone. It is rebuilt to the scorer as #76 left it
  after its corrections (an exit stated as `EXIT_CODE=N` or `exited with status 1` counts; item 5
  of `doctor-pass` reads only the Next goal line; item 5 of `doctor-fail` does not demand the word
  "fix"), so the two trials are scored the same way. Item 5 of `setup-refuse` is read by hand, as
  before.
- The plan's proof for the comment uses `gh issue view 83 --json comments`, since #76's
  `--comments --json` form was rejected.
- The trial runs in this container (Claude Code 2.1.325, the version #76 used); no task runs on
  your own host, so no shell question arises.
- One pull request. An executable plan under `docs/plans/`, no reference doc: no architectural
  choice is being made.
- Documentation: `CHANGELOG.md` only. `docs/skills.md`'s `doctor` and `setup` sections say what the
  skills report, not which tool reads the template or which model runs them, and stay true either
  way.
- Only `doctor` and `setup` get the sentence. The other seven skills cite the template the same way
  and are out of scope.

## Outcome

| | |
|---|---|
| Plan | `docs/plans/2026-11-15-rerun-haiku-doctor-setup.md` (unstaged, awaiting your commit) |
| Shape | an executable plan under `docs/plans/`, five tasks; no reference doc, as no architectural choice is made |

**Decisions.** Q1 = A: one fixed wording of the Read sentence, one trial; a Haiku miss keeps that skill on `sonnet` and the wording is not revised. Q2 = A: `tests/closing-block.test.sh` asserts both skills carry the sentence, written first and shown failing, kept whether or not a skill switches. Q3 and Q4 = proceed and coordinate: #57 also adds to `CHANGELOG.md`; one bullet under `## Unreleased`.

**Rejected.** Rewording until Haiku passes (a small sample gets fooled); a guard test only for a skill that switches; sequencing after #57; relaxing item 1 instead of changing the skill text (settled in the issue).

**My calls.** The trial script is rebuilt in the scratchpad (#76's is gone) to #76's corrected scorer, and not committed. A `read-handoff` column records how `docs/handoff.md` was opened, so a Haiku run that passes item 1 by skipping the read is visible. The comment's proof uses `gh issue view 83 --json comments`. The plugin copies are archived from `HEAD` after Task 1's commit.

**Documentation.** `CHANGELOG.md` only. `docs/skills.md`'s `doctor` and `setup` sections do not name the template's reader or the model, and stay true. No intake question was resolved here.

### Footprint

```
files:      skills/doctor/SKILL.md, skills/setup/SKILL.md, tests/closing-block.test.sh, CHANGELOG.md, docs/plans/2026-11-15-rerun-haiku-doctor-setup.md
wiki:       none
exclusive:  none
sequenced:  none — CHANGELOG.md overlaps #57; proceed and coordinate (Q3, Q4)
```

## Log

- 2026-11-15 — Q1-Q3 raised · cost: 1m · fable-5-2 64k in + 220k cached / 2k out
- 2026-11-15 — plan drafted and approved; footprint raised Q4 (#57, glob:CHANGELOG.md) · cost: 3m · sonnet-5-5 588 in + 256k cached / 547 out
- 2026-11-15 — planned: docs/plans/2026-11-15-rerun-haiku-doctor-setup.md · cost: 0m · sonnet-5-5 588 in + 256k cached / 547 out
