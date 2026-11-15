# Issue #96 — qc

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/96 |
| Branch | `feat/dev-container-follow-ups-40` |
| Updated | 2026-11-15 |

## Where this stands

Round 1 written: the build and the suite pass, 27 of 30 criteria are met, and the verdict is back to `/codeo:implement` for two blocking findings (F1: the half-written `~/.gitconfig` is untested; F2: a missing git top level lets later steps run in the caller's directory, and its test does so). Q1-Q3 are answered. The engineer's `gh release edit` (F9) is still pending.

## Questions

### Q1 — #70 and this branch: `tests/env.test.sh`

**Why it matters:** #70 (`feat/guard-home-only-skills-against`, assignee kbajpai, step `qc (working)`) lists `tests/**` in its footprint, which covers `tests/env.test.sh`; this branch adds one case to that file (`env_key_reference_lists_plugin`). #70's branch has not changed the file, so today there is nothing to merge. The answer decides whether this pass goes on, or this branch waits for #70 to merge first.
**Options:** proceed and coordinate (my pick: no change on #70's side, so no conflict) · sequence after #70 · re-scope.

**Answer:**
Proceed and coordinate, accepted in chat (2026-11-15).

### Q2 — #71 and this branch: `CHANGELOG.md` (`glob:CHANGELOG.md`)

**Why it matters:** #71 (`feat/file-new-issues-straight-board`, assignee kbajpai, step `plan (working)`) changes `CHANGELOG.md`; a trial merge conflicts there because both branches append a bullet to `## Unreleased`. The resolution is keeping both bullets, done by whichever branch merges second. The answer decides whether this pass goes on, or waits for #71.
**Options:** proceed and coordinate (my pick: keep both bullets at merge time) · sequence after #71 · re-scope.

**Answer:**
Proceed and coordinate, accepted in chat (2026-11-15).

### Q3 — #97 and this branch: `CHANGELOG.md`, `lib/env.sh` (`glob:CHANGELOG.md`, `glob:lib/env.sh`)

**Why it matters:** #97 (`docs/docs-skill-wording-test-guard`, assignee kbajpai, step `implement (working)`) changes both files. `lib/env.sh` merges cleanly (different lines of the key reference); `CHANGELOG.md` conflicts the same way as Q2 (both bullets kept). The answer decides whether this pass goes on, or waits for #97.
**Options:** proceed and coordinate (my pick: `lib/env.sh` is clean, `CHANGELOG.md` keeps both bullets) · sequence after #97 · re-scope.

**Answer:**
Proceed and coordinate, accepted in chat (2026-11-15).

## Notes

## Outcome

### Round 1 — 2026-11-15

Head under review: `d7100fa` (branch `feat/dev-container-follow-ups-40`), merge base `cf249c9` (`origin/main`). Q1-Q3 (overlaps with #70, #71, #97) were answered *proceed and coordinate* and are recorded above.

**Sync and scope.** `sync-main.sh --abort-on-conflict`: `sync-main: the branch already contains origin/main`. `overlap.sh 96` after the answers: nothing. `overlap.sh --outside 96`: nothing (every changed path is inside the footprint). `scope.sh origin/main HEAD`:

```
scope: suite shell needed for unclassified paths:
  .codeo/96/implement.md
  .codeo/96/init.md
  .codeo/96/plan.md
  .codeo/96/qc.md
  .codeo/96/release-v1.0.6-notes.md
  CHANGELOG.md
suite.shell=true
```

No environment is configured, so there is no `deploy=` line and no environment step. No invariants file and no `invariants-extra` / `wiki-rules` overlay (`overlay.sh` exit 3 for both).

**Build.** Suite `shell`, build `true`: exit 0.

**Tests.** Suite `shell`, `bash tests/run.sh`: `all cases passed` (3m21s). `bash tests/devcontainer.test.sh` run again on its own: `all cases passed`, no `SKIP` line (uid 1000, so the mode-000 cases ran).

**Mutation runs** (throwaway copies of `HEAD` under the scratchpad, deleted afterwards; nothing in the checkout changed):
- `if rm -f .codeo/active; then` → `if true; then` (criterion 21): `FAIL start_empty_lock_file_is_removed_and_the_lock_taken: lock line not printed …`, `… no lock written`, and the other removal cases (`start_empty_lock_file_on_the_base_branch_is_removed`, `…_on_a_detached_head_is_removed_and_reported`, `…_that_cannot_be_removed_is_one_todo`) fail too. Unmutated they pass.
- `&& $now == "$stamp"` removed from the identity wait's break condition (devcontainer-start.sh:313): `bash tests/devcontainer.test.sh` → `all cases passed`. See F1.

**Criteria.**

| # | Criterion | Verdict | Settled by |
|---|---|---|---|
| 1 | A test changes `plugin.repo` with an unchanged ref and sees codeo replaced. | met | `plugins_repo_change_reinstalls_codeo`, `plugins_record_without_a_repo_is_not_reinstalled` (tests/devcontainer.test.sh) |
| 2 | Two runs of the start script leave one `safe.directory` entry. | met | `start_trusts_the_clone_once` (pins "already met") |
| 3 | `git status` is clean after the start script's `claude` calls, which run from `$HOME`. | met | `start_runs_claude_outside_the_clone` (stub `claude` logs `$PWD`: only `$HOME`; `git status --porcelain --untracked-files=no` empty) |
| 4 | The start script's non-owned bind-mount message contains no `sudo chown -R` advice. | met | `start_never_chowns_a_bind_mount` (no `sudo chown -R`, names the user namespace) |
| 5 | `devcontainer.json` no longer sets a CPU limit that fails on a 1-CPU host. | met | `run_args_cap_memory_only`, `run_args_name_the_container_after_its_clone`; devcontainer.json:8 is `["--name=${containerWorkspaceFolderBasename}","--memory=4g"]` |
| 6 | `lib/env.sh` documents the `plugin` key. | met | `env_key_reference_lists_plugin` (tests/env.test.sh:137); lib/env.sh:60 |
| 7 | `tests/devcontainer.test.sh` covers the new behaviour. | met | cases listed in the other rows; see F1 and F2 for two gaps in what they pin |
| 8 | A tracked file executable on disk and recorded `100644` is named in the start script's output after `core.fileMode` goes on. | met | `start_keeps_an_executable_bit_the_index_does_not_record` |
| 9 | Calling `window-title.sh` twice leaves `info/exclude`'s mtime unchanged on the second call. | met | `title_leaves_the_exclude_file_alone_when_it_has_the_entry` |
| 10 | A `settings.json` that is a directory is reported as not a regular file, not as invalid JSON. | met | `title_reports_a_settings_path_that_is_not_a_regular_file` |
| 11 | With `core.fileMode=false` set globally, the start script's message says it overrode that value. | met | `start_names_a_file_mode_overridden_from_a_wider_scope` (see F4 for scopes the claim does not hold for) |
| 12 | A dev container for a clone in a folder named `my project` or `_x` starts, with a valid container name. | not met — decided in plan Q1, not a defect: Docker rejects the name before any script runs; the limit is documented (CHANGELOG, README) | plan Q1; F8 |
| 13 | A second `--memory` or `--cpus` entry in `runArgs` fails `tests/devcontainer.test.sh`. | met | `run_args_reject_an_extra_or_duplicate_entry`, `run_args_name_the_container_after_its_clone` |
| 14 | A failed mode listing's reason appears in the TODO; the both-changed case has a test; an interrupted run leaves no `modes.*` file. | met | `start_keeps_file_mode_off_when_the_mode_listing_fails` (reason in TODO), `start_files_restore_and_content_edit_both_count`, `start_leaves_no_modes_file_when_interrupted` |
| 15 | `bash tests/run.sh` passes and `CHANGELOG.md` records the change. | met | `bash tests/run.sh` → `all cases passed`; CHANGELOG.md `## Unreleased` has the #96 bullet |
| 16 | The issue records whether VS Code writes `~/.gitconfig` in one step; if it does not, the start script no longer reads a half-written copy, and a test covers it. | not met — the stability check is untested (F1) | issue comment #96 records "It does not" (checked with `gh`); wait loop at devcontainer-start.sh:305-321; no test fails when the check is removed (mutation run, F1) |
| 17 | An identity kept in an `[include]`d file is either followed or documented as not counting, in `.devcontainer/README.md`. | met | `readme_says_included_identities_do_not_count`; .devcontainer/README.md identity bullet |
| 18 | `CHANGELOG.md`'s `#52` bullet names `tests/replay.test.sh`'s `sed`. | met | CHANGELOG.md `(#52)` bullet; `docs_changelog_names_the_replay_sed_and_the_folder_limit` |
| 19 | The v1.0.6 Release body is the changelog section only, like v1.0.5's, or the checklist says why it is not. | not met — the live Release still has the generated lines; the checklist does not say why (F9) | `gh release view v1.0.6` body matches `What's Changed` / `Full Changelog` on 2 lines; docs/release-checklist.md step 8; the engineer's `gh release edit` is pending (plan Q4) |
| 20 | `bash tests/run.sh` passes. | met | `bash tests/run.sh` → `all cases passed` |
| 21 | With the removal step of the start script disabled, `start_empty_lock_file_is_removed_and_the_lock_taken` fails (shown in the plan's red step); with it enabled it passes. | met | mutation run in a scratch copy with `if rm -f .codeo/active` replaced by `if true`: `FAIL start_empty_lock_file_is_removed_and_the_lock_taken` (two assertions); unmutated it passes |
| 22 | A test starts a container on a detached HEAD with an empty `.codeo/active`: the file is removed and the detached-HEAD TODO is printed. A test makes the removal fail and sees the one "could not be removed" TODO and no `lock.sh` call. | met | `start_empty_lock_file_on_a_detached_head_is_removed_and_reported`, `start_empty_lock_file_that_cannot_be_removed_is_one_todo` |
| 23 | A test makes `container-name.sh` exit non-zero with two stderr lines: `window-title.sh` exits 1, prints one line with both joined by ` / ` and no `container-name: ` prefix, and leaves no `.settings.*` temp file. | met | `title_reports_a_failing_container_name_as_one_line` (the `.settings.*` check cannot fail: F6) |
| 24 | The README and the CHANGELOG no longer say "cannot run at once", and say the containers cannot both exist. | met | `docs_say_two_same_named_containers_cannot_both_exist`; `grep -c 'cannot run at once'` → 0 for CHANGELOG.md and .devcontainer/README.md |
| 25 | Tests show `codeo-root.sh` taking this clone's entry when its `projectPath` has a trailing slash and when it is a symlink to the clone; another project's entry is still never taken; a null `installPath` entry for this clone is skipped. | met | `registry_matches_a_project_path_with_a_trailing_slash`, `registry_matches_a_symlinked_project_path`, `registry_skips_a_null_install_path_for_this_clone`, `other_projects_entry_first_is_skipped` (tests/codeo-root.test.sh) |
| 26 | `bash tests/run.sh` passes and `CHANGELOG.md` records the change. | met | `bash tests/run.sh` → `all cases passed`; CHANGELOG.md has the bullet |
| 27 | A test starts a container on an issue branch with a `.codeo/active` holding `issue:   55` and mode 000 (skipped, with the reason named, where the tests run as a user that can read it anyway): it prints one TODO that names `.codeo/active` and says it cannot be read, does not print "names no issue", takes no lock, and leaves the file unchanged. | met | `start_unreadable_lock_file_is_one_todo` ran for real (uid 1000, no SKIP line in `bash tests/devcontainer.test.sh`) |
| 28 | A readable file with no `issue:` line still prints #87's TODO, and one with an `issue:` line still prints no TODO and takes no second lock; the existing #87 cases pass unchanged. | met | the #87 cases (`start_newline_only_lock_file_is_a_todo` and the `ds_no_issue_reported` family, `start_hash_issue_line_is_a_held_lock`, `start_nonempty_lock_file_is_left_alone`) pass unchanged |
| 29 | The step 3a comment describes the rule as `issue:`, optional whitespace, optional `#`s, then digits; the `-f &&` in the arm and the `DS_REPO` use in `start_hash_issue_line_is_a_held_lock` each have a comment saying why. | met | step 3a comment at devcontainer-start.sh:164-182, the `-f &&` comment, the `DS_REPO` comment in `start_hash_issue_line_is_a_held_lock`; `start_lock_directory_is_not_reported` (the `-f` guard is pinned only after the fix wave bc2cae2) |
| 30 | `bash tests/run.sh` passes and `CHANGELOG.md` records the change. | met | `bash tests/run.sh` → `all cases passed`; CHANGELOG.md has the bullet |

**Documentation.** The pages the plan names are `.devcontainer/README.md` and `docs/release-checklist.md`; both are changed. The README bullets match the scripts (the unreadable-lock TODO, the `core.fileMode` naming and override line, the identity wait and the include limit, "cannot both exist"), are in the present tense and carry no issue numbers; `docs/release-checklist.md` step 8 is consistent with the notes file `.codeo/96/release-v1.0.6-notes.md` (the changelog section without its heading, byte for byte). No other page under `docs/` describes the dev container, so none moves. One CHANGELOG claim is untrue because of F2 (see there).

**Independent review** (`opus`, given the acceptance criteria and the diff only, `.codeo/` and `docs/plans/` excluded): no Critical; two Important (F1, F2, both confirmed below) and five Minor; its own verdict was "not ready to merge" on those two. I reproduced F1 by the mutation run above and F2 by reading devcontainer-start.sh:54 and what follows it.

**Findings.**

- **F1 — blocking, `/codeo:implement`'s.** The half-written `~/.gitconfig` is not covered by a test. `ds_setup` puts a stub `stat` first on `PATH` that prints the uid whatever it is asked (tests/devcontainer.test.sh:473-476), so the stamp the wait loop compares (`gitconfig_stamp`, devcontainer-start.sh:305) never changes, and the loop breaks as soon as the file is non-empty. Removing the comparison leaves the suite green (mutation run). The case `start_waits_for_a_host_gitconfig_that_is_written_after_it_is_created` writes the two keys with two `git config` calls, so it only covers "exists empty, then filled", and that is a timing race rather than a growth check. Criterion 16 asks for a test that covers not reading a half-written copy. Root cause (Phase 1): the plan's Task 9 specified only the empty-then-filled test, which the stub `stat` cannot tell apart from the old behaviour; the criterion is the standard, so adding the test does not need a re-plan. Needed: a test that makes `stat` report a changing size/mtime (a real `stat`, or a stub that varies) or appends to the file in steps with a gap longer than the settle interval, and that fails when the comparison is removed.
- **F2 — blocking, `/codeo:implement`'s.** After "could not enter the clone" (devcontainer-start.sh:54) the script carries on, and steps 2b, 3, 3a, 3a', 3b and 6 run on relative paths in the caller's directory (`bash .devcontainer/scripts/plugins.sh`, `.codeo/active`, `window-title.sh`). The new case `start_without_a_git_top_level_is_one_todo` does not `cd` anywhere (`ds_run` does not either), so when `tests/run.sh` is run from the repository root the case runs the real checkout's `plugins.sh`, `window-title.sh` and `.codeo/active` handling against the developer's tree (the reviewer reproduced it in a scratch copy: a new `.vscode/settings.json` and an `info/exclude` line, with four TODOs on stderr). The plan's Review Focus asked for "one TODO, exit 0, nothing run in the wrong directory"; the code does the first two. `CHANGELOG.md`'s "a git top level it cannot find is one TODO" is untrue as written (more than one TODO appears). Needed: when step 2 fails, do not run the clone-relative steps (or run them against `$clone`), and run the test from a scratch working directory.
- **F3 — non-blocking, plan's.** The bind-mount TODO says git "is already told to trust the clone" (devcontainer-start.sh:48); if the `safe.directory` add on line 42 failed, the same run lists "git was not told to trust the clone" next to it. Under rootless Docker or Podman this TODO also appears on every start and never clears, so `ready` is never printed (pre-existing in kind; the text was the plan's).
- **F4 — non-blocking, `/codeo:implement`'s.** The override line ("this clone's config now overrides it with true", devcontainer-start.sh:113, 225-227) is false when the `false` comes from a scope that outranks the clone's own config (`command` scope from `GIT_CONFIG_PARAMETERS`, or `worktree` with `extensions.worktreeConfig`): the local `true` then changes nothing while the script says it did.
- **F5 — non-blocking, plan's.** `start_lock_crash_is_a_todo` counts lines containing `boom` (`grep -c`) instead of occurrences (`grep -o | wc -l`), so crash output repeated twice on the one TODO line would pass. Task 6 mandated the change.
- **F6 — non-blocking, plan's.** The `.settings.*` temp-file assertion in `title_reports_a_failing_container_name_as_one_line` cannot fail: `window-title.sh` dies before it creates `.vscode` or any temp file. The behaviour is right; the assertion pins nothing.
- **F7 — non-blocking, `/codeo:implement`'s.** `codeo-root.sh` reads the registry with `@tsv`, which escapes `\`, tab and newline (a path with a backslash would no longer match), and an empty or `false` `projectPath` now counts as no `projectPath` (before, only `null` did). Both are unlikely in a real registry.
- **F8 — non-blocking, plan's (decided).** Criterion 12 (`my project` / `_x` starts) is not met by plan Q1: Docker rejects the name before any script runs, `runArgs` is unchanged, and the limit is documented in the CHANGELOG and README. Amend the criterion on #96 if it should read as met.
- **F9 — non-blocking, the engineer's.** Criterion 19: the live v1.0.6 Release body still has the generated `## What's Changed` and `**Full Changelog**` lines, and the checklist does not say why. The plan (Q4) hands `gh release edit v1.0.6 --notes-file .codeo/96/release-v1.0.6-notes.md` to the engineer; run it before the pull request is merged.

No issue was filed by this pass.

**Verdict: back to `/codeo:implement`.**

## Log

- 2026-11-15 — Q1-Q3 raised (overlaps with #70, #71, #97 at step 2) · cost: 1m · opus-5-5 359k in + 792k cached / 1k out
- 2026-11-15 — round 1: back to /codeo:implement (F1, F2 blocking); no issue filed · cost: 21m · opus-5-5 488k in + 4.1M cached / 31k out · sonnet-5-5 52k in + 7.2M cached / 22k out
