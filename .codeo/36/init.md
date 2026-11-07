# Issue #36 — init

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/36 |
| Branch | `feat/add-dev-container-so-codeo` |
| Updated | 2026-11-07 |

## Where this stands

Branch `feat/add-dev-container-so-codeo` off `main` at `14f49f5e4c4cf8a5b4c8d26dc3a3b72fec80ed29`. Ready to hand off to `/codeo:plan`.

## Questions

None.

## Outcome

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/36 — Add a dev container so codeo is developed inside its own image |
| State | open · labels `enhancement` |
| Branch | `feat/add-dev-container-so-codeo` off `main` at `14f49f5` |
| Board | Ready → In progress |

**Problem.** codeo has no `.devcontainer/`, so it cannot be developed and tested inside a container the way projects that use codeo can. Add one dev container definition, modelled on RoadMaster's `.devcontainer/` (`Dockerfile`, `devcontainer.json`, `scripts/plugins.sh`) but carrying only what codeo needs: bash, jq, git, gh, shellcheck and Claude Code. None of RoadMaster's .NET, Node, Terraform, gcloud or PostgreSQL, and neither its `roadmaster-secrets` nor `~/.codeo-secrets` mount.

**Key requirements** (from the issue):
- One image based on Ubuntu 24.04 with bash 4.3+, jq, git, gh, shellcheck and Claude Code.
- A non-root `dev` user (UID 1000), with `remoteUser` set and a per-container memory/CPU ceiling in `runArgs`.
- `gh` login kept in the shared `codeo-gh` volume.
- superpowers and codeo installed at the pinned ref, as RoadMaster's `plugins.sh` does.
- `.codeo/config.json` carries `codename: codeo`.

**Acceptance criteria** — verbatim from the issue, unchecked:
- [ ] Opening the repo in VS Code builds the container without any host folder or volume created beforehand.
- [ ] `bash tests/run.sh` passes inside the container.
- [ ] `gh auth status` shows the `project` scope once logged in, and the login survives a rebuild.
- [ ] `/codeo:doctor` reports ready.
- [ ] The image contains none of the RoadMaster-specific tools listed above.

**Out of scope.** README development docs; running CI in the same image.

**Open at intake.** None stated in the issue. The reference (RoadMaster's `.devcontainer/`) is not in this repository, so `/codeo:plan` will need it supplied or will have to work from the issue's description of it.

## Log

- 2026-11-07 — initialized: branch feat/add-dev-container-so-codeo off main at 14f49f5 · cost: 1m · sonnet-5-5 16k in + 373k cached / 2k out
