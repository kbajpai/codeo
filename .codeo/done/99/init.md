# Issue #99 — init

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/99 |
| Branch | `feat/make-sbx-issue-sandbox-usable` |
| Updated | 2026-11-17 |

## Where this stands

Branch `feat/make-sbx-issue-sandbox-usable` cut off `main` at `6699326b8d5981bea91265e74b6c27daf332087a`, claimed and pushed. Nothing is open; the next step is `/codeo:plan`, run in this issue's own container.

## Questions

None.

## Outcome

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/99 — Make the sbx issue sandbox usable: correct the evaluation, start script, VS Code and safe removal; trust the dev container folder (consolidates #94, #85, #86, #114) |
| State | open · labels `enhancement` |
| Branch | `feat/make-sbx-issue-sandbox-usable` off `main` at `6699326` |
| Board | Ready → In progress |

**Problem.** #73's evaluation recommends a hybrid: dev container for the home container, an `sbx` sandbox per issue. This issue makes that usable, in four parts, planned in this order: (#94) correct `docs/dev-environment-sbx-evaluation.md` and #86's text against their evidence and test whether the sandbox's `gh` token is the real one (it may change what the next two assume); (#85) a start script that puts a sandbox on the pushed branch with the lock, a git identity, the pinned plugins, a name check and the Windows Git trust step; (#86) VS Code folder, extensions and window titles, no lost work on `sbx rm`, a pinned image digest and the unexplained stops; and (#114, independent, may be planned at any point) the dev container records the clone folder as trusted in Claude Code, so "Trust this folder" never appears. Only the #114 part changes `.devcontainer/`; #94's empty-diff criterion and #85's `.devcontainer/` exclusion apply to their own parts only.

**Acceptance criteria** — verbatim from the issue, unchecked, by part:

*Part of #94 (evaluation page):*
- [ ] The page quotes the `Image:` lines from the creates it cites and states whether the digest changed; #86's sentence agrees with it.
- [ ] A trial (T13) on the engineer's host settles whether the sandbox's `gh` token is the real token or a placeholder, and D1, the Recommendation and the Credentials bullet cite it.
- [ ] The Recommendation's naming sentence no longer repeats itself or contradicts its own conclusion.
- [ ] The follow-up section maps U6 and U8 to #85 and U14 to #86; #86 cites one trial range, matching the trials it uses.
- [ ] "1m47s (image pull)", the U4 file-mode claim and the doubled "was not tried" read as exactly what the output shows; the Trials introduction no longer instructs the reader to run or paste anything.
- [ ] `bash tests/run.sh` still passes, and `git diff --stat main -- .devcontainer skills` is empty.

*Part of #85 (start script):*
- [ ] On a Windows + WSL2 host, one documented command creates and starts an issue sandbox for a pushed branch, and ends with `lock: took the lock for #<N> on <branch>`.
- [ ] Inside that sandbox `git config user.name` and `git config user.email` print values, from the sources named above, and running the command again changes neither.
- [ ] Inside it `claude plugin list` shows `superpowers` and `codeo` at the pin, with no manual step.
- [ ] A sandbox whose name disagrees with the lock gets one `todo:` line naming the name to use.
- [ ] The first create for a new clone no longer fails on `dubious ownership`, or prints the one command that fixes it.
- [ ] From inside a sandbox, `git push` of a scratch branch to `origin` succeeds without a login step.
- [ ] `bash tests/run.sh` passes, and `.devcontainer/` still starts a dev container as before.

*Part of #86 (work in and end a sandbox):*
- [ ] From a created issue sandbox, one documented step opens VS Code on the clone folder, and Claude Code, ShellCheck and Markdown Mermaid are installed there.
- [ ] Two open sandboxes show different window titles naming their issues.
- [ ] A Claude Code session in an issue sandbox is titled with its issue.
- [ ] Ending a sandbox with an unfetched, unpushed commit does not remove it without saying so; ending one with nothing to lose removes it.
- [ ] A sandbox created twice on different days uses the same Claude image digest until the pin is changed.
- [ ] The cause of a running sandbox being stopped when another starts is stated in the docs, or shown not to occur in a documented number of repeats.
- [ ] `bash tests/run.sh` passes, and `.devcontainer/` still starts a dev container as before.

*Part of #114 (trust the folder):*
- [ ] In a newly created home container (`codeo-home`), opening Claude Code in VS Code shows no "Trust this folder in Claude Code?" dialog.
- [ ] The same holds in a newly created issue container (`codeo-<N>`), and after "Rebuild Container".
- [ ] The folder's `.claude/settings.json` is in effect in that first session (the codeo plugin is enabled and the session title is set).
- [ ] Only the clone folder is marked trusted; no parent folder is.
- [ ] Keys already in the state file are kept.
- [ ] A state file that is not valid JSON, or not a JSON object, is left untouched and reported as a TODO; the start script still exits 0.
- [ ] `tests/devcontainer.test.sh` covers the new step: trust written, other keys kept, malformed file reported.
- [ ] `.devcontainer/README.md` and `CHANGELOG.md` describe the new behaviour.

**Out of scope.** Each part's own, as the issue carries them. #94: changing the recommendation (hybrid) or doing any part of #85 or #86; `sync-main.sh` exiting 1 after a clean merge (#92); how projects that use codeo run it. #85: retiring the dev container or changing `.devcontainer/` beyond sharing code with the new script; opening the sandbox in VS Code, ending a sandbox without losing work and pinning the `claude` image (#86's); the home container, which stays a dev container; Remote Control inside a sandbox. #86: starting an issue sandbox (#85's); retiring the dev container or the home container; Docker's cloud sandboxes. #114: VS Code's own Workspace Trust prompt (`security.workspace.trust.*`); the permission mode or skipping tool-call prompts; persisting `~/.claude` on a volume; the Claude Code login.

**Open at intake.** #114: where the VS Code extension reads the trust decision from is unverified; the likely place is `projects["<clone path>"].hasTrustDialogAccepted` in `$CLAUDE_CONFIG_DIR/.claude.json`, and planning must confirm it first. #94: whether the sandbox's `gh` token is the real one is untested and may change what #85 and #86 assume. #85: `git push` and authenticated `git fetch` from a `--clone` sandbox were never tried; `user.email` was not checked. #86: whether a sandbox sets `REMOTE_CONTAINERS=true`, and the cause of the unexplained stops, are unknown.

**Footprint note (for `/codeo:plan`).** #116 (in flight, at qc, branch `fix/follow-ups-70-71-104`) lists `.devcontainer/README.md`, `tests/devcontainer.test.sh` and `CHANGELOG.md`, which the #114 part will also change (it does not list `devcontainer-start.sh`). Whichever merges second resolves small list conflicts; `/codeo:plan` raises it through `overlap.sh` once the branch exists. #108, #112 and #102 (not started) overlap #116, not this issue's known files.

## Log

- 2026-11-17 — initialized: branch feat/make-sbx-issue-sandbox-usable off main at 6699326 · cost: 3m · sonnet-5-5 27k in + 830k cached / 6k out
