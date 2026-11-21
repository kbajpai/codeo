# Issue #151 — qc

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/151 |
| Branch | `docs/install-codeo-one-command-document` |
| Updated | 2026-11-21 |

## Where this stands

Round 1 done: Q1-Q2 answered, the pass ran to the end, and the verdict is back to `/codeo:plan` (F1: a run at one scope silently rewrites the other, a design choice the plan did not make; F2-F3: the README's *Uninstalling* section states things `claude` contradicts). Criterion 6 stays the engineer's check at `/codeo:close`.

## Questions

### Q1 — #138 also changes `CHANGELOG.md`: proceed, sequence, or re-scope?

**Why it matters:** `overlap.sh 151` printed `138	CHANGELOG.md` and `138	glob:CHANGELOG.md`. #138 has since reached `implement` and its branch already changes `CHANGELOG.md`; this branch adds one bullet under `## Unreleased` there. Whichever merges second will meet a conflict in that one file. Sequencing would hold this change until #138 merges; proceeding changes nothing here.
**The other workflow:** #138, branch `fix/live-session-signal-does-not`, assignee kbajpai, step `implement` (working), waiting on its own `qc.md` Q1-Q3. Its footprint also names `.claude/settings.json`, `scripts/live.sh`, `skills/triage/SKILL.md`, `docs/handoff.md` and tests; this branch changes none of them. The only shared path is `CHANGELOG.md`.
**Options:**
- *Proceed and coordinate* (recommended). The same answer #149 got in `implement.md` Q1: this branch's bullet is its own new bullet and touches no other line, so the branch that merges second rebases and keeps both.
- *Sequence after #138.* Hold this change until #138 has merged, then rebase.
- *Re-scope.* Drop the changelog bullet; acceptance criterion 10 would then not be met.

**Answer:**
Proceed and coordinate (engineer, in the conversation, 2026-11-21).

### Q2 — Criterion 6 (Claude Code offers the install when the folder is trusted): run it now, or let `/codeo:close` record it in the pull request?

**Why it matters:** the criterion reads "shown on a clean machine, with the result recorded in the PR". Only you can run it (it is interactive: plan Task 8, Step 2), and `implement.md` records that nobody has yet. It decides whether this round's verdict can be clear: a criterion marked `not yet checkable` is not a pass, but its evidence can only land in a pull request, which does not exist until `/codeo:close`.
**How to run it** (in this container's terminal, bash): `d=$(mktemp -d) && cd "$d" && git init -q && CLAUDE_CONFIG_DIR=$(mktemp -d) bash /workspaces/codeo-151/install.sh --scope project`, then `CLAUDE_CONFIG_DIR=$(mktemp -d) claude` in the same folder, trust it when asked, and note what Claude Code offers.
**Options:**
- *Run it now and answer here with what you saw* (recommended). This round then settles criterion 6 as met or not met, and `/codeo:close` copies your answer into the pull request.
- *Treat it as a close-time check.* This round records criterion 6 as `not yet checkable — the engineer's check, recorded in the pull request at /codeo:close`, non-blocking, and the verdict can be clear; `/codeo:close` must not merge without it.
- *Not met.* If you already know it offers nothing, say so: that is a blocking finding, and its owner is decided from why.

**Answer:**
Treat it as a close-time check (engineer, in the conversation, 2026-11-21).

## Notes

- `sync-main.sh --abort-on-conflict`: `sync-main: the branch already contains origin/main` (exit 0).
- `overlap.sh --outside 151`: no output (no path outside the footprint).
- `scope.sh origin/main HEAD`: `suite.shell=true` (unclassified paths: `.codeo/151/*`, `CHANGELOG.md`, `CONTRIBUTING.md`, `README.md`, `install.sh`).
- No shared environment, no invariants file, no wiki module; the `invariants-extra` and `wiki-rules` overlays do not exist (exit 3).


## Outcome

### Round 1 — 2026-11-21

Q1 (#138 also changes `CHANGELOG.md`) answered *proceed and coordinate*; Q2 (criterion 6) answered *treat it as a close-time check*. `qc.md` Q1-Q2 are closed.

**Commands run this pass, and their output**
- `bash scripts/sync-main.sh --abort-on-conflict`: `sync-main: the branch already contains origin/main`.
- `bash scripts/overlap.sh 151`: no output after Q1 was answered. `bash scripts/overlap.sh --outside 151`: no output.
- `git diff origin/main...HEAD --stat`: 10 files changed, 2224 insertions(+), 44 deletions(-) (`install.sh`, `tests/install.test.sh`, `README.md`, `CONTRIBUTING.md`, `CHANGELOG.md`, the plan and the `.codeo/151/` dossiers).
- `bash scripts/scope.sh origin/main HEAD`: `suite.shell=true` (stderr: `scope: suite shell needed for unclassified paths: … CHANGELOG.md, CONTRIBUTING.md, README.md, install.sh`).
- Build: the `shell` suite's `build` is `true`; exit 0.
- Tests: `bash tests/run.sh` ended `all cases passed`, exit 0 (the whole `shell` suite, run once on this tree).
- Moved text, diffed against `origin/main:README.md` for each of `## Tests`, `## Checking a dossier`, `## Replaying finished dossiers` and `## Dev container`: identical (four `same:` lines, no diff output).
- Real `install.sh` runs, no tools on `PATH`, `CODEO_TEST_BASH_VERSION=3.2`: `install: bash 4.3 or later is required (found 3.2)`, then `jq`, `git`, `gh`, `claude (Claude Code)` each `is not installed`, then `install: nothing was installed. Install the tools above with your system's package manager, then run this again.`, exit 1. `--scope team`: `install: malformed scope: team (want user or project)`, usage line, exit 2. `--version v9.9.9`: `install: release v9.9.9 not found in kbajpai/codeo`, exit 1.
- Reproduced for the reviewer's findings (real `claude` 2.1.325, throwaway `CLAUDE_CONFIG_DIR`, a scratch git repository with a committed project-scope install at v1.0.6): plain `bash install.sh` inside it printed `install: codeo v1.0.6 -> v1.0.7 (user scope)`, and afterwards ` M .claude/settings.json` with `"ref":"v1.0.7"`; `claude plugin uninstall codeo@codeo` (no scope) printed `✘ Failed to uninstall plugin "codeo@codeo": Plugin "codeo@codeo" is enabled at project scope (.claude/settings.json, shared with your team). To disable just for you: claude plugin disable codeo@codeo --scope local`; `claude plugin marketplace remove codeo` run inside the project printed `✔ Successfully removed marketplace: codeo`, `Also uninstalled 1 plugin from this marketplace:`, `  codeo@codeo`, and left ` M .claude/settings.json` with `{"enabledPlugins":{"superpowers@superpowers-marketplace":true},"extraKnownMarketplaces":{"superpowers-marketplace":{…}}}`.
- Independent review (opus): ran `install.sh` against throwaway configurations for fresh, re-run, replace, project, subfolder and project-replace cases; its report is quoted by finding below.

**Acceptance criteria**

| Criterion | Verdict | Settled by |
|---|---|---|
| 1. One command, shown in the README, installs codeo and `superpowers`; `claude plugin list` shows both enabled | met | `t_fresh_user_install`, `t_readme_install_command_runs`; the reviewer's real fresh run printed the README's block and `claude plugin list` showed both `✔ enabled` |
| 2. Run again at the same version: nothing changes, and it says so | met | `t_rerun_changes_nothing`, `t_project_rerun_changes_nothing`; real re-run `install: nothing changed - codeo v1.0.7, user scope, superpowers 7.0.2` |
| 3. A release tag installs that tag; none installs the latest; the version is printed | met | `t_given_tag_installed`, `t_latest_is_highest_release`, `t_bare_version_gets_v`, `t_missing_tag_stops`; real `--version v9.9.9` and `1.0.6` runs |
| 4. Default scope user; project scope installs there and the command says which scope it used | met — but see F1: a run at one scope also rewrites the other | `t_default_scope_is_user`, `t_project_scope_installs_both`; summary lines name `user scope` / `project scope` |
| 5. Old bash, or `jq`, `git`, `gh` missing: each named, no system package, exit non-zero | met | `t_old_bash`, `t_missing_each`, `t_all_missing_named_together`, `t_no_system_package_installed`; real run above (exit 1) |
| 6. A project that commits the README's snippet is offered the install when its folder is trusted | not yet checkable — the engineer's check, to be recorded in the pull request at `/codeo:close` (Q2); the snippet itself equals a real project-scope run's `.claude/settings.json` under `jq -S` | the reviewer's real run; no test models `.claude/settings.json` (F4) |
| 7. README has the eight sections, and each command in them was run and its output matches | not met — F2 and F3 | `t_readme_sections` (headings: Requirements, Installing, Setting a project up, Your first workflow, The skills, Updating, Uninstalling, Troubleshooting, Contributing); the *Uninstalling* section quotes an error `claude` does not print, shows a truncated `marketplace remove` output, and says no command touches a project's settings |
| 8. README no longer holds the test, dossier-checker or replay sections; the contributor page holds them unchanged; the README links to it | met | the four diffs above (identical); `README.md` `## Contributing` links `CONTRIBUTING.md` |
| 9. Tests cover the behaviour and run in `bash tests/run.sh`, which ends `all cases passed`; a test fails when the README's install command and the script disagree | met | the full run above; `t_readme_install_command_runs` serves only the `main/install.sh` URL and runs every README `curl` line |
| 10. CHANGELOG entry states the config schema, whether the shared state changed, and whether it is safe to bump mid-workflow | met | `CHANGELOG.md` `## Unreleased` has `Config schema: 1`, `Shared state: …`, `Safe to bump mid-workflow: yes`, and the new bullet states that nothing under `scripts/`, `lib/`, `hooks/` or `skills/` changes (F8 on its wording) |

**Documentation check.** `README.md` and `CONTRIBUTING.md` are the pages the plan names, and no other page describes installing the plugin (no link to a removed README section exists elsewhere). The README has no issue numbers and no test hooks. Its *Uninstalling* and *Updating* sections state things the code and `claude` contradict: F2, F3.

**Findings**

- **F1 — blocking, `/codeo:plan`'s.** A run at one scope silently rewrites the other (`install.sh` `replace_codeo`). Run from inside a team repository that has a committed project-scope install at an older tag, a plain `install.sh` (user scope) bumps that repository's tracked `.claude/settings.json` ref and says only `(user scope)` (reproduced above); a `--scope project` run when the user's own codeo is at another version also replaces the user's copy and says only `(project scope)` (reviewer, reproduced). The code does what the plan says (plan Global Constraints, *Replace on a different version*: reinstall where it was, this project's scope included); the plan did not weigh that consequence, and the alternatives are design choices (replace only the requested scope and say what else was touched; leave a project's pin alone unless `--scope project` was asked; ask first). `t_replace_reinstalls_where_it_was` encodes the current behaviour as intended.
- **F2 — blocking, `/codeo:implement`'s (the plan asked for true README text).** README *Uninstalling*: (a) the quoted error for `claude plugin uninstall codeo@codeo` without `--scope project` is not what 2.1.325 prints (real text above); (b) the section says neither command touches a project, but `claude plugin marketplace remove codeo` inside a project that declares codeo empties that project's `enabledPlugins` and `extraKnownMarketplaces` (reproduced), and `uninstall --scope project` removes `codeo@codeo` from the project's `enabledPlugins`, so "settings still declares both" is false for that path.
- **F3 — blocking, `/codeo:implement`'s.** README *Uninstalling*: the `marketplace remove` block shows only `✔ Successfully removed marketplace: codeo`; when codeo is installed, the real output adds `Also uninstalled 1 plugin from this marketplace:` and its lines (above).
- **F4 — non-blocking, `/codeo:implement`'s.** `tests/install.test.sh` stub `claude` models no `.claude/settings.json`: a project-scope `marketplace add` of a known marketplace is a no-op whatever the ref, and `marketplace remove` strips nothing from a project's settings, so no test checks what project scope writes or the README's snippet. Criteria 4 and 6 rest on the manual runs. It matters for fixing F1.
- **F5 — non-blocking, `/codeo:implement`'s.** README *Updating* says the installer prints `codeo is no longer installed` "and the line to run again"; `install.sh` prints `…; run this again` and no command line.
- **F6 — non-blocking, `/codeo:implement`'s.** Failure messages can mislead: if reinstalling the second scope fails during a replace, the message says codeo is no longer installed although the first scope was reinstalled; any `ls-remote` exit other than 0, 124 or 128 for a given tag is reported as `not found`.
- **F7 — non-blocking, `/codeo:plan`'s.** The idempotence test compares the installed `plugin.json` version with the tag, true for v1.0.5-v1.0.7 but not guaranteed for a tag whose `plugin.json` was not bumped (every re-run would then replace); and "latest release" is the highest `vX.Y.Z` tag, not the latest GitHub Release.
- **F8 — non-blocking, `/codeo:implement`'s.** The changelog bullet says another version or source "is replaced" without saying that a replace removes the marketplace, which uninstalls codeo at every scope, including other projects' installs that are not reinstalled (the README says so). The `Shared state:` header line was written for earlier changes and says nothing about this one.
- **F9 — non-blocking, `/codeo:implement`'s.** Tests weaker than they read: `t_readme_install_command_runs` accepts any output containing `done -` or `nothing changed -`, so the README's captured output blocks can drift from the script's strings unchecked; the bash 3.2 head is covered by inspection only (`CODEO_TEST_BASH_VERSION` fakes the number), and the hook stays honoured in the shipped script.
- Carried from `implement.md`'s `## Notes`, not re-raised: the silent 10-second gap during a first install; `claude_step`'s temporary files on Ctrl-C; README sample outputs naming `v1.0.7`; the README text with no captured run behind it.

**Routing.** F1 needs a design decision the plan did not make, so this round goes back to `/codeo:plan`. The plan round should settle F1's behaviour with the engineer and carry F2-F6, F8 and F9 as tasks, since F4 is what makes F1's fix testable and F2-F3 change the same README section. Criterion 6 stays the engineer's check at `/codeo:close`.

**Verdict: back to `/codeo:plan`.**

## Log

- 2026-11-21 — Q1-Q2 raised (overlap with #138 on CHANGELOG.md; criterion 6 is the engineer's) · cost: 0m · opus-5-5 290k in + 333k cached / 1k out
- 2026-11-21 — Q1-Q2 answered; round 1: build, suite, criteria, documentation, independent review · cost: 39m · opus-5-5 413k in + 3.2M cached / 31k out · sonnet-5-5 36k in + 3.8M cached / 15k out
