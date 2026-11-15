# Issue #96 — init

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/96 |
| Branch | `feat/dev-container-follow-ups-40` |
| Updated | 2026-11-15 |

## Where this stands

Branch `feat/dev-container-follow-ups-40` cut off `main` at 90075d4, claimed and pushed. Nothing is open; the next step is `/codeo:plan`, run in this issue's own container.

## Questions

None.

## Outcome

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/96 — Dev container follow-ups from #40, #54, #81, #88 and #91: start scripts, tests, wording and registry match |
| State | open · labels `enhancement` |
| Branch | `feat/dev-container-follow-ups-40` off `main` at `90075d4` |
| Board | Ready → In progress |

**Problem.** Five dev-container follow-up issues (#40, #54, #81, #88, #91) consolidated into one pass: start-script and `plugins.sh` fixes, session-title and container-name edges, `codeo-root.sh` registry matching, git-identity wait edges, test holes and wording gaps. All were non-blocking QC findings; the issue body holds each original in full under its own heading.

**Acceptance criteria** — verbatim from the issue, unchecked:
- [ ] A test changes `plugin.repo` with an unchanged ref and sees codeo replaced.
- [ ] Two runs of the start script leave one `safe.directory` entry.
- [ ] `git status` is clean after the start script's `claude` calls, which run from `$HOME`.
- [ ] The start script's non-owned bind-mount message contains no `sudo chown -R` advice.
- [ ] `devcontainer.json` no longer sets a CPU limit that fails on a 1-CPU host.
- [ ] `lib/env.sh` documents the `plugin` key.
- [ ] `tests/devcontainer.test.sh` covers the new behaviour.
- [ ] A tracked file executable on disk and recorded `100644` is named in the start script's output after `core.fileMode` goes on.
- [ ] Calling `window-title.sh` twice leaves `info/exclude`'s mtime unchanged on the second call.
- [ ] A `settings.json` that is a directory is reported as not a regular file, not as invalid JSON.
- [ ] With `core.fileMode=false` set globally, the start script's message says it overrode that value.
- [ ] A dev container for a clone in a folder named `my project` or `_x` starts, with a valid container name.
- [ ] A second `--memory` or `--cpus` entry in `runArgs` fails `tests/devcontainer.test.sh`.
- [ ] A failed mode listing's reason appears in the TODO; the both-changed case has a test; an interrupted run leaves no `modes.*` file.
- [ ] `bash tests/run.sh` passes and `CHANGELOG.md` records the change.
- [ ] The issue records whether VS Code writes `~/.gitconfig` in one step; if it does not, the start script no longer reads a half-written copy, and a test covers it.
- [ ] An identity kept in an `[include]`d file is either followed or documented as not counting, in `.devcontainer/README.md`.
- [ ] `CHANGELOG.md`'s `#52` bullet names `tests/replay.test.sh`'s `sed`.
- [ ] The v1.0.6 Release body is the changelog section only, like v1.0.5's, or the checklist says why it is not.
- [ ] `bash tests/run.sh` passes.
- [ ] With the removal step of the start script disabled, `start_empty_lock_file_is_removed_and_the_lock_taken` fails (shown in the plan's red step); with it enabled it passes.
- [ ] A test starts a container on a detached HEAD with an empty `.codeo/active`: the file is removed and the detached-HEAD TODO is printed. A test makes the removal fail and sees the one "could not be removed" TODO and no `lock.sh` call.
- [ ] A test makes `container-name.sh` exit non-zero with two stderr lines: `window-title.sh` exits 1, prints one line with both joined by ` / ` and no `container-name: ` prefix, and leaves no `.settings.*` temp file.
- [ ] The README and the CHANGELOG no longer say "cannot run at once", and say the containers cannot both exist.
- [ ] Tests show `codeo-root.sh` taking this clone's entry when its `projectPath` has a trailing slash and when it is a symlink to the clone; another project's entry is still never taken; a null `installPath` entry for this clone is skipped.
- [ ] `bash tests/run.sh` passes and `CHANGELOG.md` records the change.
- [ ] A test starts a container on an issue branch with a `.codeo/active` holding `issue:   55` and mode 000 (skipped, with the reason named, where the tests run as a user that can read it anyway): it prints one TODO that names `.codeo/active` and says it cannot be read, does not print "names no issue", takes no lock, and leaves the file unchanged.
- [ ] A readable file with no `issue:` line still prints #87's TODO, and one with an `issue:` line still prints no TODO and takes no second lock; the existing #87 cases pass unchanged.
- [ ] The step 3a comment describes the rule as `issue:`, optional whitespace, optional `#`s, then digits; the `-f &&` in the arm and the `DS_REPO` use in `start_hash_issue_line_is_a_held_lock` each have a comment saying why.
- [ ] `bash tests/run.sh` passes and `CHANGELOG.md` records the change.

**Out of scope.** Per section: image changes, new tools, anything under `scripts/`, `lib/`, `hooks/` or `skills/`, pruning `safe.directory` beyond the fix, and the findings each section says are left.

**Open at intake.** The optional item in #40 (persisting Claude's login across rebuilds); the VS Code single-write check in #81 (settle first); and #88's left minors, each to be fixed or dismissed with a reason in `plan.md`.

## Log

- 2026-11-15 — initialized: branch feat/dev-container-follow-ups-40 off main at 90075d4 · cost: unavailable
