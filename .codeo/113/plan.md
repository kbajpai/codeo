# Issue #113 — plan

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/113 |
| Branch | `feat/cmd-mode-start-use-home` |
| Updated | 2026-11-16 |

## Where this stands

Round 1. The intake dossier, the dev container's files and scripts, their tests and the other workflow in flight (#104) are read. Nothing is drafted: Q1-Q4 each change what the plan's tasks are. The calls I can make myself are under `## Notes`, so you can overrule any of them while answering.

## Questions

### Q1 — How does the host script reach a machine that has only Docker?

**Why it matters:** the script lives in this repository, but a host with only Docker has no clone and may have no git. The answer decides the "one documented command" in the README and in the `init` hand-off, and whether the script must build the image without a local `Dockerfile`.

**Options:**
- *Download once, then run it* (recommended): the README gives one `curl` line that saves the script from `main` on GitHub, and every later command is `bash codeo-container.sh home`, `… issue <N> <branch>`, `… shell <name>`, `… rm <name>`. The script builds the image straight from the GitHub URL of the branch (Docker's BuildKit fetches it), so the host needs no git and no clone. It also works when run from a clone. Needs `curl` once; macOS and nearly every Linux have it.
- *Require a clone on the host:* `git clone`, then run the script from the clone, which builds from the `Dockerfile` beside it. Simpler script, but the host needs git, which the issue's "needing only Docker" rules out as I read it.
- *Pipe it every time:* `curl … | bash -s -- home` for each command. Nothing is saved on the host, but every command is a long line and needs the network.

**Answer:**

### Q2 — Should a cmd-mode container keep the Claude login across a rebuild?

**Why it matters:** left open at intake. Today `/home/dev/.claude` is on no volume, so a rebuild loses the login, past sessions and settings. The answer decides whether the script adds a mount and where `CLAUDE_CONFIG_DIR` points, and whether cmd mode then differs from the VS Code route.

**Options:**
- *Keep it per container, inside the container's own volume* (recommended): in cmd mode `CLAUDE_CONFIG_DIR` points at a folder on the `codeo-<N>` volume, beside the clone. A rebuild keeps the login; `docker volume rm codeo-<N>`, the command `/codeo:close` and `/codeo:cleanup` already print, removes it with everything else, so nothing is left behind. Each new container still needs one `claude auth login`, as today.
- *One shared `codeo-claude` volume for every cmd-mode container:* log in once for all containers. But sessions, settings and installed plugins are then shared between containers whose branches may pin different plugin versions, and the volume outlives every removal command.
- *Leave it as it is:* same as the VS Code route; a rebuild means `claude auth login` again. Least to build and to test.

**Answer:**

### Q3 — On which machines, and in which shell, will you run the host checks?

**Why it matters:** this session runs inside a container with no Docker, so the first six acceptance criteria and the VS Code one can only be shown on your machines; the plan marks those tasks `Runs on: the engineer's host` and writes their commands for your shell. Your machine looks like Windows with WSL2. I need two things:
1. For the Linux criterion: is a WSL2 distribution with Docker the Linux host, and is the shell there bash?
2. For the macOS criterion (`/bin/bash` 3.2, no GNU tools): do you have a Mac to run it on?

With a Mac, the plan ends with a host task there. Without one, the only proof this suite can give is a test that scans the script for constructs bash 3.2 and BSD tools lack (associative arrays, `mapfile`, `${x,,}`, `readlink -f`, `sed -i`, `stat -c` and the like), and the plan says plainly that the macOS criterion is unproven on a real Mac until someone runs it. I would write that test either way.

**Answer:**

### Q4 — #104 also changes `CHANGELOG.md`: proceed, wait, or re-scope?

**Why it matters:** #104 (branch `feat/publish-live-session-signal-so`, assignee kbajpai, at `qc`) lists `CHANGELOG.md` in its footprint, and this plan adds its own bullet under `## Unreleased` in `CHANGELOG.md`. Nothing else overlaps: #104's other files are under `scripts/`, `hooks/`, `skills/`, `docs/` and `tests/`, none of which this plan touches by the same path.

**Options:**
- *Proceed and coordinate* (recommended): both add one bullet to the same list; whichever merges second resolves a one-line conflict, which `/codeo:close` already routes.
- *Sequence after #104:* this plan's changelog task waits until #104 merges.
- *Re-scope:* leave `CHANGELOG.md` out of this change.

**Answer:**

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

## Outcome

_Pending — written at the hand-off._

## Log

- 2026-11-16 — Q1-Q4 raised · cost: 2m · fable-5-2 78k in + 376k cached / 5k out
