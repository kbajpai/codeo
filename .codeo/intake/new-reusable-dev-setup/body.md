### Description

codeo's plugin and workflow work for any project, but the container and sandbox half of the setup is built for the codeo repo itself. Make it adoptable by another project and stack: audit and remove the hardcoded codeo/kbajpai assumptions, have the plugin ship a template that `/codeo:setup --containers` writes into the project, and document the adoption path. Cover everything: the dev container, the sbx sandbox and its image, the `codeo` host command, the tracking comment and the role guard.

### Motivation / Context

Today a project adopting the "full" setup (a home container plus one container or sbx sandbox per issue) has to copy `.devcontainer/` and `.sbx/` and edit them by hand, and cannot tell which parts are codeo-specific. Examples: the Dockerfile is a bash/jq/shellcheck image for codeo itself, `devcontainer.json` names the `codeo-gh` / `codeo-git` volumes, and the scripts default to `https://github.com/kbajpai/codeo.git` (`.sbx/codeo-sandbox.sh` has 45 codeo/kbajpai references, `.devcontainer/codeo-container.sh` 31, `.devcontainer/codeo-track.sh` 10).

### Key Requirements

- Audit `.devcontainer/`, `.sbx/` (including `claude-image`), `scripts/`, `lib/`, `hooks/` and `tests/` for assumptions that name codeo, `kbajpai` or the codeo repo, and record the list in the plan.
- Everything project-specific (owner, repo, codename, repository URL, volume and container names) is read from `.codeo/config.json`, not defaulted to codeo's values.
- The plugin ships a stack-neutral base image and templates for the dev container and sbx sandbox; `/codeo:setup --containers` writes them into the project.
- The template has one documented place where a project adds its own toolchain; the codeo-specific tools (shellcheck and the like) stay in codeo's own image.
- Include one worked example: a monorepo with a C# backend, an Angular frontend, Docker and Kubernetes tooling.
- Document the adoption path in the README and `.devcontainer/README.md`: the light path (plugin only) and the full path (containers and sandboxes).
- Codeo itself keeps working unchanged, and `/codeo:doctor` reports a project's container setup when it has one.

### Acceptance Criteria
- [ ] The audit list of codeo-specific assumptions is recorded, and none of them remains hardcoded in a script or default the template ships.
- [ ] `/codeo:setup --containers` in a project whose owner and codename are not codeo's writes a working dev container and sbx sandbox setup, with the project's repository URL and names.
- [ ] A test sets up a throwaway project with a different owner and codename and asserts that no shipped script or default still names `kbajpai/codeo` or `codeo-<N>` where the project's own name belongs.
- [ ] The C# + Angular monorepo example builds its image, and an issue container or sandbox for it starts and runs the project's build and test commands.
- [ ] The README and `.devcontainer/README.md` describe both adoption paths, and every command in them was run.
- [ ] codeo's own test suite (`bash tests/run.sh`) passes, and codeo's own containers behave as before.

### Out of Scope

- Hosts other than GitHub, and Windows-native (WSL2 stays as supported today).
- Changes to the workflow skills themselves.
- Stack images beyond the one worked example.

### Reference

- `.devcontainer/README.md`, `.sbx/README.md`, `docs/home-checkout.md`
- Surfaced in a conversation about reusing the codeo setup for another project.
