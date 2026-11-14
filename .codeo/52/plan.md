# Issue #52 — plan

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/52 |
| Branch | `feat/run-codeo-latest-claude-models` |
| Updated | 2026-11-14 |

## Where this stands

Plan approved and written to `docs/plans/2026-11-14-latest-claude-models.md` (left unstaged for your review). Nothing is open. Five tasks: the rename in
`docs/` and the fixtures, the test input IDs, one comment on #52 with the alias record and the
Haiku evaluation, a follow-up issue for the Haiku trial, and the changelog entry last, waiting for
#51 (Q5). No skill or default changes.

## Questions

### Q1 — Where does the alias-to-model record go, and who posts it?

**Why it matters:** criterion 1 says "the issue records" the resolution. I have the evidence
already (table under `## Notes`). `/codeo:plan` never touches the issue, so the answer decides
whether the plan has a task that posts to GitHub, or a task that stops and waits for you.
**Options:**
- **A — `/codeo:implement` posts one comment on #52 (recommended).** The plan's task re-runs the
  four headless checks, then posts the table, the Claude Code version and the command with
  `gh issue comment`. `/codeo:qc` reads the comment as the evidence for criterion 1.
- **B — you post it.** The task prints the comment text, stops, and waits for you to paste the
  comment's URL.
- **C — A, and the same table also goes in `CHANGELOG.md`'s entry**, so the record ships with the
  release notes as well as sitting on the issue.

**Answer:**
A — `/codeo:implement` posts one comment on #52 (answered in the conversation: accept the
recommendation).

### Q2 — What should the Haiku 5.5 evaluation produce?

**Why it matters:** the issue leaves it as an evaluation, and its out-of-scope line allows a model
change only as the evaluation's result. The answer decides whether this branch changes any
`model:` line, and whether I file a follow-up issue.

My desk evaluation, from reading the skills:
- `doctor` and `setup` run one script and report its output: good Haiku candidates.
- `init` and `close` are long, rule-heavy flows that push branches, move board cards and open pull
  requests (`close` is about 670 lines): a slip there costs more than Sonnet saves. Keep Sonnet.
- `triage` judges whether a loose end duplicates an existing issue: keep Sonnet.
- The subagent default writes the code in `/codeo:implement`: keep Sonnet.
- `haiku` already resolves to `claude-haiku-5-5`, and `tests/skills.test.sh` already accepts
  `model: haiku`, so a switch is a one-line change per skill.

**Options:**
- **A — record the evaluation, change nothing, file a follow-up (recommended).** The evaluation
  above goes on #52 with the alias record and in the changelog entry; I file "try `doctor` and
  `setup` on Haiku 5.5" through `/codeo:issue`, where it can be tried on real runs.
- **B — switch `doctor` and `setup` to `model: haiku` in this branch.** Two frontmatter lines and
  `docs/skills.md` if it names their model; no trial run backs it beyond the desk evaluation.
- **C — record the evaluation and stop.** No change, no follow-up issue.

**Answer:**
A — record the evaluation, change nothing, file a follow-up (answered in the conversation: accept
the recommendation).

### Q3 — Should the old model IDs in the tests outside `tests/fixtures/` move too?

**Why it matters:** criterion 2 covers only `docs/` and `tests/fixtures/`. Two tests use older IDs
as input data: `claude-opus-4-7` in `tests/usage.test.sh` (lines 50 and 55) and
`claude-haiku-4-5` in `tests/subagent-model.test.sh` (line 97). They pass as they are, since the
IDs are arbitrary strings to those tests. The answer adds or drops one small task.
**Options:**
- **A — update them (recommended):** `claude-opus-5-5` / `opus-5-5` and `claude-haiku-5-5`. Three
  lines, proved by the same suite, and no old model name is left anywhere a reader looks.
- **B — leave them.** They are outside the criterion and prove the same thing either way.

**Answer:**
A — update them (answered in the conversation: accept the recommendation).

### Q4 — #69 also changes `CHANGELOG.md`: proceed, sequence or re-scope?

**Why it matters:** this plan must add an entry under `## Unreleased` in `CHANGELOG.md`
(criterion 4). #69 (`feat/fix-closing-blocks-that-name`, assignee kbajpai, step `qc`) lists
`CHANGELOG.md` in its footprint and has changed it. Nothing else overlaps: #69 does not touch
`docs/dossier.md`, `tests/fixtures/**`, `tests/replay.test.sh`, `tests/usage.test.sh` or
`tests/subagent-model.test.sh`.
**Options:**
- **proceed and coordinate (recommended).** Both branches add one bullet under `## Unreleased`.
  Whichever merges second gets a small conflict in that list, which `/codeo:close` routes back
  for a one-line fix.
- **sequence after #69.** Wait for #69 to merge, then merge `main` in before the changelog task.
  #69 is already at `qc`, so the wait is likely short.
- **re-scope.** Not available: criterion 4 requires the changelog entry.

**Answer:**
#69 is already merged to main and done (answered in the conversation). Nothing to coordinate; the
changelog overlap that remains is #51's, Q5.

### Q5 — #51 also changes `CHANGELOG.md`: proceed, sequence or re-scope?

**Why it matters:** raised after Q4 was answered. #51 (`feat/seed-dev-container-git-identity`,
assignee kbajpai, step `plan`) has `CHANGELOG.md` in its footprint, as this plan does. Nothing else
overlaps. The answer decides whether the changelog task waits for #51.
**Options:** proceed and coordinate · sequence after #51 · re-scope (not available: criterion 4
requires the entry).

**Answer:**
Sequence after #51 (answered in the conversation). The changelog task goes last and waits for #51
to merge.

### Q6 — `#51` overlaps on `glob:CHANGELOG.md`: proceed, sequence or re-scope?

**Why it matters:** `overlap.sh` prints `51<TAB>glob:CHANGELOG.md` for the footprint as written, and drops a pair only when a question names both tokens verbatim. Q5 raised this same overlap in prose; this restates it in the form the script reads. It changes nothing in the plan.
**Options:** proceed and coordinate · sequence after #51 · re-scope (not available).

**Answer:**
Sequence after #51, as Q5 (answered in the conversation). The changelog task stays last and waits for #51 to merge.

## Notes

**Alias resolution, checked 2026-11-14 in Claude Code 2.1.325.** For each alias,
`claude -p --model <alias> --output-format json "Reply with the single word: ok"`, reading the
keys of `modelUsage`:

| Alias | Resolves to | Used by |
|---|---|---|
| `fable` | `claude-fable-5-2` | `plan` |
| `opus` | `claude-opus-5-5` | `issue`, `qc`, `models.reviewer` default |
| `sonnet` | `claude-sonnet-5-5` | `close`, `doctor`, `implement`, `init`, `setup`, `triage`, `models.subagent` default |
| `haiku` | `claude-haiku-5-5` | nothing |

Every run also lists `claude-haiku-5-5`, which Claude Code uses for its own background calls.
This session agrees: `/codeo:init` logged `sonnet-5-5` and this step runs on `fable-5-2`.

**How I read criterion 2.** "No `fable-5-1`, `sonnet-5` or `opus-5` remains" cannot mean the bare
substrings, because the replacements `sonnet-5-5` and `opus-5-5` contain them. The plan's check
is `grep -rnE 'fable-5-1|sonnet-5([^-]|$)|opus-5([^-]|$)' docs tests/fixtures` printing nothing.
The mapping is `fable-5-1` → `fable-5-2`, `sonnet-5` → `sonnet-5-5`, `opus-5` → `opus-5-5`.

**What moves with the fixtures.** `tests/replay.test.sh:188` deletes a cost string from a golden
fixture by exact match (`sonnet-5 40k in + 200k cached / 3k out`); it changes in the same task or
the "extra finding" case stops failing the way it must. The golden fixtures under
`tests/fixtures/golden/` are inside the criterion and move too.

**What stays.** `.codeo/done/**` holds real cost lines from past runs (`fable-5-1` in
`.codeo/done/47/plan.md` and four others). They are history, outside `docs/` and
`tests/fixtures/`, and stay as written. `scripts/usage.sh` reads model names from transcripts and
does not change. No skill frontmatter or default changes unless Q2 is answered B.

**Shape.** One plan under `docs/plans/`, one pull request. No reference doc: nothing here is a
standing decision. No invariants document, no shared environment and no wiki are configured. The
`shell` suite has no `filter`, so each task's proof is `bash tests/run.sh`.

**Other workflows in flight.** #69 was the only one at Q4 and has since merged; #51 (at `plan`)
shares `CHANGELOG.md`, which is Q5.

## Outcome

| | |
|---|---|
| Plan | `docs/plans/2026-11-14-latest-claude-models.md` (unstaged, for your review) |
| Shape | a plan under `docs/plans/`; no reference doc, since nothing here is a standing decision |

**Decisions.** The aliases `fable`, `opus` and `sonnet` already resolve to `claude-fable-5-2`, `claude-opus-5-5` and `claude-sonnet-5-5` in Claude Code 2.1.325, so no skill, hook or default changes (issue Q1). Old names move `fable-5-1` → `fable-5-2`, `sonnet-5` → `sonnet-5-5`, `opus-5` → `opus-5-5` in `docs/dossier.md`, `tests/fixtures/**` and `tests/replay.test.sh`; criterion 2 is read as the grep in the plan, since the new names contain the old. Q1: `/codeo:implement` posts the alias record as one comment on #52. Q2: the Haiku 5.5 evaluation is recorded, nothing switches (`doctor` and `setup` are the candidates), and the trial is filed as its own issue. Q3: three test-input IDs move too. Q4-Q6: #69 merged; the changelog task waits for #51.

**Options rejected.** Pinning model IDs (out of scope); switching `doctor` and `setup` to Haiku here (no trial run behind it); leaving the test-input IDs (outside the criterion but left a stale name); proceeding past #51 on `CHANGELOG.md` (the engineer chose to sequence).

**Documentation the plan changes.** `docs/dossier.md` (its example log line) only; no wiki. No other page names a model version.

**Intake questions resolved.** The Haiku question left open at intake (Q2 above).

### Footprint

```
files:      docs/dossier.md, tests/fixtures/**, tests/replay.test.sh, tests/usage.test.sh, tests/subagent-model.test.sh, CHANGELOG.md, docs/plans/2026-11-14-latest-claude-models.md
wiki:       none
exclusive:  none
sequenced:  after #51 — both add a CHANGELOG.md bullet under Unreleased (Q5)
```

## Log

- 2026-11-14 — Q1-Q4 raised · cost: 2m · fable-5-2 77k in + 257k cached / 5k out
- 2026-11-14 — Q1-Q5 answered, draft written for review (.codeo/52/plan-draft.md); engineering plugin unavailable, steps 6-7 skipped (no new component or technology choice) · cost: 29m · fable-5-2 83k in + 570k cached / 10k out · sonnet-5-5 92k in + 574k cached / 10k out
- 2026-11-14 — planned: docs/plans/2026-11-14-latest-claude-models.md; Q6 restated the #51 overlap for overlap.sh · cost: 30m · fable-5-2 83k in + 570k cached / 10k out · sonnet-5-5 95k in + 1.1M cached / 13k out
