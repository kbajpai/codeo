# New issue — a container for each issue (from roadmaster)

| | |
|---|---|
| Skill | issue |
| Working title | Dev container: a home container for starting work and one container per issue |
| Reference | `/workspaces/roadmaster` (read-only clone of the project that already works this way) |

## Where this stands

Request restated: codeo's dev container (#36 and follow-ups) is one container per clone and takes no
lock, so `/codeo:init` binds whichever checkout it runs in, and two issues cannot run side by side
(seen today with #51 and #52). roadmaster solves it with a **home container** (clone on `main`, no
lock, where `/codeo:issue`, `/codeo:init` and `/codeo:triage` run) and **one container per issue**
(clone of the pushed branch, lock taken at start, where plan → implement → qc → close run). The issue
brings that to codeo. No duplicate found (`issue search` for "container per issue" and "host-workflow"
returned nothing).

What roadmaster has that codeo lacks:
- `.codeo/overlays/init.md` `## host-workflow`: init runs in the home container, writes no lock, never
  checks the branch out, and tells the engineer how to open the issue container.
- `devcontainer-start.sh` takes the lock in the issue container (`lock.sh take container`, plugin found
  by `.codeo/codeo-root.sh`) from the `init.md` on the pushed branch.
- `container-name.sh`, `folder-check.sh`, `window-title.sh`, `.codeo/project.sh`: name and window title
  (`codeo [#N]` / `codeo [home]`) come from the lock; a wrongly named clone folder is reported.
- `devcontainer.json`: `runArgs --name ${containerWorkspaceFolderBasename}`; clone-in-named-volume
  naming `<codename>-home` / `<codename>-<N>`.

Correction to what I said earlier: no host script clones and opens VS Code. The engineer does that by
hand with "Dev Containers: Clone Repository in Named Container Volume…", and init prints the exact
values. A container cannot open a sibling window.

## Questions

### Q1 — Scope: how much of roadmaster comes across?

**What.** Four separable pieces: (a) the init `host-workflow` overlay, (b) lock-taking in the start
script plus `codeo-root.sh`, (c) lock-derived name, title and folder check, (d) the naming convention in
`devcontainer.json`. (a) and (b) are what make a container per issue work; (c) and (d) make it legible
and are what roadmaster's `docker ps` / window title rely on.

**Why it matters.** (a)+(b) alone work but leave two containers named alike by folder only; all four is
a bigger change to review.

**Options.** *all four, one issue* · *(a)+(b) now, (c)+(d) as a follow-up issue* · *other*.

**Answer:**

### Q2 — Container name: replace #50's `<folder>-<devcontainerId>`?

**What.** #50 (merged) names the container `${localWorkspaceFolderBasename}-${devcontainerId}`, from the
host folder. roadmaster uses `${containerWorkspaceFolderBasename}` (the clone-in-volume folder) with no
id suffix, so the folder you type in the clone dialog is the Docker name. #54 (Backlog) is about
folders Docker rejects for the current form.

**Why it matters.** The home/issue naming relies on the folder being the name; keeping #50's form means
the name no longer says `codeo-52` vs `codeo-home`. Changing it supersedes part of #50 and touches #54.

**Options.** *adopt roadmaster's form and fold #54's name-validity requirement in* · *adopt it, leave #54
separate* · *keep #50's form; name the issue container some other way*.

**Answer:**

### Q3 — Hand-off: include roadmaster's `claude --cloud "/codeo:plan"` launch?

**What.** When the home container has a full `claude auth login`, roadmaster's overlay launches
`claude --cloud "/codeo:plan"` from the scratch worktree so the session starts on the issue's branch
with no clone step. Otherwise the overlay only prints the clone instructions.

**Why it matters.** It depends on `--cloud` behaviour and a web-session path codeo's dev container does
not use today. Leaving it out keeps the issue to the local-container flow.

**Options.** *leave it out (print the clone instructions only)* · *include it as roadmaster has it*.

**Answer:**

### Q4 — Order against #51 and #54, and how is "done" shown?

**What.** #51 (identity seeding, Ready) and #54 (container-name limits, Backlog) both edit
`devcontainer-start.sh` / `devcontainer.json`. roadmaster tests each script
(`.devcontainer/scripts/tests/*.test.sh`); codeo has `tests/devcontainer.test.sh`.

**Why it matters.** Run in parallel they conflict on the same files; `/codeo:plan`'s footprint check
would flag it, but you may want an order up front.

**Options.** *independent, let the footprint check decide* · *this after #51 and #54* · *this first*.
For "done": *a test per new script plus a manual check of two containers open at once* is my proposal;
say if you want it narrower.

**Answer:**

## Log

- 2026-11-10 — dossier opened with Q1-Q4 · cost: unavailable
