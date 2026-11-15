# Issue #96 — implement

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/96 |
| Branch | `feat/dev-container-follow-ups-40` |
| Updated | 2026-11-15 |

## Where this stands

Round 3 done (send-back from `close.md` round 1): `main` merged and the `CHANGELOG.md` conflict resolved. The build passes. Next step is `/codeo:qc`, which runs again on the merged tree.

## Questions

None.

## Notes

Each task ran as an implementer and a task review on the subagent model (sonnet), then one whole-branch review and one fix wave. No `Needs lease:` tasks, no deploy.

## Outcome

**Built** (commits `36fdc4d`..`bc2cae2` on top of the plan commit `443bf56`):

1. `devcontainer.json` loses `--cpus=2`; `runArgs` is pinned exactly (`run_args_cap_memory_only`, `run_args_reject_an_extra_or_duplicate_entry`).
2. `plugins.sh` reinstalls codeo when `plugin.repo` changes with the same ref; a record without `source.repo` counts as a match.
3. Start script: `claude auth status` from `$HOME`, the bind-mount TODO explains the user-namespace mapping with no `sudo chown -R`, an unfindable git top level is one TODO, the `>=` comment sits beside the `>=`.
4. `lib/env.sh` documents `plugin{repo,ref}` (one comment line).
5. Start script step 2b: names the tracked files executable on disk but recorded `100644`, says when it overrode a `false` from a wider scope, puts a failed mode listing's reason in the TODO, and leaves no `modes.*` file after an interrupted run.
6. Step 3a: an empty `.codeo/active` it cannot remove is one TODO and no `lock.sh` call; a non-empty one it cannot read gets its own TODO; the comments and two test tightenings from #88/#91.
7. `window-title.sh`: leaves `info/exclude` alone when current, names a non-regular or unreadable `settings.json`, reports a failing `container-name.sh` as one line; `container-name.sh`'s usage comment.
8. `codeo-root.sh` matches `projectPath` after resolving it and skips a null `installPath`.
9. Step 5 waits for the host `~/.gitconfig` to be non-empty and stable; the README says included identities do not count.
10. README, CHANGELOG (the #57 and #52 bullets edited in place, one new #96 bullet), `docs/release-checklist.md` step 8, and `.codeo/96/release-v1.0.6-notes.md`.
11. Task 11 step 1: the VS Code finding is recorded on #96 (https://github.com/kbajpai/codeo/issues/96#issuecomment-6897237556): VS Code creates `~/.gitconfig` and writes it about 41 ms later, in place.

**Documentation pages changed:** `.devcontainer/README.md`, `docs/release-checklist.md`; `CHANGELOG.md` records the change.

**Build:** the `shell` suite's build is `true`: exit 0. (`bash tests/run.sh` also printed `all cases passed` on the final head; that is QC's to grade.)

**Deviations from the plan, and why.**
- Task 3: `start_without_a_git_top_level_is_one_todo` passes before its fix on bash 5.3 (`cd ""` already fails there); it is kept as a regression pin.
- Task 5: the interrupted-run test needed two fix rounds (it first signalled the `$(...)` subshell, not the script). The cleanup is one EXIT trap that removes the temp file; the brief's INT/TERM trap was redundant because bash runs the EXIT trap on a fatal signal.
- Task 6: the stub `lock.sh` exits 0 after printing `lock already taken` (the real exit status is not specified).
- Task 10: `sync-main.sh --abort-on-conflict` merged one commit from `origin/main` (#98) without conflict but printed `comm: not in sorted order` and exited 1, the collation bug #98 fixes; the merge (`b4b60c4`) was committed and the tree was clean. `also changed on main`: #98's files only (no overlap with this plan's footprint).
- Task 11 step 2 (filing "persist Claude's login across a rebuild" as its own issue through `/codeo:issue`) is not done: that skill is an interview with the engineer. Step 3 is the engineer's command, below.
- The final fix wave (`bc2cae2`) pinned the `-f &&` guard of step 3a with an assertion, brought the #51 changelog bullet up to date and added the "safe.directory once" clause to the #96 bullet.

**Deferred minors** (none blocks; from the task and final reviews): the negative `runArgs` test has no positive control; the interrupt test's stub kill has no scratch-dir guard; `codeo-root.sh` `@tsv` escapes backslashes and `cd` has no `--`; a few long header lines; the identity-wait test fills the file atomically.

**Left for the engineer:** run `gh release edit v1.0.6 --notes-file .codeo/96/release-v1.0.6-notes.md` (proof: `gh release view v1.0.6 --json body -q .body` has no `What's Changed` or `Full Changelog` line), and file the login-persistence issue with `/codeo:issue`. #54's "`my project` / `_x` starts" criterion is not met, by plan Q1.


### Round 2 — 2026-11-15
(send-back from qc.md round 1)

Both blocking findings held against the code (F1 by a mutation run, F2 by reading step 2) and are fixed; F3-F9 are non-blocking and were not part of this round (F9 is still the engineer's `gh release edit`).

- **F1 — fixed** (`51a4388`). The test harness's stub `stat` now passes the stamp query (`%s %y`) through to the real `stat` and still prints the uid for the ownership query. New case `start_waits_for_a_host_gitconfig_that_is_still_growing` appends to the host file in place in steps shorter than the 0.2 s settle interval with the email line last, and fails (email taken from `GIT_AUTHOR_EMAIL`) when `&& $now == "$stamp"` is removed from the wait loop; three unmutated runs passed.
- **F2 — fixed** (`962d97e`). When `git rev-parse --show-toplevel` fails, step 2 falls back to `cd "$clone"`, so the later steps run from the clone folder and never from the caller's directory; that is one TODO of its own containing `top level`, and `could not enter the clone` is now only for a failed `cd "$clone"`. The case `start_without_a_git_top_level_is_one_todo` runs from a decoy directory holding marker `plugins.sh` / `window-title.sh` scripts and an empty `.codeo/active`, and fails on the pre-fix script. The CHANGELOG #96 bullet's clause now reads "a git top level it cannot find is one TODO of its own and the remaining steps run from the clone folder, not the caller's directory".

**Ruling.** F2 could have been fixed by skipping the clone-relative steps; I chose the `cd "$clone"` fallback because the identity, `gh`, Claude-settings and `claude` steps do not need the clone and keep reporting their own TODOs. Cost if wrong: a clone folder that is not a git repository runs the remaining steps against a folder with no repository (they already fail soft with TODOs, and the test pins that nothing is touched outside it).

**Documentation pages changed:** none; `CHANGELOG.md` has the one clause above.

**Build:** the `shell` suite's build is `true`: exit 0. The implementer ran `bash tests/run.sh` (`all cases passed`) before its last commit; that is QC's to grade. `sync-main.sh`: `the branch already contains origin/main`; `overlap.sh 96`: nothing.

**Deviations:** one implementer did both fixes as two commits and one reviewer checked the range, instead of a review per fix.

**Deferred minors:** the hard-coded entry count `6` in the decoy test is brittle; the test run prints a stray `Terminated` line from the interrupt case (QC F-list, not blocking).

### Round 3 — 2026-11-15

(send-back from close.md round 1)

`sync-main.sh` merged `origin/main` (`153e82f`, #105) and conflicted in `CHANGELOG.md` only (exit 2); `lib/env.sh` auto-merged. Resolution: both sides are separate bullets, so both stay, main's `qc-verdict`/`board.sh` bullet first and this branch's #96 bullet after it, each unchanged. Merge commit `b787a48`. `lib/env.sh` still carries the `plugin{repo,ref}` comment line.

Also changed on main: scripts/board.sh, scripts/overlap.sh, scripts/qc-verdict.sh, skills/{close,plan,qc,triage}/SKILL.md, the matching tests, docs/dossier.md, docs/handoff.md, CHANGELOG.md and lib/env.sh. None overlaps this branch's files except `CHANGELOG.md` and `lib/env.sh`.

Build: `true`, exit 0 (the suite has no build). No overlap lines.


## Log

- 2026-11-15 — round 1: Tasks 1-10 built and reviewed, final review and one fix wave; VS Code finding commented on #96 · cost: 137m · sonnet-5-5 1M in + 40.9M cached / 193k out
- 2026-11-15 — round 2: F1 and F2 fixed (send-back from qc.md round 1) · cost: 24m · sonnet-5-5 140k in + 5.9M cached / 28k out
- 2026-11-15 — round 3: merged main (#105) and resolved CHANGELOG.md (send-back from close.md round 1) · cost: 0m · sonnet-5-5 14k in + 881k cached / 2k out
