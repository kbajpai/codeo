# Issue #192 — qc

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/192 |
| Branch | `feat/192-guard-home-checkout-no-project` |
| Updated | 2026-11-27 |

## Where this stands

Round 1, done. Two blocking findings, both `/codeo:implement`'s; the verdict is back to `/codeo:implement`.

## Questions

None.

## Notes

- Non-blocking, left for `/codeo:implement` to take or `/codeo:triage` to collect: F3–F6 below.

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

## Log

- 2026-11-27 — qc round 1: back to implement, 2 blocking and 4 non-blocking findings · cost: 7m · opus-5-5 175k in + 2.5M cached / 28k out · sonnet-5-5 115k in + 303k cached / 1k out
