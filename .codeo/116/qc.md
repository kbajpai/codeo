# Issue #116 — qc

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/116 |
| Branch | `fix/follow-ups-70-71-104` |
| Updated | 2026-11-17 |

## Where this stands

Round 2 is written: clear, forward to `/codeo:close`. The build and the `shell` suite pass, 13 of 14 criteria are met and criterion 13 was dropped by the engineer (plan Q4). F1-F6 are fixed; five non-blocking findings (F7-F11) are recorded. Nothing is open.

## Questions

### Q1 — #103 (`feat/let-codeo-triage-judge-flight`, kbajpai, step implement) overlaps on `glob:CHANGELOG.md`, `glob:docs/handoff.md` and `glob:docs/skills.md`

**Why it matters:** `overlap.sh 116` prints these three tokens because #103's footprint globs cover files this branch changes. It is the same overlap `.codeo/116/implement.md` Q1 raised by path; only the token form differs, so the script did not recognise it as raised.
**Options:** proceed and coordinate · sequence after #103 · re-scope.

**Answer:**
Proceed and coordinate — carried from `.codeo/116/implement.md` Q1 (engineer, in the conversation, 2026-11-17: "Proceed & Coordinate"), which answered the same overlap by path.

### Q2 — #99 (`feat/make-sbx-issue-sandbox-usable`, kbajpai, step plan) overlaps on `glob:.devcontainer/README.md`, `glob:CHANGELOG.md` and `glob:tests/devcontainer.test.sh`

**Why it matters:** as Q1, the same overlap `.codeo/116/implement.md` Q2 raised by path, printed here in its glob form.
**Options:** proceed and coordinate · sequence after #99 · re-scope.

**Answer:**
Proceed and coordinate — carried from `.codeo/116/implement.md` Q2 (engineer, in the conversation, 2026-11-17: "Proceed & Coordinate").

## Outcome

### Round 1 — 2026-11-17

**Round start.** `sync-main.sh --abort-on-conflict`: "the branch already contains origin/main" (exit 0), so no `also changed on` lines. `overlap.sh 116` and `overlap.sh --outside 116` printed nothing. Head under review: 9a22444.

**Scope.** `scope.sh origin/main HEAD` printed `suite.shell=true` (the paths without a classification: `.codeo/116/*` and `CHANGELOG.md`). No environment is configured, so there is no `deploy=` line and no environment step. 34 files changed, 730 insertions, 66 deletions.

**Build.** The `shell` suite's `build` is `true`; it exited 0.

**Suite.** `bash tests/run.sh`: `all cases passed`, exit 0, no `FAIL` line.

| # | Criterion | Verdict | Settled by |
|---|---|---|---|
| 1 | Under `/run/.containerenv`, `role.sh` reports the role as for `/.dockerenv` | met | `tests/role.test.sh` `containerenv_alone_is_guarded`, `both_markers_are_guarded_the_same`; `.devcontainer/scripts/role.sh:56-57` |
| 2 | `CODEO_CLEANUP_REMOVAL` exported outside tests changes nothing | met | `scripts/cleanup.sh` no longer reads it; `tests/cleanup.test.sh` `an_exported_removal_override_changes_nothing` |
| 3 | The cleanup skill description, `docs/skills.md` and the plan/implement/qc/handoff sentence carry no project-specific container claim in generic text | not met — the cleanup description, `docs/skills.md` and the "home container" closing clause are fixed, but the plan/implement/qc/handoff sentence still opens "(the skill is running in an issue container)" at `skills/plan/SKILL.md:113`, `skills/implement/SKILL.md:17`, `skills/qc/SKILL.md:513` and `docs/handoff.md:379` | grep of those four lines; see F1 |
| 4 | `live.sh` accepts one lock-issue pattern in `read_lock` and `list`; a test pins it | met | `scripts/live.sh:120`; `tests/live.test.sh` `beat_publishes_nothing_for_a_lock_issue_list_would_drop` |
| 5 | `github.sh ref delete` counts only `Reference does not exist` as deleted | met | `scripts/github.sh:278`; `tests/github.test.sh` `ref_delete_of_a_refused_write_is_a_failure` |
| 6 | `CODEO_LIVE_PUSH_TIMEOUT` documentation matches what `live.sh` bounds | met | `scripts/live.sh:54-55`, `:110`, `:155`; `CHANGELOG.md`; `docs/handoff.md` |
| 7 | A stashed or abandoned workflow's `live:` line clears | met | `skills/close/SKILL.md` step 16, stash and abandon paths; `tests/close-skill.test.sh` |
| 8 | The docs name `CODEO_MACHINE` for the same-volume-name collision | met | `docs/handoff.md` live-signal bullet; `tests/live-signal.test.sh` `docs_state_the_live_signal_limits` |
| 9 | `board.sh` with no Backlog option names `board.statuses.backlog` | met | `scripts/board.sh:291-295`; `tests/board.test.sh` |
| 10 | `skills/issue/SKILL.md` describes `set`'s one-line-per-project output | met | `skills/issue/SKILL.md`; `tests/issue-skill.test.sh` |
| 11 | `CHANGELOG.md` states the `issue:<N>` fingerprint change and corrects the #107 bullet | met | the three edited bullets under `## Unreleased` |
| 12 | `title_reports_a_failing_container_name_as_one_line` can fail for the behaviour it names | met | `tests/devcontainer.test.sh`: the case's stderr equality fails with the join replaced by `cat` (mutation recorded in `implement.md` and checked by the reviewer) |
| 13 | The `rm -f -- ""` check output is recorded on #107 | untestable — dropped by the engineer at `plan.md` Q4; no task posts to #107; the output (`rc=0`) is in `plan.md` | `.codeo/116/plan.md` |
| 14 | `bash tests/run.sh` passes and `CHANGELOG.md` records the change | met | the suite run above; the #116 bullet under `## Unreleased` |

**Documentation.** The pages the plan named were all changed: `docs/skills.md` (cleanup, close), `docs/handoff.md` (live-signal bullet and diagram, issue-filing sentence), `.devcontainer/README.md`, `CHANGELOG.md`. No added text carries an issue number or "now". Defects are F1, F2, F3 and F4 below. No wiki module; no `wiki-rules` overlay; no `invariants-extra` overlay; no invariants file.

**Independent review** (opus, given the criteria and the diff only): "With fixes". The script changes are correct and each new test fails without its change; the findings below are its Important and Minor items, each checked against the code.

**Findings**

- **F1 — blocking — `/codeo:plan`'s.** Criterion 3 is not met. `skills/plan/SKILL.md:113`, `skills/implement/SKILL.md:17`, `skills/qc/SKILL.md:513` and `docs/handoff.md:379` still say "the project's role check refuses the call (the skill is running in an issue container)". "Issue container" is this project's layout, not a codeo concept. The code does what Task 3 said ("the closing clause becomes …"); the plan changed only the clause and never the parenthetical, and its `must_lack` pin checks only `in the home container`. Fix in the plan: Task 3 drops or generalises the parenthetical in all four places and adds a `must_lack 'issue container'` case to the plan, implement and qc skill tests and the handoff check.
- **F2 — non-blocking — `/codeo:plan`'s.** `docs/handoff.md` sequence diagram draws `S->>H: /codeo:close deletes the lock` then `H->>O: clear in the same command`, but `/codeo:close` runs `live.sh clear` itself in its Bash command; it does not go through `hooks/live-signal.sh`. Task 9 prescribed those two lines. It should read `S->>O: live.sh clear; rm -f .codeo/active (one command)`.
- **F3 — non-blocking — `/codeo:plan`'s.** Toolbox and distrobox containers also create `/run/.containerenv`, so a checkout named `codeo-<digits>` inside one is now guarded; `.devcontainer/README.md:49` still says a plain local checkout is `unguarded`. Rare; the README could name it.
- **F4 — non-blocking — `/codeo:plan`'s.** The #70 bullet at `CHANGELOG.md:16` still says the guard applies when "`/.dockerenv` exists", in the same section as the #116 bullet that adds `/run/.containerenv`.
- **F5 — non-blocking — `/codeo:implement`'s.** `tests/cleanup.test.sh` `an_exported_removal_override_changes_nothing`: the with-overlay half compares to `$plain` without asserting that `$plain` is the `docker rm -f codeo-12` line, so a broken overlay load giving the same output twice would pass.
- **F6 — non-blocking — `/codeo:implement`'s.** `tests/close-skill.test.sh`: the stash and abandon pins depend on where `skills/close/SKILL.md` wraps its lines.
- **Dropped, not a finding:** criterion 13, by the engineer's decision at plan Q4.

No issue was filed from this pass.

**Verdict: back to `/codeo:plan`.**

### Round 2 — 2026-11-17

(after implement.md round 2, which answered round 1)

**Round start.** `sync-main.sh --abort-on-conflict`: "the branch already contains origin/main" (exit 0), so no `also changed on` lines. `overlap.sh 116` printed the `glob:` forms of the overlaps `implement.md` Q1 (#103) and Q2 (#99) had raised by path; they are Q1 and Q2 above, answered as there. `overlap.sh --outside 116` printed nothing. Head under review: edc3ca8; merge base with `origin/main`: 6699326.

**Scope.** `scope.sh origin/main HEAD` printed `suite.shell=true` (paths without a classification: `.codeo/116/*` and `CHANGELOG.md`). No environment is configured, so there is no `deploy=` line and no environment step. 36 files changed, 951 insertions, 71 deletions.

**Build.** The `shell` suite's `build` is `true`; it exited 0.

**Suite.** `bash tests/run.sh`: `all cases passed`, exit 0, no `FAIL` line.

| # | Criterion | Verdict | Settled by |
|---|---|---|---|
| 1 | Under `/run/.containerenv`, `role.sh` reports the role as for `/.dockerenv` | met | `tests/role.test.sh` `containerenv_alone_is_guarded`; `.devcontainer/scripts/role.sh:56-57`; the README names the limit for toolbox and distrobox |
| 2 | `CODEO_CLEANUP_REMOVAL` exported outside tests changes nothing | met | `scripts/cleanup.sh` no longer reads it; `tests/cleanup.test.sh` `an_exported_removal_override_changes_nothing`, which now also asserts the `docker rm -f codeo-12` line before the export |
| 3 | The cleanup skill description, `docs/skills.md` and the plan/implement/qc/handoff sentence carry no project-specific container claim in generic text | met | `grep -rn 'issue container' skills/ docs/handoff.md docs/skills.md` prints nothing (rc 1); `tests/plan-skill.test.sh`, `tests/implement-skill.test.sh`, `tests/qc-skill.test.sh` pin it |
| 4 | `live.sh` accepts one lock-issue pattern in `read_lock` and `list`; a test pins it | met | `tests/live.test.sh` `beat_publishes_nothing_for_a_lock_issue_list_would_drop` (reviewer reverted the regex: it fails for 0, 0104 and 1234567890) |
| 5 | `github.sh ref delete` counts only `Reference does not exist` as deleted | met | `scripts/github.sh`; `tests/github.test.sh` `ref_delete_of_a_refused_write_is_a_failure` (fails against the old match) |
| 6 | `CODEO_LIVE_PUSH_TIMEOUT` documentation matches what `live.sh` bounds | met | `scripts/live.sh:54-55`, `docs/handoff.md:173`, `CHANGELOG.md`; see F8 for one incomplete parenthetical |
| 7 | A stashed or abandoned workflow's `live:` line clears | met | `skills/close/SKILL.md` step 16, stash and abandon paths; `tests/close-skill.test.sh` lines 321-322 |
| 8 | The docs name `CODEO_MACHINE` for the same-volume-name collision | met | `docs/handoff.md:173`; `tests/live-signal.test.sh` `docs_state_the_live_signal_limits` |
| 9 | `board.sh` with no Backlog option names `board.statuses.backlog` | met | `scripts/board.sh`; `tests/board.test.sh` (fails without the hint) |
| 10 | `skills/issue/SKILL.md` describes `set`'s one-line-per-project output | met | `skills/issue/SKILL.md`; `tests/issue-skill.test.sh` |
| 11 | `CHANGELOG.md` states the `issue:<N>` fingerprint change and corrects the #107 bullet | met | the edited bullets under `## Unreleased` |
| 12 | `title_reports_a_failing_container_name_as_one_line` can fail for the behaviour it names | met | `tests/devcontainer.test.sh`; reviewer removed the ` / ` join at `window-title.sh:25` and the case failed |
| 13 | The `rm -f -- ""` check output is recorded on #107 | untestable — dropped by the engineer at `plan.md` Q4; no task posts to #107 | `.codeo/116/plan.md`; see F7 |
| 14 | `bash tests/run.sh` passes and `CHANGELOG.md` records the change | met | the suite run above; the #116 bullet under `## Unreleased` |

**Documentation.** The round 1 documentation defects are gone: the diagram at `docs/handoff.md:190` reads `S->>O: /codeo:close runs live.sh clear and deletes the lock in one command` and the two old lines are absent; `.devcontainer/README.md:105` names toolbox and distrobox; the #70 bullet names `/run/.containerenv`. None of the added documentation text carries an issue number outside the CHANGELOG, nor "now" or "no longer". No wiki module and no diagram-render rule is configured; the one changed diagram is a Mermaid `sequenceDiagram` of the same shape as before.

**Independent review** (opus, given the criteria and the diff only): "With fixes". Strengths: every new test fails without the change it guards, each reverted in turn by the reviewer, and the suite passes in a clean worktree. Its Important item is criterion 13 (F7 below); its Minor items are F8-F10.

**Findings**

- **F1 (blocking in round 1) — fixed by 3a6b414.** Criterion 3: the four "(the skill is running in an issue container)" sentences are gone.
- **F2 — fixed by c0357d0.** The diagram draws `/codeo:close` running `live.sh clear` itself.
- **F3 — fixed by c0357d0.** The README names toolbox and distrobox.
- **F4 — fixed by c0357d0.** The #70 bullet names `/run/.containerenv`.
- **F5 — fixed by d6c708e.** The cleanup case asserts the printed removal line.
- **F6 — fixed by d6c708e.** The stash and abandon pins flatten the section, so a re-wrap cannot fail them.
- **F7 — non-blocking — the engineer's.** Criterion 13 stays unchecked on GitHub. The engineer dropped it at plan Q4 with the output (`rc=0`) already in `plan.md`, so no code or plan defect remains. Before `/codeo:close` the engineer can post that output on #107 or strike the criterion in #116's text, so the issue does not close with a criterion nothing explains. This skill edits neither.
- **F8 — non-blocking — `/codeo:implement`'s.** `scripts/live.sh:54-55` says the timeout bounds the REST fallback "(`github.sh ref put`, all its calls together)"; `clear`'s `github.sh ref delete` is bounded the same way. `docs/handoff.md:173` and the CHANGELOG say "the REST fallback as a whole" and are right.
- **F9 — non-blocking — `/codeo:plan`'s.** The 20-second `SessionEnd` timeout is justified as the two bounds of a `clear` (`hooks/hooks.json:43`, `scripts/live.sh:47-48`, `docs/handoff.md`), which is 2 × 8 seconds at the default `CODEO_LIVE_PUSH_TIMEOUT`; with it set above 10, the hook can end `clear` during the REST delete. The docs do not say the figure assumes the default.
- **F10 — non-blocking — `/codeo:implement`'s.** `tests/role.test.sh:221-225` `both_markers_are_guarded_the_same` creates `/.dockerenv` as well, so it passes with or without the `/run/.containerenv` check; its name suggests more. `containerenv_alone_is_guarded` is the case that pins the change.
- **F11 — non-blocking — `/codeo:implement`'s.** `tests/close-skill.test.sh:321-322` still search the whole stash-and-abandon section, so one pin could in principle be met by the other's paragraph; the two needles differ in their lead-in, so neither is today. Recorded by `implement.md`; nothing sends this back.

No issue was filed from this pass. All of F7-F11 are non-blocking and are for `/codeo:triage` or the engineer; none reopens a round.

**Verdict: clear — forward to `/codeo:close`.**

## Log

- 2026-11-17 — qc round 1: build rc=0, `bash tests/run.sh` all cases passed, criterion 3 not met, back to /codeo:plan · cost: 4m · opus-5-5 284k in + 3M cached / 15k out · sonnet-5-5 189k in + 239k cached / 783 out
- 2026-11-17 — qc round 2: clear, forward to /codeo:close; build rc=0, suite all cases passed; F1-F6 fixed, F7-F11 non-blocking · cost: 8m · opus-5-5 277k in + 4.2M cached / 20k out · sonnet-5-5 170k in + 1M cached / 5k out
