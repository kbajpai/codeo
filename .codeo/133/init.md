# Issue #133 — init

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/133 |
| Branch | `feat/codeo-command-host-short-bash` |
| Updated | 2026-11-18 |

## Where this stands

Initialized: branch `feat/codeo-command-host-short-bash` cut off `origin/main` at `9f1446158255d557f79970bd3774d418af75c733` and pushed. Next step: `/codeo:plan` in the issue's container.

## Questions

None.

## Outcome

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/133 — A `codeo` command for the host: short bash commands to open, list and remove issue containers and sandboxes (Linux, bash) |
| State | open · labels `enhancement` |
| Branch | `feat/codeo-command-host-short-bash` off `main` at `9f14461` |
| Board | Ready → In progress |

**Problem.** Starting and ending issue work from a host terminal takes long commands: `bash codeo-container.sh issue <N> <branch>`, `bash codeo-sandbox.sh issue <N> <branch>`, `docker rm -f codeo-<N>; docker volume rm codeo-<N>`, and a separate `curl` per script. The issue asks for one supported `codeo` command on the host's PATH (Linux, bash only) that installs and updates itself and the two scripts, runs the short forms of what they do, finds an issue's branch from `.codeo/<N>/init.md` on origin, chooses container or sandbox per issue, lists what runs on the host, and removes a container or sandbox only after a safe check. It is the full, tested version of an interim hand-written wrapper.

**Acceptance criteria** — verbatim from the issue, unchecked:
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

**Out of scope.** macOS, Windows and shells other than bash; changing `codeo-container.sh` or `codeo-sandbox.sh`, or the commands `/codeo:init`, `/codeo:close` and `/codeo:cleanup` print; running the workflow skills from `codeo`; a host run on real Docker or sbx as an acceptance step.

**Open at intake.** None recorded in the issue. It is independent of #131 and #126, which touch nearby code (the sbx removal path and the branch name); `/codeo:plan` checks their footprint when it starts.

## Log

- 2026-11-18 — initialized: branch feat/codeo-command-host-short-bash off main at 9f14461 · cost: 0m · sonnet-5-5 15k in + 607k cached / 3k out
