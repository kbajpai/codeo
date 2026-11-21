# Issue #151 — implement

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/151 |
| Branch | `docs/install-codeo-one-command-document` |
| Updated | 2026-11-21 |

## Where this stands

Round 1 done: Tasks 1-7 are built and reviewed, the final review's findings are fixed, and `## Outcome` is written. Open: acceptance criterion 6 (the trust-prompt check) is the engineer's, see `## Notes`. The hand-off is `/codeo:qc`.

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

## Log

- 2026-11-21 — Q1 raised (overlap with #149 on CHANGELOG.md) · cost: 7m · sonnet-5-5 12k in + 671k cached / 2k out
- 2026-11-21 — Q1 answered; round 1: Tasks 1-7 implemented and reviewed, final review and one fix wave · cost: 113m · sonnet-5-5 1.1M in + 29M cached / 225k out
