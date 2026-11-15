# Issue #57 — implement

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/57 |
| Branch | `feat/dev-container-follow-ups-55` |
| Plan | `docs/plans/2026-11-14-dev-container-follow-ups.md` |
| Updated | 2026-11-15 |

## Where this stands

Round 2 done, after a send-back from `/codeo:close`: `main` was merged in and the `CHANGELOG.md` conflict with #76 resolved by keeping both bullets (round 1: all five tasks built and reviewed, plus a whole-branch review that found nothing blocking). The build step is the `shell` suite's `build` (`true`). No open question. Next is `/codeo:qc`, which runs its whole pass again.

## Questions

None.

## Outcome

**Built** (commits `814411f`..`7bd358c` on top of the plan commit `cb5f109`; `sync-main.sh` reported the branch already contains `origin/main`, so there was nothing to merge and no "also changed" line; `overlap.sh 57` prints nothing):
- Task 1 — `folder-check.sh` reads `baseBranch` (else `main`) and names it in its home-clone TODO; four new cases in `tests/folder-check.test.sh`. One fix round (`eca4f74`): the review missed that `wrong_folder_on_a_configured_base_names_the_home_folder` passed with and without the fix, because its fragment `'codeo-home'` also occurs in the issue-branch text; both new cases now use the fragment `on develop` and were shown to fail on the pre-fix script.
- Task 2 — `codeo-root.sh` takes the first `codeo@codeo` entry whose `projectPath` is this clone's physical path, else the first with no `projectPath`, never another project's; the clone root is found with a `git rev-parse` that cannot abort the script. `tests/codeo-root.test.sh` runs the script from a scratch clone (`registry` takes `path[@projectPath]` entries); `tests/devcontainer.test.sh` gains `start_uses_this_projects_lock_sh` and `start_ignores_another_projects_codeo`.
- Task 3 — `devcontainer-start.sh` removes a zero-byte `.codeo/active` (printing `devcontainer-start: .codeo/active was empty and held no lock: removed it`) and carries on; a non-zero `lock.sh` exit puts its output in the one TODO and no longer prints it line by line. Three new cases, one changed (`start_lock_crash_is_a_todo`), one extended (`start_rerun_with_a_lock_does_not_take_another`).
- Task 4 — `window-title.sh` takes the title from `container-name.sh`'s stdout only (stderr to a temp file, still reported on failure); `title_ignores_a_warning_on_stderr`; the overlay needle in `tests/init-overlay.test.sh` is now `This skill does not write `.codeo/active``.
- Task 5 — the `container-name.sh` header says the Docker name is the clone folder set by `runArgs`; `.devcontainer/README.md` names `.devcontainer/scripts/devcontainer-start.sh` by its real path, states the empty-lock behaviour and the same-folder-name limit with its fix, and points *Rebuilding* at it; `CHANGELOG.md` clarifies `container-name.sh` in the `## v1.0.4` bullet for #55 and gains one `## Unreleased` bullet for #57.

**Documentation changed:** `.devcontainer/README.md`, `CHANGELOG.md`. No page under `docs/` moves, as the plan said.

**Build result:** the suite's `build` is `true`: exit 0. Each task's implementer ran `bash tests/run.sh` (`all cases passed`) and the final whole-branch reviewer ran it once more with the same result; the suites are graded by `/codeo:qc`, not here.

**Deviations from the plan, and findings:**
- One case beyond the plan: `outside_a_git_clone_only_user_entries_qualify` in `tests/codeo-root.test.sh`, for a ruling that `codeo-root.sh` must still end in its single `codeo-root:` line and exit 1 outside a git repository (the plan's Global Constraint that failures stay clean).
- The plan's Task 1 listed a fifth case, `no_base_in_the_config_means_main`, and the draft already dropped it; four cases were added.
- Task 5's `git merge origin/main` was a no-op.
- Task 5's v1.0.4 CHANGELOG edit is a clarification and not a correction: no CHANGELOG sentence claimed all three names come from `container-name.sh`, only the script header did (found at planning).
- In the real container `plugins.sh` installs codeo with `--scope user`, so its registry entry has no `projectPath`; the "this clone's `projectPath`" branch of `codeo-root.sh` matters for project-scope installs and is covered by tests, not exercised in the container itself.

**Deferred minors** (reviewers, none blocking, none fixed; the final reviewer judged each "leave"): `codeo-root.sh` falls through to the user entry when this project's entry has a null `installPath`; the `registry` helper in `tests/codeo-root.test.sh` splits on `@`; the `lock-calls-mine` assertion in `start_ignores_another_projects_codeo` is trivially true; a long header-comment line in `devcontainer-start.sh`; `grep -o boom | wc -l` is loose in `start_lock_crash_is_a_todo`; no case for an empty `.codeo/active` with a detached HEAD or a failed `rm`; the `container-name.sh` failure path of `window-title.sh` has no test; the CHANGELOG says the v1.0.4 bullet "was corrected in place" where "clarified" is exact; the CHANGELOG states the same-name limit in one parenthetical, with the full statement in `.devcontainer/README.md`; the `--docker` usage line in `container-name.sh` could say "the name the container should have".

**Deferred minors from #55, for the PR description:** all five are fixed and none is dismissed — header wording in `container-name.sh` (Task 5), `window-title.sh`'s `2>&1` capture (Task 4), the bare `-home` folder on a non-main branch (Task 1, `home_folder_off_the_base_branch_is_silent`), the `lock.sh` crash output repeated in its TODO (Task 3), the weak `.codeo/active` needle (Task 4).

### Round 2

2026-11-15
(send-back from close.md round 1)

`/codeo:close` found that the branch conflicts with `origin/main` in `CHANGELOG.md`: #76 merged (`dfa8b10`) while this branch was in `/codeo:qc`. The finding holds (checked with `git merge-tree` before and after).

**Merge** (`sync-main.sh`, exit 2, one conflict; merge commit `8edd488`; the branch is merged, not rebased, and has no pull request yet). `also changed on main` for the files this branch touches: only `CHANGELOG.md`.
- `CHANGELOG.md`: both `## Unreleased` bullets are kept — the #76 bullet (Haiku trial: `doctor` and `setup` stay on Sonnet) first, as it merged first, then this branch's #57 bullet. Nothing in either bullet changed because of the other; the conflict was only the two additions at the same spot. The merge also brought in #76's own archived dossier (`.codeo/done/76/`) and plan (`docs/plans/2026-11-14-trial-doctor-setup-haiku.md`), which this branch does not touch.
- After the merge `git merge-tree --write-tree origin/main HEAD` exits 0, and `overlap.sh 57` prints nothing.

**Also changed, from `/codeo:qc` round 1** (non-blocking F3, which `close` did not send back but which sits in the line being resolved): the #57 bullet now says the start script, after removing an empty `.codeo/active`, takes the lock "on an issue branch" (on the base branch it takes none, as `start_empty_lock_file_on_the_base_branch_is_removed` shows), and that the v1.0.4 bullet was "clarified in place", not "corrected", because no sentence in it was false. No other finding from that round is addressed here: F1, F2, F4 and F5 are left as `qc.md` recorded them.

**Build result:** the suite's `build` is `true`: exit 0. `tests/agnostic.test.sh`, which guards the wording of tracked files, passes on the merged tree. No script or test changed in this round, so no suite was run beyond that; `/codeo:qc` runs them in full.

**Documentation changed:** `CHANGELOG.md` only. No deviation from the plan.

## Log

- 2026-11-15 — implemented: 5 tasks, 1 fix round on Task 1 · cost: 45m · sonnet-5-5 625k in + 16.9M cached / 91k out
- 2026-11-15 — round 2: merged origin/main (CHANGELOG.md conflict with #76 resolved, both bullets kept), F3 wording fixed · cost: 0m · sonnet-5-5 15k in + 1.8M cached / 2k out
