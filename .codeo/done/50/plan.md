# Issue #50 — plan

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/50 |
| Branch | `feat/name-dev-container-after-its` |
| Updated | 2026-11-09 |

## Where this stands

Q1-Q3 answered. The rebuilt container is named `codeo-home-031er97u1o8nfhn55jo8tkvqb43vvn3483bfpgnn92fj540pqokb`:
on a Docker-volume clone `${localWorkspaceFolderBasename}` resolves to `codeo-home` and `${devcontainerId}` is 52
characters (`[0-9a-v]`), 63 in all. Plan approved and written to `docs/plans/2026-11-09-name-dev-container-after-its-clone.md` (unstaged). No open question; next is `/codeo:implement`.

## Questions

### Q1 — Which name do we build, given a short hash is not reachable with one line?

**Why it matters:** the issue's Key Requirements say "a short hash of the clone's absolute path", and its
intake question assumed an `initializeCommand` script could compute one. It cannot feed `--name`:
`runArgs` only substitutes the format's own variables and `${localEnv:…}`, and `initializeCommand` runs on
the host as a separate process, so nothing it computes reaches `runArgs`. No variable truncates or hashes.
What the format does offer is `${devcontainerId}`: the reference says it is "unique to the dev container …
and … stable across rebuilds" and lists `runArgs` among the properties that support it. Its length is not
stated there; from memory it is about 52 characters (to be confirmed at the first rebuild), so the name would
look like `codeo-home-1a2b…` with a long tail, not `codeo-home-a1b2c3`.
One more fact bears on how much the suffix is worth: clones here are already named per issue
(`codeo-home`, `codeo-45`), so two clones sharing a folder name is rare.

**Options:**
- *Folder name plus `${devcontainerId}` (my recommendation):*
  `"--name=${localWorkspaceFolderBasename}-${devcontainerId}"`. One line, no script, meets all six
  acceptance criteria as written (none says "short"); the Key Requirement's word "short" is dropped and the
  plan says so. Cost: a long name in `docker ps`, still starting with the folder name.
- *Folder name only, as the stashed prototype does:* `"--name=${localWorkspaceFolderBasename}"`. The readable
  name; two same-named clones fail at start with Docker's "name already in use". This re-scopes the issue —
  the criterion "two same-named clones at different paths give different names" has to be removed from #50
  by you, since the plan never edits the issue.
- *A real short hash:* move the container to Docker Compose, with an `initializeCommand` script writing a
  `.env` that `container_name` reads. Gives `codeo-home-a1b2c3`, but rewrites how the container is defined
  (`mounts`, `runArgs` caps, build), needs the script to run on every host OS, and puts most of
  `tests/devcontainer.test.sh`'s `devcontainer.json` cases in play. I would not do this for a name.

**Answer:** Folder name plus `${devcontainerId}` (recommendation accepted, 2026-11-09). The Key Requirement's word "short" is dropped; the plan says so.

### Q2 — Who proves the criteria that need the host, and when?

**Why it matters:** three criteria ("after a rebuild, `docker ps` shows …", "rebuilding gives the same name",
"two same-named clones … give different names") can only be observed on the host: this container has no
`docker`, and a rebuild ends the session that asks for it. There is also something no document states:
this clone lives on a Docker named volume (`codeo-home`, mounted at `/workspaces`), and how
`${localWorkspaceFolderBasename}` and `${devcontainerId}` resolve for a volume clone is not written down
anywhere I could find. The suite can pin the `runArgs` text; it cannot show what Docker names the container.

**Options:**
- *You run a short manual checklist, before the plan is final (my recommendation):* apply the one-line
  change in this container, rebuild, and report `docker ps --format '{{.Names}}'` — it settles the volume-clone
  unknown and the suffix's real length before any task is written. The same checklist (rebuild again; a
  second clone with the same folder name) is then a manual task in the plan, its results recorded in the
  dossier, as #36 did for the criteria it could not run.
- *Manual checklist at QC only:* plan and implement on the documented behaviour, and you run the checklist
  when `/codeo:qc` asks. Faster now; if the variables resolve differently on a volume clone, the plan comes
  back for another round.

**Answer:** The engineer runs the short manual check before the plan is final (recommendation accepted, 2026-11-09).

### Q3 — What name did the rebuilt container get?

**Why it matters:** it settles how `${localWorkspaceFolderBasename}` and `${devcontainerId}` resolve for a clone on a Docker volume, and the suffix's real length, before any task is written.

**To do (engineer):** set `runArgs` to `["--name=${localWorkspaceFolderBasename}-${devcontainerId}", "--memory=4g", "--cpus=2"]` in `.devcontainer/devcontainer.json`, rebuild the container, then on the host run `docker ps --format '{{.Names}}'` and paste the line for this container.

**Answer:** `codeo-home-031er97u1o8nfhn55jo8tkvqb43vvn3483bfpgnn92fj540pqokb` (2026-11-09). The folder part resolves correctly for a clone on a Docker volume, and the suffix is 52 characters, as expected; the name is 63 characters long.

## Outcome

**Plan:** `docs/plans/2026-11-09-name-dev-container-after-its-clone.md` — an executable plan under `docs/plans/` (four tasks, one PR); no reference doc, since nothing here is a standing decision.

**Decisions.** The container is named by one `runArgs` entry, `--name=${localWorkspaceFolderBasename}-${devcontainerId}` (Q1). Rejected: the bare folder name (collides for same-named clones) and a real short hash through Docker Compose and an `initializeCommand` (rewrites the container's definition for a name). The issue's word "short" is dropped — the suffix is the 52-character `${devcontainerId}`. The engineer ran the host check (Q2, Q3): the rebuilt container is `codeo-home-031er97u1o8nfhn55jo8tkvqb43vvn3483bfpgnn92fj540pqokb`, so both variables resolve for a clone on a Docker volume. The `runArgs` edit is already in the working tree; the plan pins it in the suite, loosens the memory/cpu case to "has both caps", and adds a CHANGELOG bullet that says a rebuild is needed and that a leftover same-named container must be `docker rm`ed.

**Documentation moved:** `CHANGELOG.md` only; no page under `docs/`, no wiki module.

**Manual checks for the engineer** (Task 4): rebuild again and see the same name; start a second clone with the same folder name and see a different suffix.

No intake question was resolved here. `overlap.sh 50` printed nothing; no other workflow in flight; no exclusive resource, so no lock was taken.

### Footprint

```
files:      .devcontainer/devcontainer.json, tests/devcontainer.test.sh, CHANGELOG.md, docs/plans/2026-11-09-name-dev-container-after-its-clone.md
wiki:       none
exclusive:  none
sequenced:  none
```

## Log

- 2026-11-09 — Q3 answered (host check passed); plan drafted for review
- 2026-11-09 — planned: docs/plans/2026-11-09-name-dev-container-after-its-clone.md · cost: 2m · sonnet-5-5 32k in + 657k cached / 9k out · `engineering` plugin unavailable, its structure applied directly
- 2026-11-09 — Q1-Q2 answered, Q3 raised (host check) · cost: see the line below (same session)
- 2026-11-09 — Q1-Q2 raised · cost: 2m · fable-5-2 139k in + 779k cached / 8k out · sonnet-5-5 32k in + 4k cached / 3k out
