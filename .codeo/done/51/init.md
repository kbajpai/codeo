# Issue #51 — init

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/51 |
| Branch | `feat/seed-dev-container-git-identity` |
| Updated | 2026-11-14 |

## Where this stands

Branch `feat/seed-dev-container-git-identity` cut off `main` at 91894c1, claimed and pushed. Nothing is open; the next step is `/codeo:plan`.

## Questions

None.

## Outcome

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/51 — Seed the dev container git identity from the host config or environment on first start |
| State | open · labels `enhancement` |
| Branch | `feat/seed-dev-container-git-identity` off `main` at `91894c1` |
| Board | Ready → In progress |

**Problem.** Since #47 the dev container sets `GIT_CONFIG_GLOBAL` to a file on the shared `codeo-git` volume, so git ignores the host `~/.gitconfig` that VS Code copies in. A fresh volume has no `user.name` or `user.email`, and step 5 of `.devcontainer/scripts/devcontainer-start.sh` only prints a TODO, so the engineer sets them by hand once per volume. The start script should fill each missing value on its own, from the host `~/.gitconfig` first and then `GIT_AUTHOR_NAME` / `GIT_AUTHOR_EMAIL`, never overwrite a value already in the volume config, copy nothing else, and keep the TODO (now naming the sources tried) when neither source has a value.

**Acceptance criteria** — verbatim from the issue, unchecked:
- [ ] With an empty volume config and an identity in the host `~/.gitconfig`, `git config --global user.name` and `user.email` return the host's values after the start script runs.
- [ ] With an empty volume config, no host identity, and `GIT_AUTHOR_NAME` / `GIT_AUTHOR_EMAIL` set, those values land in the volume config.
- [ ] With the host file and the environment both set, the host file's values win.
- [ ] A `user.name` or `user.email` already in the volume config is unchanged after a run, and a missing one beside it is still filled.
- [ ] With no source holding an identity, the TODO still appears and lists the sources that were tried.
- [ ] `tests/devcontainer.test.sh` covers each case above and the suite passes; `CHANGELOG.md` records the change.

**Out of scope.** Copying any other host git setting (such as `init.defaultBranch` or `pull.rebase`), or the whole host `~/.gitconfig`; moving the identity out of the volume, or changing `GIT_CONFIG_GLOBAL`; naming the container (#50); any change under `scripts/`, `lib/`, `hooks/` or `skills/`.

**Open at intake.** None.

## Log

- 2026-11-14 — initialized: branch feat/seed-dev-container-git-identity off main at 91894c1 · cost: 0m · sonnet-5-5 13k in + 304k cached / 2k out
