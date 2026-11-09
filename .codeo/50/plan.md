# Issue #50 — plan

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/50 |
| Branch | `feat/name-dev-container-after-its` |
| Updated | 2026-11-09 |

## Where this stands

Q1 and Q2 answered (name = folder + `${devcontainerId}`; the engineer runs the host check first). Waiting on Q3:
the engineer applies the one-line `runArgs` change, rebuilds, and reports the `docker ps` names. Nothing is drafted past it.

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

**Answer:**

## Outcome

_Pending — written at the hand-off._

## Log

- 2026-11-09 — Q1-Q2 answered, Q3 raised (host check) · cost: see the line below (same session)
- 2026-11-09 — Q1-Q2 raised · cost: 2m · fable-5-2 139k in + 779k cached / 8k out · sonnet-5-5 32k in + 4k cached / 3k out
