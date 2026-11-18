# Issue #133 — plan

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/133 |
| Branch | `feat/codeo-command-host-short-bash` |
| Updated | 2026-11-18 |

## Where this stands

Q1-Q5 are answered. Q6 (the three files shared with #131) is open; the plan is drafted and shown once it is answered.

What I found that shapes the questions:

- `codeo-container.sh` has no removal command and no listing. `codeo rm <N>` for a container and `codeo list` are therefore new logic inside `codeo` itself (the issue forbids changing the two scripts). For a sandbox, `codeo-sandbox.sh end <N> [--force]` already does the safe check.
- `codeo-sandbox.sh` makes and reads the clone `./codeo-<N>` in the current directory, so `codeo` must `cd` to its own directory before every call. `codeo-container.sh` keeps nothing on the host.
- Both scripts hold their own argument checks (exit 2). `codeo` repeats the number and branch checks so that nothing runs on a bad argument.
- The `shell` suite has no single-test filter, so every task's proof is `bash tests/run.sh`. The stub pattern to copy is `tests/sandbox.test.sh` (a `PATH` of stubs that log each call to a file).

## Questions

### Q1 — Where does `codeo` install, and where does its file live in the repository?

**Why it matters:** it decides the download line in both READMEs, what `codeo update` replaces, and which folder the plan adds a file to.
**Options:**
- **A — the command in `~/.local/bin`, everything else in `~/codeo` (my pick).** The download line is `mkdir -p ~/.local/bin && curl -fsSL -o ~/.local/bin/codeo <raw URL> && chmod +x ~/.local/bin/codeo`. The two scripts, the sandbox clones `codeo-<N>` and the saved default live in `~/codeo` (`CODEO_HOME` names another directory). `codeo` creates `~/codeo` and downloads a missing script on first use. When `~/.local/bin` is not on `PATH`, `codeo help` run by its full path prints the one line to add to `~/.bashrc`; `codeo` never edits `~/.bashrc` itself.
- **B — everything in `~/codeo`.** `codeo` sits beside the two scripts and the engineer adds `~/codeo` to `PATH` by hand. One directory to delete, but a `PATH` edit is always needed, and the clones `codeo-<N>` then sit in a `PATH` directory.
- **C — `curl … | bash -s install`.** The script installs itself and can edit `~/.bashrc`. Shortest line, but it runs a piped download and changes a login file.

In the repository I would put the file at `.devcontainer/codeo` (no extension, executable), beside `codeo-container.sh`, which is the script every route needs; the `shell` suite's paths already cover it. Say so if you want a new top-level folder (for example `host/codeo`) instead, which also needs a line in `.codeo/config.json`.

**Answer:** A — the command in `~/.local/bin`, everything else in `~/codeo`; the file is `.devcontainer/codeo`. (Engineer: "go with my picks", 2026-11-18.)

### Q2 — Is this the command set you want? And does your interim wrapper use names you want kept?

**Why it matters:** the names become the documented interface and the test cases. The issue fixes `home`, `shell`, `issue`, `list`, `rm`, `update` and `help`; the sandbox-only words and the flags are mine.

| Command | Runs |
|---|---|
| `codeo home [--rebuild]` | `codeo-container.sh home [--rebuild]` |
| `codeo issue <N> [<branch>] [--rebuild] [--container\|--sandbox]` | `codeo-container.sh issue …` or `codeo-sandbox.sh issue …` (branch looked up when not given) |
| `codeo shell home\|<N>` | the container's or the sandbox's `shell` (Q3 says which) |
| `codeo open <N>` | `codeo-sandbox.sh open <N>` (VS Code; sandbox only, one line and exit 1 for a container) |
| `codeo list` | new: issue containers and sandboxes with number and branch |
| `codeo rm <N> [--force]` | container: safe check, then `docker rm -f` and `docker volume rm` (Q4); sandbox: `codeo-sandbox.sh end <N> [--force]` |
| `codeo default [container\|sandbox]` | prints or saves the default kind for `issue` |
| `codeo update` | replaces `codeo` and both scripts from `main` |
| `codeo help` | the list above |

Two points to confirm: the sandbox's `end` is reached as `codeo rm <N>` only (no separate `codeo end`), and `--rebuild` with `--sandbox` is refused with a usage line, because `codeo-sandbox.sh issue` has no rebuild. If your wrapper has other names or shortcuts you rely on, paste them or name them here.

**Options:** as in the table · as in the table, plus `codeo end <N>` as a second name for a sandbox's `rm` · changes, named in the answer.

**Answer:** As in the table; `codeo rm <N>` is the only way to end a sandbox, and `--rebuild` with `--sandbox` is refused. (Engineer: "go with my picks".)

### Q3 — For an issue that already exists on the host, how should `shell`, `open` and `rm` decide between container and sandbox?

**Why it matters:** the flag and the saved default say what `issue` creates. Later commands act on what is there, and the saved default may have changed since.
**Options:**
- **A — look at the host (my pick).** `codeo` asks `docker` for a container `codeo-<N>` and `sbx ls` for a sandbox `codeo-<N>`. One found: use it. Neither: one line naming `codeo issue <N>`, exit 1. Both: one line saying both exist, and the same command with `--container` or `--sandbox` picks one. A missing `docker` or `sbx` program counts as "none of that kind", so a host with only one of them works.
- **B — the saved default, unless a flag is given.** No lookup, but `codeo shell 133` fails for a sandbox issue on a host whose default is `container`.

The saved default is one word in `~/codeo/default` (written by `codeo default sandbox`); with no file it is `container`. `CODEO_KIND` in the environment is not read: one mechanism only. Say so if you would rather set it in the environment.

**Answer:** A — look at the host; the saved default is `~/codeo/default`, `CODEO_KIND` is not read. (Engineer: "go with my picks".)

### Q4 — What must `codeo rm <N>` prove for a container before it removes it, and does it remove the image too?

**Why it matters:** this check is new code and it deletes a volume. A sandbox's check already exists (`end`); the container's has to be defined here.

My proposal, run through `docker exec` in `/workspaces/codeo-<N>` (a stopped container is started first):

1. `git fetch origin` in the clone. If it fails, nothing is removed, with or without `--force`… unless you choose otherwise below.
2. Refuse, listing up to 10 lines of each, when there are: uncommitted or untracked changes (`git status --porcelain`), stashes (`git stash list`), a detached HEAD, or commits on any local branch that no `origin` branch holds (`git rev-list --branches --not --remotes=origin`).
3. Otherwise `docker rm -f codeo-<N>` and `docker volume rm codeo-<N>`, then one line `removed codeo-<N>`.

`--force` skips step 2 and removes anyway, saying what was not kept. Nothing is set aside for a container (a sandbox's `--force` keeps refs in the host clone; a container has no host clone to keep them in).

**Options, two parts:**
- **When the check itself cannot run** (the container will not start, the fetch fails, there is no clone): `--force` still removes it, and says nothing could be checked (my pick: otherwise a broken container can only be removed by typing the `docker` commands) · nothing is removed even with `--force`, and the line names the raw `docker` commands.
- **The image `codeo-dev:codeo-<N>`:** `rm` removes it too, after the volume, and a failure to remove it is only a warning (my pick) · left alone, as the READMEs describe today.

Unlike `end`, this check does not count a commit that is only on a pull request's head as delivered: in a container the branch is pushed to origin itself, so it does not arise. The Claude Code login on the volume is lost with it, as today; `rm` says so in its `removed` line.

**Answer:** As proposed: fetch, refuse on uncommitted changes, stashes, detached HEAD or unpushed commits; `--force` skips the refusal and also removes when the check cannot run; the image `codeo-dev:codeo-<N>` is removed too, a failure there only a warning. (Engineer: "go with my picks".)

### Q5 — What should `codeo list` show?

**Why it matters:** it decides the columns, whether a stopped container is started just to be read, and what an empty host prints.

My proposal, one row each, containers first, sorted by number:

```
#131  container  running   feat/make-sbx-sandbox-lock-follow
#133  sandbox    detached  feat/codeo-command-host-short-bash
#140  container  stopped   -
```

- A container's branch is read with `docker exec … git branch --show-current`; a stopped container is not started, and its branch is `-`.
- A sandbox's branch is read from the host clone `~/codeo/codeo-<N>` with `git`, with no `sbx exec`, so listing never starts a stopped sandbox; with no clone it is `-`.
- With nothing to list it prints `no issue containers or sandboxes` and exits 0. A missing `docker` or `sbx` program is skipped silently; when both are missing it says so and exits 1.

**Options:** as proposed · as proposed, plus a first row for `codeo-home` when it exists · start nothing, but read a stopped container's branch another way (say which) · changes, named in the answer.

**Answer:** As proposed: containers first, a stopped container's branch `-`, no `codeo-home` row. (Engineer: "go with my picks".)

### Q6 — How do we coordinate the three files this plan shares with #131?

**Why it matters:** two parallel branches that edit the same README section or changelog block conflict at merge, and the second one to merge has to resolve it by hand.

**What overlaps.** #131 (branch `feat/make-sbx-sandbox-lock-follow`, assignee kbajpai, step `init`, waiting on `/codeo:plan`) has a footprint that includes `glob:.devcontainer/README.md`, `glob:.sbx/README.md` and `glob:CHANGELOG.md`. This plan edits all three: the `codeo` form beside each long command in both READMEs (the sections *Opening a container from the command line*, *Removing a finished container*, *Rebuilding*; *Getting the script*, *Commands*, *Ending a sandbox*) and one changelog bullet. #131 also lists `.sbx/codeo-sandbox.sh`, which this plan never edits and only calls through `end <N> [--force]`. Neither branch has changed a file yet (`changed: none`).

**Options:**
- **A — proceed and coordinate (my pick).** Each plan edits different sections and adds its own changelog bullet under `## Unreleased`; whichever merges second rebases and keeps both. The plan adds `## Unreleased` to `CHANGELOG.md` only if it is still absent when the task runs.
- **B — sequence after #131.** This plan waits for #131 to merge, then edits the READMEs as #131 left them. No conflict, but #133 is held until #131 is planned, built and merged.
- **C — re-scope.** Drop the README edits from this plan and file them as a separate issue to follow both. The acceptance criterion that names the READMEs would then be moved by the engineer.

**Answer:**

## Notes

Calls made without a question. Each is mine; correct any of them in an answer above or in a line here.

- **One plan, one pull request.** Shape: an implementation plan under `docs/plans/`, no standing reference doc; the command is documented in the two READMEs, as the criteria ask.
- **Branch lookup.** The host has only `bash`, `curl` and `git`, and the repository may be private, so `codeo` keeps a blob-less bare clone at `~/codeo/.lookup.git` (`git clone --bare --filter=blob:none`), fetches it on each lookup, and tests every `origin` branch with `git cat-file -e <branch>:.codeo/<N>/init.md`. Exactly one match is the branch. None: `codeo: no branch on origin carries .codeo/<N>/init.md: run /codeo:init #<N> first, or give the branch`. Several: one line listing them, and nothing is created. Rejected: `raw.githubusercontent.com` per branch (fails on a private repository, one request per branch) and the GitHub API (needs a token on the host). `CODEO_REPO_URL` is honoured, as in both scripts. #126 (the number in the branch name) does not change this: the lookup reads the dossier, never the name.
- **Update is all or nothing.** The three files are downloaded into a temporary directory in `~/codeo`, each checked to be non-empty and to start with `#!`, and only then moved over the installed ones (`mv` within one filesystem for the scripts; `codeo` itself is replaced last). Any failed download removes the temporary directory and changes nothing. `CODEO_RAW_URL` names another base URL, which is also how the tests point it at a stub `curl`.
- **Argument checks come first.** A number is a positive integer with no leading zero and a branch matches the two scripts' rule, checked before any `docker`, `sbx`, `git`, `curl` or script call; a failure prints the usage on stderr and exits 2, as both scripts do.
- **Exit status.** `codeo` ends with the called script's status (it `exec`s the script where it can).
- **Bash 4.3 or later, Linux only.** No macOS workarounds.
- **No task runs on the engineer's host.** The issue excludes a real Docker or sbx run, so no `Runs on:` task and no shell question, although the lock's host is `container`.
- **Tests:** one new file, `tests/codeo-command.test.sh`, with stub `docker`, `sbx`, `git`, `curl` and stub copies of the two scripts in a scratch `CODEO_HOME`, each logging its call; it covers every command, the three argument errors, the lookup with none, one and several matches, update's success and failed download, and `rm` for both kinds with and without `--force`.
- **Documentation the change moves:** `.devcontainer/README.md` (*Opening a container from the command line*, *Removing a finished container*, *Rebuilding*: the `codeo` form beside each long command, and a short section on installing `codeo`), `.sbx/README.md` (*Getting the script*, *Commands*, *Ending a sandbox*), `CHANGELOG.md`. The repository `README.md` gets a line only if it already names the host scripts. No skill, overlay or printed command changes (out of scope).
- **#131 is in flight** (`feat/make-sbx-sandbox-lock-follow`, kbajpai, at `init`, waiting on its own Q1-Q5). It has no footprint yet and its branch has changed nothing, so there is nothing to compare. From its dossier it will edit `.sbx/codeo-sandbox.sh`, `.sbx/README.md`, `.devcontainer/README.md` and `CHANGELOG.md`; this plan edits the last three. `codeo` only calls `end <N> [--force]`, whose interface #131 keeps under either answer to its Q3. The overlap is raised as a numbered question once either footprint exists (`overlap.sh`, at this plan's hand-off). #126 has no workflow in flight.

### Footprint

```
files:      .devcontainer/codeo, .devcontainer/README.md, .sbx/README.md, CHANGELOG.md, tests/codeo-command.test.sh, docs/plans/2026-11-18-codeo-host-command-133.md
wiki:       none
exclusive:  none
sequenced:  none
```

## Outcome

_Pending — written at the hand-off._

## Log

- 2026-11-18 — Q1-Q5 raised · cost: 1m · fable-5-2 77k in + 584k cached / 5k out
