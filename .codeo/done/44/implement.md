# Issue #44 — implement

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/44 |
| Branch | `feat/dev-container-defaults-remote-control` |
| Updated | 2026-11-08 |

## Where this stands

Round 1 done: all four plan tasks built, reviewed and committed; the build passes. Next: `/codeo:qc`.

## Questions

None.

## Outcome

**Plan:** `docs/plans/2026-11-08-dev-container-defaults.md`, executed with `superpowers:subagent-driven-development`; every dispatch on sonnet. Step 2a: the branch already contained `origin/main`; `overlap.sh 44` printed nothing.

**Built**
- Task 1 (ce9d105): `.devcontainer/scripts/window-title.sh` — `--print` gives `codeo [home]` / `codeo [#N]`; a plain run merges `window.title` into `.vscode/settings.json` and adds it to the clone's `info/exclude`. 7 test cases.
- Task 2 (88f292f): `devcontainer-start.sh` calls the title script, merges `remoteControlAtStartup: true` into `${CLAUDE_CONFIG_DIR:-$HOME/.claude}/settings.json`, and reports TODOs for the three credential variables and a non-claude.ai login. `ds_run` now clears the three variables and sets `CLAUDE_CONFIG_DIR`. 6 test cases.
- Task 3 (2b74415): `devcontainer.json` `postStartCommand` = `bash .devcontainer/scripts/window-title.sh || true`. 1 test case.
- Task 4 (7d87053): `CHANGELOG.md` entry.
- Final review fix wave (b1f0777): an empty (0-byte) settings file is filled instead of replaced by an empty one, in both scripts; 2 test cases.

**Documentation changed:** `CHANGELOG.md` only, as planned.

**Deviations from the plan**
- `.codeo/44/issue.md` (the issue dossier `/codeo:init` copied onto this branch) named the private reference project, which `tests/agnostic.test.sh` rejects in tracked files. With the engineer's say-so I replaced the names with "the reference project" (608cb7a). Pushed history before that commit, and the GitHub bodies of #44 and #45, still carry the names; editing the issues is the engineer's.
- The Task 3 implementer wrote the JSON before the test and re-verified the failing state afterwards; the end state is as planned.
- The plan's last-task proof (`bash tests/run.sh`) first failed on the agnostic guard above; after 608cb7a the whole suite printed `all cases passed` (run before the fix wave; `/codeo:qc` runs the suites again).

**Left unfixed (Minor, from the per-task and final reviews):** the `window-title.sh` temp file's mode is 0600 after `mv`; "not valid JSON" wording for a non-object JSON file; no assertion on the stdout line of a plain title run; the env-var test's inline `env` call; two near-duplicate TODOs when `mkdir` fails; a stray `.tmp` if `mv` fails; a JSONC `.vscode/settings.json` (comments) is left untouched with a TODO, so its title stays unset.

**Build:** shell suite `build` = `true`, exit 0. No shared environment, so no lease and no deploy.

**For `/codeo:qc`:** criteria 1 and 2 (the session is listed in claude.ai/code, also after `/clear`) need the manual check named in the plan; the suite cannot see them.

## Log

- 2026-11-08 — implemented: Tasks 1-4 and one fix wave (ce9d105..b1f0777) · cost: 18m · sonnet-5-5 421k in + 11.9M cached / 61k out
