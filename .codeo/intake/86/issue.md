# Issue #86 — issue

## Questions

1. Which follow-ups, and how many issues? — **Answer:** the five from #73's recommendation (hybrid), consolidated into two issues (engineer, 2026-11-15): the other covers starting an issue sandbox; this one covers working in one and ending it.
2. Is a design question open that changes this issue? — **Answer:** none that the issue must settle. How the extensions are installed, and whether work is fetched or pushed on removal, are `/codeo:plan`'s.

## Notes

Duplicate search (sbx, sandbox): only #73. #70 (print removal commands at close, a print-only `/codeo:cleanup`) is the dev container's cleanup, and the ending in this issue has to fit with it; related, not a duplicate.

## Outcome

**Title:** Work in and end an sbx issue sandbox: VS Code folder and extensions, no lost work on removal, a pinned image

**Labels:** enhancement · **Type:** none

### Description

#73's evaluation recommends a hybrid in which each issue runs in an `sbx` sandbox. Three things around using and ending a sandbox are not covered by the dev container's setup or by `sbx` as it ships: the editor opens with no folder and none of the project's extensions, removing a sandbox loses commits that were not fetched or pushed, and the agent image and the sandbox lifecycle are not stable enough to rely on unattended. This issue closes those three.

### Motivation / Context

Tried on a Windows 11 + WSL2 host with `sbx` v0.53.0 (#73, trials T5 to T12):
- After `sbx setup ssh`, VS Code Remote-SSH to `<name>.sbx` connects and a terminal runs `claude`, but the window opens with no folder and only the GitHub Pull Requests extension; Claude Code, ShellCheck and Markdown Mermaid, which `devcontainer.json` installs, were not there. There is no window title (T12).
- `sbx rm` on a `--clone` sandbox warns that commits made inside are lost unless fetched first (`git fetch sandbox-<name>`, which mirrors them into `refs/sandboxes/<name>/*`) or pushed (T8). The dev container's cleanup is #70.
- The `docker.io/sbx/claude:latest` image changed digest between two creates the same day (T10), so a sandbox is not reproducible from its name.
- A running sandbox was found stopped, twice, right after another was created or started, with no `stop` command and no printed reason; a later check had both running together (T9).

### Key Requirements

- Opening an issue sandbox in VS Code gives a window on the sandbox's clone folder, with the three extensions in `devcontainer.json` available, and a way to tell the windows of two sandboxes apart.
- Ending an issue's sandbox never loses work silently: before `sbx rm`, commits inside the sandbox are either fetched into the host repository or pushed, or the engineer is told which are not and the removal waits. It sits with #70's cleanup, so there is one way to finish an issue.
- The Claude image a sandbox uses is pinned to a digest the project chooses, and moving the pin is a deliberate change.
- The unexplained stops are either explained and avoided, or documented with the condition that triggers them and what to run to recover.

### Acceptance Criteria

- [ ] From a created issue sandbox, one documented step opens VS Code on the clone folder, and Claude Code, ShellCheck and Markdown Mermaid are installed there.
- [ ] Two open sandboxes show different window titles naming their issues.
- [ ] Ending a sandbox with an unfetched, unpushed commit does not remove it without saying so; ending one with nothing to lose removes it.
- [ ] A sandbox created twice on different days uses the same Claude image digest until the pin is changed.
- [ ] The cause of a running sandbox being stopped when another starts is stated in the docs, or shown not to occur in a documented number of repeats.
- [ ] `bash tests/run.sh` passes, and `.devcontainer/` still starts a dev container as before.

### Out of Scope

- Starting an issue sandbox (lock, identity, plugins, the pushed branch, the Windows Git trust step): the other issue.
- Retiring the dev container, or the home container.
- Docker's cloud sandboxes.

### Reference

- #73 and its page `docs/dev-environment-sbx-evaluation.md`: rows D2, D3, D4, U13, U18; trials T8 to T12.
- Related: #70 (cleanup).
