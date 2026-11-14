# Issue (new-devcontainer-vs-sbx) — issue

## Questions

1. Which sbx? — **Answer:** Docker Sandboxes (`sbx` CLI, microVM per agent).
2. What does done deliver? — **Answer:** a comparison and a recommendation (a spike). Any migration goes in a follow-up issue.
3. Which pain points drive this? — **Answer:** isolation/safety, the VS Code dependency, the per-issue lifecycle, parallel agents.
4. What is out of scope? — **Answer:** projects that use codeo, other sandbox tools, Remote Control/cloud.

## Notes

Duplicate search (sandbox, sbx, devcontainer): none found. Related: #36, #55, #57, #70. The repo is user-owned, so there are no Issue Types.

## Outcome

**Title:** Evaluate Docker Sandboxes (sbx) against the dev container setup and recommend whether to migrate

**Labels:** question, documentation · **Type:** none

### Description

codeo is developed in a VS Code dev container (`.devcontainer/`) with two kinds of container:
the home container on `main` (`codeo-home`) and one container per issue (`codeo-<N>`). Each one
is its own clone in its own named Docker volume, opened through **Dev Containers: Clone Repository
in Named Container Volume…**. A start script trusts the clone, installs the pinned plugins, takes
the workflow lock in an issue container, and sets the window and session titles.

Docker Sandboxes (`sbx`) run coding agents such as Claude Code in a microVM per sandbox. This issue
compares the two for codeo's own development and recommends whether to migrate, and if so how far.
It does not do the migration.

### Motivation / Context

The current setup has costs that sbx might reduce:
- **Isolation / safety:** the container shares the host kernel through Docker, and `dev` has
  passwordless sudo. Running Claude with fewer permission prompts is only as safe as that boundary.
- **VS Code dependency:** containers open only through VS Code's clone-in-volume flow, so a terminal
  or headless start is not possible.
- **Per-issue lifecycle:** creating and naming `codeo-<N>` containers (the folder rule), cleaning up
  finished ones (#70), and logging in to Claude again after a rebuild because `~/.claude` is not on a
  volume.
- **Parallel agents:** running several issues or agents at once on one machine.

### Key Requirements

- Compare the two setups against at least the four drivers above, plus whatever else the
  evaluation finds that matters: host support (the current host is Windows + WSL2), resource
  limits, persistence of the `gh`/git/Claude logins, plugin installation, network policy, and
  editor attach.
- Map each duty of the current setup onto sbx, or mark it as having no equivalent: the
  home/issue split, one clone per issue, `devcontainer-start.sh` (trust, chown, plugins, lock,
  folder check, todo lines), `plugins.sh`, window and session titles, and the `codeo-gh`/`codeo-git`
  volumes.
- Back claims with evidence: something tried on a real host, or a cited Docker doc. Say which.
- End with a recommendation (migrate, hybrid, or stay) and why. If it says migrate or hybrid, list
  the follow-up issues needed to get there.

### Acceptance Criteria
- [ ] A written comparison exists (where it lives is up to `/codeo:plan`) covering every driver
      and requirement above, with each point marked as tried or cited.
- [ ] Every duty of the current setup listed under Key Requirements has an sbx equivalent, a
      workaround, or "no equivalent".
- [ ] It states whether sbx runs on the current host (Windows + WSL2), with evidence.
- [ ] It ends with one recommendation and its rationale.
- [ ] If the recommendation is migrate or hybrid, the follow-up issues are filed and linked here.
- [ ] `.devcontainer/` and the workflow skills are unchanged by this issue.

### Out of Scope

- Doing the migration, or changing `.devcontainer/` or any skill.
- How projects that use codeo run it. This is only about codeo's own development environment.
- Other sandbox or remote options (Codespaces, Claude Code's built-in sandbox, Podman, …).
- Remote Control and cloud sessions.

### Open questions (for the evaluation to answer)
- Can an sbx sandbox express the home/issue split and the one-clone-per-issue model, or does the
  workflow lock have to work differently?
- Can VS Code (or another editor) attach to an sbx sandbox, or does sbx push work to the terminal?
- How do the Claude, `gh` and git logins persist across sandbox restarts?

### Reference
- `.devcontainer/README.md`, `.devcontainer/devcontainer.json`, `.devcontainer/Dockerfile`
- `.devcontainer/scripts/devcontainer-start.sh`, `plugins.sh`, `container-name.sh`, `folder-check.sh`
- Related: #36, #55, #57, #70
