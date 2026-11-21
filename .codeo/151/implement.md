# Issue #151 — implement

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/151 |
| Branch | `docs/install-codeo-one-command-document` |
| Updated | 2026-11-21 |

## Where this stands

Round 2 done: Tasks 1-5 of the round-2 plan are built and reviewed, the final review's findings are fixed, and `## Outcome` has its round. Open: acceptance criterion 6 (the trust-prompt check) is the engineer's, recorded in the pull request at `/codeo:close`. The hand-off is `/codeo:qc`.

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

## Log

- 2026-11-21 — Q1 raised (overlap with #149 on CHANGELOG.md) · cost: 7m · sonnet-5-5 12k in + 671k cached / 2k out
- 2026-11-21 — Q1 answered; round 1: Tasks 1-7 implemented and reviewed, final review and one fix wave · cost: 113m · sonnet-5-5 1.1M in + 29M cached / 225k out
- 2026-11-21 — round 2 (after plan.md round 2): Tasks 1-5 implemented and reviewed, final review and one fix wave · cost: 30m · sonnet-5-5 330k in + 16.3M cached / 58k out
