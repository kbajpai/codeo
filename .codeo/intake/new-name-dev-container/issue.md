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
nearest, a different scope). Blocked on Q1-Q3.

## Questions

### Q1 — What name should the container get?

**Why it matters:** the prototype uses the bare folder name, which can collide with an unrelated container, or a stopped one, of the same name; a prefix avoids that but changes the name (`codeo-codeo-home` for this clone).
**Options:** bare clone-folder name (`codeo-home`) · fixed prefix plus folder name · the repo name from `.codeo/config.json` (not available to `devcontainer.json` variables, so it would need a script).

**Answer:**

### Q2 — If a container of that name already exists (e.g. stopped), what should happen?

**Why it matters:** Docker refuses to start a second container with the same name; the issue either accepts that and documents the `docker rm`, or asks for it to be handled.
**Options:** accept the error and document it · out of scope, note it only · handle it in the start script.

**Answer:**

### Q3 — Is anything beyond naming in scope?

**Why it matters:** the volumes `codeo-git` and `codeo-gh` are shared by every dev container, and the window and session titles already use the codename; the issue could align the container name with those or leave them alone.
**Options:** naming only · also align with the codename used for window and session titles.

**Answer:**

## Notes

Done looks like: after a rebuild, `docker ps` shows the chosen name for this clone; the `runArgs`
test pins it; the CHANGELOG records it and the rebuild it needs. Out of scope: the git-identity
seeding (its own dossier) and anything under `scripts/`, `lib/`, `hooks/` or `skills/`.

## Outcome

_Pending — written at the hand-off._

## Log

- 2026-11-09 — Q1-Q3 raised
