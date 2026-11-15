# Issue #57 — qc

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/57 |
| Branch | `feat/dev-container-follow-ups-55` at `7593b85` |
| Updated | 2026-11-15 |

## Where this stands

Round 2 is written, after the send-back from `/codeo:close` (a `CHANGELOG.md` conflict with #76, merged and resolved in `/codeo:implement` round 2): no question was raised, the build and the full suite pass on the merged tree, every acceptance criterion is met or recorded, and nothing blocking was found. The verdict is clear, forward to `/codeo:close`.

## Questions

None.

## Notes

Nothing outside the round.

## Outcome

### Round 1 — 2026-11-15

**Commands and output (this pass, branch `7593b85`):**
- `sync-main.sh --abort-on-conflict`: "sync-main: the branch already contains origin/main". `overlap.sh 57`: nothing. `overlap.sh --outside 57`: nothing.
- `scope.sh origin/main HEAD`: "scope: suite shell needed for unclassified paths: .codeo/57/implement.md, .codeo/57/init.md, .codeo/57/issue.md, .codeo/57/plan.md, CHANGELOG.md" then `suite.shell=true`. No `deploy=` line: no shared environment is configured, so step 9 does not apply.
- `git diff origin/main...HEAD --stat`: 16 files, 791 insertions, 37 deletions: the five scripts and `container-name.sh`, `.devcontainer/README.md`, `CHANGELOG.md`, four test files, the plan, and the `.codeo/57/` dossiers. Nothing under `scripts/`, `lib/`, `hooks/` or `skills/`.
- Build (`true`): exit 0.
- Test (`bash tests/run.sh`, 40 files): exit 0, "all cases passed" (225 s).
- `overlay.sh qc invariants-extra` and `qc wiki-rules`: exit 3 (none). No invariants file, no wiki module.
- Independent review (`QC review: issue #57 dev container follow-ups`, on Opus, against `09e3013..7593b85`): ready to merge, no Critical or Important finding. It also ran the new test files against the base revision in a throwaway worktree: the codeo-root cases (3 of 4), `wrong_folder_on_a_configured_base_names_the_home_folder`, `issue_folder_on_the_home_clone_is_reported`, both empty-lock cases, the crash-once assertion, `start_uses_this_projects_lock_sh`, `start_ignores_another_projects_codeo` and `title_ignores_a_warning_on_stderr` fail there.

**Criteria:**

| # | Criterion | Verdict | Settled by |
|---|---|---|---|
| 1 | two same-named checkouts start, or the README and CHANGELOG state the limit and the fix | met — by the documentation alternative | `.devcontainer/README.md` *The folder rule* (the limit, `name already in use`, rename a folder or use the named-volume flow) and the `CHANGELOG.md` `## Unreleased` bullet |
| 2 | another project's `codeo@codeo` entry first; the start script uses this project's `lock.sh` | met | `start_uses_this_projects_lock_sh` (`tests/devcontainer.test.sh:605`), with `other_projects_entry_first_is_skipped` (`tests/codeo-root.test.sh:116`); both fail at the base |
| 3 | a container with an empty `.codeo/active` sees a lock taken or a `todo:` line | met | `start_empty_lock_file_is_removed_and_the_lock_taken` (`tests/devcontainer.test.sh:512`): the removal line, one `take container` call, the lock written; fails at the base |
| 4 | `folder-check.sh` on a non-`main` base, on its home clone, gets no wrong-folder TODO | met | `home_folder_on_a_configured_base_is_silent` (`tests/folder-check.test.sh:101`), with the cases that fail at the base: `wrong_folder_on_a_configured_base_names_the_home_folder`, `issue_folder_on_the_home_clone_is_reported` (see F1) |
| 5 | the comment, the CHANGELOG line and the README path match the code | met | `container-name.sh` header against `devcontainer.json:7`; README path `.devcontainer/scripts/devcontainer-start.sh` (no bare `scripts/…` left); the v1.0.4 bullet against the scripts; but see F3 for one imprecise phrase in the new bullet |
| 6 | each deferred minor is fixed or dismissed in the PR description | not yet checkable — the PR description is written by `/codeo:close`; all five are fixed in code | header wording (`container-name.sh`), `window-title.sh`'s `2>&1` (`title_ignores_a_warning_on_stderr`), the bare `-home` folder (`home_folder_off_the_base_branch_is_silent`), the crash output repeated (`start_lock_crash_is_a_todo`), the weak needle (`tests/init-overlay.test.sh`) |
| 7 | `bash tests/run.sh` passes and `CHANGELOG.md` records the change | met | suite exit 0 above; `CHANGELOG.md` `## Unreleased` bullet for #57 |

**Documentation check:** `.devcontainer/README.md` and `CHANGELOG.md` describe the behaviour in the present tense (the README with no issue numbers) and match the code except F3. No page under `docs/` described the dev container, as the plan said; the plan's one moved page, `.devcontainer/README.md`, is updated. `container-name.sh`'s header is true of `runArgs` and of what `--docker` prints.

**Findings** (all against lines this change touched; the reviewer's and this pass's together):
- **F1 — non-blocking, `/codeo:implement`'s.** `tests/folder-check.test.sh:101-104` (`home_folder_on_a_configured_base_is_silent`), the case that most literally matches criterion 4, passes at the base as well: `codeo-home` was already silent on a non-`main` branch. The two sibling cases fail at the base and carry the proof. Say so in the PR description, or have the case also assert that `codeo-12` on `develop` is reported.
- **F2 — non-blocking, `/codeo:plan`'s.** `devcontainer-start.sh` tests `.codeo/active` with `-s`, so a file holding only a newline or text with no `issue:` line still counts as a held lock: `lock.sh` is skipped, `container-name.sh` reads it as home, and the folder check says nothing. The issue names only the empty file, so this is outside the criteria; it is the same silent state F6 targets, from a non-empty file. Left for `/codeo:triage`.
- **F3 — non-blocking, `/codeo:implement`'s.** `CHANGELOG.md:11` says the start script "removes an empty `.codeo/active`, says so and takes the lock"; on the base branch it takes none (`start_empty_lock_file_on_the_base_branch_is_removed`). The README says "on an issue branch". The same bullet says the v1.0.4 bullet "was corrected in place", where the plan found no sentence false and "clarified" is exact.
- **F4 — non-blocking, `/codeo:plan`'s.** `codeo-root.sh:68-72`: the `projectPath` match is an exact string match against `pwd -P`; a project-scoped entry recorded with a symlinked path or a trailing slash no longer matches, and with no user-scope entry the start script reports "codeo is not installed". Low risk: `plugins.sh` installs at user scope and `/workspaces` is a real path.
- **F5 — non-blocking, `/codeo:implement`'s.** `devcontainer-start.sh`'s step 3a header comment has one line far past its neighbours' width. Cosmetic.
- Deferred minors from the per-task reviews, recorded in `implement.md`: all are non-blocking and the Opus reviewer judged each "leave".
- Declined by the reviewer, recorded: a `.codeo/active` that is a directory (predates the change); same-basename checkouts running at once (the plan chose document only); `lock: TODO — …` lines from a failing `lock.sh` folded into the one crash TODO; a non-string `baseBranch`.

Issues filed by this pass: none. F2 is the one finding worth its own issue; it goes to `/codeo:triage`.

**Verdict: clear — forward to `/codeo:close`.**

### Round 2 — 2026-11-15

Whole pass re-run on `fbe74b3` after the send-back from `/codeo:close` round 1 (a conflict with `main` in `CHANGELOG.md`, resolved in `/codeo:implement` round 2 by merging `origin/main` and keeping both `## Unreleased` bullets).

**Commands and output (this pass, branch `fbe74b3`):**
- `sync-main.sh --abort-on-conflict`: "sync-main: the branch already contains origin/main". `overlap.sh 57`: nothing. `overlap.sh --outside 57`: nothing.
- `scope.sh origin/main HEAD`: "scope: suite shell needed for unclassified paths: .codeo/57/close.md, .codeo/57/implement.md, .codeo/57/init.md, .codeo/57/issue.md, .codeo/57/plan.md, .codeo/57/qc.md, CHANGELOG.md" then `suite.shell=true`. No `deploy=` line: no shared environment is configured, so step 9 does not apply.
- `git diff origin/main...HEAD --stat`: 18 files, 902 insertions, 37 deletions — the same change as round 1 plus `.codeo/57/close.md` and the round 2 dossier text. Since round 1's head (`7593b85`) no script, test or documentation page changed except `CHANGELOG.md` (the merge with #76's bullet, and two wording fixes in the #57 bullet); `git diff 7593b85 HEAD --stat -- .devcontainer tests scripts lib hooks skills` printed nothing. Nothing under `scripts/`, `lib/`, `hooks/` or `skills/` changed.
- Build (`true`): exit 0.
- Test (`bash tests/run.sh`, 40 files): exit 0, "all cases passed" (194 s).
- `overlay.sh qc invariants-extra` and `qc wiki-rules`: exit 3 (none). No invariants file, no wiki module.
- Independent review (`QC review: issue #57 round 2`, on Opus, against `dfa8b10..fbe74b3`): ready to merge, no Critical or Important finding. It ran the new test files against the base revision in a throwaway worktree: the four new `codeo-root` cases, the empty-lock cases, the crash-output assertions, `start_uses_this_projects_lock_sh`, `start_ignores_another_projects_codeo`, `title_ignores_a_warning_on_stderr`, `wrong_folder_on_a_configured_base_names_the_home_folder` and `issue_folder_on_the_home_clone_is_reported` fail there. It checked that the merge left the other Unreleased bullets (#51, #52, #76) intact and the file well-formed, and that the `## v1.0.4` bullet still sits under `## v1.0.4`.

**Criteria:**

| # | Criterion | Verdict | Settled by |
|---|---|---|---|
| 1 | two same-named checkouts start, or the README and CHANGELOG state the limit and the fix | met — by the documentation alternative | `.devcontainer/README.md` *The folder rule* and the `CHANGELOG.md` `## Unreleased` bullet for #57 |
| 2 | another project's `codeo@codeo` entry first; the start script uses this project's `lock.sh` | met | `start_uses_this_projects_lock_sh` (`tests/devcontainer.test.sh`), with `other_projects_entry_first_is_skipped` (`tests/codeo-root.test.sh`); both fail at the base |
| 3 | a container with an empty `.codeo/active` sees a lock taken or a `todo:` line | met | `start_empty_lock_file_is_removed_and_the_lock_taken` (`tests/devcontainer.test.sh`): the removal line, one `take container` call, the lock written; fails at the base (see F7) |
| 4 | `folder-check.sh` on a non-`main` base, on its home clone, gets no wrong-folder TODO | met | `home_folder_on_a_configured_base_is_silent` (`tests/folder-check.test.sh`), with the cases that fail at the base: `wrong_folder_on_a_configured_base_names_the_home_folder`, `issue_folder_on_the_home_clone_is_reported` (see F1) |
| 5 | the comment, the CHANGELOG line and the README path match the code | met | `container-name.sh` header against `devcontainer.json`'s `runArgs`; README path `.devcontainer/scripts/devcontainer-start.sh`; the #57 bullet now says the lock is taken "on an issue branch" and the v1.0.4 bullet "clarified" (round 1's F3, fixed) |
| 6 | each deferred minor is fixed or dismissed in the PR description | not yet checkable — the PR description is written by `/codeo:close`; all five are fixed in code | header wording (`container-name.sh`), `window-title.sh`'s `2>&1` (`title_ignores_a_warning_on_stderr`), the bare `-home` folder (`home_folder_off_the_base_branch_is_silent`), the crash output repeated (`start_lock_crash_is_a_todo`), the weak needle (`tests/init-overlay.test.sh`) |
| 7 | `bash tests/run.sh` passes and `CHANGELOG.md` records the change | met | suite exit 0 above; `CHANGELOG.md` `## Unreleased` bullet for #57 |

**Documentation check:** `.devcontainer/README.md` and `CHANGELOG.md` match the code, in the present tense and with no issue numbers in the README; the merged `CHANGELOG.md` keeps all four Unreleased bullets (#51, #52, #76, #57). No page under `docs/` describes the dev container, as the plan said. One imprecise phrase remains (F8).

**Findings** (against lines this change touched; the reviewer's and this pass's together):
- F3 (non-blocking in round 1) — fixed by `8edd488`: the #57 bullet says the lock is taken "on an issue branch", and the v1.0.4 bullet was "clarified".
- **F1 — non-blocking, `/codeo:implement`'s.** Unchanged from round 1: `home_folder_on_a_configured_base_is_silent` passes at the base as well; `wrong_folder_on_a_configured_base_names_the_home_folder` and `issue_folder_on_the_home_clone_is_reported` carry the proof. The PR description should say so.
- **F2 — non-blocking, `/codeo:plan`'s.** Unchanged: a `.codeo/active` holding only a newline or text with no `issue:` line still counts as a held lock (`-s`) and stays silent. Outside the criteria; left for `/codeo:triage`.
- **F4 — non-blocking, `/codeo:plan`'s.** Unchanged: `codeo-root.sh` matches `projectPath` by exact string against `pwd -P`; low risk, since `plugins.sh` installs at user scope.
- **F5 — non-blocking, `/codeo:implement`'s.** Unchanged: one over-long comment line in `devcontainer-start.sh`'s step 3a header.
- **F7 — non-blocking, `/codeo:implement`'s (new this round).** `ds_lock_stub`'s `lock.sh` writes `.codeo/active` whether or not the file exists, so `start_empty_lock_file_is_removed_and_the_lock_taken` reproduces F6 only through its removal-line assertion: the real `lock.sh` sees the empty file and prints "lock already taken:" with nothing after it. Making the stub refuse when the file exists would let the "lock taken" assertion prove the removal by itself.
- **F8 — non-blocking, `/codeo:implement`'s (new this round).** `.devcontainer/README.md` *The folder rule* and the CHANGELOG bullet say two containers whose folders share a name "cannot run at once". A stopped container keeps its name, so the second cannot be created even while the first is stopped: "cannot both exist" is exact. The remedy given (rename one folder, or use the named-volume flow) is correct as written.
- Deferred minors from the per-task reviews, recorded in `implement.md`: all non-blocking.
- Declined by the reviewer, recorded: a `projectPath` recorded through a symlinked path; a this-project entry without `scripts/lock.sh` failing rather than falling back to the user entry (the no-guessing rule); `lock: TODO — …` lines from a failing `lock.sh` folded into the one crash TODO; the README's "never clash" against a host folder literally named `codeo-home`; comment line length.

Issues filed by this pass: none. F2 goes to `/codeo:triage`.

**Verdict: clear — forward to `/codeo:close`.**

## Log

- 2026-11-15 — qc round 1 written: verdict clear, forward to /codeo:close · cost: 6m · opus-5-5 371k in + 3.1M cached / 15k out · sonnet-5-5 284k in + 342k cached / 254 out
- 2026-11-15 — qc round 2 written (after the close send-back for the CHANGELOG.md conflict): verdict clear, forward to /codeo:close · cost: 3m · opus-5-5 438k in + 2.3M cached / 13k out · sonnet-5-5 24k in + 755k cached / 269 out
