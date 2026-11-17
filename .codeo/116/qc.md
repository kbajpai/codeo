# Issue #116 — qc

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/116 |
| Branch | `fix/follow-ups-70-71-104` |
| Updated | 2026-11-17 |

## Where this stands

Round 1 is written: back to `/codeo:plan`. The build and the `shell` suite pass, and 13 of 14 criteria are met or dropped, but criterion 3 is not met: four generic sentences still say "the skill is running in an issue container", which the plan never told `/codeo:implement` to change. Nothing is open.

## Questions

None.

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

## Log

- 2026-11-17 — qc round 1: build rc=0, `bash tests/run.sh` all cases passed, criterion 3 not met, back to /codeo:plan · cost: 4m · opus-5-5 284k in + 3M cached / 15k out · sonnet-5-5 189k in + 239k cached / 783 out
