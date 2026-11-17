# Issue #113 — plan

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/113 |
| Branch | `feat/cmd-mode-start-use-home` |
| Updated | 2026-11-16 |

## Where this stands

Round 2, after a send-back from `qc.md` round 2: Q5 is answered (refuse) and the follow-up plan `docs/plans/2026-11-16-cmd-mode-existing-container.md` is approved and written, unstaged for the engineer to commit. Nothing is open.

## Questions

### Q1 — How does the host script reach a machine that has only Docker?

**Why it matters:** the script lives in this repository, but a host with only Docker has no clone and may have no git. The answer decides the "one documented command" in the README and in the `init` hand-off, and whether the script must build the image without a local `Dockerfile`.

**Options:**
- *Download once, then run it* (recommended): the README gives one `curl` line that saves the script from `main` on GitHub, and every later command is `bash codeo-container.sh home`, `… issue <N> <branch>`, `… shell <name>`, `… rm <name>`. The script builds the image straight from the GitHub URL of the branch (Docker's BuildKit fetches it), so the host needs no git and no clone. It also works when run from a clone. Needs `curl` once; macOS and nearly every Linux have it.
- *Require a clone on the host:* `git clone`, then run the script from the clone, which builds from the `Dockerfile` beside it. Simpler script, but the host needs git, which the issue's "needing only Docker" rules out as I read it.
- *Pipe it every time:* `curl … | bash -s -- home` for each command. Nothing is saved on the host, but every command is a long line and needs the network.

**Answer:**
Accepted the recommendation: download the script once with a `curl` line, then run it; the image is built from the GitHub URL, so the host needs no git and no clone (engineer, in the conversation, 2026-11-16).

### Q2 — Should a cmd-mode container keep the Claude login across a rebuild?

**Why it matters:** left open at intake. Today `/home/dev/.claude` is on no volume, so a rebuild loses the login, past sessions and settings. The answer decides whether the script adds a mount and where `CLAUDE_CONFIG_DIR` points, and whether cmd mode then differs from the VS Code route.

**Options:**
- *Keep it per container, inside the container's own volume* (recommended): in cmd mode `CLAUDE_CONFIG_DIR` points at a folder on the `codeo-<N>` volume, beside the clone. A rebuild keeps the login; `docker volume rm codeo-<N>`, the command `/codeo:close` and `/codeo:cleanup` already print, removes it with everything else, so nothing is left behind. Each new container still needs one `claude auth login`, as today.
- *One shared `codeo-claude` volume for every cmd-mode container:* log in once for all containers. But sessions, settings and installed plugins are then shared between containers whose branches may pin different plugin versions, and the volume outlives every removal command.
- *Leave it as it is:* same as the VS Code route; a rebuild means `claude auth login` again. Least to build and to test.

**Answer:**
Accepted the recommendation: keep the Claude config per container, on the container's own `codeo-<N>` volume (engineer, in the conversation, 2026-11-16).

### Q3 — On which machines, and in which shell, will you run the host checks?

**Why it matters:** this session runs inside a container with no Docker, so the first six acceptance criteria and the VS Code one can only be shown on your machines; the plan marks those tasks `Runs on: the engineer's host` and writes their commands for your shell. Your machine looks like Windows with WSL2. I need two things:
1. For the Linux criterion: is a WSL2 distribution with Docker the Linux host, and is the shell there bash?
2. For the macOS criterion (`/bin/bash` 3.2, no GNU tools): do you have a Mac to run it on?

With a Mac, the plan ends with a host task there. Without one, the only proof this suite can give is a test that scans the script for constructs bash 3.2 and BSD tools lack (associative arrays, `mapfile`, `${x,,}`, `readlink -f`, `sed -i`, `stat -c` and the like), and the plan says plainly that the macOS criterion is unproven on a real Mac until someone runs it. I would write that test either way.

**Answer:**
"I own a mac" (engineer, in the conversation, 2026-11-16). That settles the macOS criterion: the plan ends with a host task on the Mac, run with `/bin/bash`. The Linux half went unanswered; I take the Linux host to be WSL2's bash and write every host command neutral (one command, no shell variable), so the shell does not matter. Say so if that is wrong.

### Q4 — #104 also changes `CHANGELOG.md`: proceed, wait, or re-scope?

**Why it matters:** #104 (branch `feat/publish-live-session-signal-so`, assignee kbajpai, at `qc`) lists `CHANGELOG.md` in its footprint, and this plan adds its own bullet under `## Unreleased` in `CHANGELOG.md`. The overlap is `glob:CHANGELOG.md`. Nothing else overlaps: #104's other files are under `scripts/`, `hooks/`, `skills/`, `docs/` and `tests/`, none of which this plan touches by the same path.

**Options:**
- *Proceed and coordinate* (recommended): both add one bullet to the same list; whichever merges second resolves a one-line conflict, which `/codeo:close` already routes.
- *Sequence after #104:* this plan's changelog task waits until #104 merges.
- *Re-scope:* leave `CHANGELOG.md` out of this change.

**Answer:**
Accepted the recommendation: proceed and coordinate (engineer, in the conversation, 2026-11-16).

### Q5 — What does `issue <N> <branch>` do when `codeo-<N>` already exists?

**Why it matters:** QC round 2's R1 (blocking, the plan's). The plan said a second run "creates nothing and runs the start script again". That reuses whatever clone the container holds. After a stash, `/codeo:init #<N>` in the home container prints `bash codeo-container.sh issue <N> <branch>` as the way back; if the old container was not removed first, that command re-runs the start script in the stale clone and `lock.sh` takes the lock there from its old `init.md`. In the VS Code route Docker's `name already in use` stops this; `role.sh` says a stashed container is left through `/codeo:init`, "never the start script". A mistyped branch is accepted the same way. The answer decides the script's behaviour, two README paragraphs and the init hand-off's text.

**Options:**
- *Refuse, as Docker does for VS Code* (recommended): `issue` on an existing `codeo-<N>`, running or stopped, changes nothing and exits 1 with one line that names the ways on: `bash codeo-container.sh shell <N>` to enter it (the start script is re-run from inside, as its own TODO lines already say), `--rebuild` to rebuild it, and the removal commands to start afresh, which is the stash-resume path. `issue … --rebuild` keeps working on an existing container but first checks that the clone is on `<branch>` and refuses on a mismatch. `home` keeps its re-run: it has no lock and no stash. This gives cmd mode the same safeguard as the VS Code route with the least new logic; the cost is that "run it again to see the TODO list" becomes `shell`, then the start script.
- *Check, then reuse:* keep the re-run, but only after the script checks that the clone is on `<branch>` and that `role.sh` in it does not report a stashed, abandoned or finished workflow. Friendlier, but the host script then depends on `role.sh`'s output, and a stale clone whose dossier has not been fetched since the stash's resume can still pass.
- *Leave the behaviour, fix the words:* keep the re-run and only add "remove the old container first" to the init hand-off and the README. Least work; the silent reuse stays.

**Answer:**
Accepted the recommendation: refuse, as Docker does for the VS Code route (engineer, in the conversation, 2026-11-16).

## Notes

Calls I am making unless you say otherwise in an answer:

- **Script and commands.** One file, `.devcontainer/codeo-container.sh`, written for bash 3.2 and BSD tools, with the sub-commands `home`, `issue <N> <branch>`, `shell <name>`, `rebuild <name>` and `rm <name>`. `issue` takes the number as well as the branch because the container and volume names are needed before anything is cloned; `/codeo:init` prints both filled in.
- **Same layout as VS Code's.** The volume `codeo-home` / `codeo-<N>` is mounted at `/workspaces` and the clone is `/workspaces/codeo-home` / `/workspaces/codeo-<N>`, with `--name`, `--memory=4g`, the `codeo-gh` and `codeo-git` volumes and `GIT_CONFIG_GLOBAL` as in `devcontainer.json`. So `role.sh`, `folder-check.sh`, `lock.sh`'s `volume:` line and the removal commands work unchanged. The repository is public, so the clone inside the container needs no login.
- **Telling the two routes apart.** The script starts the container with one environment variable of its own (`CODEO_CMD_MODE=1`). With it set, `devcontainer-start.sh` does not run `window-title.sh` and does not wait for a `~/.gitconfig` copy, and `session-title.sh` titles the session without writing `.vscode/settings.json`. `REMOTE_CONTAINERS=true` keeps meaning VS Code, and that path is not changed.
- **Git identity.** When the host has git, the script reads `user.name` and `user.email` from it and passes them to the start script only, as `GIT_AUTHOR_NAME` / `GIT_AUTHOR_EMAIL`; they are not left set in the container, where they would override the volume's config on every commit.
- **Which container the terminal is in.** The container's hostname is its name, so the prompt reads `dev@codeo-113`, and `shell` sets the terminal's title to `codeo [#113]` or `codeo [home]`.
- **Remote Control** (the other intake question) cannot be answered here: it has to be tried. The plan gets a host task that tries it in a cmd-mode container and the README records what happened; if it does not work, that becomes its own issue, not part of this change.
- **`devcontainer.json` is not changed,** and one pull request carries the whole change.
- **Documentation the change moves:** `.devcontainer/README.md` (opening, rebuilding and removing a container from the command line; the git identity and title paragraphs), `.codeo/overlays/init.md` (the hand-off prints the command-line step beside the VS Code one), `CHANGELOG.md`.


**Round 2 (send-back from qc.md round 2).** Calls I am making unless you say otherwise in Q5's answer:

- **One short follow-up plan,** `docs/plans/2026-11-16-cmd-mode-existing-container.md`, with the first plan as its Spec; the first plan's text is not edited. Same footprint files, plus the new plan file.
- **R2 (`CODEO_CONTEXT`):** the behaviour stays; the README, the script's header and the changelog line say it is the `.devcontainer` directory of a local clone, that only the image is built from it, and that the clone still comes from `CODEO_REPO_URL`.
- **R3 (terminal title):** the words change, not the behaviour: `shell` sets the title once, and the container's prompt (`dev@codeo-<N>`) then names the terminal. Making the title last would mean changing the image's shell start-up, which the VS Code route shares.
- **R4-R6** go in as small fixes: the README's list of differences gains `--init`; a failing `docker info` prints Docker's own reason instead of "install it and start it"; `session-title.sh` accepts any non-empty `CODEO_CMD_MODE`, as the start script does.
- **R7 and R8** change nothing: bash 3.2 on a real Mac is Task 10's, and the image's removal is already in the README.

## Outcome

| | |
|---|---|
| Plan | `docs/plans/2026-11-16-cmd-mode-containers.md` (approved by the engineer in the conversation, 2026-11-16; left unstaged) |
| Shape | an executable plan under `docs/plans/`, ten tasks; no separate reference doc, because `.devcontainer/README.md` becomes the standing reference |

**Decisions.**
- A plain host script, `.devcontainer/codeo-container.sh` (bash 3.2, builtins plus `docker` and `git`), with `home [--rebuild]`, `issue <N> <branch> [--rebuild]` and `shell home|<N>`. It builds the image from the repository's GitHub URL, so the host needs no clone (Q1), and runs the container with the VS Code route's names, volumes and memory cap.
- The Claude config of a cmd-mode container sits at `/workspaces/.claude` on the container's own volume, so a rebuild keeps the login and removing the volume removes it (Q2).
- `CODEO_CMD_MODE=1`, set on the container, is how the start script and `session-title.sh` skip the `.vscode/settings.json` write and the host `~/.gitconfig` wait; `REMOTE_CONTAINERS=true` keeps meaning VS Code. `devcontainer.json` is not edited.
- The host's git identity goes to the start script's `docker exec` only, as `GIT_AUTHOR_*`, and never overwrites the volume's.
- The Mac is the engineer's; Task 10 runs the host checks on WSL2 and on the Mac (Q3). Linux is taken to be WSL2's bash, with neutral commands.
- `CHANGELOG.md` overlaps #104's footprint; proceed and coordinate (Q4).

**Options rejected.** The `devcontainer` CLI (needs Node on the host; ruled out in #36's plan); Docker Sandboxes (#99); requiring a clone on the host, or piping the script on every run (Q1); one shared `codeo-claude` volume, or leaving the login to be lost on rebuild (Q2); a `rm` sub-command (the removal commands `/codeo:close` and `/codeo:cleanup` print already serve).

**Documentation the plan changes.** `.devcontainer/README.md` (a command-line section with a Mermaid sequence diagram, rebuild, removal, identity, titles), `.codeo/overlays/init.md` (the hand-off's command-line step) and `CHANGELOG.md`. No page under `docs/` moves.

**Intake questions resolved.** Whether cmd mode keeps the Claude login across rebuilds: yes, on the container's volume (Q2). Whether Remote Control works without VS Code is not resolved: it has to be tried, as Task 10's step 3, and a failure becomes its own issue.

**What only the engineer can prove.** The Linux and macOS criteria, the VS Code route and the `init` hand-off in a cmd-mode home container run on the engineer's machines (Task 10; the hand-off check only after the pull request merges). This suite proves the host script's calls against a stub `docker` and scans it for bash 4 and GNU-only constructs.

### Round 2
2026-11-16
(send-back from qc.md round 2)

| | |
|---|---|
| Plan | `docs/plans/2026-11-16-cmd-mode-existing-container.md` (approved by the engineer in the conversation, 2026-11-16; left unstaged). Its Spec is the first plan, which stays as it is. |
| Shape | an executable follow-up plan, four tasks (the last the engineer's, on their host) |

**Decisions.**
- R1 (blocking, the plan's), Q5: `issue <N> <branch>` on an existing `codeo-<N>`, running or stopped, changes nothing and exits 1 with one line naming `shell <N>`, `--rebuild` and the removal commands. With `--rebuild`, or a volume left without its container, the clone must be on `<branch>`, else the script refuses. `home` keeps its re-run (Task 1).
- R5, R6 and R2's header comment are small script fixes: `require_docker` shows Docker's own first error line; `session-title.sh` accepts any non-empty `CODEO_CMD_MODE` (Task 2).
- R2, R3, R4 and the stash paragraph are documentation: the README, the init hand-off and the changelog bullet say what the code does (Task 3).
- R7 and R8 change nothing: bash 3.2 on a real Mac stays with the first plan's Task 10, and the image's removal is in the README already.

**Options rejected.** Checking `role.sh`'s output before reusing a container, and only fixing the words (Q5); changing the image's shell start-up to make the terminal title last (R3); editing the first plan's text.

**Documentation the plan changes.** `.devcontainer/README.md`, `.codeo/overlays/init.md`, `CHANGELOG.md` (the `(#113)` bullet edited in place). No page under `docs/` moves.

**What only the engineer can prove.** Task 4: `issue` on a running `codeo-<N>` on a real Docker host. The first plan's Task 10 still stands.

### Footprint

```
files:      .devcontainer/codeo-container.sh, .devcontainer/README.md, .devcontainer/scripts/devcontainer-start.sh, .devcontainer/scripts/session-title.sh, .codeo/overlays/init.md, tests/cmd-mode.test.sh, tests/devcontainer.test.sh, tests/init-overlay.test.sh, CHANGELOG.md, docs/plans/2026-11-16-cmd-mode-containers.md, docs/plans/2026-11-16-cmd-mode-existing-container.md
wiki:       none
exclusive:  none
sequenced:  none
```

## Log

- 2026-11-16 — Q1-Q4 raised · cost: 2m · fable-5-2 78k in + 376k cached / 5k out
- 2026-11-16 — planned: docs/plans/2026-11-16-cmd-mode-containers.md; Q1-Q4 answered in the conversation; `engineering:system-design` and `engineering:architecture` were unavailable, so their structure was applied directly; Q4's wording gained the token `glob:CHANGELOG.md` so overlap.sh recognises it as raised (answer untouched) · cost: 14m · fable-5-2 94k in + 710k cached / 12k out · sonnet-5-5 157k in + 2.6M cached / 46k out
- 2026-11-16 — round 2 (send-back from qc.md round 2): Q5 raised · cost: 1m · fable-5-2 204k in + 254k cached / 4k out
- 2026-11-16 — round 2 (send-back from qc.md round 2): Q5 answered, planned: docs/plans/2026-11-16-cmd-mode-existing-container.md; `engineering:*` skills not used; overlap.sh prints nothing · cost: 85m · fable-5-2 208k in + 484k cached / 5k out · sonnet-5-5 306k in + 987k cached / 11k out
