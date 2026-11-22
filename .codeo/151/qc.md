# Issue #151 — qc

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/151 |
| Branch | `docs/install-codeo-one-command-document` |
| Updated | 2026-11-21 |

## Where this stands

Round 3 done: no question was open, the pass ran to the end, and the verdict is back to `/codeo:plan` (F19: after a `--version` run, the restore command the installer prints undoes that choice and drops the other installs again). F10 and F11 are fixed; F20-F23 are non-blocking. Criterion 6 stays the engineer's check at `/codeo:close`.

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

### Q3 — A replace drops other projects' installs: say so, or leave it as documented (pass 2, reviewer findings 1 and 2)

**Why it matters:** it decides whether this round can be clear and which way it routes. Both points were reproduced with real `claude` 2.1.325 on a throwaway configuration, and neither is a bug in what round 2's plan asked for; the plan's own constraint says other projects' installs are not reinstalled. They are a surprise the plan did not weigh, in the same class as the one Q7 settled for the current project.
**What is there now:**
- *Silent for every project but the current one.* `claude plugin marketplace remove codeo` uninstalls codeo at every scope on the machine. The installer names the dropped install only when the run starts inside the project that owns it. Reproduced: codeo installed at project scope in project A, then a plain `install.sh` run from `~` printed `install: codeo v1.0.6 -> v1.0.7 (user scope)` and no line about project A, and `claude plugin list --json` afterwards shows project A's install gone. Running inside project B, or any `--scope project` run, drops project A's the same way.
- *An unverified claim in the docs.* `README.md` (*Setting a project up*, *Updating*, *Uninstalling*) and the CHANGELOG bullet say other projects' installs "are offered again by their own committed settings" when their folder is trusted. Nothing in this pass shows that. Reproduced: once the machine's codeo marketplace is at v1.0.7, `claude plugin marketplace add kbajpai/codeo@v1.0.6 --scope project` run in project A fails with `its source doesn't match its extraKnownMarketplaces entry in user or managed settings`; and a folder that was already trusted is not asked again.
**Options:**
- *Say so and correct the docs* (recommended). After a replace the installer prints one line per project-scope install it dropped, from `claude plugin list --json`'s `projectPath` (for example `install: codeo is no longer installed for /path/to/projectA (project scope, v1.0.6); run install.sh --scope project there to restore it`); the README and the CHANGELOG drop the "offered again" claim and say this instead. This is new installer behaviour the plan did not specify, so the round goes back to `/codeo:plan`.
- *Correct the docs only.* The installer is unchanged. The README and the CHANGELOG drop the "offered again" claim and say plainly that a replace drops every project's install on this machine, and that each is restored by running `install.sh --scope project` in it. The round goes back to `/codeo:implement`.
- *Leave it.* Both stay as documented, the unverified sentence included; recorded as non-blocking findings, and the verdict can be clear. I advise against it: the sentence is the only place an adopter is told what happens to their other projects, and the evidence points against it.

**Answer:**
Say so and correct the docs, as recommended (engineer, in the conversation, 2026-11-21).

## Notes

- `sync-main.sh --abort-on-conflict`: `sync-main: the branch already contains origin/main` (exit 0).
- `overlap.sh --outside 151`: no output (no path outside the footprint).
- `scope.sh origin/main HEAD`: `suite.shell=true` (unclassified paths: `.codeo/151/*`, `CHANGELOG.md`, `CONTRIBUTING.md`, `README.md`, `install.sh`).
- No shared environment, no invariants file, no wiki module; the `invariants-extra` and `wiki-rules` overlays do not exist (exit 3).


**Pass 2 (after the round-2 implementation), evidence so far** — the pass stopped at step 10 on Q3, so no round is written yet:
- `bash scripts/sync-main.sh --abort-on-conflict`: `sync-main: merged origin/main (1 commit(s))`, `sync-main: also changed on main: CHANGELOG.md` (the merge, `84de56a`, brought in #149's pull request; `CHANGELOG.md` has no conflict markers and this branch's bullet is intact). `overlap.sh 151` and `overlap.sh --outside 151`: no output. `scope.sh origin/main HEAD`: `suite.shell=true`. Build (`true`): exit 0. `bash tests/run.sh` on the merged tree: `all cases passed`, exit 0.
- Real runs by this pass (throwaway `CLAUDE_CONFIG_DIR`): fresh `install.sh` printed `install: done - codeo v1.0.7, user scope, superpowers 7.0.2` and a re-run `install: nothing changed - …`; a plain run from `proj/sub` with a committed project-scope install at v1.0.6 printed `install: codeo v1.0.6 -> v1.0.7 (user scope)` and `install: this project's own codeo (project scope, v1.0.6) is no longer installed on this machine; its .claude/settings.json was not changed`, with `git status --short` empty and the file still pinning v1.0.6 (F1 fixed); a `--scope project` run with a user copy at another tag printed the moved line; `claude plugin uninstall codeo@codeo` without `--scope` printed the refusal the README quotes.
- Moved README sections: `Tests`, `Checking a dossier`, `Replaying finished dossiers` and `Dev container` are byte-identical in `CONTRIBUTING.md` (four `same:` lines against `origin/main:README.md`).
- Independent review (opus): criteria 1-5 and 8-10 met, 6 correct only when the teammate has no codeo at another tag yet (the README's *Troubleshooting* already covers the source-mismatch error), 7 met with exceptions; its Important findings 1 and 2 are Q3. Findings it rated Minor, to classify when the round is written: the installed check ignores the project's own pin; `README.md` says `claude` refuses a bare `uninstall` in a project, which holds only without a user-scope copy (with both, the user copy is uninstalled); *Your first workflow* does not name the dossier it quotes; "latest release" is the highest tag, not a GitHub release; a replace re-enables a user copy that was disabled; `CODEO_TEST_BASH_VERSION` is honoured in production; no check of the bash 3.2 head beyond the version number; a non-JSON line from `claude plugin list --json` aborts without an `install:` line.

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


### Round 2 — 2026-11-21

Q3 (what a replace does to other projects' installs) answered *say so and correct the docs*, so this round goes back to `/codeo:plan`. `qc.md` Q1-Q3 are closed.

**Commands run this pass, and their output**
- `bash scripts/sync-main.sh --abort-on-conflict`: `sync-main: merged origin/main (1 commit(s))`, `sync-main: also changed on main: CHANGELOG.md`. The merge (`84de56a`) brought in the pull request for #149; `CHANGELOG.md` has no conflict markers and this branch's bullet is intact (re-checked against the other change).
- `bash scripts/overlap.sh 151` and `bash scripts/overlap.sh --outside 151`: no output.
- `bash scripts/scope.sh origin/main HEAD`: `suite.shell=true` (unclassified paths: `.codeo/151/*`, `CHANGELOG.md`, `CONTRIBUTING.md`, `README.md`, `install.sh`).
- Build: the `shell` suite's `build` is `true`; exit 0. Tests: `bash tests/run.sh` on the merged tree ended `all cases passed`, exit 0.
- Moved text against `git show origin/main:README.md`: `same: Tests`, `same: Checking a dossier`, `same: Replaying finished dossiers`, `same: Dev container`.
- Real `install.sh` runs (claude 2.1.325, throwaway `CLAUDE_CONFIG_DIR`): fresh `install: done - codeo v1.0.7, user scope, superpowers 7.0.2`, re-run `install: nothing changed - codeo v1.0.7, user scope, superpowers 7.0.2`; a plain run from `proj/sub` with a committed project-scope install at v1.0.6: `install: codeo v1.0.6 -> v1.0.7 (user scope)`, `install: this project's own codeo (project scope, v1.0.6) is no longer installed on this machine; its .claude/settings.json was not changed`, `git status --short` empty, the file still pinning `v1.0.6`; a `--scope project` run with a user copy at another tag: `install: codeo v1.0.7 -> v1.0.6 (project scope)`, `install: your user-scope codeo moved to v1.0.6 too: one machine holds one codeo version`; `claude plugin uninstall codeo@codeo` without `--scope` in a project with only a project-scope install: `✘ Failed to uninstall plugin "codeo@codeo": Plugin "codeo@codeo" is enabled at project scope (.claude/settings.json, shared with your team). To disable just for you: claude plugin disable codeo@codeo --scope local`.
- Reproduced for the reviewer's Important findings: project A with its own install at v1.0.6, then a plain `install.sh` from `~` printed `install: codeo v1.0.6 -> v1.0.7 (user scope)` and `install: done - …` with no line about project A, and `claude plugin list --json` afterwards listed only the user-scope entry (`{"id":"codeo@codeo","version":"1.0.7","scope":"user","projectPath":null}`); `claude plugin marketplace add kbajpai/codeo@v1.0.6 --scope project` in project A then printed `✘ Failed to add marketplace: Cannot add marketplace "codeo": its source doesn't match its extraKnownMarketplaces entry in user or managed settings; add it from the source that entry lists, or change the entry.`
- Independent review (opus): its report is quoted in plain text by finding below.

**Round 1's findings, recapped:** F1 (blocking in round 1) — fixed by `6cbe7d1` (a user-scope run leaves the project's file alone and says when its install was dropped; reproduced above). F2 (blocking in round 1) — fixed by `ba6f9dd`. F3 (blocking in round 1) — fixed by `ba6f9dd`. F4 (non-blocking), F5, F6, F7, F8 and F9 were fixed by `1e4029b`, `ba6f9dd`, `a8b6c4f`, `6cbe7d1`, `8c0cc63` and `ba6f9dd`; F7's remaining half (the highest tag, not a GitHub release) is F15 below.

**Acceptance criteria**

| Criterion | Verdict | Settled by |
|---|---|---|
| 1. One command, shown in the README, installs codeo and `superpowers`; `claude plugin list` shows both enabled | met | `t_fresh_user_install`, `t_readme_install_command_runs`; real fresh run above and the reviewer's, `claude plugin list` showed both `✔ enabled` |
| 2. Run again at the same version: nothing changes, and it says so | met | `t_rerun_changes_nothing`, `t_project_rerun_changes_nothing`; real re-run above |
| 3. A release tag installs that tag; none installs the latest; the version is printed | met | `t_given_tag_installed`, `t_latest_is_highest_release`, `t_bare_version_gets_v`, `t_missing_tag_stops` |
| 4. Default scope user; project scope installs there and the command says which scope it used | met | `t_default_scope_is_user`, `t_project_scope_installs_both`; real runs above name the scope on every line |
| 5. Old bash, or `jq`, `git`, `gh` missing: each named, no system package, exit non-zero | met | `t_old_bash`, `t_missing_each`, `t_all_missing_named_together`, `t_no_system_package_installed` in the full run above (the real no-tools run from round 1 is not repeated; F17 on the head's coverage) |
| 6. A project that commits the README's snippet is offered the install when its folder is trusted | not yet checkable — the engineer's check, recorded in the pull request at `/codeo:close` (Q2); the snippet equals a real project-scope run's `.claude/settings.json` under `jq -S` (`t_project_scope_writes_the_readme_snippet`, the reviewer's real run); it is sufficient only when the teammate has no codeo at another tag yet, which *Troubleshooting* covers | the reviewer's real run |
| 7. README has the eight sections, and each command in them was run and its output matches | not met — F11 (the README states something `claude` contradicts); F13 is non-blocking | `t_readme_sections`, `t_readme_install_blocks_match_the_script`; the reviewer ran the README's `uninstall`, `marketplace remove`, `plugin update superpowers` and the Troubleshooting `marketplace add` for real |
| 8. README no longer holds the test, dossier-checker or replay sections; the contributor page holds them unchanged; the README links to it | met | the four `same:` diffs above; `README.md` `## Contributing` |
| 9. Tests cover the behaviour and run in `bash tests/run.sh`, which ends `all cases passed`; a test fails when the README's install command and the script disagree | met | the full run above; `t_readme_install_command_runs`, `t_readme_install_blocks_match_the_script` |
| 10. CHANGELOG entry states the config schema, whether the shared state changed, and whether it is safe to bump mid-workflow | met | `CHANGELOG.md` `## Unreleased` header lines plus the bullet; its "offered again" wording is F11 |

**Documentation check.** `README.md` and `CONTRIBUTING.md` are the pages the plan names; no other page describes installing the plugin. The README's *Installing* blocks match real runs. Two statements are not true: the "offered again by their own committed settings" sentences (`README.md` *Setting a project up*, *Updating*, *Uninstalling*, and the CHANGELOG bullet) and the claim that `claude` refuses a bare `uninstall` in a project (F11, F13).

**Findings**
- **F10 — blocking, `/codeo:plan`'s.** A replace silently uninstalls other projects' project-scope installs. `claude plugin marketplace remove codeo` uninstalls codeo at every scope on the machine; `install.sh` names a dropped project install only when the run starts inside that project (`proj_e` is looked up only for a user-scope run inside a git repository). Reproduced above: a plain run from `~` drops project A's install with no line; a run inside project B, or any `--scope project` run, does the same. A `--scope local` install is never looked for. The code does what the plan says (other projects' installs are not reinstalled); the plan did not weigh that this is silent. The engineer's Q3 answer is the decision: after a replace the installer prints one line per project-scope install it dropped, from `claude plugin list --json`'s `projectPath`, with the command that restores it.
- **F11 — blocking, `/codeo:plan`'s.** The docs claim other projects' installs "are offered again by their own committed settings" when their folder is trusted (`README.md` lines 145, 280 and 290, and the CHANGELOG bullet). Nothing shows it, and it is contradicted: once the machine's marketplace is at the new tag, `claude plugin marketplace add kbajpai/codeo@v1.0.6 --scope project` in a project pinning the old tag fails (output above), and an already-trusted folder is not asked again. The plan wrote the claim; per Q3 the sentences go and the dropped-install lines of F10 replace them.
- **F12 — non-blocking, `/codeo:plan`'s.** "Already installed" at project scope reads the machine's pin, not the project's own `.claude/settings.json`: a project file hand-edited to `ref: v1.0.6` (as the README's *Updating* says) with the machine at v1.0.7 gets `nothing changed` from `--scope project`. Parked in round 2's plan as a known limit.
- **F13 — non-blocking, `/codeo:implement`'s.** `README.md` *Uninstalling* says `claude` refuses a bare `claude plugin uninstall codeo@codeo` run in a project; that holds only when no user-scope copy exists. With both scopes installed the bare command uninstalls the user copy and succeeds (the reviewer verified it).
- **F14 — non-blocking, `/codeo:implement`'s.** *Your first workflow* quotes "three leftovers" and "all nine as recommended" without naming the dossier or issue it comes from, so a reader cannot check it.
- **F15 — non-blocking, `/codeo:plan`'s.** "Latest release" is the highest `vX.Y.Z` tag, not a GitHub release (the remote has tags without a release, such as `v1.0.1`); a tag pushed before its release is published would be installed as the latest.
- **F16 — non-blocking, `/codeo:implement`'s.** A replace re-enables a user-scope copy the engineer had disabled, and the line says only "moved to vX too".
- **F17 — non-blocking, `/codeo:implement`'s.** The bash 3.2 head is covered only through `CODEO_TEST_BASH_VERSION`; no check reads the head for bash-4-only syntax. `CODEO_TEST_BASH_VERSION` is also honoured in production, and a non-numeric value makes the version test error out and pass.
- **F18 — non-blocking, `/codeo:implement`'s.** A non-JSON line on stdout from `claude plugin list --json` (an update notice, say) aborts the run with jq's own error and no `install:` line.

**Routing.** F10 is new installer behaviour the plan did not specify and F11 is wording the plan wrote, so this goes back to `/codeo:plan`. The plan round should carry F10 and F11 per the engineer's Q3 answer, and may fold F13, F14, F16, F17 and F18 in as tasks since F11 and F13 change the same README sections; F12 and F15 are known limits for the plan to accept or schedule. Criterion 6 stays the engineer's check at `/codeo:close`.

**Verdict: back to `/codeo:plan`.**

### Round 3 — 2026-11-22

No question was open; the pass ran to the end on the tree after round 3's implementation (`3100c20`).

**Commands run this pass, and their output**
- `bash scripts/role.sh --check qc` (`bash .devcontainer/scripts/role.sh --check qc`): exit 0. `sync-main.sh --abort-on-conflict`: `sync-main: the branch already contains origin/main`.
- `overlap.sh 151` and `overlap.sh --outside 151`: no output.
- `scope.sh origin/main HEAD`: `suite.shell=true` (unclassified paths: `.codeo/151/*`, `CHANGELOG.md`, `CONTRIBUTING.md`, `README.md`, `install.sh`).
- Build: the `shell` suite's `build` is `true`; exit 0. Tests: `bash tests/run.sh` (the whole suite, 54 files, foreground) ended `all cases passed`, exit 0; `bash tests/install.test.sh` alone ended `all cases passed`; 83 cases are registered in `cases=(`.
- Moved text against `git show origin/main:README.md`: `same: Tests`, `same: Checking a dossier`, `same: Replaying finished dossiers`, `same: Dev container`; none of the four headings is left in `README.md`.
- Real runs (claude 2.1.325, throwaway `HOME` and `CLAUDE_CONFIG_DIR`):
  - Project A pinned at v1.0.6, then a plain `install.sh` from `$HOME`: `install: codeo v1.0.6 -> v1.0.7 (user scope)`, `install: codeo is no longer installed for <A> (project scope, v1.0.6); its .claude/settings.json was not changed; run install.sh --scope project there to restore it`, `install: done - codeo v1.0.7, user scope, superpowers 7.0.2`. Running the printed command in A: `install: codeo v1.0.7 installed (project scope)`, ` M .claude/settings.json`, and `claude plugin list --json` listed the user and the project entry. A re-run from `$HOME`: `install: nothing changed - codeo v1.0.7, user scope, superpowers 7.0.2`.
  - A local install in project B and a disabled user copy, then `--scope project --version v1.0.6` in A: `install: your user-scope codeo moved to v1.0.6 too: one machine holds one codeo version (it was disabled; it is enabled now)` and `install: codeo is no longer installed for <B> (local scope, v1.0.7); its .claude/settings.local.json was not changed; run claude plugin install codeo@codeo --scope local there to restore it`; B's `.claude` holds only `settings.local.json`, and the local restore command printed `✔ Successfully installed plugin: codeo@codeo (scope: local)`.
  - No tools on `PATH`: with `CODEO_TEST_BASH_VERSION=3.2` the run printed `install: bash 4.3 or later is required (found 3.2)`, then `jq`, `git`, `gh` and `claude (Claude Code)` each `is not installed`, `install: nothing was installed. …`, exit 1; with `x.y` the hook is ignored and only the four tools are named (exit 1).
  - F19's reproduction is under Findings.
- Independent review (opus): its report is quoted in plain text by finding below; it ran the README's fresh, `--version`, `--scope project`, plain-update, project-restore, local-restore and uninstall blocks for real and found each matches.

**Round 2's findings, recapped:** F10 (blocking in round 2) — fixed by `766caf8` and `1f94e21`: a replace names every project and local install it dropped (reproduced above). F11 (blocking in round 2) — fixed by `b990804` and `7f7d281`: no "offered again" claim is left in `README.md` or `CHANGELOG.md` (`t_readme_has_no_offered_again_claim`, and a grep for `offered` finds none). F12 and F15 are documented as accepted limits (README *Updating* and *Installing*). F13 (fixed by `b990804`), F14 (the example names `.codeo/done/143/`), F16 for a project-scope run (reproduced above), F17 (`7496d9a`, `t_nonnumeric_test_bash_version_is_ignored`, `t_head_uses_no_bash4_syntax`) and F18 (`96a9975`, the `t_list_*notice*` cases) are fixed.

**Acceptance criteria**

| Criterion | Verdict | Settled by |
|---|---|---|
| 1. One command, shown in the README, installs codeo and `superpowers`; `claude plugin list` shows both enabled | met | `t_fresh_user_install`, `t_readme_install_command_runs`; the reviewer's real fresh run |
| 2. Run again at the same version: nothing changes, and it says so | met | `t_rerun_changes_nothing`, `t_project_rerun_changes_nothing`; real re-run above |
| 3. A release tag installs that tag; none installs the latest; the version is printed | met | `t_given_tag_installed`, `t_latest_is_highest_release`, `t_bare_version_gets_v`, `t_missing_tag_stops`; real `--version v1.0.6` runs above |
| 4. Default scope user; project scope installs there and the command says which scope it used | met | `t_default_scope_is_user`, `t_project_scope_installs_both`; every real summary line above names the scope |
| 5. Old bash, or `jq`, `git`, `gh` missing: each named, no system package, exit non-zero | met | `t_old_bash`, `t_missing_each`, `t_all_missing_named_together`, `t_no_system_package_installed`; the real no-tools run above (exit 1) |
| 6. A project that commits the README's snippet is offered the install when its folder is trusted | not yet checkable — the engineer's check, recorded in the pull request at `/codeo:close` (Q2) | `t_project_scope_writes_the_readme_snippet` shows the snippet equals what a project-scope run writes; the trust prompt itself is interactive |
| 7. README has the eight sections, and each command in them was run and its output matches | met — the printed restore command in the *Updating* blocks is F19 | `t_readme_sections`, `t_readme_install_blocks_match_the_script`; the reviewer's real runs of every block |
| 8. README no longer holds the test, dossier-checker or replay sections; the contributor page holds them unchanged; the README links to it | met | the four `same:` diffs above; `README.md` `## Contributing` |
| 9. Tests cover the behaviour and run in `bash tests/run.sh`, which ends `all cases passed`; a test fails when the README's install command and the script disagree | met | the full run above; `t_readme_install_command_runs`, `t_readme_install_blocks_match_the_script`, `t_readme_names_the_restore_command` |
| 10. CHANGELOG entry states the config schema, whether the shared state changed, and whether it is safe to bump mid-workflow | met | `CHANGELOG.md` `## Unreleased`: `Config schema: 1`, `Shared state: …`, `Safe to bump mid-workflow: yes`, and the `install.sh` bullet (the diff against `origin/main` is one added bullet) |

**Documentation check.** `README.md`, `CONTRIBUTING.md` and `CHANGELOG.md` are the pages the plan names; no other page describes installing the plugin. The README's captured blocks match real runs, and it has no issue numbers. The one statement that misleads is the restore command after a `--version` run (F19), and *Updating*'s "running the same command again finishes the job" does not cover the dropped-project lines after a failed replace (F20).

**Findings**
- **F19 — blocking, `/codeo:plan`'s.** The restore command the installer prints for a dropped project install is `install.sh --scope project` with no `--version`, so after a deliberate `--version vX` run, following it installs the latest release: that is a replace, which moves the user's copy to the latest and drops every other install again. Reproduced by this pass and by the reviewer (`install.sh:280-281`; `README.md` lines 257-258, 264 and 298): after `install.sh --version v1.0.6` from `$HOME` dropped project `team` (`install: codeo is no longer installed for <team> (project scope, v1.0.7); … run install.sh --scope project there to restore it`), the printed command run in `team` printed `install: release v1.0.7`, `install: codeo v1.0.6 -> v1.0.7 (project scope)`, `install: your user-scope codeo moved to v1.0.7 too: one machine holds one codeo version`, and `claude plugin list --json` then showed `{"version":"1.0.7","scope":"project"}` and `{"version":"1.0.7","scope":"user"}`. The code does what the plan says (the plan fixed the line's form); the plan did not weigh that the advice undoes the flag it follows. This is the silent-surprise class Q3 settled, now caused by the installer's own advice.
- **F20 — non-blocking, `/codeo:plan`'s.** A failure partway through a replace never names the dropped installs: `dropped` is computed before the remove but printed only after a reinstall succeeds, `replace_failed` dies without it, and the re-run finds no pin to replace (reviewer, reproduced with a `claude` wrapper that fails `plugin marketplace add`: `install: codeo is no longer installed: network down; run this again`, then the re-run printed a fresh install and no dropped line). Already parked in round 3's plan and `implement.md` as a known limit; the README should say it.
- **F21 — non-blocking, `/codeo:implement`'s.** A user-scope replace re-enables a disabled user copy without saying so; only the `--scope project` path prints `(it was disabled; it is enabled now)` (reviewer, reproduced; `install.sh:310-325`).
- **F22 — non-blocking, `/codeo:implement`'s.** The restore line names `install.sh`, which an adopter who installed with `curl … | bash` does not have on disk; the README shows the curl form beside it, the installer's output does not (`install.sh:281`).
- **F23 — non-blocking, `/codeo:implement`'s.** A usage error or `--help` exits 1 when a prerequisite is also missing, because the prerequisite check runs before argument parsing, while the header promises exit 2 for a usage error (reviewer, `install.sh:42-46` against `:11`).
- The reviewer's `--scope project` finding (the run overwrites a committed pin) is documented in `README.md` and is not raised. Parked limits from `implement.md` (a `[`-leading notice line, the symlinked checkout string compare, gaps in the head-syntax test's banned list, `vnull` for a missing `.version`) are not re-raised.

**Routing.** F19 is the only blocking finding, and its form was the plan's, so this goes back to `/codeo:plan`. The plan round should settle the printed restore form (the reviewer suggests `install.sh --scope project --version <the tag the run installed>`; a user-scope run after a `--version` choice is the case to weigh), and may carry F20-F23 in with it. Criterion 6 stays the engineer's check at `/codeo:close`.

**Verdict: back to `/codeo:plan`.**

## Log

- 2026-11-21 — Q1-Q2 raised (overlap with #138 on CHANGELOG.md; criterion 6 is the engineer's) · cost: 0m · opus-5-5 290k in + 333k cached / 1k out
- 2026-11-21 — Q1-Q2 answered; round 1: build, suite, criteria, documentation, independent review · cost: 39m · opus-5-5 413k in + 3.2M cached / 31k out · sonnet-5-5 36k in + 3.8M cached / 15k out
- 2026-11-21 — pass 2: Q3 raised (a replace drops other projects' installs; an unverified README/CHANGELOG claim) · cost: 10m · opus-5-5 121k in + 2.8M cached / 29k out · sonnet-5-5 14k in + 5.4M cached / 11k out
- 2026-11-21 — pass 2: Q3 answered; round 2: build, suite, criteria, documentation, independent review · cost: 14m · opus-5-5 121k in + 2.8M cached / 29k out · sonnet-5-5 22k in + 7.4M cached / 17k out
- 2026-11-22 — round 3: build, suite, criteria, documentation, independent review; verdict back to /codeo:plan (F19) · cost: 14m · opus-5-5 211k in + 4.3M cached / 27k out · sonnet-5-5 123k in + 166k cached / 2k out
