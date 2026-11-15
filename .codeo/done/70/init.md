# Issue #70 — init

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/70 |
| Branch | `feat/guard-home-only-skills-against` |
| Updated | 2026-11-15 |

## Where this stands

Branch `feat/guard-home-only-skills-against` cut off `main` at 90075d4, claimed and pushed. Nothing is open; the next step is `/codeo:plan`, run in this issue's own container.

## Questions

None.

## Outcome

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/70 — Guard the home-only skills against finished issue containers, print removal commands at close, and add a print-only /codeo:cleanup |
| State | open · no labels |
| Branch | `feat/guard-home-only-skills-against` off `main` at 90075d4 |
| Board | Ready → In progress |

**Problem.** `/codeo:issue`, `/codeo:init` and `/codeo:triage` are meant for the home container and `/codeo:plan` through `/codeo:close` for an issue container, but nothing enforces it: `/codeo:close` deletes `.codeo/active`, so a finished issue container looks like an unbound home container (seen 2026-11-14 in `codeo-67`). `/codeo:close` also never lists the host commands that remove its finished container and volume, and the home container cannot remove them itself (no container engine, no Docker socket).

**Acceptance criteria** — verbatim from the issue, unchecked:
- [ ] The role script prints `home` for a clone on `main` in folder `<codename>-home` with no lock, `issue:<N>` when a lock for `<N>` exists, and `stale:<N>` for a clone with no lock whose folder is `<codename>-<N>` or whose branch is not `main`; a test pins each case.
- [ ] `/codeo:issue`, `/codeo:init`, `/codeo:triage` and `/codeo:cleanup` each stop, with one line naming the role, outside the home container, and have no override; a test fails if any of the four stops declaring or calling the check.
- [ ] `/codeo:plan`, `/codeo:implement`, `/codeo:qc` and `/codeo:close` stop when the clone's folder does not match the lock's issue, and every skill stops in a stale container with a message naming the finished issue.
- [ ] In a hosted web session or a plain local checkout, the four home-only skills run as they do today.
- [ ] After a finished workflow in a container, `/codeo:close`'s final report contains `docker rm -f codeo-<N>; docker volume rm codeo-<N>` with `<N>` taken from the lock's `volume:` line, says it runs on the host and says to check `git status` first; a test pins the text.
- [ ] `/codeo:cleanup` prints a removal command only for an issue that passes all four proofs, lists any other issue with the failed proof and no command, and never prints `codeo-home`, `codeo-gh`, `codeo-git` or any name outside `^codeo-[0-9]+$`; a test pins each.
- [ ] `/codeo:cleanup` runs no Docker command, and `.devcontainer/Dockerfile` and `.devcontainer/devcontainer.json` gain no container engine, bind mount or secret (`tests/devcontainer.test.sh` still passes).
- [ ] `docs/skills.md`, the README's Skills table, `docs/skills-inventory.md` and `.devcontainer/README.md` describe the new skill and the roles, `CHANGELOG.md` has an `## Unreleased` entry, and `bash tests/run.sh` passes.

**Out of scope.** Actually removing containers or volumes, mounting the Docker socket, and putting a container engine in the Dockerfile; #69's own items (closing blocks, plan host commands, the #67 wording notes); the open dev container follow-ups #40, #51, #54 and #57.

**Open at intake.** (history, frozen; `/codeo:plan` settles them)
- How does a skill detect that the checkout is this project's dev container, so the guard does not lock out a hosted web session or a plain local checkout? The proposed rule (guard only where it is a dev container) needs the engineer's confirmation at the plan's approval gate.
- Is a `.codeo/closed` tombstone, written by `/codeo:close`, worth having on top of the folder-and-branch check?
- Where does the role script live: this project's `.devcontainer/scripts/` or the plugin's `scripts/`?
- #57 changes `folder-check.sh` (it hard-codes `main`); does the role script reuse or replace that check?

## Log

- 2026-11-15 — initialized: branch feat/guard-home-only-skills-against off main at 90075d4 · cost: 1m · sonnet-5-5 19k in + 485k cached / 4k out
