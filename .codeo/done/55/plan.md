# Issue #55 — plan

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/55 |
| Branch | `feat/dev-container-home-container-starting` |
| Updated | 2026-11-10 |

## Where this stands

Plan approved and written to `docs/plans/2026-11-10-home-and-issue-containers.md` (unstaged). No open question; next is `/codeo:implement`.

What exploration found, which shapes the questions:
- **No plugin change is needed.** The installed 1.0.3 `lock.sh take container` already writes the lock from the `init.md` naming the checked-out branch, records the volume, and takes none on `main`. The start script only has to call it, as the reference project's does.
- **`window-title.sh` already derives `codeo [#N]` / `codeo [home]` from `.codeo/active`**, reading the codename from `.codeo/config.json`. What is missing is the Docker-name form, the folder check, and one source for all three so they cannot drift (the reference project's `container-name.sh`).
- **#50's name `${localWorkspaceFolderBasename}-${devcontainerId}` resolves to the clone folder plus 52 characters** (its plan, Q3), so the folder part already works on a volume clone. The new name drops the suffix and uses `${containerWorkspaceFolderBasename}`, as the reference project does.
- **`init`'s default already stops on a `.codeo/active`**; the overlay narrows it to "run it in the home container" and stops it from switching the checkout or taking the lock.
- **No other workflow in flight**, so no footprint overlap to raise now. #51 and #52 are Ready but not started.

Decisions taken without a question, to be shown as such in the plan: one PR; the overlay prints the clone instructions only (no `claude --cloud`, your answer to intake Q3); no change under `scripts/`, `lib/`, `hooks/` or `skills/`; a test per new script, in new files under `tests/` (the suite runs every `tests/*.test.sh`), with the existing `tests/devcontainer.test.sh` cases for `runArgs` and the start script updated; AC8 (two containers at once) is a manual task for you, as #50's host check was, because this container has no `docker`.

## Questions

### Q1 — Acceptance criterion 7 (a folder Docker rejects) cannot be met by a script for a clone-in-volume. What do we build?

**Why it matters:** AC7 says a clone folder with a space, `+`, `@`, non-ASCII or a leading `.`/`_` "starts, with a valid name or a stated reason". With `--name ${containerWorkspaceFolderBasename}` the Docker name is the folder, and Docker refuses an invalid name when it creates the container, before the start script (or any script) runs. `devcontainer.json` has no variable that sanitises, and the reference project's own comment records that `initializeCommand` does not run on the host for a volume clone, so nothing can compute a fallback name. I have not been able to test this here (no `docker`); it rests on the reference project's comment and on the dev container reference.

What can be done:
- **A. Valid by construction, reason stated in writing.** The folders `init` prints are always `codeo-home` and `codeo-<N>`, which are valid. The new `.devcontainer/README.md` states the allowed characters (`[a-zA-Z0-9][a-zA-Z0-9_.-]+`) and that Docker, not codeo, refuses anything else, with the fix (re-clone with a valid folder). The CHANGELOG says the same. When the start script does run, `folder-check.sh` names the folder it expects. "A stated reason" is met in documentation, not at the moment of failure.
- **B. A and a guard in the start script** that also reports a folder outside the allowed set. It can only run for a container that started, so it helps a folder Docker accepted but codeo dislikes (for example a leading digit-free name that is not `codeo-home` or `codeo-<N>`), not the rejected ones. Small, and `folder-check.sh` already covers the "wrong name" half.
- **C. Keep `-${devcontainerId}` (#50's form) for local folders and use the folder alone only for volume clones.** Not possible: `devcontainer.json` cannot branch on how it was opened.

I recommend A, with B's reporting folded into `folder-check.sh` as it is anyway. Either way the literal AC7 ("starts") holds only for names Docker accepts, so the issue's wording would be read as "starts, or the reason is stated in the README and CHANGELOG". Editing the issue's criterion is yours to do; say here whether to read AC7 that way or to change it first.

**Options:** A (recommended), reading AC7 as stated-in-writing · A, and you will reword AC7 in the issue first · something else.

**Answer:** A — valid by construction, reason stated in writing; AC7 read as "starts, or the reason is stated in the README and CHANGELOG" (engineer, 2026-11-10)

### Q2 — How is the name logic shared, and does codeo get a `.codeo/project.sh`?

**Why it matters:** the reference project has `.codeo/project.sh` (codename and secrets resolution), `.codeo/codeo-root.sh` (finds the installed plugin) and `.devcontainer/scripts/{container-name,folder-check}.sh`. codeo needs only some of that: it has no secrets store, and `window-title.sh` already reads the codename with `jq` from `.codeo/config.json`.

What can be built:
- **A. Two new scripts, no `project.sh`.** `.devcontainer/scripts/container-name.sh [--docker] [dir]` prints `codeo [#N]` / `codeo [home]` or `codeo-<N>` / `codeo-home` from the lock; `window-title.sh` calls it instead of deriving the title itself, so there is one source. `folder-check.sh <folder>` as the reference project's. `codeo-root.sh` lives beside them in `.devcontainer/scripts/` (only the start script uses it). The codename is read from `.codeo/config.json` with `jq` in `container-name.sh`, falling back to the clone directory's name as `window-title.sh` does today.
- **B. Port the reference project's four files as they are**, including `.codeo/project.sh`, with the codename check it brings. More code to keep, most of it unused here.

I recommend A: it keeps the diff to what the criteria need, and `window-title.sh`'s present behaviour (including its codename fallback) is kept and tested.

**Options:** A (recommended) · B · something else.

**Answer:** A — two new scripts plus codeo-root.sh in .devcontainer/scripts/, no .codeo/project.sh (engineer, 2026-11-10)

### Q3 — Where does the how-to for the two kinds of container live?

**Why it matters:** the criteria need the clone-in-named-volume steps in two places: printed by `init` (the overlay) and written down for someone who has not run it yet. codeo has no page about the dev container today (`README.md` and `docs/` never mention it); the reference project keeps `.devcontainer/README.md`.

What can be built:
- **A. `.devcontainer/README.md`**, short: the home and issue container names, the exact "Clone Repository in Named Container Volume…" values, the allowed folder characters (Q1), rebuild note, and the one-time `docker rm` for a leftover container of the same name. Linked from `README.md` in one line. The overlay's printed text stays the source for the per-issue values.
- **B. A section in `README.md`** only.
- **C. Nothing beyond the overlay and CHANGELOG.**

I recommend A, because the rebuild and folder-name notes belong next to the container's definition and Q1's reading of AC7 relies on them being written down.

**Options:** A (recommended) · B · C.

**Answer:** A — .devcontainer/README.md, linked from README.md (engineer, 2026-11-10)

### Q4 — Which overlays does this issue add?

**Why it matters:** the reference project has overlays for `init`, `close`, `plan`, `implement`, `qc` and `triage`; most are about its shared DEV environment. Two bear on this change: `init` (the issue, AC1-3) and `close`'s `host-workflow` (tells the engineer how to remove the issue's container and volume at the end, using the lock's `volume:` line). Without a `close` overlay the plugin's default report names the lock's host and says whether anything is left to remove, which is correct but gives no commands.

What can be built:
- **A. `init` only**, as the criteria say. `close`'s default report stands.
- **B. `init` and `close/host-workflow`**, the second printing the `docker rm` / `docker volume rm` commands for the lock's volume. It adds a file, a test and a CHANGELOG line to a change that is already large, and is not in any criterion.

I recommend A, and filing the `close` overlay as its own small issue through `/codeo:issue` when you want it; say if you would rather fold it in.

**Options:** A (recommended), `close` overlay as a separate issue · B · A and no follow-up.

**Answer:** A — init overlay only; the close overlay is a separate issue (engineer, 2026-11-10)

## Outcome

**Plan.** `docs/plans/2026-11-10-home-and-issue-containers.md` (unstaged, awaiting your commit). Shape: an executable plan under `docs/plans/` — eight test-first tasks, each ending in a `bash tests/run.sh <pattern>` proof; no reference doc, because the standing decisions fit the plan's options table.

**Decisions** (Q1-Q4 all A):
- Q1 — a folder Docker rejects is handled by construction (`codeo-home`, `codeo-<N>`) and by stating the rule and fix in `.devcontainer/README.md` and the CHANGELOG; AC7 is read as "starts, or the reason is stated in writing". Rejected: a script fallback name (nothing runs before Docker refuses), keeping `-${devcontainerId}`.
- Q2 — `container-name.sh` (title, Docker name, `--codename`), `folder-check.sh`, `codeo-root.sh` in `.devcontainer/scripts/`; no `.codeo/project.sh`. `window-title.sh` calls `container-name.sh`.
- Q3 — `.devcontainer/README.md`, linked from `README.md`.
- Q4 — `init` overlay only; the `close` overlay is a separate issue.
- Own calls: the start script takes the lock with the installed plugin's `lock.sh take container` (no plugin change) and prints its lines verbatim; no lock on the base branch; `runArgs` pinned exactly; `.codeo/overlays/**` added to the shell suite's paths; AC1-5 and AC8 are proved by the engineer on the host (no `docker` here).

**Documentation the plan changes:** `.devcontainer/README.md` (new), `README.md` (one link), `CHANGELOG.md`. `docs/extension-points.md` already covers `init/host-workflow`.

**Intake questions resolved:** none open at intake.

### Footprint

```
files:      .devcontainer/**, .codeo/overlays/**, .codeo/config.json, tests/**, README.md, CHANGELOG.md, docs/plans/2026-11-10-home-and-issue-containers.md
wiki:       none
exclusive:  none
```

## Log

- 2026-11-10 — plan dossier opened with Q1-Q4 · cost: unavailable
- 2026-11-10 — planned: docs/plans/2026-11-10-home-and-issue-containers.md · cost: 14m · sonnet-5-5 82k in + 3.3M cached / 33k out
