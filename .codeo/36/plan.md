# Issue #36 — plan

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/36 |
| Branch | `feat/add-dev-container-so-codeo` |
| Updated | 2026-11-07 |

## Where this stands

Round 1. Explored RoadMaster's `.devcontainer/` (`Dockerfile`, `devcontainer.json`, `scripts/plugins.sh`, and the start, naming and login scripts beside them) and codeo's side: `.codeo/config.json`, `scripts/doctor.sh`, `tests/run.sh`, `.github/workflows/ci.yml`, `.claude/settings.json`. Three questions are open; nothing is drafted past them.

What I found that shapes the questions:

- `.codeo/config.json` has no `codename` and no pin. `plugins.sh` reads `.plugin.repo` and `.plugin.ref` from it. `config.sh validate` only checks `schema`, so a new `plugin` key is accepted, and `doctor.sh` already validates `codename`.
- `docker` 29.8.2 is on this machine, so the image can be built and `bash tests/run.sh` run inside it here. `devcontainer` and `shellcheck` are not installed on the host.
- Ubuntu 24.04's own git is 2.43, which has `git merge-tree --write-tree` (2.38+), the only reason RoadMaster adds the git-core PPA. Its bash is 5.2, above codeo's 4.3 floor.
- The `shell` suite's `paths` do not cover `.devcontainer/**`, so a change there would match no suite.
- RoadMaster's start script is large and mostly project-specific: secrets store, `.NET` and Terraform, folder-name checks, and an `agy` login. Only the `gh`, git-identity, Claude-login and lock-taking parts could carry over.

## Questions

### Q1 — Which ref does the container pin, and does superpowers get one too?

**Why it matters:** `plugins.sh` reinstalls whatever `.codeo/config.json` pins, so the pin decides which codeo the container runs: the last release, or whatever is on `main` at build time. The issue says "installed at the pinned ref, as RoadMaster's `plugins.sh` does", but RoadMaster pins only codeo and leaves superpowers at the marketplace's latest.

**Options:** codeo pinned to `v1.0.3` (the latest tag), superpowers unpinned as in RoadMaster (my recommendation: it matches the reference, and codeo is the only plugin whose version the repo's own tooling depends on) · codeo pinned to `v1.0.3` and superpowers pinned to a commit or tag you name · codeo pinned to `main` · something else.

**Answer:**

### Q2 — How much of RoadMaster's start script does codeo's container need?

**Why it matters:** this sets the size of the work. The issue names only `plugins.sh` as a script to carry over, but the AC also need the `gh` login to work (`gh auth setup-git`, a hint for the missing `project` scope), and `/codeo:init` run in a container takes its lock through `lock.sh take container`.

**Options:**
- *Minimal (my recommendation):* a short `postCreateCommand` that runs `plugins.sh`, runs `gh auth setup-git` when logged in, and prints what is left to do (`gh auth login`, `gh auth refresh -s project`, `claude auth login`). No lock-taking and no container naming. `/codeo:init` binds the lock locally in whichever container you run it in, which `lock.sh` already supports.
- *Plus the lock:* also take the container lock at start, as RoadMaster does, and name the container `codeo-<N>` / `codeo-home` through `runArgs --name`.
- *Plus identity and Claude login scripts:* carry over `git-identity.sh` and `claude-login.sh` as well.

**Answer:**

### Q3 — How is "done" proved for the acceptance criteria that need VS Code and a real login?

**Why it matters:** two criteria cannot be run from here. "Opening the repo in VS Code builds the container" needs the Dev Containers extension. "`gh auth status` shows the `project` scope … and the login survives a rebuild" needs your GitHub account. What I can prove here with `docker`: the image builds from a clean state, its contents are right (no .NET, Node, Terraform, gcloud or PostgreSQL), `bash tests/run.sh` passes in it as user `dev`, and `devcontainer.json` has the volume, `remoteUser` and `runArgs` the issue asks for.

**Options:** I prove everything `docker build` and `docker run` can show, and you confirm the VS Code open and the login-survives-rebuild by hand before `/codeo:close` (my recommendation; I list those two steps in the plan as manual checks) · I also try to install the `devcontainer` CLI on the host and use it for the build · you want the manual checks done differently.

**Answer:**

## Notes

Calls I am making unless you say otherwise (none changes what gets built much):

- **Base image** is plain `ubuntu:24.04`, not the .NET SDK image. The git-core PPA is dropped, and git, jq, `shellcheck` and `gh` come from apt and GitHub's apt repository.
- **No `agy`, no `--name`, no bind mounts.** `agy` is not in the issue. `--name` needs the clone-in-volume workflow and collides when two containers share a folder name. Bind mounts are what fail when the host folder is missing.
- **Mounts** are the one named volume `codeo-gh` at `/home/dev/.config/gh`. The Dockerfile creates that directory owned by `dev` first, so the empty volume takes `dev`'s ownership on first mount. Claude's config stays per container, as in RoadMaster.
- **Ceiling** in `runArgs` is `--memory=4g --cpus=2`: the suite is shell scripts, and the RoadMaster values (12g, 6) are sized for six containers at once.
- **Claude Code** is installed with the native installer, latest, as in RoadMaster.
- **VS Code extensions:** `anthropic.claude-code`, `timonwong.shellcheck`, `bierner.markdown-mermaid`.
- **Config:** `.codeo/config.json` gains `"codename": "codeo"`, a `plugin` pin (Q1), and `.devcontainer/**` in the `shell` suite's `paths`, so a change under `.devcontainer/` is judged by the suite.
- **Tests:** a new `tests/devcontainer.test.sh` checks the files (valid JSON, `remoteUser`, `runArgs`, the `codeo-gh` mount and no other, no bind mounts, none of the excluded tools or the RoadMaster secrets names in any `.devcontainer/` file, the `codename`).
- **Docs:** `CHANGELOG.md` gets an `Unreleased` line. `README.md` is untouched (out of scope per the issue), and `docs/` describes the pipeline, not the repo's tooling, so no page moves.

## Outcome

_Pending — written at the hand-off._

## Log

- 2026-11-07 — questions raised: Q1-Q3 (round 1)
