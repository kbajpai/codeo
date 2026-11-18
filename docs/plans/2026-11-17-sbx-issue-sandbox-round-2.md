# sbx issue sandbox, QC round 1 fixes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Close `/codeo:qc` round 1's findings on #99. With them closed, one download runs `issue`, `end` removes a squash-merged sandbox with no `--force`, a recreated sandbox starts from the pushed tip, and a later sandbox for the same issue number does not inherit an earlier one's refs.

**Architecture:** Four behaviour changes in `.sbx/codeo-sandbox.sh`, each test-first in `tests/sandbox.test.sh`:
- the pin is read from the clone;
- a clone is refreshed before a new sandbox is created from it;
- pull-request heads count as delivered;
- refs are cleared or set aside at removal.

Then the round's non-blocking polish, the README and CHANGELOG updates, and round 1's host acceptance run, amended.

**Tech Stack:** bash, git, `bash tests/run.sh` (the `shell` suite).

**Spec:** `.codeo/99/qc.md` (`### Round 1`, findings F1-F8), `.codeo/99/plan.md` (Q10-Q13, answered), `.codeo/99/init.md` (the acceptance criteria). This plan follows `docs/plans/2026-11-17-sbx-issue-sandbox.md`, whose Tasks 1-13 are done. Its tasks are numbered 15-22, so the two plans share no task number. Task 22 replaces round 1's Task 14.

## Global Constraints

- **Scope.** F1-F8 only, as Q10-Q13 settled them. No file under `scripts/`, `hooks/` or `skills/` changes. `scripts/cleanup.sh` and the `removal-command` overlay sections are untouched, as in round 1.
- **Pin source (Q10).** The first of these is read:
  1. `CODEO_SBX_IMAGE` (a file path), when set;
  2. `codeo-<N>/.sbx/claude-image`;
  3. `git -C codeo-<N> show origin/HEAD:.sbx/claude-image`.

  None at all is one line naming all three, exit 1, and no `create`. The line format is unchanged: `docker.io/sbx/claude@sha256:<64 hex>`. The script no longer reads a `claude-image` beside itself.
- **Delivered (Q11).**
  - After `git fetch origin`, `end` runs `git -C codeo-<N> fetch origin '+refs/pull/*/head:refs/remotes/origin/pr/*'`.
  - `unpushed_commits` keeps `--not --remotes=origin`, which then covers `refs/remotes/origin/pr/*`.
  - A failed pull-request fetch is one line, "nothing removed", exit 1, like the origin fetch.
- **Refs at removal (Q12).**
  - A plain `end` with nothing unpushed deletes every ref under `refs/sandboxes/codeo-<N>/` once `sbx rm` has succeeded.
  - `end --force` moves each ref under `refs/sandboxes/codeo-<N>/<rest>` to `refs/codeo/ended/codeo-<N>/<UTC>/<rest>`. `<UTC>` is `date -u +%Y%m%dT%H%M%SZ`. All the refs move in one `git update-ref --stdin` transaction, and the message prints `refs/codeo/ended/codeo-<N>/<UTC>/`.
  - A ref step that fails after the removal is one line naming the clone and the refs. It exits 1, because the sandbox is already gone.
- **Clone refresh (Q13).** This applies only when `./codeo-<N>` exists and the sandbox `codeo-<N>` is `missing`. After the branch check, `issue` runs `git -C codeo-<N> fetch origin`, then `git -C codeo-<N> merge --ff-only origin/<branch>`.
  - A fetch failure exits 1 with one line, and nothing is created.
  - So does an `origin` with no `<branch>`.
  - So does a merge refusal (diverged, or local changes in the way). That line reads `codeo-<N> cannot be brought up to origin/<branch>: settle it there, or remove codeo-<N>, then run this again`.
  - A clone already at or ahead of `origin/<branch>` passes unchanged. With the sandbox present, the clone is not touched.
- **Names** as round 1: sandbox `codeo-<N>`, clone `./codeo-<N>`, remote `sandbox-codeo-<N>`, refs `refs/sandboxes/codeo-<N>/*`; new: `refs/codeo/ended/codeo-<N>/<UTC>/*`.
- **Tests** run the script with `PATH` holding only stubs, as round 1. The clone, `origin` and the refs use real git, as `end_setup` already does. A pull-request head is a ref `refs/pull/<k>/head` written into the bare `origin.git`.
- **Documentation this change moves:**
  - `.sbx/README.md`: Getting the script, Commands, Ending a sandbox and its flowchart, The image pin, and the token line.
  - `.codeo/overlays/init.md`: the "Either way" sentence.
  - `docs/dev-environment-sbx-evaluation.md:455`: "which does not exist yet".
  - `CHANGELOG.md`: this branch's sandbox-route bullet, amended rather than a new bullet.
  - No other page describes the sandbox route.
- **Suite.** The `shell` suite has no `filter`. Each task proves itself with the test file it touches (`bash tests/<file>.test.sh`, ending `all cases passed`), then `bash tests/run.sh`, ending `all cases passed`, exit 0.
- **No shared environment, no invariants file, no exclusive resource.**

## Review Focus

- A branch cut before the pin file existed has no `.sbx/claude-image`, so `issue` must read it from `origin/HEAD` rather than refuse. Task 15 tests this with `issue_reads_the_pin_from_the_default_branch_when_the_branch_has_none`.
- A sandbox commit made after the last push must still be listed even when a pull-request head exists. A PR head is no blanket pass. Task 17 tests this with `end_lists_a_commit_made_after_the_pull_request_head`.
- `end --force` twice for one issue number, in the same second, must not lose the first set of refs. `update-ref` `create` refuses an existing ref, so the second run fails loudly instead. Task 18 tests this with `end_force_does_not_overwrite_refs_set_aside_earlier`.
- A clone with uncommitted changes that do not touch what the merge changes is still fast-forwarded. One whose changes would be overwritten is refused, as git decides. Task 16 tests the refusal with `issue_refuses_a_clone_that_cannot_fast_forward`.
- `open` on a sandbox whose path holds a space must give VS Code a URI it can parse. Task 19 tests this with `open_percent_encodes_the_folder_path`.

---

### Task 15: The pin is read from the clone (F1, Q10)

**Files:**
- Modify: `.sbx/codeo-sandbox.sh` (`read_pin`, `cmd_issue`)
- Test: `tests/sandbox.test.sh`

**Interfaces:**
- Produces: `read_pin <N>`. It sets `create_agent` from the sources in the Global Constraints' order. `cmd_issue` calls it after `ensure_host_clone` and before `ensure_sandbox`.

- [ ] **Step 1: Write the failing tests:**
  - `issue_reads_the_pin_from_the_clone`: the branch holds `.sbx/claude-image` with digest A, and `CODEO_SBX_IMAGE` is unset. The `create` call carries `docker.io/sbx/claude@sha256:<A>`.
  - `issue_reads_the_pin_from_the_default_branch_when_the_branch_has_none`: the branch has no file, and `origin`'s default branch has digest B. `create` carries B.
  - `issue_without_any_pin_is_one_line`: no file in either place. Exit 1. The last stderr line names `CODEO_SBX_IMAGE`, `codeo-113/.sbx/claude-image` and `origin/HEAD:.sbx/claude-image`. No `create` call.
  - `issue_pin_override_wins_over_the_clone`: `CODEO_SBX_IMAGE` names digest C while the clone has A. `create` carries C.

  The existing `a_pin_that_is_not_a_digest_is_refused` keeps passing through `CODEO_SBX_IMAGE`.
- [ ] **Step 2: Run `bash tests/sandbox.test.sh`.** Expected: the four new cases FAIL (the script still reads beside itself).
- [ ] **Step 3: Implement** `read_pin <N>` and move its call. Remove the beside-the-script default and its comment.
- [ ] **Step 4: Proof of done:** `bash tests/sandbox.test.sh` → `all cases passed`, then `bash tests/run.sh` → `all cases passed`.
- [ ] **Step 5: Commit** `fix: read the sbx image pin from the issue's clone (#99, #86)`.

### Task 16: An existing clone is brought up to origin before a new sandbox (F3, Q13)

**Files:**
- Modify: `.sbx/codeo-sandbox.sh` (`ensure_host_clone`, `cmd_issue`)
- Test: `tests/sandbox.test.sh`

**Interfaces:**
- Consumes: `sandbox_state <name>` (round 1).
- Produces: `ensure_host_clone <N> <branch>`, which refreshes an existing clone when `sandbox_state codeo-<N>` is `missing`. `cmd_issue` keeps calling it before `read_pin <N>`, so the pin is read from the refreshed clone.

- [ ] **Step 1: Write the failing tests:**
  - `issue_fast_forwards_a_stale_clone_before_creating`: the clone is one commit behind `origin/fix/x`, and the sandbox is missing. After `issue`, the clone's `HEAD` equals `origin/fix/x`, and `create` ran.
  - `issue_refuses_a_clone_that_cannot_fast_forward`: the clone has a local commit and `origin` has another. Exit 1, the exact refusal line from the Global Constraints, no `create`, and the clone's `HEAD` unchanged.
  - `issue_refuses_when_origin_has_no_branch`: the branch was deleted on `origin`. Exit 1 with one line naming `origin/fix/x`, and no `create`.
  - `issue_leaves_the_clone_alone_when_the_sandbox_exists`: the sandbox is `running` and the clone is behind. The clone's `HEAD` is unchanged, and no `fetch` runs in it.
- [ ] **Step 2: Run `bash tests/sandbox.test.sh`.** Expected: the four new cases FAIL.
- [ ] **Step 3: Implement** the refresh in `ensure_host_clone`. A clone just made by `git clone` is not fetched again.
- [ ] **Step 4: Proof of done:** as Task 15.
- [ ] **Step 5: Commit** `fix: bring an existing clone up to origin before creating its sandbox (#99, #85)`.

### Task 17: Pull-request heads count as delivered (F2, Q11)

**Files:**
- Modify: `.sbx/codeo-sandbox.sh` (`cmd_end`, the comment on `unpushed_commits`)
- Test: `tests/sandbox.test.sh`

- [ ] **Step 1: Write the failing tests** (extend `end_setup` so `origin.git` can carry `refs/pull/<k>/head`):
  - `end_after_a_squash_merge_removes_the_sandbox`: the sandbox's branch tip is `refs/pull/7/head` on `origin`, and no `origin` branch holds it. Exit 0, `sbx rm --force codeo-113` called, stdout `removed codeo-113`.
  - `end_lists_a_commit_made_after_the_pull_request_head`: as above, plus one commit on top in the sandbox. Exit 1, that commit listed, no `rm`.
  - `end_with_a_failed_pull_request_fetch_removes_nothing`: the `git` stub fails only the `refs/pull` fetch. Exit 1, a one-line message containing `nothing removed`, no `rm`.
- [ ] **Step 2: Run `bash tests/sandbox.test.sh`.** Expected: the first and third FAIL. The second already passes (the commit is unpushed either way).
- [ ] **Step 3: Implement** the extra fetch after `git fetch origin`.
- [ ] **Step 4: Proof of done:** as Task 15.
- [ ] **Step 5: Commit** `fix: end counts pull-request heads as delivered (#99, #86)`.

### Task 18: `end` clears its refs, or sets them aside with `--force` (F4, Q12)

**Files:**
- Modify: `.sbx/codeo-sandbox.sh` (`cmd_end`; a new `clear_sandbox_refs <dir> <name>` and `set_aside_sandbox_refs <dir> <name>`)
- Test: `tests/sandbox.test.sh`

**Interfaces:**
- Produces:
  - `clear_sandbox_refs <dir> <name>`: deletes every ref under `refs/sandboxes/<name>/`. Returns non-zero on failure.
  - `set_aside_sandbox_refs <dir> <name>`: moves them to `refs/codeo/ended/<name>/<UTC>/`, prints that prefix, and returns non-zero on failure.

- [ ] **Step 1: Write the failing tests:**
  - `end_with_nothing_to_lose_deletes_the_sandbox_refs`: after exit 0, `git for-each-ref refs/sandboxes/codeo-113/` in the clone prints nothing.
  - `end_force_sets_the_refs_aside`: after exit 0, `refs/sandboxes/codeo-113/` is empty, and `refs/codeo/ended/codeo-113/<UTC>/<branch>` points at the unpushed tip. stdout names that prefix. `<UTC>` is matched as `[0-9]{8}T[0-9]{6}Z`.
  - `end_force_does_not_overwrite_refs_set_aside_earlier`: a ref under `refs/codeo/ended/codeo-113/<UTC>/` already exists for the same second. A `date` stub fixes `<UTC>`, so the clash is certain. Exit 1 with one line naming the clone, and the earlier ref is unchanged.
  - `a_second_sandbox_for_the_number_starts_clean`: run `end --force`, recreate the sandbox remote with a new pushed branch, then run `end`. Exit 0 and `rm` called; the first sandbox's commits are not listed.

  `end_force_removes_and_says_where_the_commits_are` changes its expected message to the new prefix.
- [ ] **Step 2: Run `bash tests/sandbox.test.sh`.** Expected: the four new cases FAIL, and so does the changed one.
- [ ] **Step 3: Implement** both functions and call them after `sbx rm` succeeds.
- [ ] **Step 4: Proof of done:** as Task 15.
- [ ] **Step 5: Commit** `fix: end clears a sandbox's refs, or sets them aside with --force (#99, #86)`.

### Task 19: Host-script polish (F7, F8)

**Files:**
- Modify: `.sbx/codeo-sandbox.sh` (`cmd_open`, `check_name`; a new `uri_path <path>`)
- Test: `tests/sandbox.test.sh`

- [ ] **Step 1: Write the failing tests:**
  - `open_checks_ssh_without_prompting`: the `ssh` stub records its arguments, and they include `-o BatchMode=yes` and `-o ConnectTimeout=10` before `codeo-113.sbx`.
  - `open_percent_encodes_the_folder_path`: the stubbed `pwd` prints `/wsl.localhost/U/home/a b/codeo-113`. The `code` stub receives `vscode-remote://ssh-remote+codeo-113.sbx/wsl.localhost/U/home/a%20b/codeo-113`. Every byte outside `A-Za-z0-9/._~-` is written `%XX` in upper-case hex.
  - `issue_with_no_lock_says_to_start_the_workflow`: `container-name.sh --docker` prints `codeo-home`. The todo line reads `todo: the sandbox is codeo-113 but its clone holds no workflow lock: run /codeo:init #113 on its branch, then issue 113 <branch> again`.
  - `issue_takes_the_identity_from_the_host_gitconfig`: `HOME` points at a scratch folder whose `.gitconfig` sets the name and email, and `GIT_AUTHOR_*` is unset. The start script's `env` line carries both.
- [ ] **Step 2: Run `bash tests/sandbox.test.sh`.** Expected: the first three FAIL. The fourth may already pass, because it covers an untested path rather than a bug. If it passes at once, say so in the report.
- [ ] **Step 3: Implement** each change.
- [ ] **Step 4: Proof of done:** as Task 15.
- [ ] **Step 5: Commit** `fix: open checks ssh without a prompt and encodes the folder; clearer no-lock todo (#99, #86)`.

### Task 20: An empty `.claude.json` is treated as `{}` (F7)

**Files:**
- Modify: `.devcontainer/scripts/devcontainer-start.sh` (step 3d)
- Test: `tests/devcontainer.test.sh`

- [ ] **Step 1: Write the failing test:** `start_trust_fills_an_empty_state_file`. A zero-byte `$CLAUDE_CONFIG_DIR/.claude.json` ends as `{"projects":{"<top>":{"hasTrustDialogAccepted":true}}}`, with no `could not write` TODO. The script exits 0.
- [ ] **Step 2: Run `bash tests/devcontainer.test.sh`.** Expected: FAIL (it reports the TODO).
- [ ] **Step 3: Implement.** Step 3d reads a zero-byte or whitespace-only file as `{}`, as step 3c reads an empty `settings.json`.
- [ ] **Step 4: Proof of done:** `bash tests/devcontainer.test.sh` → `all cases passed`, then `bash tests/run.sh` → `all cases passed`.
- [ ] **Step 5: Commit** `fix: folder trust fills an empty Claude state file (#99, #114)`.

### Task 21: Documentation for round 2 (F1-F6, F8)

**Files:**
- Modify: `.sbx/README.md`, `.codeo/overlays/init.md:34`, `docs/dev-environment-sbx-evaluation.md:455`, `CHANGELOG.md` (this branch's sandbox-route bullet)
- Test: `tests/sandbox.test.sh` (`docs_*` cases)

- [ ] **Step 1: Write or tighten the docs tests:**
  - `docs_readme_says_how_to_move_the_pin`: one line of the README contains both `.sbx/claude-image` and `CHANGELOG` (F8).
  - `docs_readme_says_where_the_pin_is_read`: the README names `CODEO_SBX_IMAGE`, `codeo-<N>/.sbx/claude-image` and `origin/HEAD`.
  - `docs_readme_says_where_forced_refs_go`: the README contains `refs/codeo/ended/codeo-<N>/`.
  - `docs_readme_names_codeo_code`: the README contains `CODEO_CODE`.
  - `docs_the_hand_off_says_whichever_route`: `.codeo/overlays/init.md` contains `Whichever route` and not `Either way`.
  - `docs_evaluation_page_names_the_script_as_it_is`: `docs/dev-environment-sbx-evaluation.md` lacks `does not exist yet`.
- [ ] **Step 2: Run `bash tests/sandbox.test.sh`.** Expected: those cases FAIL.
- [ ] **Step 3: Edit the pages.** They describe the system as it is, in the present tense, with no issue numbers and no "now". The CHANGELOG follows its own style.
  - **`.sbx/README.md`, Getting the script.** One download is enough. The pin is read from the sources in the Global Constraints, in that order.
  - **`.sbx/README.md`, Commands.** `issue` brings an existing clone up to `origin/<branch>` before it creates a missing sandbox, and stops when it cannot.
  - **`.sbx/README.md`, Ending a sandbox.** A commit reachable from a pull request's head counts as delivered. A plain `end` deletes `refs/sandboxes/codeo-<N>/`. `--force` sets the refs aside under `refs/codeo/ended/codeo-<N>/<UTC>/`. Recover them with `git -C codeo-<N> log refs/codeo/ended/codeo-<N>/<UTC>/<branch>`; delete them with `git -C codeo-<N> for-each-ref --format='delete %(refname)' refs/codeo/ended/codeo-<N>/ | git -C codeo-<N> update-ref --stdin`. The flowchart gains the pull-request fetch and the two ref steps.
  - **`.sbx/README.md`, safe.directory.** The line about it quotes the entry as the script writes it: `%(prefix)///wsl.localhost/<distro><the clone's path on the host>`, which is the clone's path as Windows Git sees it.
  - **`.sbx/README.md`, `CODEO_CODE`.** It names the VS Code program `open` runs.
  - **`.sbx/README.md`, token (F6).** The line says what the trial showed: the sandbox's `gh` holds a placeholder, the real token stays on the host, and pushes work.
  - **`.codeo/overlays/init.md`.** "Either way" becomes "Whichever route".
  - **Evaluation page, `:455`.** The parenthesis names `.sbx/codeo-sandbox.sh` without "which does not exist yet".
  - **`CHANGELOG.md`.** The sandbox-route bullet gains the pin source, the clone refresh, the pull-request heads and the ref handling.
- [ ] **Step 4: Proof of done:** `bash tests/sandbox.test.sh` → `all cases passed`, then `bash tests/run.sh` → `all cases passed`.
- [ ] **Step 5: Commit** `docs: the sbx route's pin source, clone refresh and ref handling (#99, #86)`.

### Task 22: Run the acceptance criteria (replaces round 1's Task 14)

Runs on: the engineer's host

Round 1's Task 14 applies, run in WSL2 bash from the folder that holds the clones, with these changes. Paste each output into `.codeo/99/implement.md` under `## Acceptance`.

- Step 1 downloads only `codeo-sandbox.sh`; no `claude-image` beside it.
- After step 2: `sbx.exe exec codeo-99 test -e /run/.containerenv`, then `sbx.exe exec codeo-99 bash .devcontainer/scripts/role.sh`. Record both outputs. They settle the `role.sh` gap.
- After step 8: `sbx.exe exec codeo-99 git reset --hard HEAD~1`, then `bash codeo-sandbox.sh end 99`. Exit 0, `removed codeo-99`, and the sandbox is gone from `sbx.exe ls` with no `--force`. Then `bash codeo-sandbox.sh issue 99 feat/make-sbx-issue-sandbox-usable` again. It creates the sandbox from a clone that is up to date with `origin`.
- Step 9's ten `ls` outputs are the evidence for "Stopped sandboxes". `.sbx/README.md`'s section is then updated in a follow-up commit, stating the cause, or the repeat count with no stop.
- Step 11 stays: `end 99 --force` for cleanup. Its output names `refs/codeo/ended/codeo-99/<UTC>/`.
