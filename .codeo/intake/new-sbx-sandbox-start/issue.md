# Issue new-sbx-sandbox-start — issue

## Questions

1. Which follow-ups, and how many issues? — **Answer:** the five from #73's recommendation (hybrid), consolidated into two issues (engineer, 2026-11-15): this one covers starting an issue sandbox; the other covers working in one and ending it.
2. Is a design question open that changes this issue? — **Answer:** none that the issue must settle. Where the script lives, whether it runs on the host or inside the sandbox, and how the identity is passed are `/codeo:plan`'s; #73's evidence for each is in the Reference.

## Notes

Duplicate search (sbx, sandbox, start script, devcontainer): only #73 mentions sbx. The start-script issues #40, #54, #57, #81 are about the dev container's own script and are not this. Related: #73, #70.

## Outcome

**Title:** Start an sbx issue sandbox: a start script for the lock, identity and plugins, on the pushed branch

**Labels:** enhancement · **Type:** none

### Description

#73's evaluation (`docs/dev-environment-sbx-evaluation.md`, in its pull request) recommends a hybrid: keep the dev container for the home container and for editor-centred work, and run each issue in an `sbx` sandbox. A sandbox has no create-time hook and no git identity, and starts on whatever ref the host has checked out, so what `devcontainer-start.sh` does for an issue container does not happen by itself. This issue adds the start-up for an issue sandbox.

### Motivation / Context

Tried on a Windows 11 + WSL2 host with `sbx` v0.53.0 (#73, trials T3 to T9):
- `sbx create --clone` makes the clone inside the sandbox but follows the ref checked out on the host, and makes no branch (docs; not tried).
- `git config user.name` printed nothing inside a sandbox, so there is no git identity (T7).
- `.devcontainer/scripts/plugins.sh` ran unchanged inside a sandbox and installed `superpowers` and `codeo`; plugins do not survive a recreate (T7, T8).
- The workflow lock, the folder check and the TODO lines were not tried; they are shell scripts that would run through `sbx exec` (docs).
- Each clone needs its own `safe.directory` entry in Windows Git before `sbx` accepts it, and the host program is `sbx.exe` from WSL (T3, T9).

### Key Requirements

- Starting an issue sandbox from a branch `/codeo:init` pushed puts the sandbox on that branch, with the clone's `.codeo/active` lock taken from the branch's `init.md`, as the dev container's start script does.
- A new sandbox has a git identity (`user.name`, `user.email`), from the same sources the dev container uses (the host's `~/.gitconfig`, else `GIT_AUTHOR_NAME` / `GIT_AUTHOR_EMAIL`), and never a value already set.
- A new sandbox has the two pinned plugins installed (`superpowers`, and `codeo` at the pin in `.codeo/config.json`).
- The sandbox's name is checked against the lock the way the dev container's folder check compares the clone folder, with a printed `todo:` line when they disagree.
- The per-clone Windows Git trust step is done, or its command is printed, before `sbx create`, so a first create does not fail with `dubious ownership`.
- What is still left for the engineer (logins, identity) is printed as `todo:` lines, as today.
- The dev container's own start script is unchanged, and keeps working.

### Acceptance Criteria

- [ ] On a Windows + WSL2 host, one documented command creates and starts an issue sandbox for a pushed branch, and ends with `lock: took the lock for #<N> on <branch>`.
- [ ] Inside that sandbox `git config user.name` and `git config user.email` print values, from the sources named above, and running the command again changes neither.
- [ ] Inside it `claude plugin list` shows `superpowers` and `codeo` at the pin, with no manual step.
- [ ] A sandbox whose name disagrees with the lock gets one `todo:` line naming the name to use.
- [ ] The first create for a new clone no longer fails on `dubious ownership`, or prints the one command that fixes it.
- [ ] `bash tests/run.sh` passes, and `.devcontainer/` still starts a dev container as before.

### Out of Scope

- Retiring the dev container or changing `.devcontainer/` beyond sharing code with the new script.
- Opening the sandbox in VS Code, ending a sandbox without losing work, and pinning the `claude` image: the other issue.
- The home container, which stays a dev container.
- Remote Control inside a sandbox (not tried in #73).

### Reference

- #73 and its page `docs/dev-environment-sbx-evaluation.md`: rows U2, U3, U5, U7, U9, U12; trials T3, T7, T8, T9.
- `.devcontainer/scripts/devcontainer-start.sh`, `plugins.sh`, `folder-check.sh`.
- Related: #70 (cleanup), #51 (git-identity seeding).
