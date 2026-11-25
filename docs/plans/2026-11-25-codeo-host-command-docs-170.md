# Say the `codeo` host command installs separately, and cover macOS `flock` and the keychain over SSH (#170) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

> Round 2 of this plan, rewritten in place before any task ran: #171 merged first and moved the macOS paragraph from `README.md` to `docs/home-checkout.md`, and added `tests/readme.test.sh`.

**Goal:** A Mac user who runs the README's install line learns that `codeo` is a separate install, how to get `flock`, and what to do when `codeo home` fails over SSH with a keychain error.

**Architecture:** Documentation only, in three pages, pinned by one new check in `tests/readme.test.sh`. `README.md` gets one paragraph under *Installing*. The macOS paragraph of `docs/home-checkout.md` names `brew install flock` and points to the keychain note. The note itself and the corrected host sentence live in `.devcontainer/README.md`, the page that documents `codeo`'s install. No script (`install.sh`, `.devcontainer/codeo`) changes.

**Tech Stack:** Markdown; the bash suite `shell` (`bash tests/run.sh`).

**Spec:** `.codeo/170/init.md` (`## Outcome`: the five acceptance criteria) and `.codeo/170/plan.md` (Q1-Q6, answered).

## Global Constraints

- **Criterion 2 after #171.** "The README's macOS paragraph" is the paragraph that begins "It works on Linux, on macOS" and now sits in `docs/home-checkout.md` (*The home checkout*). It is edited there, and `README.md` gains no macOS text (Q6).
- **Out of scope** (the issue's): changing `codeo` itself, and macOS behaviour not verified past `codeo home`. The note names `codeo home` only and offers no `credsStore` remedy (Q3).
- **Quoted verbatim.** The unlock command is `security -v unlock-keychain ~/Library/Keychains/login.keychain-db`; the error text is `keychain cannot be accessed because the current session does not allow user interaction`, said to follow `error getting credentials` (Q2).
- **Anchors.** `.devcontainer/README.md#installing-the-codeo-command` (heading exists today) and `#the-keychain-over-ssh-on-macos` (new heading `### The keychain over SSH on macOS`). `tests/readme.test.sh`'s `links` check already fails a link from `README.md` or `docs/home-checkout.md` whose anchor is not a heading slug.
- **`README.md`'s `##` headings do not change** (`tests/readme.test.sh` `sections` and `tests/install.test.sh` `t_readme_sections` pin the thirteen).
- **Sandboxes stay Linux and WSL2 only** (`.sbx/README.md`): the corrected host sentence says so.
- **Page style:** present tense, no issue numbers, no "now", as the existing pages are written.
- **Documentation moved:** `README.md` (*Installing*), `docs/home-checkout.md` (*The home checkout*), `.devcontainer/README.md` (*Installing the `codeo` command*). `docs/updating.md` and the other `docs/` pages say nothing about either and are untouched.
- **No changelog entry:** `CHANGELOG.md` has no `## Unreleased` block.
- **Invariants:** none configured. **Shared environment:** none; no task carries a lease marker. Every task runs in this checkout.

## Review Focus

- The README sentence sitting outside *Installing* (a later reorder moves it): Task 1 reads it from the `Installing` section only.
- The unlock command spelled two ways: only `.devcontainer/README.md` carries it; the other two pages link to it.

---

## File Structure

| File | Change |
|---|---|
| `tests/readme.test.sh` | new check `host-command`, placed after `troubleshooting`; one line for it in the header comment |
| `README.md` | one paragraph in *Installing*, after the first output block and before "Run it again and nothing changes:" |
| `docs/home-checkout.md` | the paragraph "It works on Linux, on macOS ..." |
| `.devcontainer/README.md` | the host sentence of *Installing the `codeo` command*; new `### The keychain over SSH on macOS` as the last part of that section, before `## What the start script does` |

## Tasks

### Task 1: Pin the documentation (the failing check first)

**Files:** Modify `tests/readme.test.sh`.

**Interfaces:** Uses the file's `fail <check> <detail>`, `section <file> <title>`, `prose <file>` and `$readme`. Produces the check name `host-command`, which Tasks 2 and 3 make pass.

- [ ] **Step 1: Write the check** `host-command`, each assertion with its own `fail host-command "…"`:
  - `section "$readme" Installing` contains `](.devcontainer/README.md#installing-the-codeo-command)`;
  - `prose docs/home-checkout.md` contains `brew install flock` and `](../.devcontainer/README.md#the-keychain-over-ssh-on-macos)`;
  - `.devcontainer/README.md` has the exact line `### The keychain over SSH on macOS` (`grep -qxF`), and contains `brew install flock`, `security -v unlock-keychain ~/Library/Keychains/login.keychain-db` and `keychain cannot be accessed because the current session does not allow user interaction`.
  Add `#   host-command     …` to the header comment's list.
- [ ] **Step 2: Run it and see it fail.** Proof: `bash tests/run.sh readme` exits 1 and prints one `FAIL host-command:` line per assertion (seven), and no other `FAIL`.
- [ ] **Step 3: Commit** `tests/readme.test.sh`: `test: pin the codeo-command install pointer and the macOS notes (#170)`.

### Task 2: `README.md` and `docs/home-checkout.md`

**Files:** Modify `README.md`, `docs/home-checkout.md`.

- [ ] **Step 1: `README.md`, *Installing*.** A new paragraph after the first output block (the one ending `install: restart any Claude Code sessions already open to load the plugins`) and before "Run it again and nothing changes:". It says: `install.sh` installs the two plugins and not the `codeo` host command, which opens the containers from a terminal and is installed separately; see [Installing the `codeo` command](.devcontainer/README.md#installing-the-codeo-command).
- [ ] **Step 2: `docs/home-checkout.md`.** In the paragraph "It works on Linux, on macOS ...": after "and `flock`" add "(`brew install flock`)"; leave the bash clause as it is. After the sentence that ends "run on 3.2." add one sentence: over SSH, `codeo home` can stop at the Docker build with a keychain error until the login keychain is unlocked; see [The keychain over SSH on macOS](../.devcontainer/README.md#the-keychain-over-ssh-on-macos).
- [ ] **Step 3: Proof.** `bash tests/run.sh readme` still exits 1; its `FAIL` lines are now only `links` (the keychain anchor has no heading yet) and `host-command` lines that name `.devcontainer/README.md`. `bash tests/run.sh install` prints `all cases passed`.
- [ ] **Step 4: Commit** both pages: `docs: say the codeo command installs separately; brew install flock on macOS (#170)`.

### Task 3: `.devcontainer/README.md`

**Files:** Modify `.devcontainer/README.md`.

- [ ] **Step 1: The host sentence** (first paragraph of *Installing the `codeo` command*) becomes: "The host is Linux or macOS with bash 4.3 or later, `curl`, `git` and `flock` (util-linux on Linux, `brew install flock` on macOS); a sandbox needs Linux or WSL2 (`.sbx/README.md`). `docker` and `sbx` are each optional, and a missing one counts as none of that kind."
- [ ] **Step 2: New subsection** `### The keychain over SSH on macOS`, the last part of that section. It says: in an SSH session on a Mac the login keychain is locked, and Docker's credential helper `docker-credential-desktop` cannot read it, so the image build of `codeo home` stops with `error getting credentials` followed by `keychain cannot be accessed because the current session does not allow user interaction`. Unlock the keychain in that session, then run the command again:

  ```bash
  security -v unlock-keychain ~/Library/Keychains/login.keychain-db
  ```
  It asks for the login password. Close with: this is what `codeo home` showed over SSH; other commands were not tried.
- [ ] **Step 3: Proof (the whole change).** `bash tests/run.sh` prints `all cases passed`. Then `grep -c 'brew install flock' docs/home-checkout.md .devcontainer/README.md` prints 1 or more for each file, and `git diff --stat origin/main...HEAD -- README.md docs/home-checkout.md .devcontainer/README.md tests/readme.test.sh` lists exactly those four files.
- [ ] **Step 4: Commit:** `docs: macOS host for the codeo command, and the keychain over SSH (#170)`.

## Self-review

Criterion 1 → Task 2 step 1. Criterion 2 → Task 2 step 2 (the paragraph where it lives, Q6). Criterion 3 → Task 3 step 2. Criterion 4 → Task 1's check plus the existing `links` and `paths` checks. Criterion 5 → Task 3 step 3. Q1 Tasks 2-3 · Q2 Task 3 · Q3 Global Constraints · Q4 Task 3 step 1 · Q5 Task 1 (in `tests/readme.test.sh`, the guard #171 added for these pages, in place of `tests/install.test.sh`) · Q6 Task 2 step 2.

### Footprint

```
files:      README.md, docs/home-checkout.md, .devcontainer/README.md, tests/readme.test.sh, docs/plans/2026-11-25-codeo-host-command-docs-170.md
wiki:       none
exclusive:  none
sequenced:  none
```
