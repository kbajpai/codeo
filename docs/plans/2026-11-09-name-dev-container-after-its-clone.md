# Name the Dev Container After Its Clone Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `docker ps` shows the dev container as `<clone folder>-<devcontainerId>` instead of a random Docker name, stable across rebuilds, distinct for same-named clones at different paths.

**Architecture:** One `runArgs` entry in `.devcontainer/devcontainer.json`: `--name=${localWorkspaceFolderBasename}-${devcontainerId}`. Both variables are substituted by the dev container tooling in `runArgs`; no script is involved. The change is already in the working tree (the engineer applied it for the Q3 host check); the plan pins it in the suite and records it.

**Tech Stack:** JSON (`devcontainer.json`), bash, jq; `tests/devcontainer.test.sh`.

**Spec:** GitHub issue #50 as restated in `.codeo/50/init.md` → `## Outcome`; decisions in `.codeo/50/plan.md` Q1–Q3.

## Options considered

| Decision | Chosen | Rejected | Why |
|---|---|---|---|
| The name (Q1) | folder name + `${devcontainerId}` | folder name alone; a real short hash via Docker Compose + `initializeCommand` | one line, no script, all six criteria hold; the alone form collides on same-named clones; Compose rewrites the container's definition for a name |
| Who proves the host-only criteria (Q2) | the engineer, before the plan was final, and again at QC | at QC only | the volume-clone behaviour is undocumented |
| Host result (Q3) | `codeo-home-031er97u1o8nfhn55jo8tkvqb43vvn3483bfpgnn92fj540pqokb` | — | folder part resolves to `codeo-home`; suffix is 52 characters |

The issue's Key Requirement says "short hash"; none of the acceptance criteria does. The suffix is a 52-character `${devcontainerId}`, not a short hash. This is the deliberate departure from the issue's wording (Q1).

## Global Constraints

- Files that change: `.devcontainer/devcontainer.json` (already edited, uncommitted), `tests/devcontainer.test.sh`, `CHANGELOG.md`. Nothing in `scripts/`, `lib/`, `hooks/`, `skills/` or `docs/`.
- `runArgs` is exactly `["--name=${localWorkspaceFolderBasename}-${devcontainerId}","--memory=4g","--cpus=2"]` — the memory and cpu caps stay (criterion 5).
- The suite (`shell`) has no `filter`, so a task's proof is `bash tests/run.sh devcontainer` (the one test file); the last task runs the whole suite. A failing case prints `FAIL <case>: …`.
- Documentation moved: `CHANGELOG.md` only (Task 2) and the test file's header comment (Task 1). No page under `docs/` describes the dev container, there is no wiki module, no invariants document and no shared environment: no task carries a lease marker.
- A leftover stopped container with the same name makes the next start fail with Docker's "name already in use" (`docker rm <name>`); the CHANGELOG entry says so (issue intake Q2).
- Host-only criteria (rebuild gives the same name; two same-named clones differ) cannot run in this container (no `docker`, a rebuild ends the session). They are the manual Task 4, results recorded in `.codeo/50/qc.md`'s hand-off by the engineer.

## Tasks

### Task 1: Pin the naming in the suite

**Files:**
- Modify: `tests/devcontainer.test.sh` (case `run_args_cap_memory_and_cpus`, `cases=( … )`, header comment)

**Interfaces:**
- Produces: case `run_args_name_the_container_after_its_clone`; `run_args_cap_memory_and_cpus` now checks the caps are present rather than the whole array.

- [ ] **Step 1: Write the failing test.** Add `run_args_name_the_container_after_its_clone`: `jq -e '.runArgs | index("--name=${localWorkspaceFolderBasename}-${devcontainerId}")' "$(dc_json)"` (single-quoted, so bash leaves `${…}` alone), else `fail 'runArgs has no --name=${localWorkspaceFolderBasename}-${devcontainerId}'`. Change `run_args_cap_memory_and_cpus` to `jq -e '.runArgs | (index("--memory=4g") != null) and (index("--cpus=2") != null)'`. List the new case right after it in `cases=( … )`, and add "names the container after its clone folder" to the header comment's `devcontainer.json` sentence.
- [ ] **Step 2: Run to verify it fails.** The edit to `devcontainer.json` is already in the working tree, so revert it for this run: `git stash push -- .devcontainer/devcontainer.json && bash tests/run.sh devcontainer; git stash pop`. Expected: `FAIL run_args_name_the_container_after_its_clone: runArgs has no --name=…`; every other case passes.
- [ ] **Step 3: Run with the edit.** `bash tests/run.sh devcontainer`. Expected: no `FAIL` line, exit 0.
- [ ] **Step 4: Commit** `tests/devcontainer.test.sh` and `.devcontainer/devcontainer.json` together: `feat: name the dev container after its clone folder (#50)`.

**Proof of done:** `bash tests/run.sh devcontainer` exits 0 with no `FAIL`; `shellcheck tests/devcontainer.test.sh` is clean.

### Task 2: Record the change in the CHANGELOG

**Files:**
- Modify: `CHANGELOG.md` (one bullet under `## Unreleased`, after the #47 entry)

- [ ] **Step 1: Add the bullet.** It says: the dev container is named `<clone folder>-<devcontainerId>` (for this clone `codeo-home-031er…`, 63 characters) through `runArgs` `--name=${localWorkspaceFolderBasename}-${devcontainerId}`, so `docker ps` shows which clone it belongs to; the name is stable across rebuilds and differs for same-named clones at different paths; **rebuild the container once to get the name**; a leftover container of the same name makes the start fail with "name already in use" — `docker rm` it; nothing in `scripts/`, `lib/`, `hooks/` or `skills/` changes (#50).
- [ ] **Step 2: Verify.** `grep -c '#50' CHANGELOG.md` → `1`; `grep -n 'rebuild' CHANGELOG.md` shows the new bullet.
- [ ] **Step 3: Commit** `docs: record the dev container name in the changelog (#50)`.

**Proof of done:** `grep -c '(#50)' CHANGELOG.md` prints `1`, and `bash tests/run.sh` still exits 0 (the CHANGELOG is not under the suite's paths, so this is the check that nothing else moved).

### Task 3: Run the whole suite

- [ ] **Step 1:** `bash tests/run.sh`. Expected: exit 0, no `FAIL`.
- [ ] **Step 2:** `git status --short` shows nothing outside the three files named in Global Constraints.

**Proof of done:** `bash tests/run.sh` exits 0.

### Task 4: Manual host checks (the engineer)

Cannot run in this container; `/codeo:qc` asks for the results.

- [ ] **Step 1: Rebuild again.** Rebuild the container; on the host `docker ps --format '{{.Names}}'` shows the same name as the Q3 answer, `codeo-home-031er97u1o8nfhn55jo8tkvqb43vvn3483bfpgnn92fj540pqokb` (criterion 2).
- [ ] **Step 2: A second clone with the same folder name.** Open a clone at another path whose folder is also called `codeo-home` and start its container; `docker ps` shows two names that share `codeo-home-` and differ in the suffix, and both start (criterion 3).

**Proof of done:** the two `docker ps` outputs, pasted into the dossier.

## Review Focus

1. The name is `<folder>-<52 characters>`, not a short hash — the issue's Key Requirement wording is dropped by Q1.
2. `run_args_cap_memory_and_cpus` is loosened from "exactly this array" to "carries both caps", so adding `--name` does not break it; the new case pins the name.
