# Issue #52 — qc

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/52 |
| Branch | `feat/run-codeo-latest-claude-models` |
| Updated | 2026-11-14 |

## Where this stands

Round 1 written: the change is clear and goes forward to `/codeo:close`. Nothing is open. Criterion 2 was settled by the engineer's answer to Q1.

## Questions

### Q1 — Does criterion 2 count the plan file under `docs/plans/`?

**Why it matters:** criterion 2 says no `fable-5-1`, `sonnet-5` or `opus-5` remains in `docs/` or `tests/fixtures/`. Read literally it fails on 7 lines of `docs/plans/2026-11-14-latest-claude-models.md`, which quotes the old names in its own grep and rename commands. Every example and fixture is clean. The answer decides between met (plans are records), not met and blocking (send back to `/codeo:plan` to reword the plan), and not met but non-blocking.
**Options:** met, plans are records · not met, blocking · not met, non-blocking.

**Answer:**
Met: plans are records (answered in the conversation). Criterion 2 is judged with `docs/plans/` excluded, and the literal mismatch is a non-blocking finding.

## Notes

`sync-main.sh --abort-on-conflict` printed `sync-main: the branch already contains origin/main`, exit 0. `sync-main.sh` exited 1 after a committed merge in two earlier `/codeo:implement` passes on a `comm` sort warning; it did not this time. Not filed: it is outside this diff.

## Outcome

### Round 1 — 2026-11-14

Head `20ca072`, merge base `5c7b0a1` (`origin/main`). `overlap.sh 52` and `overlap.sh --outside 52` printed nothing. The `qc` overlays `invariants-extra` and `wiki-rules` exit 3: none. No invariants document, no shared environment, no wiki are configured.

**Commands run and their output**

- `bash scripts/scope.sh origin/main HEAD` printed `suite.shell=true`, with `shell needed for unclassified paths`: `.codeo/52/*.md` and `CHANGELOG.md`. (`bash "$CLAUDE_PLUGIN_ROOT/scripts/scope.sh" origin/main HEAD`.)
- `git diff origin/main...HEAD --stat` ends `76 files changed, 469 insertions(+), 82 deletions(-)`. Outside `tests/fixtures/` the files are `.codeo/52/*.md`, `CHANGELOG.md`, `docs/dossier.md`, `docs/plans/2026-11-14-latest-claude-models.md`, `tests/replay.test.sh`, `tests/subagent-model.test.sh`, `tests/usage.test.sh`.
- Build: the `shell` suite's `build` is `true`; exit 0.
- Suite: `bash tests/run.sh` printed `all cases passed`, exit 0. The reviewer also ran `replay`, `usage` and `subagent-model` tests one by one: all three `all cases passed`.
- `grep -rnE 'fable-5-1|sonnet-5([^-]|$)|opus-5([^-]|$)' docs tests/fixtures` printed 7 lines, all in `docs/plans/2026-11-14-latest-claude-models.md` (lines 15, 17, 38, 42, 43, 44, 47). With `--exclude-dir=plans` it printed nothing, exit 1.
- `gh issue view 52 --json comments -q '.comments[].body' | grep -E '^\| `(fable|opus|sonnet)`'` printed the three rows `fable` → `claude-fable-5-2`, `opus` → `claude-opus-5-5`, `sonnet` → `claude-sonnet-5-5`.
- `sed -n '/^## Unreleased/,/^## v1/p' CHANGELOG.md | grep -n '#52'` printed the one bullet (line 8 of the section).

**Criteria**

| Criterion | Verdict | Settled by |
|---|---|---|
| The issue records which model each alias resolves to, for `fable`, `opus` and `sonnet` | met | the comment https://github.com/kbajpai/codeo/issues/52#issuecomment-6882746316: the Claude Code version (2.1.325), the command, and the three rows above |
| No `fable-5-1`, `sonnet-5` or `opus-5` remains in `docs/` or `tests/fixtures/` | met — with `docs/plans/` excluded, per Q1; the literal grep still prints the plan's 7 lines (finding F1) | the two `grep` runs above |
| `bash tests/run.sh` passes | met | `all cases passed`, exit 0, this round |
| `CHANGELOG.md` records the change | met | the `#52` bullet under `## Unreleased`, after #51's |

**Documentation check.** The plan names one page, `docs/dossier.md`, and the diff changes its example log line (`fable-5-1`/`sonnet-5` → `fable-5-2`/`sonnet-5-5`); the page still describes the same format. The plan's claim that no other page names a model version holds: `docs/skills.md` says "the strongest model available" and names none. No diagram applies.

**Findings.** The reviewer's verdict, quoted in plain text: "Ready to merge? With fixes", on one Critical finding, which Q1 settles. I found none of my own.

- F1 (non-blocking) — the plan file `docs/plans/2026-11-14-latest-claude-models.md` spells the old names in its grep and rename commands, so the literal check of criterion 2 prints 7 lines. The reviewer graded it Critical and offered two fixes: reword the plan, or have the engineer agree `docs/plans/` is out of scope. The engineer chose the second at Q1, so it is non-blocking. Whose: `/codeo:plan`'s (the plan quotes its own commands), wording only.
- F2 (non-blocking) — `CHANGELOG.md` says "the two tests that use model IDs as input" and leaves out `tests/replay.test.sh`'s `sed`, which changed to keep matching the renamed fixture. True but incomplete. Whose: `/codeo:implement`'s, one clause.
- F3 (non-blocking) — Task 3's proof command in the plan combines `--comments` with `--json`, which `gh` refuses. `implement.md` records the working command. Whose: `/codeo:plan`'s; the plan is history.
- The reviewer's note that the plan's "82 lines in 70 files" is wrong is not a finding: the dry run included Task 2's two test files, so 79 + 3 lines and 68 + 2 files is the figure the plan states.

None sends the change back on its own. They are recorded, not fixed, and no further round is opened for them.

**Evidence not reproduced here.** The reviewer did not re-run `claude -p` per alias; this pass read the posted record and the skills' `model:` lines (`fable` in `plan`; `opus` in `issue`, `qc`; `sonnet` in the rest), which match the comment's "Used by" column. The alias resolution itself was run twice by `/codeo:plan` and `/codeo:implement` (Claude Code 2.1.325).

**Issues filed:** none. #76 (the Haiku trial) was filed by `/codeo:implement`.

**Verdict: clear — forward to `/codeo:close`.**

## Log

- 2026-11-14 — qc round 1: clear, 3 non-blocking findings, Q1 answered in the conversation · opus reviewer · no shared environment · cost: 4m · opus-5-5 255k in + 1.9M cached / 11k out · sonnet-5-5 28k in + 620k cached / 777 out
