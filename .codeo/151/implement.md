# Issue #151 — implement

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/151 |
| Branch | `docs/install-codeo-one-command-document` |
| Updated | 2026-11-21 |

## Where this stands

Round 4 done: Tasks 1-5 of the round-4 plan are built and reviewed, the final review's one finding is fixed, and `## Outcome` has its round. Open: acceptance criterion 6 (the trust-prompt check) is the engineer's, recorded in the pull request at `/codeo:close`. The hand-off is `/codeo:qc`.

## Questions

### Q1 — #149 also edits `CHANGELOG.md`: proceed, sequence, or re-scope?

**Why it matters:** `overlap.sh` printed `149	glob:CHANGELOG.md`. Both branches add a bullet under `## Unreleased` (this plan's Task 7), so whichever merges second hits a conflict in that one file. Sequencing changes when Task 7 runs; proceeding changes nothing here.
**The other workflow:** #149, branch `fix/close-non-blocking-findings-143`, assignee kbajpai, step `plan` (working), waiting for `/codeo:implement`, nothing changed on its branch yet. Its footprint also names `.devcontainer/README.md` and `.sbx/README.md`; this plan changes neither. The only shared path is `CHANGELOG.md`.
**Options:**
- *Proceed and coordinate* (recommended). This plan adds one new bullet under `## Unreleased`, touches no other line there, and the branch that merges second rebases onto the other's bullet and keeps both. Task 7 is last in this plan, so the conflict, if any, is one file at the very end.
- *Sequence after #149.* Task 7 waits until #149 has merged, so the changelog is edited once on top of it. Costs waiting on a workflow that has not started implementing.
- *Re-scope.* Drop Task 7 and write the changelog bullet in a later change. The acceptance criteria require the entry, so this would leave one open.

**Answer:**
Proceed and coordinate (engineer, in the conversation, 2026-11-21).

## Notes

**Real-run evidence** (Claude Code 2.1.325, throwaway `CLAUDE_CONFIG_DIR`, never the real configuration):
- `cat install.sh | bash` on an empty configuration installed both plugins (`install: done - codeo v1.0.7, user scope, superpowers 7.0.2`, exit 0); `claude plugin list` showed `codeo@codeo` 1.0.7 and `superpowers@superpowers-marketplace` 7.0.2, both user scope, `✔ enabled`. A second run printed `install: nothing changed - codeo v1.0.7, user scope, superpowers 7.0.2`.
- `--version v1.0.6` printed `install: codeo v1.0.7 -> v1.0.6 (user scope)`; a bare run moved it back to `v1.0.7`.
- `--scope project` in a scratch git repository wrote a `.claude/settings.json` equal, under `jq -S`, to the README's JSON snippet.
- After the fix wave, a fresh run and a re-run were diffed against README lines 26-44 and 50-53: identical. The implementer diffed the replace, project and `claude plugin list` blocks too.

**Two behaviours found while capturing README output** (both documented in the README): `claude plugin uninstall codeo@codeo` fails for a project-scope install unless `--scope project` is given, and `claude plugin marketplace remove` leaves the declarations in a project's `.claude/settings.json`.

**README text with no captured run behind it** (taken from `scripts/doctor.sh`'s own messages): the `gh-scopes` fix, the `priority-labels` message, the `deps` and `overlays` entries, and the `uninstall superpowers --scope project` form.

**Parked at the end (no second fix wave):** a successful `claude` add or install is replayed after the call, so a slow clone shows nothing for about 10 seconds and no `install:` line says it is working; `claude_step`'s temporary files are not removed on Ctrl-C; the replace path's add and install show no output on success; the README's sample outputs name `v1.0.7` and will go stale; the Troubleshooting entry for `gh-scopes` omits doctor's "no working login" message.

**Still open, the engineer's:** acceptance criterion 6 (Claude Code offers the install when a folder holding the snippet is trusted). Plan Task 8, Step 2: in a new empty git repository, `bash <checkout>/install.sh --scope project` against an empty `CLAUDE_CONFIG_DIR` produces `.claude/settings.json`; then start `claude` under a third empty configuration directory in that repository, trust the folder, and paste what Claude Code offers into the pull request. Nothing is recorded for it yet.

## Outcome

**Built, all seven code and documentation tasks of `docs/plans/2026-11-21-install-one-command-151.md`, each through an implementer and a task review, then a whole-branch review and one fix wave with a scoped re-review:**
- `install.sh` (root) with `--version vX.Y.Z` and `--scope user|project`: a bash-3.2-parsable prerequisite check (bash 4.3+, jq, git, gh, claude; every missing one named in one run; no system package installed), release resolution (a given tag checked with `git ls-remote`, else the highest `vX.Y.Z`), user- and project-scope install of `superpowers` and codeo, a no-op that says `nothing changed`, replacement of another version or source (tag verified first; the marketplace is removed from `$HOME`; codeo is reinstalled where it was), enabling of a disabled plugin, and `install:` failure lines including `codeo is no longer installed … run this again`.
- `tests/install.test.sh`, run by `bash tests/run.sh install` and by the full suite, with a stub `claude`, `git`, `gh` and package managers. It includes the README tests: every README `curl … install.sh` line is run against the checkout's script, so a README that disagrees with the script fails.
- `README.md` rewritten for adopters (Requirements, Installing, Setting a project up, Your first workflow, The skills, Updating, Uninstalling, Troubleshooting, Contributing); `CONTRIBUTING.md` holds *Dev container*, *Tests*, *Checking a dossier* and *Replaying finished dossiers*, the last three unchanged (diffed against `origin/main`).
- `CHANGELOG.md`: one new bullet under `## Unreleased`, added as its own bullet so the branch that merges second keeps both (Q1: #149 also edits that file). The header lines (`Config schema: 1`, `Shared state`, `Safe to bump mid-workflow: yes`) are unchanged.

**Documentation pages changed:** `README.md` and `CONTRIBUTING.md` (Task 6), `CHANGELOG.md` (Task 7), as the plan names. No page outside the plan was written.

**Build result:** the `shell` suite's `build` command is `true`; it exited 0. The full `bash tests/run.sh` ended `all cases passed` (exit 0) at the last implementer commit, which changed nothing after it.

**Deviations from the plan:**
- The prerequisite check runs before option parsing, because the bash-version check has to be the first command; with a tool missing, `--help` or a bad option reports the missing tool and exits 1.
- Q1 was answered *proceed and coordinate*; `overlap.sh` had printed `149 glob:CHANGELOG.md`.
- Task 6 found and documented the two behaviours above; the README's *Uninstalling* section says to pass `--scope project`.
- The final review's two Important findings (a replace from a subdirectory did not restore the project install; `marketplace remove` ran in the project directory for `--scope project`) were fixed in the fix wave, with tests. The fix wave first hid `claude`'s own output on success, which made the README's captured blocks untrue; a second commit passes it through again and the blocks were diffed against real runs.
- `.codeo/config.json` is not changed, as the plan decided.

**Outstanding for `/codeo:qc` and the engineer:** acceptance criterion 6 (see `## Notes`); the parked items above; the README's text with no captured run.

No environment is configured, so nothing was leased, deployed or released.


### Round 2

2026-11-21
(after plan.md round 2)

**Built, all five tasks of `docs/plans/2026-11-21-install-one-command-151-round-2.md`, each through an implementer and a task review, then a whole-change review, one fix wave and its scoped re-review. This round answers `qc.md` round 1 (F1-F9) through the re-plan.**
- Task 1 (F4): the test stub `claude` models settings files: `marketplace add --scope project` writes `extraKnownMarketplaces` into the project's `.claude/settings.json`, a user-scope one into the user's; `install` sets `enabledPlugins`; `marketplace remove` strips codeo from the user's file and from `$PWD/.claude/settings.json` when run there. New cases: `t_project_scope_writes_the_readme_snippet`, `t_user_scope_declares_in_user_settings`, `t_remove_from_home_leaves_project_settings`.
- Task 2 (F1, F7; the engineer's Q7 answer): a replace writes only the asked scope. A user-scope run never passes `--scope project`, leaves the project's `.claude/settings.json` untouched and prints `install: this project's own codeo (project scope, vX) is no longer installed on this machine; its .claude/settings.json was not changed` when this project had its own install; a `--scope project` replace rewrites the project's pin and, when a user copy existed, reinstalls it and prints `install: your user-scope codeo moved to vX too: one machine holds one codeo version`. The marketplace is declared at the asked scope before every install. "Already installed" goes by the marketplace pin plus an entry at the asked scope; the entry's version string is not compared, and the only replace trigger is a pin at another ref or repo. The two round-1 cases that asserted the old behaviour (`t_replace_reinstalls_where_it_was`, `t_replace_from_subdirectory_restores_the_project`) were replaced by seven new ones.
- Task 3 (F6): failure lines say what is true: `codeo is no longer installed: <line>; run this again` (with `; run this again with --scope project, then once without --scope to restore your user-scope copy` when a `--scope project` run had wiped a user copy), and `codeo <tag> is installed at <done> scope but not at <s> scope: <line>; run this again with --scope <s>`; for a given tag only `git ls-remote` exit 2 is `release … not found`, any other failure is `cannot read the releases`.
- Task 4 (F2, F3, F5, F9): README *Updating* and *Uninstalling* rewritten from real captures against `claude` 2.1.325 (the real refusal text for `uninstall` without `--scope project`; the complete `marketplace remove` output; that `marketplace remove` run inside a project strips codeo from that project's `.claude/settings.json` and from outside it leaves the file alone; that `uninstall --scope project` removes `codeo@codeo` from the project's `enabledPlugins`); `t_readme_install_blocks_match_the_script` ties every README block's `install:` lines to the script's own output in stubbed scenarios.
- Task 5 (F8): this branch's one CHANGELOG bullet says what a replace removes and reinstalls; the final review's two wording corrections were applied in a fix commit (`8c0cc63`).

**Documentation pages changed:** `README.md` (Task 4) and the `CHANGELOG.md` bullet (Task 5), as the plan names. `CONTRIBUTING.md` and `docs/` are unchanged.

**Build result:** the `shell` suite's `build` is `true`; exit 0. The full `bash tests/run.sh` ended `all cases passed` (exit 0) at the fix commit; `qc` runs it again.

**Deviations from the plan:**
- Task 1's `marketplace remove` test hook: because the script runs the remove from `$HOME`, the stub cannot see the project file from its `$PWD`, so the test names the file in `$STUB_DIR/watch-settings` and the stub copies it to `$STUB_DIR/settings-at-remove` once the remove's own edits are done; a mutation check (running the remove inside the project) makes the test fail.
- Task 3 carries a Task 2 review finding the plan did not foresee: with a `--scope project` replace that wiped a user copy, a failing project step used to leave the user copy silently unrestored on retry; the failure lines now name every wiped scope and the command that restores it.
- The first Task 4 implementer died of an API authentication error part-way through; a second implementer kept its partial test edits and completed the task.

**Still open, the engineer's:** acceptance criterion 6 (the trust-prompt check), recorded in the pull request at `/codeo:close` (`qc.md` Q2). Parked, not fixed: "already installed" at project scope reads the machine's pin, not the project's own `.claude/settings.json`, so a project file pinning an older ref is reported `already installed`; the silent gap during a first install; `claude_step`'s temporary files on Ctrl-C; README samples naming `v1.0.7`; the README's *Updating* failure quotes come from the script and stubbed runs, not from real `claude` failures; only the `install:` lines of README blocks are tied to the script; `declare_marketplace` in the stub always rewrites through `jq`.

**Environment note:** between Tasks 3 and 4 the real `~/.claude/plugins` of this machine was reset (codeo and `superpowers` no longer installed there, the `superpowers` skill scripts gone); no subagent command touched the real configuration and the cause is unknown. The Task 4 review package was built with `git` directly.

### Round 3

2026-11-21
(after plan.md round 3)

**Built, all five tasks of `docs/plans/2026-11-21-install-one-command-151-round-3.md`, each through a sonnet implementer and a task review, then a whole-round review, one fix wave and one scoped re-review.**
- Task 1 (F10; `qc.md` Q3): after a replace, `install.sh` prints one line per project or local-scope codeo install it dropped (path, scope, version, the command that restores it), from `claude plugin list --json` read before the marketplace is removed; a project-scope run does not name its own project. A review ruling made a local line say `.claude/settings.local.json` (see Deviations). Commits `766caf8`, `1f94e21`.
- Task 2 (F16, F17): a disabled user-scope copy that a `--scope project` replace reinstalls is reported as enabled; `CODEO_TEST_BASH_VERSION` is honoured only as `<digits>.<digits>`; a test checks the head for bash-4-only syntax. Commit `7496d9a`.
- Task 3 (F18): one shared `plugin_list_json` helper feeds both readers of the list; a notice before or after the array, or a compact array, no longer aborts the run, and no JSON at all still dies with the `install:` line. Commit `96a9975`.
- Task 4 (F11-F15): README *Setting a project up*, *Installing*, *Your first workflow*, *Updating*, *Uninstalling* and *Troubleshooting* rewritten from real captures against `claude` 2.1.325 (the "offered again" claims removed; the dropped-install lines and their restore commands shown; the bare `uninstall` result with and without a user-scope copy; the highest-tag sentence; the hand-edited-`ref` entry). Two new stub scenarios and two tests tie the README to the script. Commit `b990804`.
- Task 5 (F11): this branch's CHANGELOG bullet names every dropped install and its restore command; its one clause was changed in Task 4's commit because the new README test also scans the CHANGELOG, so Task 5 needed no commit of its own.
- Fix wave `7f7d281`: README.md's remaining "offered them again" wording, the F12 entry's `--version <tag>` note, and two vacuous test checks.

**Real evidence gathered** (`claude` 2.1.325, scratch `HOME` and `CLAUDE_CONFIG_DIR`): `claude plugin list --json` run from `$HOME` lists other projects' project and local entries with `projectPath`; `install.sh --scope project` in a dropped project restores it (it installs the latest release and rewrites the pin `ref`, a git change to commit) and `claude plugin install codeo@codeo --scope local` restores a local install; the F12 sequence (hand-edited `ref`, `nothing changed`, `marketplace remove` from outside the project, `install.sh --scope project`) behaves as the README says. Commands and output are in the sdd reports for Task 4 and the fix wave.

**Documentation pages changed:** `README.md` (Task 4, fix wave) and the `CHANGELOG.md` bullet. `CONTRIBUTING.md` and `docs/` are unchanged.

**Build result:** the `shell` suite's `build` is `true`; exit 0. The full `bash tests/run.sh` ended `all cases passed` (exit 0) at `b990804` and again at the fix commit `7f7d281`; `qc` runs it again. `sync-main.sh` reported the branch already contains `origin/main`; `overlap.sh` printed nothing.

**Deviations from the plan:**
- A local-scope dropped line reads `its .claude/settings.local.json was not changed` where the plan's F10 text had `.claude/settings.json` for both scopes: a local install lives in `settings.local.json`. The plan's other text is unchanged.
- Task 1's proof could not pass alone: `t_readme_install_blocks_match_the_script` stays red until Task 4 re-captures the README (the plan's order); every other case was green at each step.
- The plan's Task 4 has Task 5's CHANGELOG clause change land in Task 4's commit (above).

**Still open, the engineer's:** acceptance criterion 6 (the trust-prompt check), recorded in the pull request at `/codeo:close` (`qc.md` Q2).

**Parked, not fixed (known limits for `qc` to weigh):**
- If a reinstall fails after the marketplace removal, the dropped-project lines are not printed and a re-run finds no pin to replace, so those projects are not named.
- A notice line that starts with `[` before the list's array makes the run die cleanly with the `install:` line.
- The projectPath comparison is a string compare, so a symlinked checkout could be named as dropped when it is the current project.
- The head-syntax test's banned list omits `${x^}`, `declare -n`, `;;&`, `[[ -R`, `read -i`; a missing `.version` would print `vnull`.
- The reviewer's three SIGINT failures were an artifact of running the suite as a background job; foreground runs ended `all cases passed`.

### Round 4

2026-11-22
(send-back from qc.md round 3)

**Built, all five tasks of `docs/plans/2026-11-22-install-one-command-151-round-4.md`, each through a sonnet implementer and a task review, then a whole-round review, one fix wave and one scoped re-review.** The plan file was uncommitted when this step started; it was committed (`df6bb40`) on your invocation of this step after you approved it.
- Task 1 (F19, F22): the restore line for a dropped project install is `claude plugin install codeo@codeo --scope project` (no `install.sh`; the local line is unchanged). Commit `869b2c5`.
- Task 2 (F21): a user-scope replace of a disabled user copy ends `(it was disabled; it is enabled now)`. Commit `4e31dd3`.
- Task 3 (F20): a failed replace prints the dropped-install lines (stdout) before the `install: codeo is no longer installed: …; run this again` error (stderr); on a project-scope run whose project was not yet reinstalled the current project is named too. `dropped_installs` takes `skip_own`; `replace_failed` takes the list as a fifth argument. Commit `06a1924`.
- Task 4 (F23): argument parsing (`usage_text`, `usage`, `parse_args`) moved into the bash-3.2-safe head, before the prerequisite check, so a usage error exits 2 and `--help` exits 0 when `jq` or `gh` is missing. See Deviations for the version check. Commit `76f9aab`.
- Task 5 (F19-F22 docs): README *Updating*, *Uninstalling* and the sample blocks rewritten from real captures; two new stub scenarios (`user-replace-disabled`, `replace-add-fails-with-drops`), `t_readme_restore_blocks_do_not_replace`, and a stricter `t_readme_names_the_restore_command`; the CHANGELOG bullet reworded. Commit `6f8b572`; a task-review fix (a fused scenario name in `fail_names` had silently dropped one scenario from the README comparison; a `norm_block` helper) in `82d6801`.
- Final-review fix wave `64a4d4f`: the README (and the CHANGELOG bullet) said a separate `install.sh --scope project` run moves a project's pin; after the printed restore it prints `nothing changed` and leaves the `ref` alone (reproduced). They now say a `--scope project` run rewrites the `ref` only when it installs or replaces codeo at project scope, and that a restored project's pin moves by editing `ref` and committing, as the end of *Updating* says. The scoped re-review marked it ADDRESSED.

**Real evidence gathered** (`claude` 2.1.325, scratch `HOME` and `CLAUDE_CONFIG_DIR`, scratch repositories deleted afterwards): (a) a project pinned at v1.0.7 with the machine downgraded to v1.0.6 by `install.sh --version v1.0.6` from `$HOME`, which printed `install: codeo is no longer installed for <app> (project scope, v1.0.7); … run claude plugin install codeo@codeo --scope project there to restore it`; the printed command in the project gave `✔ Successfully installed plugin: codeo@codeo (scope: project)`, `claude plugin list --json` listed user 1.0.6 and project 1.0.6, `git status --short` was empty and the `ref` stayed v1.0.7. (b) the same with a project pinned at v1.0.6 and the machine updated to v1.0.7: user 1.0.7, project 1.0.7, `git status --short` empty, `ref` still v1.0.6. (c) a `claude` wrapper failing only `plugin marketplace add kbajpai/codeo@*`, two projects and one local install dropped: stdout held the three dropped lines, stderr `install: codeo is no longer installed: Error: network unreachable; run this again`, exit 1; the re-run finished with exit 0 and the project restore command then worked with `git status` empty. The reviewers' own runs reproduced F19-F23's fixes with real `claude` (downgrade and update cases, a disabled copy in both directions, the failed replace at user and project scope, `--help` and `--bogus` with only a `bash` symlink on `PATH`). Commands and output are in the sdd reports for Task 5, the review fix and the final review.

**Documentation pages changed:** `README.md` (Task 5, the fix wave) and the `CHANGELOG.md` bullet. `CONTRIBUTING.md` and `docs/` are unchanged.

**Build result:** the `shell` suite's `build` is `true`; exit 0. The full `bash tests/run.sh`, run in the foreground by this session at `82d6801`, ended `all cases passed` (5m53s); the implementer's full run at `64a4d4f` ended `all cases passed` too. `qc` runs it again. `sync-main.sh` at the start of the round reported the branch already contains `origin/main`; `origin/main` has moved since (#138's pull request), so `qc` will merge it. `overlap.sh` printed nothing.

**Deviations from the plan:**
- Task 4: the plan said to keep the version regex in a variable and test it with `[[ $2 =~ $re ]]`; `t_head_uses_no_bash4_syntax` bans `=~` in the head (it greps for `\[\[.*=~`), so the implementer used `printf '%s\n' "$2" | grep -Eq "$version_re"`. One edge differs: a `--version` value with an embedded newline whose first line is a valid version is now accepted, then fails at the tag lookup with exit 1 and a two-line message instead of exit 2.
- Task 5 added a comparison helper (`norm_block`) and a comment in the test, which the review asked for; it also normalises the failure message in the README block comparison (the stub prints its own error text where a real `claude` prints another), a narrow mask anchored on `is no longer installed: ` and `; run this again`.
- Tasks 1-4's proofs ran only the install cases, per the plan's red and green steps; the full suite ran twice afterwards (above).

**Still open, the engineer's:** acceptance criterion 6 (the trust-prompt check), recorded in the pull request at `/codeo:close` (`qc.md` Q2).

**Parked, not fixed (known limits for `qc` to weigh):**
- The deferred Minors from the task reviews, each triaged "leave" by the final review: no test for a user-scope replace with no existing user copy; `t_failure_before_the_remove_names_nothing` may stop at an earlier `plugin list` call and not exercise the new ordering; the project-scope failure test does not assert stderr or that the error is last; the dropped-lines print loop is duplicated in `replace_failed`; no test for a usage error under `CODEO_TEST_BASH_VERSION=3.2` (the reviewer checked it by hand: exit 2); a missing `grep` prints `grep: command not found` before the usage error (exit 2 still).
- The dropped-install lines of a failed replace give a command that fails until the re-run succeeds, because the marketplace is gone; the README says so, the lines do not.
- Round 3's parked limits stand unchanged: a notice line that starts with `[` before the plugin list's array; the projectPath string compare for a symlinked checkout; gaps in the head-syntax test's banned list; a missing `.version` printing `vnull`.

## Log

- 2026-11-21 — Q1 raised (overlap with #149 on CHANGELOG.md) · cost: 7m · sonnet-5-5 12k in + 671k cached / 2k out
- 2026-11-21 — Q1 answered; round 1: Tasks 1-7 implemented and reviewed, final review and one fix wave · cost: 113m · sonnet-5-5 1.1M in + 29M cached / 225k out
- 2026-11-21 — round 2 (after plan.md round 2): Tasks 1-5 implemented and reviewed, final review and one fix wave · cost: 30m · sonnet-5-5 330k in + 16.3M cached / 58k out
- 2026-11-21 — round 3 (after plan.md round 3): Tasks 1-5 implemented and reviewed, final review, one fix wave and a scoped re-review · cost: 74m · sonnet-5-5 690k in + 22.2M cached / 121k out
- 2026-11-22 — round 4 (send-back from qc.md round 3): Tasks 1-5 implemented and reviewed, final review, one fix wave and a scoped re-review · cost: 47m · opus-5-5 224k in + 275k cached / 844 out · sonnet-5-5 681k in + 22.2M cached / 99k out
