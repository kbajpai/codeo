# Say the `codeo` host command installs separately, and cover macOS `flock` and the keychain over SSH (#170) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A Mac user who runs the README's install line learns that `codeo` is a separate install, how to get `flock`, and what to do when `codeo home` fails over SSH with a keychain error.

**Architecture:** Documentation only, in two READMEs, pinned by one new case in `tests/install.test.sh`. The README gets one sentence under *Installing* and one clause in its macOS paragraph; the full keychain note and the corrected host sentence live in `.devcontainer/README.md`, the page that already documents `codeo`'s install. No script (`install.sh`, `.devcontainer/codeo`) changes.

**Tech Stack:** Markdown; the bash suite (`bash tests/run.sh`).

**Spec:** `.codeo/170/init.md` (`## Outcome`: the five acceptance criteria) and `.codeo/170/plan.md` (Q1-Q5, answered).

## Global Constraints

- **Out of scope** (the issue's): changing `codeo` itself (a zsh-aware PATH hint, detecting the keychain failure), and macOS behaviour not verified past `codeo home`. The note therefore names `codeo home` only, and offers no `credsStore` remedy (Q3).
- **Quoted verbatim.** The unlock command is `security -v unlock-keychain ~/Library/Keychains/login.keychain-db`; the error text is `keychain cannot be accessed because the current session does not allow user interaction`, said to follow `error getting credentials` (Q2).
- **Link target.** `.devcontainer/README.md#installing-the-codeo-command` (the heading `## Installing the \`codeo\` command` exists today); the new heading's anchor is `#the-keychain-over-ssh-on-macos`.
- **Sandboxes stay Linux and WSL2 only** (`.sbx/README.md`): the corrected host sentence says so rather than claiming macOS for them.
- **Documentation moved:** `README.md` (*Installing*, *The home checkout*) and `.devcontainer/README.md` (*Installing the `codeo` command*, a new subsection). No other page describes the install or the macOS prerequisites. The `docs/` pages are untouched.
- **No changelog entry:** `CHANGELOG.md` has no `## Unreleased` block (v1.0.9 is the top entry) and #168 owns the release notes, so this change does not edit it.
- **Invariants:** none configured (`.invariants` unset). **Shared environment:** none, so no task carries a lease marker.
- **Parallel work:** #168 and #171 edit `README.md` too (init's note); `inflight.sh` showed none in flight at plan time. Task 2's edits are two small insertions to ease a later merge.

## Review Focus

- A link whose file exists but whose anchor does not passes `t_readme_links_resolve` (it strips `#…`): Task 1 pins both anchors against the headings.
- The README quoting an unlock command spelled differently from the one the `.devcontainer/README.md` note gives: Task 1 greps both files for the one string.

---

## File Structure

| File | Change |
|---|---|
| `tests/install.test.sh` | one new case `t_readme_points_at_the_codeo_command_install`, registered after `t_readme_links_resolve` |
| `README.md` | one sentence under *Installing*; the macOS paragraph (*The home checkout*, last paragraph) |
| `.devcontainer/README.md` | the host sentence of *Installing the `codeo` command*; new `### The keychain over SSH on macOS` at the end of that section, before `## What the start script does` |

### Footprint

```
files:      README.md, .devcontainer/README.md, tests/install.test.sh, docs/plans/2026-11-25-codeo-host-command-docs-170.md
wiki:       none
exclusive:  none
sequenced:  none
```

## Tasks

### Task 1: Pin the documentation (the failing test first)

**Files:** Modify `tests/install.test.sh` (new function after `t_readme_links_resolve`, one line in the case list after `t_readme_links_resolve`, near line 1787).

**Interfaces:** Produces `t_readme_points_at_the_codeo_command_install`, which Tasks 2 and 3 make pass. Uses the file's own `$repo` and `fail`.

- [ ] **Step 1: Write the case.** It asserts, each with its own `fail` message:
  - `README.md` contains the string `.devcontainer/README.md#installing-the-codeo-command`, and `.devcontainer/README.md` has the line `## Installing the \`codeo\` command` (`grep -qxF`);
  - `README.md` contains `brew install flock`;
  - `README.md` contains `.devcontainer/README.md#the-keychain-over-ssh-on-macos`, and `.devcontainer/README.md` has the line `### The keychain over SSH on macOS`;
  - `.devcontainer/README.md` contains `security -v unlock-keychain ~/Library/Keychains/login.keychain-db` and `keychain cannot be accessed because the current session does not allow user interaction`.
- [ ] **Step 2: Run it and see it fail.** Proof: `bash tests/run.sh install` exits non-zero and the output names the first failed `fail` message ("README lacks …").
- [ ] **Step 3: Commit** `tests/install.test.sh` alone: `test: pin the README's codeo-command and macOS wording (#170)`.

### Task 2: `README.md`

**Files:** Modify `README.md`.

- [ ] **Step 1: *Installing*.** Directly after the paragraph that ends "...to load the plugins." add one paragraph: `install.sh` installs the two plugins and not the `codeo` host command; install that separately, following *Installing the `codeo` command* in `.devcontainer/README.md`, linked as `[Installing the \`codeo\` command](.devcontainer/README.md#installing-the-codeo-command)`.
- [ ] **Step 2: macOS paragraph.** In the last paragraph of *The home checkout* ("It works on Linux, on macOS ..."): leave the bash clause alone and, after "and `flock`", add "(`brew install flock`)". End the paragraph with one sentence: over SSH, `codeo home` can stop at the Docker build with a keychain error until the login keychain is unlocked, and [the keychain note](.devcontainer/README.md#the-keychain-over-ssh-on-macos) has the command.
- [ ] **Step 3: Proof.** `bash tests/run.sh install` still fails, now only on the `.devcontainer/README.md` assertions (Task 3); `t_readme_links_resolve` passes. No other `README` line changes: `git diff --stat README.md` shows insertions and the one changed paragraph.

### Task 3: `.devcontainer/README.md`

**Files:** Modify `.devcontainer/README.md`.

- [ ] **Step 1: The host sentence** (first paragraph of *Installing the `codeo` command*): "The host is Linux or macOS with bash 4.3 or later, `curl`, `git` and `flock` (util-linux on Linux, `brew install flock` on macOS); the sandbox kind needs Linux or WSL2 (`.sbx/README.md`); `docker` and `sbx` are each optional, and a missing one counts as none of that kind."
- [ ] **Step 2: New subsection** `### The keychain over SSH on macOS` at the end of that section. Content: over SSH the login keychain is locked, so the Docker build of `codeo home` can stop with `error getting credentials` followed by `keychain cannot be accessed because the current session does not allow user interaction` (from Docker's `docker-credential-desktop`); unlock it in that session, then run the command again:

  ```bash
  security -v unlock-keychain ~/Library/Keychains/login.keychain-db
  ```
  It asks for the login password. Say that this was seen on a Mac over SSH with `codeo home`; no other command was tried.
- [ ] **Step 3: Proof (the whole change).** `bash tests/run.sh` prints `all cases passed` (Task 1's case now passes). Then each name the change makes exists: `grep -n 'brew install flock' README.md .devcontainer/README.md`, `grep -n '^## Installing the `codeo` command$\|^### The keychain over SSH on macOS$' .devcontainer/README.md`, and `test -f .devcontainer/codeo -a -f install.sh`.
- [ ] **Step 4: Commit** the two READMEs: `docs: say the codeo command installs separately; macOS flock and keychain over SSH (#170)`.

## Self-review

Criterion 1 → Task 2 step 1; 2 → Task 2 step 2 (and Task 3 step 1); 3 → Task 3 step 2; 4 → Task 1's anchors plus Task 3 step 3's greps; 5 → Task 3 step 3. Q1-Q5 each land: Q1 Tasks 2-3, Q2 Task 3, Q3 Global Constraints, Q4 Task 3 step 1, Q5 Task 1.
