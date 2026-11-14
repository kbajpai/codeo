# Issue #67 — init

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/67 |
| Branch | `feat/move-dev-container-image-ubuntu` |
| Updated | 2026-11-14 |

## Where this stands

Branch `feat/move-dev-container-image-ubuntu` cut off `main` at 1e4d43a, claimed and pushed. Nothing is open; the next step is `/codeo:plan`.

## Questions

None.

## Outcome

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/67 — Move the dev container image to Ubuntu 26.04 LTS |
| State | open · labels `enhancement` |
| Branch | `feat/move-dev-container-image-ubuntu` off `main` at `1e4d43a` |
| Board | Ready → In progress |

**Problem.** The dev container image (`.devcontainer/Dockerfile`) is built on `ubuntu:24.04`, and 26.04 is now the current LTS. The image should move to the exact tag `ubuntu:26.04` and keep the same tools (bash, git, jq, shellcheck, `gh`, Claude Code, `en_US.UTF-8`), the non-root `dev` user at UID 1000 with passwordless sudo, and the same start scripts. Comments and current docs naming the version are updated; #36's historical records are left alone.

**Acceptance criteria** — verbatim from the issue, unchecked:
- [ ] The first `FROM` in `.devcontainer/Dockerfile` is `ubuntu:26.04`.
- [ ] `docker build` of `.devcontainer/Dockerfile` succeeds.
- [ ] In the built image, `bash`, `git`, `jq`, `shellcheck`, `gh` and `claude --version` all run,
      and `id dev` reports UID 1000.
- [ ] `tests/devcontainer.test.sh` asserts `ubuntu:26.04` and passes, along with the rest of the
      `shell` suite.
- [ ] No current (non-historical) file in `.devcontainer/` or the tests still names Ubuntu 24.04.
- [ ] `CHANGELOG.md` has an `## Unreleased` entry for the change.

**Out of scope.** CI runners (`runs-on: ubuntu-latest` in `.github/workflows/ci.yml`); adding or removing tools in the image; the open dev container follow-ups #40, #51, #54 and #57.

**Open at intake.**
- Does the `ubuntu:26.04` image still ship an `ubuntu` user at UID 1000, which the Dockerfile removes with `userdel -r ubuntu`? If it doesn't, that step has to change.
- Does every package in the apt install list exist under the same name on 26.04?

## Log

- 2026-11-14 — initialized: branch feat/move-dev-container-image-ubuntu off main at 1e4d43a · cost: 1m · sonnet-5-5 14k in + 381k cached / 2k out
