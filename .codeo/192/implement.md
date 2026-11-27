# Issue #192 — implement

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/192 |
| Branch | `feat/192-guard-home-checkout-no-project` |
| Updated | 2026-11-27 |

## Where this stands

Round 3, done (send-back from qc.md round 2). F14 and F7 are fixed with the small items, the build (`true`) passes, and the next step is `/codeo:qc`.

## Questions

None.

## Notes

- Not guarded by design, and said so on the page: a file changed through the shell (`sed -i`, redirection, `rm`, `cp`), a nested shell (`bash -c`), a subshell `( … )` or `$(…)`; heredoc body lines that begin with `git push` are read as commands (a false refusal).
- Left as it is: `git add <absolute path under .codeo/>` is refused (fail-closed; the home skills stage by relative name). `git commit … -- .codeo/x` and a quoted `.codeo/` pathspec are refused for the same reason. `git tag` is refused even when it only lists tags, as the plan lists it.

## Outcome

### Round 1 — 2026-11-26

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


### Round 2 — 2026-11-27
(send-back from qc.md round 1)

- **Merge of the base branch.** `sync-main.sh` conflicted in `CHANGELOG.md`: `origin/main` had added a #190 bullet under `## Unreleased`, and this branch added the guard's bullet there. Resolved by keeping both bullets under the one section (#190's first, then #192's) and committing the merge (`88f5318`). No other file conflicted. Files `origin/main` changed that this branch's work touches: `.devcontainer/scripts/role.sh` (a two-line change) and `docs/home-checkout.md` (five lines); the guard reads `role.sh` only by running it, and the page's section was re-read after the merge.
- **F1 (blocking) — held.** `sed -z` is GNU-only and the page says home runs on macOS. `3d0284a` replaces the `sed` pipeline with `normalize_cmd`, plain bash for bash 3.2, with the same quoting, `cd`/`-C` and segment-break rules. New case group `bash_without_gnu_sed` runs the hook with a `sed` that rejects `-z` and checks a home `git push` is still refused and `git -C <issue clone> commit` still allowed.
- **F2 (blocking) — held, reproduced.** `3f3188c`: a redirection word is not a pathspec, `N>&M` and `&>` no longer split the segment, and `under_codeo_p` resolves a pathspec lexically against the directory the command addresses, accepting `.codeo` itself, `./.codeo/x`, an absolute path under the root's `.codeo/`, and a relative path from inside `.codeo/`; any `..` still refuses. New case group `bash_codeo_commands_in_home` covers the six reported commands and four denied counterparts. The new allow-tests failed against the old code first (10 failures), then passed.
- **F3, F4, F6 (non-blocking) — documented, not coded.** The edit-guard section's "What it does not see" now lists shell control words and prefixes (`if`, `for`, `{ }`, `!`, `time`, `command`, `xargs`, `pushd`), `git --git-dir=…`, `git commit --pathspec-from-file`, and writes into a `.git/` directory. These are limits the guard does not close; they are not fixed in code because the guard judges a segment by its first word, by design.
- **F5 (non-blocking) — left.** `git clean` and `git branch -f` stay outside the refused list; whether they belong in the guard is the engineer's call.
- **Documentation pages changed:** `docs/home-checkout.md` (`## The edit guard`: allowed pathspec forms, redirection, the bash 3.2 and BSD-tools note, the added limits, and `acf9bbd`'s sentence that an absolute pathspec must spell the checkout's real path). No other page.
- **Build result:** `true` exits 0.
- **Commits:** `88f5318` merge, `3d0284a` F1, `3f3188c` F2 and the page, `acf9bbd` a wording fix to the page.
- **Known limits found this round, left as they are:** an absolute pathspec through a symlinked prefix (such as `/tmp` against `/private/tmp` on macOS) does not match the checkout's real path and is refused (fail-closed; now said on the page); a redirection written before `git` (`2>/dev/null git add x`) makes that segment's first word not `git`, so it is not judged — the same class as F3. The BSD-sed case was proved with a shim that fails on `-z`, not on a Mac.
- **Review:** the controller read the 3d0284a/3f3188c code diff and ran `bash tests/home-guard.test.sh` (`all cases passed`); the full suite is `/codeo:qc`'s.

### Round 3 — 2026-11-27
(send-back from qc.md round 2)

- **Base branch.** `sync-main.sh`: the branch already contains `origin/main`; no `also changed on` lines. `overlap.sh 192`: nothing.
- **F14 (blocking, answered by Q1) — held, reproduced.** A throwaway repository outside the project, whose executable `role.sh` creates a marker file, had that script run by an `Edit` of one of its files. `4a202ce`: the hook runs a repository's `role.sh` only when it is the session's project (`$CLAUDE_PROJECT_DIR`, else the repository of the hook's `cwd`) or a worktree of it (same git common directory), and allows otherwise. `/codeo:init`'s scratch worktree is a worktree of the project and stays judged. The round 1 cross-checkout cases changed with it: from an issue clone, `git -C <home> commit` and an edit by absolute path into the home clone are no longer judged. New group `role_sh_only_in_the_project` asserts the foreign `role.sh` is not run, a worktree is judged, and `CLAUDE_PROJECT_DIR` wins over `cwd`. Re-run here: an `Edit` and a `git -C` into the foreign repository both allow and no marker file appears.
- **F7 (blocking) — held, reproduced** (7.7 s at 31 KB). `e8142ce`: a command with no `git` in it returns before normalising; a command over 16384 bytes is not judged; the context test in `normalize_cmd` reads a short tail, and it runs byte-wise. New group `bash_long_commands`. Re-run here: a 23 KB heredoc with no `git`, `LC_ALL=C.UTF-8`: 0.013 s.
- **F8, F9, F12 (non-blocking) — taken, being cheap.** `3f4ae2e` refuses `--amen`, `--inc`, `--onl` and the other abbreviations of `--amend`, `--include` and `--only` of three letters or more; `cc717d6` runs `role.sh` with `bash` and needs only that the file exists; `4829526` takes the physical path of the Bash `cwd`. Each has a test that failed first.
- **F10, F11 (non-blocking) — documented, not coded.** `744ed1a`: an unresolvable `cd` target and a `git` not written as the bare word (a path, quotes, `\git`, an alias, a line continuation) are on the page's not-seen list.
- **F13 — left.** The stash listing, comments, heredoc bodies, `git clean` and `git branch -f` stay as the page says; the last two are the engineer's call.
- **Documentation pages changed:** `docs/home-checkout.md` (`## The edit guard`: which repositories are judged, the 16 KB limit, abbreviated options, `role.sh` run with `bash`, the added limits, and the flowchart's new check). No other page.
- **Build result:** `true` exits 0.
- **Commits:** `4a202ce` F14, `e8142ce` F7, `3f4ae2e` F8, `cc717d6` F9, `4829526` F12, `744ed1a` the page.
- **Known edge, left:** if the `cwd` is empty and its `cd` fails, the starting directory is empty and the call is not judged (fail-open).
- **Review:** the controller read the code diff and re-ran the F14 and F7 reproductions; `bash tests/home-guard.test.sh` and the full `bash tests/run.sh` print `all cases passed`. Grading them is `/codeo:qc`'s.

## Log

- 2026-11-26 — built: 4 tasks, 7 commits, build exit 0 · cost: 43m · sonnet-5-5 380k in + 11.5M cached / 75k out
- 2026-11-27 — round 2: F1 and F2 fixed, 4 commits, build exit 0 · cost: 15m · sonnet-5-5 236k in + 3.8M cached / 30k out
- 2026-11-27 — round 3: F14, F7 fixed plus F8, F9, F12, 6 commits, build exit 0 · cost: 21m · sonnet-5-5 112k in + 3.8M cached / 29k out
