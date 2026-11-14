# new-devcontainer-ubuntu-2604 — issue

| | |
|---|---|
| Issue | _not filed yet_ |
| Updated | 2026-11-14 |

## Where this stands

Q1–Q2 answered in the conversation. Draft written below and waiting for the engineer's approval before filing.

## Questions

### Q1 — Pin `ubuntu:26.04`, track `ubuntu:latest`, or pin a digest?

**Why it matters:** decides the acceptance criterion for the `FROM` line and whether the next LTS
move happens by review or on its own.
**Options:** pin `ubuntu:26.04` · track `ubuntu:latest` · pin a digest.

**Answer:**
Pin `ubuntu:26.04` (answered in the conversation).

### Q2 — Should this cover CI's `ubuntu-latest` runners too?

**Why it matters:** adds `.github/workflows/ci.yml` to the scope, or leaves it out of scope.
**Options:** dev container only · also pin CI runners.

**Answer:**
Dev container only (answered in the conversation).

## Notes

- `.devcontainer/Dockerfile:6` is `FROM ubuntu:24.04`. Its header comment (line 1) and the
  `ubuntu`-user comment (line 30) also name 24.04.
- `tests/devcontainer.test.sh:111-115` (`dockerfile_is_ubuntu_2404_with_the_tools`) requires the
  first `FROM` to be exactly `ubuntu:24.04`.
- The `CHANGELOG.md` entry for #36, `docs/plans/2026-11-07-dev-container.md` and `.codeo/done/36/`
  are history and stay as they are.
- No existing issue covers this. Searched for "ubuntu" and "devcontainer". Open dev container
  follow-ups: #40, #51, #54, #57.
- Unknown: whether the 26.04 base image still has the `ubuntu` user at UID 1000 (the Dockerfile
  runs `userdel -r ubuntu`), and whether every package in the apt list still exists under the
  same name. This goes into the issue as an open question for `/codeo:plan`.

## Draft

**Title:** Move the dev container image to Ubuntu 26.04 LTS

**Issue Type:** none. The repository is user-owned and has no Issue Types.
**Labels:** `enhancement`

```markdown
### Description

The dev container image (`.devcontainer/Dockerfile`) is built on `ubuntu:24.04`. Ubuntu 26.04 LTS
is now the current stable LTS release. Move the image to `ubuntu:26.04`, keeping the same tools,
user and behaviour.

### Motivation / Context

The image was built on 24.04 in #36, when that was the newest LTS. 26.04 has newer base packages
(bash, git, jq, shellcheck) and a longer support window. Nothing else in the container setup is
supposed to change.

### Key Requirements

- The base image is pinned to the exact tag `ubuntu:26.04`, not `latest` and not a digest.
  Moving to a later LTS is a separate issue.
- The image still provides what it does now: bash, git, jq, shellcheck, `gh` from GitHub's apt
  repository, Claude Code, and the `en_US.UTF-8` locale. It still runs as the non-root `dev` user
  with UID 1000 and passwordless sudo, and the `.config/gh`, `.config/git` and `.claude`
  directories are still owned by `dev`.
- The start scripts under `.devcontainer/scripts/` keep working unchanged, or change only where
  26.04 requires it.
- Comments and current documentation that name the Ubuntu version are updated. Historical
  records (#36's changelog entry, its plan, and its archived dossier) are left as they are.

### Acceptance Criteria

- [ ] The first `FROM` in `.devcontainer/Dockerfile` is `ubuntu:26.04`.
- [ ] `docker build` of `.devcontainer/Dockerfile` succeeds.
- [ ] In the built image, `bash`, `git`, `jq`, `shellcheck`, `gh` and `claude --version` all run,
      and `id dev` reports UID 1000.
- [ ] `tests/devcontainer.test.sh` asserts `ubuntu:26.04` and passes, along with the rest of the
      `shell` suite.
- [ ] No current (non-historical) file in `.devcontainer/` or the tests still names Ubuntu 24.04.
- [ ] `CHANGELOG.md` has an `## Unreleased` entry for the change.

### Out of Scope

- CI runners (`runs-on: ubuntu-latest` in `.github/workflows/ci.yml`).
- Adding or removing tools in the image.
- The open dev container follow-ups #40, #51, #54 and #57.

### Open questions

- Does the `ubuntu:26.04` image still ship an `ubuntu` user at UID 1000, which the Dockerfile
  removes with `userdel -r ubuntu`? If it doesn't, that step has to change.
- Does every package in the apt install list exist under the same name on 26.04?

### Reference

- `.devcontainer/Dockerfile`, lines 1, 6 and 30-34
- `tests/devcontainer.test.sh`, `dockerfile_is_ubuntu_2404_with_the_tools` (lines 111-115)
- #36, the issue that introduced the dev container on 24.04
```

## Outcome

_Pending — written when the issue is filed._

## Log

- 2026-11-14 — Q1-Q2 asked and answered; draft written · cost: 1m · opus-5-5 61k in + 426k cached / 4k out
