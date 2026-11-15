# Issue #96 — implement

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/96 |
| Branch | `feat/dev-container-follow-ups-40` |
| Updated | 2026-11-15 |

## Where this stands

Round 1 done: Tasks 1-10 of `docs/plans/2026-11-15-dev-container-follow-ups-96.md` are built and committed, the build passes, and the next step is `/codeo:qc`. Task 11's step 3 (the v1.0.6 Release edit) is the engineer's, and its step 2 (filing the login-persistence issue) is still to do.

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

## Log

- 2026-11-15 — round 1: Tasks 1-10 built and reviewed, final review and one fix wave; VS Code finding commented on #96 · cost: 137m · sonnet-5-5 1M in + 40.9M cached / 193k out
