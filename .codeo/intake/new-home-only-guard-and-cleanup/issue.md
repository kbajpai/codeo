# Issue #new-home-only-guard-and-cleanup — issue

| | |
|---|---|
| Issue | not filed yet |
| Called from | the engineer, in the conversation after `/codeo:init #69` ran in a finished issue container; not from triage |
| Updated | 2026-11-14 |

## Where this stands

Request restated, duplicates searched (none), facts checked against `main`. The one question the engineer had not answered is answered (Q1). Draft written below and waiting for the engineer's approval before filing.

**Problem as I understand it.** `/codeo:issue`, `/codeo:init` and `/codeo:triage` are meant to run in the home container (`.devcontainer/README.md`: "Where these run"), but the only thing that keeps them out of an issue container is `.codeo/active`, and `/codeo:close` deletes that file at the end. On 2026-11-14 `/codeo:triage` and `/codeo:init #69` ran in the finished container `codeo-67` (folder `codeo-67`, a stale feature branch, no lock) and nothing stopped them. Separately, `/codeo:close` ends by saying the container and volume are "the engineer's to remove" without saying how, and nothing lists the containers that are left. The engineer asked for a guard, for exact removal commands at the end of `close`, and for a new `/codeo:cleanup` that is print-only, because the home container has no container engine.

## Questions

### Q1 — Is the home-only rule strict, or can the engineer override it?

**Why it matters:** an override needs a recorded-words path in each of four skills and a test for it; strict needs neither, and a hosted web session or local checkout would have to be handled by the guard's own rule instead.
**Options:** strictly home-only · override in the engineer's words, recorded in the dossier.

**Answer:**
Strictly home-only (answered in the conversation).

## Notes

- Duplicate search (`github.sh issue search`): "home container" finds #57, #40, #51 (dev container follow-ups); "cleanup" finds only #58 (closed); "stale container" finds #69; "guard" finds #41, #43, #34. None covers a home-only guard or a cleanup skill. #57 is the nearest: it includes `folder-check.sh` hard-coding `main` and shared folder names, so a role script touches the same area.
- Checked on `origin/main`: `.devcontainer/README.md` lists "Where these run" as `/codeo:issue`, `/codeo:init`, `/codeo:triage` for home and `/codeo:plan` through `/codeo:close` for issue containers; `skills/` holds `close doctor implement init issue plan qc setup triage`, so `doctor` and `setup` have no stated role; `skills/close/SKILL.md` line 513 reads "**`host: container`** — the checkout is a container, which this skill cannot remove from…"; `container-name.sh` names a clone "home" whenever `.codeo/active` is absent, and `folder-check.sh` leaves a `codeo-<digits>` folder alone, which is why a finished container reads as home.
- The home container cannot remove containers: its Dockerfile leaves out a container engine on purpose and `tests/devcontainer.test.sh` forbids bind mounts and secrets. The engineer decided: print only, never mount the Docker socket.
- Proposed (not asked, goes to the approval gate): the guard is the project's, so it lives in overlays and a script, and applies only where the checkout is this project's dev container; a hosted web session or a plain local checkout runs as it does today. How a skill detects "this is a dev container" is `/codeo:plan`'s.
- Proposed: no Issue Type (a user-owned repository has none); label `enhancement`.

## Draft

**Title:** Guard the home-only skills against finished issue containers, print removal commands at close, and add a print-only /codeo:cleanup

**Issue Type:** none. The repository is user-owned and has no Issue Types.
**Labels:** `enhancement`

```markdown
### Description

Make the skills that belong in the home container refuse to run anywhere else, have `/codeo:close` print the exact host commands that remove its finished container and volume, and add a `/codeo:cleanup` skill, run from the home container, that prints those commands for every finished issue. It prints and never runs them.

### Motivation / Context

`.devcontainer/README.md` says `/codeo:issue`, `/codeo:init` and `/codeo:triage` run in the home container and `/codeo:plan` through `/codeo:close` in an issue container. Nothing enforces it. The one guard is that `.codeo/active` must be absent, and `/codeo:close` deletes that file when it finishes, so a finished issue container looks like an unbound home container. On 2026-11-14 `/codeo:triage` and `/codeo:init #69` ran in the finished container `codeo-67` (folder `codeo-67`, a stale feature branch, no lock) without a word. `container-name.sh` even titles such a container `codeo [home]`, and `folder-check.sh` leaves a `codeo-<digits>` folder alone.

At the end of a workflow `/codeo:close` says only that the container and its volume "are the engineer's to remove", and nothing lists which ones are left. The home container cannot do the removing: its Dockerfile leaves out a container engine on purpose, and a test forbids bind mounts and secrets, which rules out mounting the Docker socket.

### Key Requirements

- A checkout has one role: home (folder `<codename>-home`, on `main`, no lock), issue `<N>` (a lock for `<N>`), or stale `<N>` (no lock, but the folder is `<codename>-<digits>` or the branch is not `main`). One script decides it, and everything below uses it.
- `/codeo:issue`, `/codeo:init`, `/codeo:triage` and `/codeo:cleanup` run only in the home container, strictly: outside it they stop with one line naming the role and saying to run in the home container. There is no override.
- `/codeo:plan`, `/codeo:implement`, `/codeo:qc` and `/codeo:close` also stop when the clone's folder does not match the lock's issue. In a stale container every skill stops, and the message says the container belongs to a finished issue.
- The guard is the project's. It applies where the checkout is this project's dev container, and a hosted web session or a plain local checkout runs as it does today. (Proposed here, not yet confirmed by the engineer; see Open questions.)
- When a workflow finishes in a container, `/codeo:close`'s final report prints the host commands that remove its container and volume, built from the lock's `volume:` line read before the lock is deleted, for example `docker rm -f codeo-67; docker volume rm codeo-67`. It says they run on the host, not inside the container, and says to check `git status` in that clone first. They run unmodified in PowerShell and in bash.
- `/codeo:cleanup` finds finished issues from `.codeo/done/<N>` on `origin/main`, re-proves each one on GitHub (issue closed, pull request closed with `merged_at` set, remote branch gone, no live `.codeo/<N>` dossier on any branch), and prints one removal command per issue that passes. An issue that fails a proof is listed with the proof that failed and no command.
- `/codeo:cleanup` only ever prints names that match `^codeo-[0-9]+$`. It never prints `codeo-home`, `codeo-gh` or `codeo-git`; the last two hold the `gh` login and the git identity.
- `/codeo:cleanup` never runs a Docker command, and nothing here gives the home container a container engine or the Docker socket. It says that unpushed work in a clone is invisible from the home container, and that it relies on `close.md` having recorded a clean tree with the tip equal to the pull request's head. It records what it printed in a dossier on the intake branch, as `/codeo:triage` does.
- The new skill is documented where every skill is: `docs/skills.md`, the README's Skills table, `docs/skills-inventory.md`, and the container table in `.devcontainer/README.md`, which also gains the role of `doctor` and `setup`.
- This work follows #69, which also changes `skills/close/SKILL.md`, `docs/handoff.md` and `tests/closing-block.test.sh`.

### Acceptance Criteria

- [ ] The role script prints `home` for a clone on `main` in folder `<codename>-home` with no lock, `issue:<N>` when a lock for `<N>` exists, and `stale:<N>` for a clone with no lock whose folder is `<codename>-<N>` or whose branch is not `main`; a test pins each case.
- [ ] `/codeo:issue`, `/codeo:init`, `/codeo:triage` and `/codeo:cleanup` each stop, with one line naming the role, outside the home container, and have no override; a test fails if any of the four stops declaring or calling the check.
- [ ] `/codeo:plan`, `/codeo:implement`, `/codeo:qc` and `/codeo:close` stop when the clone's folder does not match the lock's issue, and every skill stops in a stale container with a message naming the finished issue.
- [ ] In a hosted web session or a plain local checkout, the four home-only skills run as they do today.
- [ ] After a finished workflow in a container, `/codeo:close`'s final report contains `docker rm -f codeo-<N>; docker volume rm codeo-<N>` with `<N>` taken from the lock's `volume:` line, says it runs on the host and says to check `git status` first; a test pins the text.
- [ ] `/codeo:cleanup` prints a removal command only for an issue that passes all four proofs, lists any other issue with the failed proof and no command, and never prints `codeo-home`, `codeo-gh`, `codeo-git` or any name outside `^codeo-[0-9]+$`; a test pins each.
- [ ] `/codeo:cleanup` runs no Docker command, and `.devcontainer/Dockerfile` and `.devcontainer/devcontainer.json` gain no container engine, bind mount or secret (`tests/devcontainer.test.sh` still passes).
- [ ] `docs/skills.md`, the README's Skills table, `docs/skills-inventory.md` and `.devcontainer/README.md` describe the new skill and the roles, `CHANGELOG.md` has an `## Unreleased` entry, and `bash tests/run.sh` passes.

### Out of Scope

- Actually removing containers or volumes, mounting the Docker socket, and putting a container engine in the Dockerfile.
- #69's own items (the closing blocks, plan host commands, the #67 wording notes).
- The open dev container follow-ups #40, #51, #54 and #57.

### Open questions

- How does a skill detect that the checkout is this project's dev container, so the guard does not lock out a hosted web session or a plain local checkout? `/codeo:plan` settles this; the proposed rule (guard only where it is a dev container) needs the engineer's confirmation at the approval gate.
- Is a `.codeo/closed` tombstone, written by `/codeo:close` instead of only deleting the lock, worth having on top of the folder-and-branch check? `/codeo:plan` settles this.
- Where does the role script live (this project's `.devcontainer/scripts/` next to `container-name.sh` and `folder-check.sh`, or the plugin's `scripts/`), given that the home container is this project's concept and not codeo's? `/codeo:plan` settles this.
- #57 changes `folder-check.sh` (it hard-codes `main`); does the role script reuse or replace that check? `/codeo:plan` settles this.

### Reference

- `.devcontainer/README.md` ("Where these run"), `.devcontainer/scripts/container-name.sh`, `.devcontainer/scripts/folder-check.sh`, `.codeo/overlays/init.md`.
- `skills/close/SKILL.md` (step 17 and the `host: container` line), `docs/handoff.md → The lock`.
- Observed 2026-11-14: `/codeo:triage` and `/codeo:init #69` ran in the finished container `codeo-67`.
- #69 (closing blocks; this follows it), #57 (dev container follow-ups, `folder-check.sh`), #67 (the change that left the finished container).
```

## Outcome

_Pending — written at the hand-off._

## Log

- 2026-11-14 — request restated, duplicates searched, Q1 answered in the conversation, draft written · cost: 1m · sonnet-5-5 18k in + 2.4M cached / 10k out
