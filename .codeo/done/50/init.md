# Issue #50 — init

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/50 |
| Branch | `feat/name-dev-container-after-its` |
| Updated | 2026-11-09 |

## Where this stands

Branch `feat/name-dev-container-after-its` cut off `origin/main` at `26d88bf`; the dossier is pushed to claim it, the assignee and board card are set.

## Questions

None.

## Outcome

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/50 — Name the dev container after its clone folder, with a short per-clone suffix so same-named clones do not collide |
| State | open · labels `enhancement` |
| Branch | `feat/name-dev-container-after-its` off `main` at `26d88bf` |
| Board | Ready → In progress |

**Problem.** The dev container gets a random Docker name because `runArgs` has no `--name`. Name it after its clone folder plus a short hash of the clone's absolute path (for example `codeo-home-a1b2c3`), so `docker ps` shows which container belongs to which clone, the name is stable across rebuilds, and two clones with the same folder name get different names.

**Acceptance criteria** — verbatim from the issue, unchecked:
- [ ] After a rebuild, `docker ps` shows this clone's container as `codeo-home-<hash>`.
- [ ] Rebuilding the same clone gives the same name.
- [ ] Two same-named clones at different paths give different names.
- [ ] `tests/devcontainer.test.sh` pins the naming, and the suite passes.
- [ ] `runArgs` still carries `--memory=4g` and `--cpus=2`.
- [ ] `CHANGELOG.md` records the change and the rebuild it needs.

**Out of scope.** A timestamp suffix; a prefix, or a name derived from the codename; changing the window or session titles; seeding the git identity (#51).

**Open at intake.** A devcontainer variable cannot compute a hash, so the suffix needs a step that runs before the container is created (for example an `initializeCommand` script). The mechanism is for `/codeo:plan`.

## Log

- 2026-11-09 — initialized: branch feat/name-dev-container-after-its off main at 26d88bf · cost: 2m · sonnet-5-5 15k in + 611k cached / 3k out
