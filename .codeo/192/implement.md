# Issue #192 — implement

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/192 |
| Branch | `feat/192-guard-home-checkout-no-project` |
| Updated | 2026-11-26 |

## Where this stands

Round 1, done. All four tasks of `docs/plans/2026-11-26-home-checkout-edit-guard-192.md` are built and committed, the build (`true`) passes, and the next step is `/codeo:qc`.

## Questions

None.

## Notes

- Not guarded by design, and said so on the page: a file changed through the shell (`sed -i`, redirection, `rm`, `cp`), a nested shell (`bash -c`), a subshell `( … )` or `$(…)`; heredoc body lines that begin with `git push` are read as commands (a false refusal).
- Left as it is: `git add <absolute path under .codeo/>` is refused (fail-closed; the home skills stage by relative name). `git commit … -- .codeo/x` and a quoted `.codeo/` pathspec are refused for the same reason. `git tag` is refused even when it only lists tags, as the plan lists it.

## Outcome

- **Built:** `hooks/home-guard.sh` (the guard for Edit, Write, NotebookEdit and git writes through Bash, built on the checkout's own `.devcontainer/scripts/role.sh`, override `CODEO_HOME_EDITS=allow`, fails open), its registration in `hooks/hooks.json` as a second `PreToolUse` entry with matcher `Edit|Write|NotebookEdit|Bash`, and `tests/home-guard.test.sh` (scratch clones playing each role).
- **Documentation pages changed:** `docs/home-checkout.md` (new `## The edit guard` section with a Mermaid flowchart) and `CHANGELOG.md` (a new `## Unreleased` section with one bullet). No other page.
- **Build result:** the `shell` suite's build command is `true`; it exits 0. The suite's tests (`bash tests/run.sh`) were run by each task's implementer and print `all cases passed`; grading them is `/codeo:qc`'s.
- **Commits:** `964ff2f` Task 1, `13f7e57` its fix, `216c492` Task 2, `e7ec8c8` its fix, `0cbecc3` Task 3, `d979d9f` Task 4, `a6e95c9` a wording fix to the page.
- **Deviations from the plan, and why:**
  - Task 1 review found that a missing tail with `..` after an existing `.codeo/` ancestor (`.codeo/nope/../../src/x.txt`) was exempt; such a path is now never exempt (`13f7e57`).
  - Task 2 review found that `git commit <pathspec>` and `-i/--include` bypassed the commit rule, that a quoted `-C "<dir>"` or `cd "<dir>"` target was not followed, and that clustered flags (`checkout -qb`, `switch -qc`) were missed. The plan's commit rule named only `--amend`, `--only`/`-o` and ` -- `; it now also treats a pathspec outside `.codeo/` and `-i`/`--include` as a write, follows quoted directories, and refuses the clusters (`e7ec8c8`). This widens the plan's rule in the direction of its stated intent.
  - The plan's Global Constraints say the documentation names the exemptions; the page also lists the branch-creating forms of `checkout` and `switch` as refused, because the code does.
  - Task 3's registration test runs the registered command through `bash -c` itself rather than through the `hook` helper, which always runs the script directly.
- **Review:** each task had a spec-and-quality review; the Task 3 diff (21 lines) was read by the controller, and a final whole-branch review found no Critical or Important issue.
- **No environment:** no shared environment is configured, so no lease was taken and nothing was deployed.

## Log

- 2026-11-26 — built: 4 tasks, 7 commits, build exit 0 · cost: 43m · sonnet-5-5 380k in + 11.5M cached / 75k out
