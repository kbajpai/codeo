# Issue #107 — qc

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/107 |
| Branch | `feat/dev-container-follow-ups-96` |
| Updated | 2026-11-16 |

## Where this stands

Round 1 is written and the verdict is clear: forward to `/codeo:close`. Q1 (the #104 overlap on `CHANGELOG.md`) is answered, proceed and coordinate. The build and the whole `shell` suite pass on the merged tree, every criterion but one is met (criterion 8 is half met, by plan Q2), and three non-blocking findings are recorded. No shared environment is configured, so there is no environment block and no lease to release.

## Questions

### Q1 — #104 overlaps this branch on `CHANGELOG.md` and `glob:CHANGELOG.md`: proceed, sequence or re-scope?

`overlap.sh 107` printed `104	CHANGELOG.md` and `104	glob:CHANGELOG.md`. #104 is on branch `feat/publish-live-session-signal-so`, assignee kbajpai, at step `implement` (working); its footprint and its branch both change `CHANGELOG.md`, and nothing else of it overlaps this branch (its other files are under `scripts/`, `hooks/`, `skills/`, `docs/` and `tests/` other than this branch's two test files). This branch changes `CHANGELOG.md` by rewording the #96 bullet and appending one #107 bullet under `## Unreleased`; #70 and #71 already merged their CHANGELOG bullets into this branch without a conflict.

**Why it matters:** *proceed and coordinate* lets this pass go on to its verdict; whichever of #104 and #107 merges second keeps both bullets. *Sequence after #104* holds this issue until #104 merges, then a new pass re-checks the merged CHANGELOG. *Re-scope* would drop the CHANGELOG change, which criterion 10 requires.
**Options:** proceed and coordinate (recommended: two different bullets, as with #70 and #71) · sequence after #104 · re-scope.

**Answer:**
Proceed and coordinate (given in the conversation: "Proceed & Coordinate").

## Notes

Step 2 output so far, quoted:

```
sync-main: merged origin/main (1 commit(s))
sync-main: also changed on main: CHANGELOG.md
104	CHANGELOG.md
104	glob:CHANGELOG.md
```

`sync-main.sh` ran under `LC_ALL=C`: the plugin copy in use (v1.0.6) still has the locale bug #98 fixed in the repository's own script, which made the same merge exit 1 in `/codeo:implement`.

## Outcome

### Round 1 — 2026-11-16

**Scope.** `sync-main.sh --abort-on-conflict` (run under `LC_ALL=C`: the v1.0.6 plugin copy has the #98 locale bug) merged `origin/main` (738aaa4, #110 / #71) cleanly as 99ae574 and printed `sync-main: also changed on main: CHANGELOG.md`; this branch's own CHANGELOG edits were made on top of main's earlier merges and the merge had no conflict. A second run said `the branch already contains origin/main`. `overlap.sh 107` printed `104 CHANGELOG.md` and `104 glob:CHANGELOG.md` (raised as Q1, answered proceed and coordinate), then nothing. `overlap.sh --outside 107` printed nothing: no file outside the footprint. `git diff origin/main...HEAD --stat`: 11 files, 718 insertions, 42 deletions (the dossiers, the plan, `.devcontainer/README.md`, `codeo-root.sh`, `devcontainer-start.sh`, `CHANGELOG.md`, `tests/codeo-root.test.sh`, `tests/devcontainer.test.sh`; nothing under `scripts/`, `lib/`, `hooks/` or `skills/`). `scope.sh origin/main HEAD`:

```
scope: suite shell needed for unclassified paths:
  .codeo/107/implement.md
  .codeo/107/init.md
  .codeo/107/issue.md
  .codeo/107/plan.md
  CHANGELOG.md
suite.shell=true
```

**Build.** The `shell` suite's `build` is `true`: exit 0.

**Suite.** `bash tests/run.sh` from the project root: `all cases passed`, exit 0 (3m27s). `bash tests/devcontainer.test.sh` run on its own: one output line, `all cases passed`, `Terminated` count 0. `bash tests/codeo-root.test.sh`: `all cases passed`.

**Mutations, each in a scratch copy of the tree** (`cp -a`, edit in the copy, run the test file; the checkout was never changed):

| Mutation | Result |
|---|---|
| `## Unreleased` retitled `## v9.9.9` | `all cases passed`, no FAIL |
| `tests/replay.test.sh` renamed in the `(#52)` bullet | `FAIL docs_changelog_names_the_replay_sed_and_the_folder_limit: the #52 bullet does not name tests/replay.test.sh` |
| bind-mount TODO claims trust unconditionally | `FAIL start_bind_mount_todo_does_not_claim_trust_when_the_add_failed` |
| the effective-`core.fileMode` readback disabled | `FAIL start_does_not_claim_an_override_the_scope_outranks` (param, count and worktree, five assertions each) |
| `mktemp … 2>/dev/null` as before | `FAIL start_mode_listing_todo_carries_the_reason_when_mktemp_fails` |
| old trap `rm -f -- "${modes_list:-}"` | `FAIL start_trap_never_runs_rm_with_an_empty_operand: rm ran with an empty operand` |
| lock-crash TODO prints the output twice (F5) | `FAIL start_lock_crash_is_a_todo: boom does not appear exactly once on stderr: … boom boom` |
| `cd "$HOME" &&` dropped before `claude auth status` (F10) | `FAIL start_runs_claude_outside_the_clone: claude left a file in the clone` (and two more) |
| `.settings.leak` written before `title=$(bash` (F6) | `FAIL title_reports_a_failing_container_name_as_one_line: the failure left something in .vscode: .settings.leak` |
| settle check dropped from the identity wait (F14) | `FAIL start_waits_for_a_host_gitconfig_that_is_still_growing: user.email is not the host's` |
| `codeo-root.sh` back to `@tsv` (F7) | `FAIL registry_matches_a_project_path_with_a_backslash: wanted …/mine, got …/user` |

**Criteria** (`init.md`'s ten, verbatim order):

| # | Criterion | Verdict | Settled by |
|---|---|---|---|
| 1 | Retitled `## Unreleased` still passes `docs_changelog_names_the_replay_sed_and_the_folder_limit`; with `tests/replay.test.sh` removed from the `(#52)` bullet it fails | met | `tests/devcontainer.test.sh` (the case, whole-file greps); the first two mutations above |
| 2 | A test sees no "already told to trust the clone" when the `safe.directory` add fails | met | `start_bind_mount_todo_does_not_claim_trust_when_the_add_failed`; `devcontainer-start.sh:41-49`; the trust mutation |
| 3 | `core.fileMode=false` from `GIT_CONFIG_COUNT`/`GIT_CONFIG_PARAMETERS` gives no "overrode" claim; set globally the message is unchanged | met | `start_does_not_claim_an_override_the_scope_outranks` (param, count, worktree); `start_names_a_file_mode_overridden_from_a_wider_scope` unchanged and passing; the readback mutation |
| 4 | A test makes `mktemp` fail and sees the reason in the "could not be listed" TODO | met | `start_mode_listing_todo_carries_the_reason_when_mktemp_fails`; the `2>/dev/null` mutation |
| 5 | `codeo-root.sh` with a backslash `projectPath`, and an empty or `false` one: this clone's entry taken or skipped as documented, no other project's taken | met | `registry_matches_a_project_path_with_a_backslash`, `registry_treats_an_empty_project_path_as_none`, `registry_treats_a_false_project_path_as_none` (the last two put another project's entry first); the `@tsv` mutation |
| 6 | F5, F6, F10 fail when the behaviour they guard breaks (mutation in a scratch copy); no `Terminated` line | met | the F5, F10 and F6 mutations above; `Terminated` count 0 (F6 can fail only for a reordering of the temp file, see F3) |
| 7 | 20 runs under `nice`, or the timing dependence gone by construction (F14) | met | by construction: the stub `stat` appends one piece per settle-stamp read, the wait loop counts ticks, the case asserts `grow-n == 8`; the settle-check mutation fails it. The 20 runs were not done |
| 8 | `rm -f -- ""` checked on the image's coreutils and recorded on the issue; the trap does not run it when no temp file exists | not met in its first half — decided in plan Q2; second half met | the trap `[[ -z ${modes_list:-} ]] \|\| rm -f -- "$modes_list"` and `start_trap_never_runs_rm_with_an_empty_operand` (old-trap mutation fails it). The issue comment (https://github.com/kbajpai/codeo/issues/107#issuecomment-6904097075) records that `/usr/bin/rm` is `gnurm`, GNU coreutils 9.7, and that the literal command was not run: this environment's safety check refuses an empty `rm` operand, and neither the implementer nor the reviewer could run it |
| 9 | The CHANGELOG bullet and the test header say what F11 and F12 name | met | `CHANGELOG.md` #96 bullet (opens `follow-ups to #36, #47, #50, #51, #52, #55, #57, #75 and #87`, names `docs/release-checklist.md` step 8, reads `start_trusts_the_clone_once` as pinning existing behaviour); `tests/devcontainer.test.sh` header names `codeo-gh` and `codeo-git` |
| 10 | `bash tests/run.sh` passes and `CHANGELOG.md` records the change | met | `bash tests/run.sh`: `all cases passed`; `CHANGELOG.md` line 20, the #107 bullet |

**Documentation.** The pages the plan names are `.devcontainer/README.md` and `CHANGELOG.md`; both are changed, nothing else describes the dev container. The README's `core.fileMode` bullet says what the code does (one TODO naming the scope, no `ready`), in the present tense, without issue numbers or "now". The #96 and #107 CHANGELOG bullets were checked claim by claim against the scripts, the tests and `docs/release-checklist.md` step 8 (its `--notes-file`, never `--generate-notes`, `gh release edit` text); one claim overstates (F2). No diagram is involved. No wiki module.

**Independent review** (`opus`, given the acceptance criteria and the diff of `.devcontainer/`, `tests/`, `CHANGELOG.md` and `README.md` only, with `.codeo/` and `docs/plans/` excluded): no Critical, no Important, three Minor, which are F1-F3 below; its own verdict was "With fixes", with nothing blocking the merge.

**Findings.**
- **F1 — non-blocking, the engineer's.** Criterion 8's "checked" half is recorded as not done (see the table). The reviewer's own attempt was refused the same way. Fix: run `rm -f -- ""; echo "rc=$?"` in a container terminal and add the output to #107, or amend the criterion.
- **F2 — non-blocking, `/codeo:implement`'s.** `CHANGELOG.md` line 20, the #107 bullet, says `codeo-root.sh` now "treats an empty or `false` one as none (F7)". The old filter `(.projectPath // "")` already did (`git show 738aaa4:.devcontainer/scripts/codeo-root.sh`, line 34); only the backslash handling changed, and the two new cases pin the rest. The bullet reads as a behaviour change. Fix: say the cases pin it.
- **F3 — non-blocking, plan's.** `title_reports_a_failing_container_name_as_one_line` guards less than its wording suggests: `window-title.sh` dies at line 25, before the `.settings.XXXXXX` temp file is created at line 59, so the assertion only catches a reordering (as the F6 mutation shows). The task asked for an assertion that can fail, and it can.

Carried over, unchanged and not findings: the new `start_trap_never_runs_rm_with_an_empty_operand` would pass if its stub `rm` were never reached (it fails against the old trap, as shown), and `mktemp … 2>&1` would fold a warning printed on success into the file name (neither GNU nor uutils `mktemp` warns on success). No issue was filed by this pass.

**Verdict: clear — forward to `/codeo:close`.**

## Log

- 2026-11-16 — round 1 stopped at step 2: Q1 raised (#104 overlaps on CHANGELOG.md) · cost: 0m · opus-5-5 304k in + 354k cached / 1k out
- 2026-11-16 — round 1: clear, forward to /codeo:close (no blocking finding; F1 is the engineer's); no issue filed · cost: 12m · opus-5-5 374k in + 2M cached / 20k out · sonnet-5-5 46k in + 5.5M cached / 19k out
