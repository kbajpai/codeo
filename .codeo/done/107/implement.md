# Issue #107 — implement

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/107 |
| Branch | `feat/dev-container-follow-ups-96` |
| Updated | 2026-11-16 |

## Where this stands

Round 1 is built: all nine tasks of `docs/plans/2026-11-15-dev-container-follow-ups-107.md` are done and reviewed, the build command exits 0 and the whole suite passes. Nothing is open. The next step is `/codeo:qc`.

## Questions

None.

## Notes

Nothing here was a question for the engineer; the rulings made while building are in the outcome.

## Outcome

2026-11-16

**Built.** Eight commits on top of the merge of `origin/main` (5c043a2), one per task except Tasks 7 and 9, which write no code:

| Task | Commit | What |
|---|---|---|
| 1 | 0aca7eb | `docs_changelog_names_the_replay_sed_and_the_folder_limit` reads the whole `CHANGELOG.md`, so retitling `## Unreleased` cannot break it (F16) |
| 2 | 0708c1f | the lock-crash case counts occurrences (F5); `start_runs_claude_outside_the_clone` checks a marker file in the clone, not `git status` (F10); the title-failure case seeds `.vscode/settings.json` and checks it and the folder are untouched (F6) |
| 3 | c4fd6a4 | the growing-gitconfig case has no sleeps: a stub `stat` appends the next piece per settle-stamp read (F14); the interrupt case prints no `Terminated` line (F13); one SC2016 directive covers its line (F18); the header names `codeo-gh` and `codeo-git` (F12) |
| 4 | 9abacac | the bind-mount TODO says git is told to trust the clone only when the `safe.directory` add worked (F3); a failed `mktemp` puts its reason in the "could not be listed" TODO (F17); the EXIT trap runs `rm` only when a temp file exists (F15) |
| 5 | 51aecdb, c8d869f | a `core.fileMode` `false` from the command or worktree scope: one TODO naming the scope, no "overrides" line and no `ready`; the local `true` stays and the modes are restored (F4, Q1 option A). c8d869f tightens the scope-name assertion after the task review |
| 6 | ebed575 | `codeo-root.sh` reads registry fields with `join("\t")`, so a backslash matches; an empty or `false` `projectPath` counts as none (F7) |
| 7 | — | controller: the whole suite once, no `Terminated` line |
| 8 | 2300013 | `.devcontainer/README.md` (the `core.fileMode` bullet) and `CHANGELOG.md` (the #96 bullet: follow-up list, `docs/release-checklist.md` step 8, the `safe.directory` wording; one new #107 bullet) (F11) |
| 9 | — | controller: the `rm` check recorded on #107 (https://github.com/kbajpai/codeo/issues/107#issuecomment-6904097075) |

**Documentation pages changed:** `.devcontainer/README.md` and `CHANGELOG.md`, as the plan names. Nothing under `scripts/`, `lib/`, `hooks/` or `skills/` changed; six files changed in all (`.devcontainer/README.md`, `.devcontainer/scripts/codeo-root.sh`, `.devcontainer/scripts/devcontainer-start.sh`, `CHANGELOG.md`, `tests/codeo-root.test.sh`, `tests/devcontainer.test.sh`).

**Build.** The `shell` suite's `build` is `true`: exit 0. For information only (grading is `/codeo:qc`'s): `bash tests/run.sh` printed `all cases passed` (3m26s) after Task 6, and `bash tests/devcontainer.test.sh` printed only that line, with no `Terminated`. Each of F5, F6, F10 and F14 was shown red by a mutation in a scratch copy (reports under the git-ignored `.superpowers/sdd/`); the `core.fileMode` and `codeo-root` cases were shown red before their fixes.

**Base branch.** `sync-main.sh` merged `origin/main` (one commit, #109 / #70) cleanly and then exited 1 with `comm: file 2 is not in sorted order`, so its `also changed on main:` lines were lost. That is the locale bug #98 fixed in the repository's own `scripts/sync-main.sh`; the plugin copy this session runs is v1.0.6. A second run under `LC_ALL=C` said the branch already contains `origin/main`. Main's merge touched `.devcontainer/README.md` and `CHANGELOG.md`, which Task 8 edits; both merged without conflict, and Task 8 was written on top of the merged text. `overlap.sh 107` printed nothing before and after.

**Deviations from the plan, and rulings** (each stays a one-line ruling, none changed what gets built):
- Task 1's second mutation uses `/(#52)\.$/`, not `/(#52)$/`: the bullet ends `(#52).`, so the plan's pattern matches nothing. A proof command only.
- Task 2's F6 mutation line is guarded (`[[ ! -d "$root/.vscode" ]] || : > "$root/.vscode/.settings.leak"`): unguarded it aborts other cases under `set -e` when `.vscode` does not exist. A proof command only.
- Task 8's new bullet is appended at the end of the `## Unreleased` bullets, not "at the top": older bullets come first there.
- Tasks 7 and 9 were run by the controller, not dispatched, since they write no code.
- Every dispatch, the whole-branch review included, ran on `sonnet` (`models.subagent`), not "the most capable available model" as the sub-skill suggests; `/codeo:qc` runs its own independent review.
- The plan file was committed (366289a) at the start of the round, on the engineer's yes, as step 2 requires.
- Task 9's comment records that `rm` here is GNU `rm` 9.7 (`/usr/bin/gnurm`) and that the literal `rm -f -- ""` was not run; the engineer pasted no output.

**Accepted Minor findings** (nothing blocking): the new `start_trap_never_runs_rm_with_an_empty_operand` passes even if its stub `rm` is never reached (it fails against the old trap, as shown); `mktemp … 2>&1` would fold a warning printed on success into the file name; the whole-file greps of the changelog test are weaker than the section-scoped ones, as the plan prescribed; the F6 case compares `ls -A` output as a string; the new CHANGELOG bullet's finding labels (F3 …) are resolvable only through `.codeo/done/96/qc.md`.

## Log

- 2026-11-16 — round 1: built the plan's nine tasks (8 commits, 2 tasks run by the controller); build exit 0; final whole-branch review clean (ready for qc); no `/codeo:issue` filed; the optional lease steps did not apply (no shared environment) · cost: 74m · sonnet-5-5 693k in + 22.8M cached / 112k out
