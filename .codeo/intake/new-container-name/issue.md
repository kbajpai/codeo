# Issue — amend #50: collision-proof container name

Not a new issue: #50 already covers `--name`. Amending it to bring the same-folder-name collision into scope.

## Questions
1. Amend #50, file a follow-up, or replace? — **Answered: amend #50.**
2. Collision scheme: timestamp, short path hash, or document only? — **Answered: short suffix stable per clone** (hash of the clone's absolute path). A timestamp would change on every rebuild and break the stable `docker ps` name.

## Draft (amended #50)
Title: Name the dev container after its clone folder, with a short per-clone suffix so same-named clones do not collide

Changes versus the filed body:
- Description/Requirements: name is `<folder>-<short hash of the clone's absolute path>`, e.g. `codeo-home-a1b2c3`.
- Key Requirements: stable across rebuilds; two clones with the same folder name get different names; derived from the clone path only.
- Out of Scope: "name already taken" removed; timestamp suffix explicitly out.
- Acceptance: two same-named clones in different paths get different names; test pins it.
- Open question (for /codeo:plan): a devcontainer variable cannot hash, so the suffix needs a pre-create step (e.g. initializeCommand); the mechanism is for the plan.
