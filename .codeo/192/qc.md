# Issue #192 — qc

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/192 |
| Branch | `feat/192-guard-home-checkout-no-project` |
| Updated | 2026-11-27 |

## Where this stands

Round 2, done. Q1 is answered; two blocking findings, F7 and F14, both `/codeo:implement`'s; the verdict is back to `/codeo:implement`.

## Questions

### Q1 — Should the hook run `role.sh` from any repository an edit or `git -C` points at, or only from the session's own project?

**Why it matters:** `hooks/home-guard.sh:12-13` runs `<repo root>/.devcontainer/scripts/role.sh` of whatever repository the target path is in, before Claude Code's permission prompt, and the plugin is active in every project at user scope. Reproduced this pass: a throwaway repo outside the session's project, holding an executable `role.sh` that runs `touch <dir>/pwned`, was handed an `Edit` of one of its files; the hook ran the script and the file appeared, whether or not the edit was then allowed. A skill runs `role.sh` only in the project the engineer invoked it in, so this is new exposure. The plan's Q2 answer says "`<project root>/.devcontainer/scripts/role.sh`" and the code reads the target's repository root instead, which is what lets `git -C <home> commit` from an issue checkout be judged (a round 1 test). If the answer is "keep it", the page says so and the finding closes; if "restrict it", `/codeo:implement` changes what is judged and the tests with it.

- Only when the target's repository is the session's project (`$CLAUDE_PROJECT_DIR`, or the `cwd` the hook is given) or a worktree of it. Cost: `git -C <other clone>` and an edit by absolute path in another clone are not judged (fail-open), so the cross-checkout tests change.
- As now, and say so on the page: the hook runs the `role.sh` of any repository Claude edits in. Cost: an untrusted clone's script runs on a proposed edit, before any prompt.
- Only when the target's repository also has `.codeo/config.json` tracked by git. Cost: still repository-supplied code; it narrows which repositories, it does not make the script trusted.

I recommend the first: the guard's purpose is the session's own checkout, and the cross-clone case is a convenience.

**Options:** restrict to the session's project (recommended) · keep and document · require a tracked `.codeo/config.json` · no preference, you pick.

**Answer:**
Restrict to the session's own project, as recommended. Given in the conversation: "Q1 - Your Pick".


## Notes

- Non-blocking, left for `/codeo:implement` to take or `/codeo:triage` to collect: F8–F13 of round 2.

## Outcome

### Round 1 — 2026-11-27

**Sync.** `sync-main.sh --abort-on-conflict`: `sync-main: the branch already contains origin/main` (exit 0). `overlap.sh 192`: no output, exit 0. `overlap.sh --outside 192`: no output, exit 0 (nothing outside the footprint).

**Scope.** `git diff origin/main...HEAD --stat`: 9 files, 920 insertions, 1 deletion (the hook, `hooks.json`, the test, `docs/home-checkout.md`, `CHANGELOG.md`, the plan and the dossiers). `scope.sh origin/main HEAD`:

```
scope: suite shell needed for unclassified paths:
  .codeo/192/implement.md
  .codeo/192/init.md
  .codeo/192/plan.md
  CHANGELOG.md
suite.shell=true
```

No `deploy=` line: no environment is configured, so step 9 does not apply.

**Build.** Suite `shell`, build `true`: exit 0.

**Tests.** Suite `shell`, test `bash tests/run.sh`, run whole: last lines `all cases passed`, `test-exit=0`.

**Project rules.** `overlay.sh qc invariants-extra`: exit 3 (none); no invariants file is configured. `overlay.sh qc wiki-rules`: exit 3 (the pages under `docs/` set the conventions).

#### Acceptance criteria

| # | Criterion | Settled by | Verdict |
|---|---|---|---|
| 1 | In home, Edit/Write, `git commit`, `git push` refused with the one-line reason; the same succeed in `issue:<N>` | `tests/home-guard.test.sh`: `file_tools_refused_in_guarded_roles`, `file_tools_allowed_elsewhere`, `bash_git_writes_refused_in_home`, `bash_unguarded_roles` | met on Linux. Not met where `sed -z` is missing (F1): the Bash half then allows everything. |
| 2 | Override lets the calls through; a session without it stays guarded | `override_and_fail_open` (`allow` passes; `1`, `yes`, `deny`, empty stay denied); `bash_unguarded_roles` (`CODEO_HOME_EDITS=allow`); `CODEO_HOME_EDITS=allow git push` in the command text stays refused | met |
| 3 | `/codeo:issue`, `/codeo:init`, `/codeo:triage`, `/codeo:cleanup` still run in home, `.codeo/` writes included | `file_tools_allowed_elsewhere` (`.codeo/` paths), `bash_allowed_in_home`, `bash_judged_by_the_checkout_it_addresses` (a `.codeo/` commit in a scratch worktree). The skills commit through `intake.sh`/`claim.sh`, which the guard does not see. | not met — the commands `/codeo:init` step 9 runs for its dossier commit are refused once they carry a redirection or an absolute path (F2) |
| 4 | Hosted sessions and non-codeo projects unaffected | `file_tools_allowed_elsewhere` (`CLAUDE_CODE_REMOTE=true`, a repo with no `role.sh`), `bash_unguarded_roles` (remote, a path outside any repository) | met |
| 5 | A test covers each criterion against a scratch clone; `bash tests/run.sh` passes | `tests/home-guard.test.sh`, ten case groups; `bash tests/run.sh` → `all cases passed` | met for the cases written; the two blocking findings have no test, which is how they got through |

#### Documentation check

`docs/home-checkout.md` (new `## The edit guard`, with a Mermaid flowchart) and `CHANGELOG.md` (`## Unreleased`) describe the change, in present tense, with no issue number inside the page text; the changelog bullet carries `(#192)` as that file's convention. The plan named exactly these two pages. The flowchart matches the code's order of checks. Two sentences are not exact: "`git commit` passes only when everything it would commit is under `.codeo/`" (F4: `--pathspec-from-file`), and the "What it does not see" list omits the shell keywords of F3 and the `.git/` paths of F6. The diagram needs no render here; it uses plain `flowchart TD` nodes and edges only.

#### Independent review

An opus reviewer was given the acceptance criteria and the diff range only. It ran the guard's own test (`all cases passed`) and probed the hook in throwaway clones. Its verdict, in plain text: ready to merge with fixes — issues 1 and 2 should be fixed with tests before merge, the rest can go in the doc or a follow-up. Its findings are F1–F6.

#### Findings

- **F1 — blocking, `/codeo:implement`'s.** `hooks/home-guard.sh:92` uses `sed -z`, a GNU-only option; BSD sed on macOS rejects it, `cmd` comes out empty, no segment is read, and every Bash call is allowed. `docs/home-checkout.md:22` says home works on macOS, and this is the only `sed -z` outside the tests (`grep -rn 'sed -z' --include=*.sh .`). I could not run BSD sed here; the reviewer simulated it with a `sed` shim that rejects `-z`, and the conclusion rests on BSD sed's documented options. Effect: criterion 1 silently fails for Bash on a Mac. The plan did not prescribe `sed`, so the code diverged from what the page promises, not the plan. Needed: quote-blanking and splitting that run on macOS's tools and on bash 3.2 (the page says the role guard runs on 3.2), and a test that runs the hook with a `sed` that rejects `-z`.
- **F2 — blocking, `/codeo:implement`'s.** `.codeo/`-only staging and commits are refused when the command carries a redirection or an absolute path. Reproduced here in a home clone with only `.codeo/9/init.md` staged:

  ```
  [git commit -m x]                                      => allow
  [git commit -m x 2>&1]                                 => deny
  [git add .codeo/9/init.md 2>/dev/null]                 => deny
  [git add <home>/.codeo/9/init.md]                      => deny
  [git add .codeo]                                       => deny
  ```

  Causes: `&` splits the segment, leaving a stray `2>` word counted as a pathspec outside `.codeo/` (`:52-58`, `:71`, `:92`); `under_codeo_p` accepts only a path that starts with `.codeo/`, so an absolute path or `.codeo` itself fails. The plan's rule is that the home skills' `.codeo/` writes keep working; `/codeo:init` step 9 stages and commits `.codeo/` files in a scratch worktree, and agents add `2>&1` and absolute paths as a matter of course. The refusal then tells the agent to file an issue, the wrong way out. Needed: skip redirection tokens when reading pathspecs; resolve a pathspec against the segment's directory and the repository root before the `.codeo/` test, and accept `.codeo` itself; tests for each form above.
- **F3 — non-blocking, `/codeo:implement`'s.** Only a segment whose first word is `git` or `cd` is judged, so `if true; then git push; fi`, `for d in a; do git push; done`, `{ git push; }`, `! git push`, `time git push`, `command git push` and `xargs git push` are allowed in home. The page lists what is not seen, and these are not on it. Strip leading keywords and prefix words, or name them on the page.
- **F4 — non-blocking, `/codeo:implement`'s.** `git commit --pathspec-from-file=f` passes with only `.codeo/` staged yet commits what `f` names; `git --git-dir=<home>/.git push` and `pushd <home> && git push` from an issue checkout are judged by the issue checkout. The page's claim about what a commit passes is not exact for the first.
- **F5 — non-blocking, a judgment call.** `git clean -fdx` and `git branch -f main HEAD~1` are allowed in home. The page lists exactly what is refused, so it is accurate; whether they belong in the guard is the engineer's.
- **F6 — non-blocking, `/codeo:implement`'s.** A Write to `<home>/.git/hooks/pre-commit` is allowed: `rev-parse --show-toplevel` fails inside `.git`, so the hook fails open. Not on the page's list of unseen paths.

Not findings, quoted from the reviewer: the blanket `.codeo/` exemption (including `.codeo/config.json`) is the design's choice and `git push` is still refused; plain `checkout -- <file>`, `pull` and `worktree` are allowed as documented; `git tag` and `git stash list` refusals and heredoc false positives are documented.

No issue was filed from this pass.

**Verdict: back to `/codeo:implement`.**

### Round 2 — 2026-11-27

**Sync.** `sync-main.sh --abort-on-conflict`: `sync-main: the branch already contains origin/main` (exit 0), run at the start and again before this round was written. `overlap.sh 192` and `overlap.sh --outside 192`: no output, exit 0. The round reviews `462bc41..0431ef9` for code (the merge base to the head before this pass's dossier commits).

**Scope.** `git diff origin/main...HEAD --stat`: 10 files, 1131 insertions, 1 deletion (the hook, `hooks.json`, the test, `docs/home-checkout.md`, `CHANGELOG.md`, the plan and the dossiers). `scope.sh origin/main HEAD` printed `scope: suite shell needed for unclassified paths:` for `.codeo/192/{implement,init,plan,qc}.md` and `CHANGELOG.md`, then `suite.shell=true`. No `deploy=` line: no environment is configured, so step 9 does not apply.

**Build.** Suite `shell`, build `true`: `build-exit=0`.

**Tests.** Suite `shell`, test `bash tests/run.sh`, run whole: `all cases passed`, `test-exit=0`. `bash tests/home-guard.test.sh` alone also passes; the new case groups `bash_without_gnu_sed` and `bash_codeo_commands_in_home` are in it.

**Project rules.** `overlay.sh qc invariants-extra` and `qc wiki-rules`: exit 3 in round 1, and no overlay changed since. No invariants file is configured.

**Re-run of round 1's reproductions** against the current hook, in a scratch home clone with only `.codeo/9/init.md` staged: `git commit -m x`, `git commit -m x 2>&1`, `git commit -m x 2>&1 | tail -2`, `git add .codeo/9/init.md 2>/dev/null`, `git add <absolute>/.codeo/9/init.md`, `git add .codeo` and `cd <home>/.codeo && git add 9/init.md` all allow; `git push`, `git add a.txt 2>&1` and `git add .codeo/../a.txt` deny; with `a.txt` staged, `git commit -m x 2>&1` denies; with a `sed` that exits 2 on `-z` first on `PATH`, `git push` still denies. `grep` of the hook for `sed -z`, `readlink -f`, `realpath`, `mapfile`, `declare -A`, `${x,,}`, `|&`, `grep -P` and `date -d` finds only a comment.

#### Acceptance criteria

| # | Criterion | Settled by | Verdict |
|---|---|---|---|
| 1 | In home, Edit/Write, `git commit`, `git push` refused with the one-line reason; the same succeed in `issue:<N>` | `file_tools_refused_in_guarded_roles`, `file_tools_allowed_elsewhere`, `bash_git_writes_refused_in_home`, `bash_unguarded_roles`, and the no-GNU-sed case `bash_without_gnu_sed` | met |
| 2 | Override lets the calls through; a session without it stays guarded | `override_and_fail_open`, `bash_unguarded_roles`; `CODEO_HOME_EDITS=allow git push` in the command text stays refused | met |
| 3 | `/codeo:issue`, `/codeo:init`, `/codeo:triage`, `/codeo:cleanup` still run in home, `.codeo/` writes included | `file_tools_allowed_elsewhere`, `bash_allowed_in_home`, `bash_judged_by_the_checkout_it_addresses`, `bash_codeo_commands_in_home`; the re-run above of `/codeo:init` step 9's command forms | met |
| 4 | Hosted sessions and non-codeo projects unaffected | `file_tools_allowed_elsewhere` (hosted, a repo with no `role.sh`), `bash_unguarded_roles` for the decisions; but a command with no `git` in it is slowed by the hook in every project (F7), and the hook runs a repository's own `role.sh` in repositories outside the session's project (Q1) | not met — F7, and Q1's answer |
| 5 | A test covers each criterion against a scratch clone; `bash tests/run.sh` passes | `tests/home-guard.test.sh`, twelve case groups; `bash tests/run.sh` → `all cases passed` | met for the cases written; F7 and the Q1 restriction have no test yet |

#### Documentation check

`docs/home-checkout.md` `## The edit guard` and `CHANGELOG.md` `## Unreleased` describe the change in present tense; the page names the bash 3.2 and BSD tools, the redirection and absolute-path forms, and the added limits. The flowchart's order of checks matches the code. Not exact yet: "`--amend`, `-i`, `--include`, `-o`, `--only` … are always refused" is untrue for git's abbreviated `--amen`, `--inc`, `--onl` (F8); the not-seen list omits an unresolvable `cd` target (F10) and the literal-`git`-word forms (F11); and after Q1's answer the page must say which repositories' `role.sh` the hook runs. No diagram changed in this round.

#### Independent review

A fresh opus reviewer was given the acceptance criteria and the diff range only. It ran `bash tests/home-guard.test.sh` (`all cases passed`) and probed the hook in throwaway clones. Its verdict, in plain text: ready to merge with fixes — stop running `role.sh` from arbitrary repositories (its item 1) and skip the normalisation for commands with no `git` in them (its item 2); items 3–5 are small edits to the code or to the page's lists.

#### Questions this round

Q1, answered: *restrict `role.sh` to the session's own project*; the engineer's answer was "Q1 - Your Pick", the recommended option, given in the conversation.

#### Findings

- **F1, F2 (blocking in round 1) — fixed** by `3d0284a` and `3f3188c`; re-run above.
- **F7 — blocking, `/codeo:implement`'s.** `normalize_cmd` is quadratic in the command's length and runs on every Bash call in every project before the hook knows there is a `git` word. Measured here, a heredoc of quoted lines with no `git` in it, `LC_ALL=C.UTF-8`: 7.7 KB 0.55 s, 15 KB 2.0 s, 31 KB 7.7 s; the reviewer measured 69 KB at 44 s against a 60 s hook timeout, and a timeout fails open only after the wait. Needed: return early, before normalising, when the command has no `git` word; keep the rest linear or small; a test that a long command with no `git` returns within a bound.
- **F14 — blocking, `/codeo:implement`'s** (Q1's answer). The hook runs `<repo root>/.devcontainer/scripts/role.sh` of whatever repository the target path is in, before the permission prompt (`hooks/home-guard.sh:12-13`); reproduced here with a throwaway repository whose `role.sh` created a file when an `Edit` of one of its files was offered. The plan's Q2 says the hook runs `<project root>/.devcontainer/scripts/role.sh`, so the code diverges from the plan. Needed: run `role.sh` only when the target's repository is the session's project (`$CLAUDE_PROJECT_DIR`, else the `cwd` the hook is given) or a worktree of it, and allow otherwise; the round 1 cross-checkout cases that name another clone (`git -C <home>` from an issue checkout, an absolute path into another clone) change with it; a test that a repository outside the project is not consulted (its `role.sh` is not run); the page says which repositories are judged.
- **F8 — non-blocking, `/codeo:implement`'s.** `git commit --amen`, `--inc` and `--onl`, abbreviations git accepts, are not matched, so the page's "always refused" is untrue for them.
- **F9 — non-blocking, `/codeo:implement`'s.** `[[ -x role.sh ]]` is required, but the skills run `bash .devcontainer/scripts/role.sh`: a copy that lost its exec bit has the skill refusals and silently no edit guard. Run it with `bash` and test `-f`.
- **F10 — non-blocking, `/codeo:implement`'s.** An unresolvable `cd` target (`cd -`, a bare `cd`, `cd ~/…`, `cd $VAR/…`) leaves the tracked directory where it was, so from an issue checkout `cd ~/codeo-home && git push` is allowed, and a subshell's `cd` leaks into later segments. Refuse or name it on the page.
- **F11 — non-blocking, `/codeo:implement`'s.** The git word is matched literally: `/usr/bin/git push`, `git 'push'`, `"git" push`, `\git push`, a git alias and a backslash-newline continuation are allowed and are not on the page's not-seen list.
- **F12 — non-blocking, `/codeo:implement`'s.** The Bash `cwd` is not canonicalised while the repository root is, so a `cwd` reported through a symlink makes `git add .codeo/…` in home refuse; `cur=$(cd "$cur" && pwd -P)`. Whether Claude Code reports such a `cwd` was not confirmed.
- **F13 — non-blocking.** `git stash list`/`show`, `ls # note; git push` (comments are not stripped) and heredoc bodies are refused; `git clean -fdx` and `git branch -f` are allowed (round 1's F5, still the engineer's call).

Not findings: the reviewer's other points (`pull`, `branch`, `worktree` allowed; shell-level writes; `--git-dir`; `.codeo/` symlinks; no `MultiEdit` in the matcher; `-p`/`--interactive`) are documented limits or choices. No issue was filed from this pass.

**Verdict: back to `/codeo:implement`.**

## Log

- 2026-11-27 — qc round 1: back to implement, 2 blocking and 4 non-blocking findings · cost: 7m · opus-5-5 175k in + 2.5M cached / 28k out · sonnet-5-5 115k in + 303k cached / 1k out
- 2026-11-27 — qc round 2 paused: Q1 raised, F7 blocking, build and suite pass · cost: 9m · opus-5-5 272k in + 1.9M cached / 25k out · sonnet-5-5 191k in + 660k cached / 4k out
- 2026-11-27 — qc round 2: back to implement, 2 blocking (F7, F14) and 6 non-blocking findings; Q1 answered · cost: 10m · opus-5-5 272k in + 1.9M cached / 25k out · sonnet-5-5 199k in + 2.2M cached / 10k out
