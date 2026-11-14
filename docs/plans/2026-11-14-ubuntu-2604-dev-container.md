# Ubuntu 26.04 Dev Container Image Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Move the dev container image from `ubuntu:24.04` to `ubuntu:26.04`, keeping its tools, its `dev` user and its start scripts, and prove the new image builds and runs codeo's suite.

**Architecture:** One line in the Dockerfile changes, plus the two comments that name the version. The test that pins the base image is renamed and re-pinned first (red), then the Dockerfile follows (green). The README and the changelog say what the move means for existing containers. This container has no `docker` and CI does not build the image, so the last task is the engineer's: it prints the build and run commands, stops, and waits for the output (plan Q1 = A), and it runs the whole `shell` suite inside the image (plan Q2).

**Tech Stack:** bash, `bash tests/run.sh`, Docker (on the host only).

**Spec:** `.codeo/67/init.md` (`## Outcome`: the six acceptance criteria); plan Q1-Q2 of `.codeo/67/plan.md`.

## Global Constraints

- The base image is the exact tag `ubuntu:26.04`: not `latest`, not a digest (issue Q1).
- Nothing else in the image changes. The apt list, the `gh` repository line, the `userdel -r ubuntu` step, the `dev` user and everything below the comments stay as they are. Checked against the published image and package index: `ubuntu:26.04` (26.04.1 LTS, Resolute Raccoon) still has `ubuntu` at UID 1000, every package in the apt list exists under the same name (`shellcheck` in `universe`, which the image enables), and `gh`'s repository suite is `stable`.
- Out of scope: CI runners (`.github/workflows/ci.yml`), adding or removing tools, and #40, #51, #54, #57.
- Historical records stay as written: `CHANGELOG.md`'s v1.0.4 entry for #36, `docs/plans/2026-11-07-dev-container.md` and `.codeo/done/36/`.
- Criterion 5 means no file under `.devcontainer/` or `tests/` names the old version, the README's new line included: it says "the move to Ubuntu 26.04" and never the old number.
- Documentation: the one page this change moves is `.devcontainer/README.md` (*Rebuilding*, Task 2). No page under `docs/` names the image's version.
- Ordering: Tasks 1 and 2 are proved by the `shell` suite in this checkout. Task 3 needs a Docker host and the engineer. There is no shared environment, so no task carries `Needs lease:`, and no invariants document is configured.
- The `shell` suite has no `filter`, so a task's proof is the whole `bash tests/run.sh`; `bash tests/devcontainer.test.sh` is the quick loop for red and green.

## Review Focus

- The scripts run on a different userland in 26.04: the default coreutils are the Rust rewrite (`rust-coreutils` 0.10), bash is 5.3, jq 1.8.1, git 2.53, shellcheck 0.11. A script that passes on 24.04's tools could fail there. Task 3 runs the whole suite inside the image.
- `userdel -r ubuntu` could stop being needed or stop working: Task 3 checks `ubuntu` is gone and `dev` is UID 1000.
- Installing `sudo` could leave no working `sudo` (the base image ships neither `sudo` nor `sudo-rs`): Task 3 runs `sudo -n true` as `dev`.
- `locale-gen en_US.UTF-8` could produce no locale: Task 3 checks `locale -a` and `$LANG`.
- A container built before this change stays on the old image until it is rebuilt: Task 2 says so in the README and the changelog.

---

### Task 1: Pin the test to `ubuntu:26.04`, then move the Dockerfile

**Files:**
- Modify: `tests/devcontainer.test.sh` (header comment line 9; case at lines 111-115; `cases=(` entry at line 1644)
- Modify: `.devcontainer/Dockerfile` (lines 1, 6 and 30)

- [ ] **Step 1: Re-pin the test (red).** In `tests/devcontainer.test.sh` rename `dockerfile_is_ubuntu_2404_with_the_tools` to `dockerfile_is_ubuntu_2604_with_the_tools` in its definition and in the `cases=( ... )` array, change its assertion to `[[ "$first" == 'FROM ubuntu:26.04' ]] || fail "first FROM is not ubuntu:26.04 (got: $first)"`, and change the header comment's "Ubuntu 24.04" to "Ubuntu 26.04".

- [ ] **Step 2: Run it to see it fail.**
  Run: `bash tests/devcontainer.test.sh`
  Expected: exit 1, with exactly one line `FAIL dockerfile_is_ubuntu_2604_with_the_tools: first FROM is not ubuntu:26.04 (got: FROM ubuntu:24.04)`.

- [ ] **Step 3: Move the Dockerfile (green).** In `.devcontainer/Dockerfile`: `FROM ubuntu:24.04` becomes `FROM ubuntu:26.04`; the header comment's "Ubuntu 24.04" becomes "Ubuntu 26.04"; the comment above the `userdel` step becomes "Ubuntu 26.04 ships a user named ubuntu that holds UID 1000; remove it so dev can have that UID." Change nothing else in the file.

- [ ] **Step 4: Prove it.**
  Run: `bash tests/run.sh`
  Expected: prints `all cases passed`, exit 0.
  Run: `git grep -n -E '24\.04|2404' -- .devcontainer/Dockerfile tests`
  Expected: no output, exit 1.

- [ ] **Step 5: Commit.**

```bash
git add tests/devcontainer.test.sh .devcontainer/Dockerfile
git commit -m "feat: move the dev container image to ubuntu:26.04 (#67)"
```

### Task 2: Say what the move means for an existing container

**Files:**
- Modify: `.devcontainer/README.md` (*Rebuilding*, after line 36)
- Modify: `CHANGELOG.md` (new `## Unreleased` block above `## v1.0.5`)

- [ ] **Step 1: README.** Add one paragraph to *Rebuilding*: a container created before the move to Ubuntu 26.04 is still on the older image; rebuild it once (**Dev Containers: Rebuild Container**) to get the new one, and the clone and the `codeo-gh` and `codeo-git` volumes are kept. It must not contain the old version number (Global Constraints).

- [ ] **Step 2: Changelog.** Insert, between `# Changelog` and `## v1.0.5 — 2026-11-14`, this block in the shape the file's earlier `## Unreleased` blocks took:

```markdown
## Unreleased

Config schema: 1
Shared state: unchanged
Safe to bump mid-workflow: yes

- The dev container image is now built on `ubuntu:26.04` (Ubuntu 26.04 LTS) instead of `ubuntu:24.04`. The tools, the `dev` user at UID 1000 with passwordless sudo and the start scripts are unchanged; `tests/devcontainer.test.sh` pins the new tag. Rebuild an existing container once to get the new image. Nothing in `scripts/`, `lib/`, `hooks/` or `skills/` changes (#67).
```

- [ ] **Step 3: Prove it.**
  Run: `bash tests/run.sh`
  Expected: `all cases passed`, exit 0.
  Run: `git grep -n -E '24\.04|2404' -- .devcontainer tests`
  Expected: no output, exit 1.
  Run: `grep -n '^## Unreleased' CHANGELOG.md`
  Expected: `3:## Unreleased`.

- [ ] **Step 4: Commit.**

```bash
git add .devcontainer/README.md CHANGELOG.md
git commit -m "docs: say what the ubuntu:26.04 move means for an existing container (#67)"
```

### Task 3: Build the image on a Docker host and run the checks in it

This task is the engineer's, because this container has no `docker` (plan Q1 = A). The implementer prints the three commands below, **stops**, and records the engineer's pasted output in `implement.md` for `/codeo:qc`. It writes no file and commits nothing.

**Files:** none.

- [ ] **Step 1: Build.** From the root of a checkout of this branch on a host with Docker:

```bash
docker build -t codeo-dev-2604 -f .devcontainer/Dockerfile .devcontainer
```

  Expected: exit 0 (criterion 2).

- [ ] **Step 2: Check the tools and the user.**

```bash
docker run --rm codeo-dev-2604 bash -c '. /etc/os-release; echo "os: $VERSION_ID"; bash --version | head -n1; git --version; jq --version; shellcheck --version | sed -n 2p; gh --version | head -n1; claude --version; id dev; getent passwd ubuntu || echo "ubuntu: gone"; sudo -n true && echo "sudo: ok"; echo "LANG=$LANG"; locale -a | grep -i en_us'
```

  Expected: `os: 26.04`; a version line from each of bash, git, jq, shellcheck, gh and `claude`; `id dev` reports `uid=1000(dev)`; `ubuntu: gone`; `sudo: ok`; `LANG=en_US.UTF-8`; and `en_US.utf8` listed (criterion 3).

- [ ] **Step 3: Run the whole suite inside the image (plan Q2).** The checkout is mounted read-only and copied, so the host's file ownership cannot matter:

```bash
docker run --rm -v "$PWD":/src:ro codeo-dev-2604 bash -c 'cp -a /src /tmp/w && cd /tmp/w && git config --global --add safe.directory "*" && bash tests/run.sh'
```

  Expected: prints `all cases passed`, exit 0. A failure here means 26.04 needs a change in a script under `.devcontainer/scripts/` (the issue allows that, "only where 26.04 requires it"): paste the failing output back, and `/codeo:implement` adds a task for it rather than patching around it.
