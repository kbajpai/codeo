# Issue #190 — init

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/190 |
| Branch | `docs/190-make-container-sandbox-setup-reusable` |
| Updated | 2026-11-26 |

## Where this stands

Branch `docs/190-make-container-sandbox-setup-reusable` cut off `main` at 7b7cc0f and pushed. Next step: `/codeo:plan` in the issue's container.

## Questions

None.

## Outcome

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/190 — Make the container and sandbox setup reusable by another project (template + /codeo:setup --containers) |
| State | open · labels `documentation`, `enhancement`, `priority: medium` |
| Branch | `docs/190-make-container-sandbox-setup-reusable` off `main` at 7b7cc0f |
| Board | Ready → In progress |

**Problem.** The container and sandbox half of codeo's setup is built for the codeo repo itself (its repository URL, the `codeo-` name prefix, volume names, a bash/jq/shellcheck image), so another project must copy `.devcontainer/` and `.sbx/` and edit them by hand. Make it adoptable by any project and stack from `.codeo/config.json`, ship a stack-neutral template, and add one re-runnable command (`scripts/codeo-init.sh`) that adopts codeo in a project whose GitHub repository and `origin` already exist; codeo never creates the repository.

**Acceptance criteria** — verbatim from the issue, unchecked:
- [ ] The audit list of codeo-specific assumptions is recorded, and none of them remains hardcoded in a script or default the template ships.
- [ ] `/codeo:setup --containers` in a project whose owner and codename are not codeo's writes a working dev container and sbx sandbox setup, with the project's repository URL and names.
- [ ] A test sets up a throwaway project with a different owner and codename and asserts that no shipped script or default still names `kbajpai/codeo` or `codeo-<N>` where the project's own name belongs.
- [ ] The C# + Angular monorepo example builds its image, and an issue container or sandbox for it starts and runs the project's build and test commands.
- [ ] The README and `.devcontainer/README.md` describe both adoption paths, and every command in them was run.
- [ ] codeo's own test suite (`bash tests/run.sh`) passes, and codeo's own containers behave as before.
- [ ] `scripts/codeo-init.sh --yes` in a clone of a repository that is not codeo's, with another codename, produces a config, the container and sandbox files with the project's names, and a passing doctor; no shipped file names `kbajpai/codeo` or `codeo-<N>` where the project's own name belongs.
- [ ] The wizard fails with a stated reason, creating nothing, when there is no `origin`, `gh` is logged out, or `gh` cannot see the repository, and no create call is ever made.
- [ ] Rerunning the wizard keeps an existing config and never overwrites a seed file.
- [ ] codeo's own checked-in container files equal what the templates render for codeo's config (checked by a test), so codeo's own containers behave as before.

**Out of scope.** Hosts other than GitHub, and Windows-native (WSL2 stays as supported today). Changes to the workflow skills themselves. Stack images beyond the one worked example.

**Open at intake.** A first slice already exists on `origin/feat/190-one-command-setup` (commit `74b3afe`, written by hand in the home checkout before this init): container templates, `scripts/containers.sh`, `setup.sh --codename/--containers`, the doctor `containers` check, `scripts/codeo-init.sh`, `lib/prompt.sh` and their tests. It is not on this branch; bring it over with `git cherry-pick 74b3afe` before planning. It edits `skills/setup/SKILL.md` (one sentence for the new flags), which sits against "Changes to the workflow skills themselves" being out of scope; `/codeo:setup --containers` is a stated requirement, so `/codeo:plan` should confirm that reading. Still to do per the issue: the audit list, the C# + Angular example, the READMEs, inventory and changelog entries, and building an image from the neutral Dockerfile. A guard against changes in the home checkout is filed separately as #192.

## Log

- 2026-11-26 — initialized: branch docs/190-make-container-sandbox-setup-reusable off main at 7b7cc0f · cost: 1m · sonnet-5-5 19k in + 1.2M cached / 5k out
