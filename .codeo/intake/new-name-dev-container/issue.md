# Issue new-name-dev-container — issue

| | |
|---|---|
| Issue | not filed yet |
| Branch | none (intake) |
| Updated | 2026-11-09 |

## Where this stands

Drafting. Problem restated: the dev container gets a random Docker name (`upbeat_germain`) because
`runArgs` in `.devcontainer/devcontainer.json` has no `--name`, so the engineer cannot tell which
container belongs to which clone in `docker ps`. A prototype (`--name=${localWorkspaceFolderBasename}`,
plus the `runArgs` assertion in `tests/devcontainer.test.sh` and a CHANGELOG line) exists uncommitted
on `main`; it would name this clone's container `codeo-home`. The issue records the requirement, not
the prototype. Searched existing issues for "container name" and "runArgs": no duplicate (#40 is the
nearest, a different scope). Q1-Q3 answered; the draft below awaits approval.

## Questions

### Q1 — What name should the container get?

**Why it matters:** the prototype uses the bare folder name, which can collide with an unrelated container, or a stopped one, of the same name; a prefix avoids that but changes the name (`codeo-codeo-home` for this clone).
**Options:** bare clone-folder name (`codeo-home`) · fixed prefix plus folder name · the repo name from `.codeo/config.json` (not available to `devcontainer.json` variables, so it would need a script).

**Answer:**
Bare clone-folder name (`codeo-home`).

### Q2 — If a container of that name already exists (e.g. stopped), what should happen?

**Why it matters:** Docker refuses to start a second container with the same name; the issue either accepts that and documents the `docker rm`, or asks for it to be handled.
**Options:** accept the error and document it · out of scope, note it only · handle it in the start script.

**Answer:**
Accept the error and document it. (Duplicates only arise from two clones with the same folder name, or a leftover stopped container.)

### Q3 — Is anything beyond naming in scope?

**Why it matters:** the volumes `codeo-git` and `codeo-gh` are shared by every dev container, and the window and session titles already use the codename; the issue could align the container name with those or leave them alone.
**Options:** naming only · also align with the codename used for window and session titles.

**Answer:**
Naming only; the container name stays independent of the codename used for the window and session titles. (The name cannot read `.codeo/config.json` without a script, and the codename is less unique than the folder name.)

## Notes

Done looks like: after a rebuild, `docker ps` shows the chosen name for this clone; the `runArgs`
test pins it; the CHANGELOG records it and the rebuild it needs. Out of scope: the git-identity
seeding (its own dossier) and anything under `scripts/`, `lib/`, `hooks/` or `skills/`.

## Outcome

_Pending — written at the hand-off._

## Draft

Title: Name the dev container after its clone folder instead of a random Docker name
Issue Type: none (user-owned repository). Labels: enhancement

### Description

The dev container gets a random Docker name (for example `upbeat_germain`) because `runArgs` in `.devcontainer/devcontainer.json` has no `--name`. Name it after its clone folder, so `docker ps` shows which container belongs to which clone (`codeo-home` for this one).

### Motivation / Context

With several dev containers running, a random name says nothing about the clone behind it. The window and session titles are already named for the clone; the container itself is the odd one out.

### Key Requirements

- The container's Docker name is the clone folder's name, with no prefix.
- The name comes from the devcontainer variable for the workspace folder's basename, so it needs no script and does not read `.codeo/config.json`.
- The container name stays independent of the codename the window and session titles use.
- The CHANGELOG says the name needs a container rebuild to take effect, and that a stopped container of the same name must be removed with `docker rm` before the container can start.

### Acceptance Criteria
- [ ] After a rebuild, `docker ps` shows this clone's container as `codeo-home`.
- [ ] `tests/devcontainer.test.sh` pins the `--name` entry in `runArgs`, and the suite passes.
- [ ] `CHANGELOG.md` records the change, the rebuild it needs, and the `docker rm` remedy for a name that is already taken.
- [ ] `runArgs` still carries `--memory=4g` and `--cpus=2`.

### Out of Scope

- Handling a name that is already taken (Docker's error is accepted and documented).
- A prefix, or a name derived from the codename.
- Changing the window or session titles.
- Seeding the git identity (its own issue).

### Reference

- `.devcontainer/devcontainer.json` (`runArgs`), `tests/devcontainer.test.sh` (the `runArgs` assertion), `CHANGELOG.md`.
- Related, closed: #45 (session titles), #47 (dev container hardening).
- A prototype of the `runArgs` change exists uncommitted on `main` in the engineer's working tree.

## Log

- 2026-11-09 — Q1-Q3 raised
- 2026-11-09 — Q1-Q3 answered; draft recorded
