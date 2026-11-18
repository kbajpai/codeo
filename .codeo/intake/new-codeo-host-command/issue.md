# Issue — new-codeo-host-command

## Questions

1. Install and update — answered: one download line plus `codeo update`.
2. Commands — answered: branch lookup, `codeo list`, safe removal, container-or-sandbox per issue.
3. Done — answered: stub tests, both READMEs, CHANGELOG; no real-host run.
4. Ordering — answered: independent of #131 and #126, dependency noted.

## Outcome

Proposed: label `enhancement`, no Issue Type (the repo has none).

## Draft

**Title:** A `codeo` command for the host: short bash commands to open, list and remove issue containers and sandboxes (Linux, bash)

### Description

Add a supported `codeo` command for the host's bash, so an engineer starts and ends issue work with short commands instead of long script invocations. Today that takes `bash codeo-container.sh issue <N> <branch>`, `bash codeo-container.sh shell <N>`, `bash codeo-sandbox.sh issue <N> <branch>`, `docker rm -f codeo-<N>; docker volume rm codeo-<N>`, and a separate `curl` download of each of the two scripts. This issue is the full, tested, documented version of an interim wrapper the engineer wrote by hand (a single bash script that dispatches to the two scripts; it is not in the repository). It covers Linux and bash only.

### Motivation / Context

`/codeo:init` and `/codeo:close` already print these long commands, and the engineer types or pastes them for every issue, in a container or a sandbox, with the branch and number filled in by hand. Running several issues in parallel from the host (one `codeo-<N>` each, with the home container kept open) multiplies that. The interim wrapper shortens the commands but leaves the branch lookup, the choice between container and sandbox, a list of what is running, and a safe removal to the engineer.

### Key Requirements

- **One command on the host's PATH**, `codeo`, for Linux and bash. No macOS, no Windows, and no other shell, in this issue.
- **Install and update.** One download line installs `codeo`, the way the two scripts are fetched today, and `codeo update` refreshes `codeo` and the two scripts it calls from `main`. A missing script is downloaded on first use rather than failing.
- **Short commands for what the two scripts do today:** open the home container, open an issue's container, open a shell in either, and for a sandbox create it, open it in VS Code, open a shell and end it.
- **`codeo issue <N>` needs no branch.** `codeo` finds the branch that carries `.codeo/<N>/init.md` on origin, and stops with one line, naming what it found, when there is none or more than one. A branch given explicitly still works.
- **Container or sandbox is chosen per issue,** by a flag on the command, or by one default the engineer sets once (not a separate command word for each).
- **`codeo list`** shows the issue containers and sandboxes on this host, with each one's issue number and branch.
- **Removal runs the safe check.** `codeo rm <N>` removes an issue's container (and its volume) or its sandbox, whichever it is, and refuses while anything in it is unpushed or uncommitted, with an explicit override.
- **Arguments are checked** before any command runs: an issue number that is not a number, a missing branch, or an unknown command stops with a usage line and a non-zero exit, and nothing is created.
- **Where it works.** The clones and downloaded scripts live in one directory (default under the home directory, overridable), so the command works from any current directory.
- **No change to what the two scripts do.** `codeo` calls them; where something it needs is missing from them, that is a separate change.

### Acceptance Criteria
- [ ] One download line installs `codeo` on a Linux host with only `bash`, `curl` and `git`, and `codeo help` prints the commands.
- [ ] `codeo update` replaces `codeo` and both scripts with the versions on `main`, and a failed download leaves the installed files unchanged.
- [ ] `codeo home`, `codeo shell home|<N>` and `codeo issue <N> [<branch>] [--rebuild]` run the matching `codeo-container.sh` command from the `codeo` directory, whatever the current directory is.
- [ ] `codeo issue <N>` with no branch uses the branch on origin that carries `.codeo/<N>/init.md`; with none or several it prints one line naming what it found and creates nothing.
- [ ] An issue is opened as a container or as a sandbox by the flag or the saved default, and the sandbox commands (create, open, shell, end) are reachable from `codeo`.
- [ ] `codeo list` prints each issue container and sandbox on the host with its issue number and branch, and prints nothing misleading when there are none.
- [ ] `codeo rm <N>` refuses, naming what is unpushed or uncommitted, when there is any, and removes the container and its volume, or the sandbox, when there is none; the override removes it anyway.
- [ ] A non-numeric issue number, a missing argument and an unknown command each print a usage line, exit non-zero and run no `docker`, `sbx` or script command.
- [ ] A test in `tests/` runs `codeo` against stub scripts and a stub `docker` and `sbx`, and covers each command above, including the argument errors and the branch lookup with none, one and several matches; `tests/run.sh` passes.
- [ ] `.devcontainer/README.md` and `.sbx/README.md` show the `codeo` commands beside the long ones, and `CHANGELOG.md` has an entry.

### Out of Scope

- macOS, Windows, and shells other than bash.
- Changing `codeo-container.sh` or `codeo-sandbox.sh`, or the commands `/codeo:init`, `/codeo:close` and `/codeo:cleanup` print (a later issue may point them at `codeo`).
- Running the workflow skills (`/codeo:plan` and the rest) from `codeo`.
- A host run on real Docker or sbx as an acceptance step; the criteria use stubs.

### Reference

- `.devcontainer/README.md` (command-line section), `.sbx/README.md`, `.devcontainer/codeo-container.sh`, `.sbx/codeo-sandbox.sh`.
- Related and in flight: #131 (the sbx lock and the sandbox removal path) and #126 (the issue number in the branch name, which changes how a branch is found). This issue is independent of both; the plan checks their footprint when it starts, and the branch lookup and the removal command may need a one-line change if they land first.
- Surfaced by the engineer during `/codeo:triage` (2026-11-18), alongside an interim hand-written wrapper.
