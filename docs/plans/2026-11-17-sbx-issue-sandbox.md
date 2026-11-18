# sbx Issue Sandbox and Dev Container Folder Trust Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the dev container trust its clone folder in Claude Code. Correct the `sbx` evaluation page against its evidence and settle the sandbox's `gh` token. Add one host script that starts, opens and ends an `sbx` issue sandbox on the pushed branch, with the lock, identity, plugins, folder trust, a pinned image and no silent loss of work.

**Architecture:** The trust step is a new step 3d in `.devcontainer/scripts/devcontainer-start.sh`, written like step 3c. The sandbox route is a new host script, `.sbx/codeo-sandbox.sh`, the counterpart of `.devcontainer/codeo-container.sh`. It clones the branch on the host into `./codeo-<N>`, adds the Windows Git `safe.directory` line when the program is `sbx.exe`, and creates the sandbox `codeo-<N>` from that clone at the pinned image. It then runs the unchanged `devcontainer-start.sh` inside the sandbox in cmd mode (`CODEO_CMD_MODE=1`). Three more sub-commands: `open <N>` opens VS Code over Remote-SSH on the clone folder, `end <N>` fetches and checks before `sbx rm`, and `shell <N>` opens a shell. `session-title.sh` also titles sessions in a sandbox, recognised by a marker file the host script writes. The evaluation page is corrected in place, and #99's body carries #86's corrected text.

```mermaid
sequenceDiagram
    participant E as Engineer (Linux or WSL2 bash)
    participant S as codeo-sandbox.sh
    participant G as host git / git.exe
    participant X as sbx or sbx.exe
    participant B as sandbox codeo-N
    E->>S: issue N branch
    S->>G: git clone --branch branch into ./codeo-N (or check the clone is on branch)
    S->>G: git.exe safe.directory line, only with sbx.exe and only when missing
    S->>X: create --clone --name codeo-N at the pinned image (only when it does not exist; else start it)
    S->>B: write the sandbox marker
    S->>B: env CODEO_CMD_MODE=1 GIT_AUTHOR_* bash .devcontainer/scripts/devcontainer-start.sh
    B-->>E: lock: took the lock for #N on branch, then ready or TODO lines
    S->>B: container-name.sh --docker, compared with codeo-N
    S-->>E: one todo: line when the lock names another issue
```

```mermaid
flowchart TD
    A[end N] --> B{sandbox exists?}
    B -- no --> Z1[exit 1: no sandbox codeo-N]
    B -- yes --> C[start it if stopped]
    C --> D[git fetch sandbox-codeo-N in ./codeo-N]
    D -- fails --> Z2[exit 1, nothing removed]
    D --> F[git fetch origin]
    F -- fails --> Z3[exit 1: cannot prove anything is pushed, nothing removed]
    F --> G{commits under refs/sandboxes/codeo-N/ not on any origin branch?}
    G -- none --> R[sbx rm codeo-N, print removed]
    G -- some, no --force --> Z4[list up to 10 commits, exit 1, nothing removed]
    G -- some, --force --> R2[sbx rm codeo-N, say the commits are kept in refs/sandboxes/codeo-N/]
```

**Tech Stack:** bash 4.3+ (the host script runs on Linux and WSL2 only, never macOS), git, `sbx` v0.53.0 (`sbx.exe` from WSL2), jq in the container, VS Code Remote-SSH, `gh` for the issue-body edits, and `bash tests/run.sh`.

**Spec:** `.codeo/99/init.md` (`## Outcome`: the issue and its 28 acceptance criteria, by part) and `.codeo/99/plan.md` Q1-Q7 and Notes. The issue's own text is https://github.com/kbajpai/codeo/issues/99.

## Global Constraints

- Four parts, in this order: #114 (Tasks 1-2), #94 (Tasks 3-4 and 6), #85 (Tasks 7-8), #86 (Tasks 9-13). Task 5 (the trials) and Task 14 (acceptance) are the engineer's, on their own host. One branch and one pull request.
- `.devcontainer/` changes only in the #114 part and in `session-title.sh` (#86's session titles). Both are allowed: #94's empty-diff criterion and #85's `.devcontainer/` exclusion apply to their own parts only (the issue says so). `devcontainer-start.sh` changes only by step 3d. `codeo-container.sh` and `devcontainer.json` are not edited.
- `skills/` is not edited. The #94 part's criterion `git diff --stat main -- .devcontainer skills` is judged on Tasks 3, 4 and 6's own commits: `git diff --stat <commit before Task 3>..<Task 6's commit> -- .devcontainer skills` is empty, because no task between them touches either folder.
- Folder trust (#114): `$CLAUDE_CONFIG_DIR/.claude.json` (else `$HOME/.claude.json` when `CLAUDE_CONFIG_DIR` is unset), key `projects["<top>"].hasTrustDialogAccepted = true`. `<top>` is the clone's `git rev-parse --show-toplevel` after `pwd -P` resolution (the step 2 `top`). Never `/workspaces`, `$HOME` or `/`. Every other key, including the other keys of that project's entry, is kept. Claude Code's permissions page documents the key, the file and the repository-root rule. The VS Code extension reading the same file is inferred, so Task 14 checks it.
- The host script is `.sbx/codeo-sandbox.sh`. Its tests run it with `PATH` holding only stubs (`sbx`, `sbx.exe`, `git`, `git.exe`, `code`) plus `/usr/bin` tools it is allowed (`env`, `cat`, `mkdir`), as `tests/cmd-mode.test.sh` does. The program is `CODEO_SBX` when set, else `sbx` when on `PATH`, else `sbx.exe`, else exit 1 with `codeo-sandbox: sbx is not installed: …`. The Windows Git trust step runs only when that program's name ends in `.exe`.
- Names: sandbox `codeo-<N>`, host clone folder `./codeo-<N>` in the current directory, git remote `sandbox-codeo-<N>` (created by `sbx`), refs `refs/sandboxes/codeo-<N>/*`. `<N>` is a positive integer without a leading zero; a branch starts with a letter or digit and holds only letters, digits, `. _ / -` and no `..`, exactly `codeo-container.sh`'s rule. A bad argument prints the usage and exits 2 before any `sbx` or `git` call.
- Resource limits as the dev container's: `--cpus 2 --memory 4g` on `create` (T10 showed both work).
- Git identity reaches the start script only, as `GIT_AUTHOR_NAME` / `GIT_AUTHOR_EMAIL`, from the host's `git config --global user.name` / `user.email`, else the host environment, each key on its own. The start script's step 5 never overwrites a value, so a re-run changes nothing.
- The pinned image is the one line of `.sbx/claude-image`, a `docker.io/sbx/claude@sha256:<64 hex>` reference. Moving it is an edit to that file, with a CHANGELOG line.
- The extensions are installed by the engineer's one-time VS Code user setting `"remote.SSH.defaultExtensions": ["anthropic.claude-code", "timonwong.shellcheck", "bierner.markdown-mermaid"]` (Q4), documented in `.sbx/README.md`. No file under `.vscode/` is committed.
- Ending a sandbox (Q5) is `end <N> [--force]` only. `scripts/cleanup.sh`, the skills and the `removal-command` overlay sections are not changed. The README says that for a sandbox, `end <N>` replaces the `docker rm` line `/codeo:close` and `/codeo:cleanup` print.
- #86's corrected text goes into the "Part of #86" section of #99's body (Q6). Closed #86 is not edited. #73's result comment is updated only where its counts change.
- The suite config gains `.sbx/**` in the `shell` suite's `paths` (Task 7), so changes there trigger `bash tests/run.sh`.
- Trial-dependent choices (Tasks 8, 10, 12) are read from Task 5's results in `.codeo/99/implement.md`, and each task names its fallback. If S5 shows `devcontainer-start.sh` cannot run in a sandbox, the implementer stops at Task 8 and reports to the engineer. It does not write a second start script.
- Documentation moved: `.devcontainer/README.md` (Tasks 2 and 13), `.sbx/README.md` (new, Task 13), `.codeo/overlays/init.md`'s hand-off (Task 13), `docs/dev-environment-sbx-evaluation.md` (Tasks 3 and 6), `CHANGELOG.md` (Tasks 2 and 13), and #99's body (Task 4). No page under `docs/` other than the evaluation page describes containers or sandboxes.
- No shared environment is configured, so no task carries `Needs lease:`. No invariants document is configured.
- The `shell` suite has no `filter`, so every code task's proof is the whole `bash tests/run.sh` (prints `all cases passed`, exit 0). `bash tests/devcontainer.test.sh` and `bash tests/sandbox.test.sh` are the quick loops for red and green.
- #116 (at `qc`) also edits `.devcontainer/README.md`, `tests/devcontainer.test.sh` and `CHANGELOG.md`: proceed and coordinate (Q7). Tasks 2 and 13 run `bash "${CLAUDE_PLUGIN_ROOT}/scripts/sync-main.sh"` first when #116 has merged.
- Out of scope, as in the issue: changing the hybrid recommendation, `sync-main.sh` (#92), retiring the dev container or the home container, Remote Control in a sandbox, Docker's cloud sandboxes, VS Code's own Workspace Trust, permission modes, persisting `~/.claude` on a volume, the Claude login, macOS hosts for the sandbox route, and teaching `/codeo:close` / `/codeo:cleanup` about sandboxes (Q5).

## Review Focus

- A `./codeo-<N>` that already exists on another branch, or is not a git clone: `issue` refuses with one line naming the branch it is on and creates no sandbox (Task 8, `issue_refuses_a_host_clone_on_another_branch`, `issue_refuses_a_folder_that_is_not_a_clone`).
- `end` when `origin` cannot be reached, or the sandbox is stopped: nothing is removed when unpushed work cannot be ruled out, and a stopped sandbox is started before the fetch (Task 12, `end_without_origin_removes_nothing`, `end_starts_a_stopped_sandbox_first`).
- `.claude.json` with a `projects` value that is not an object, or a project entry that is not an object: one TODO, the file is untouched, exit 0 (Task 1, `start_trust_with_projects_not_an_object_is_a_todo`).
- A clone reached through a symlink: the trust key is the resolved top level, not the symlink path (Task 1, `start_trust_uses_the_resolved_top_level`).
- The `safe.directory` line already present, or `git.exe` missing: no duplicate line; with no `git.exe`, one `todo:` line carrying the exact command, and `create` is still tried (Task 8, `issue_adds_the_windows_trust_line_once`, `issue_without_git_exe_prints_the_trust_command`).

---

## Part 1: folder trust in the dev container (#114)

### Task 1: Step 3d trusts the clone folder in Claude Code

**Files:**
- Modify: `.devcontainer/scripts/devcontainer-start.sh` (header comment; new step 3d after step 3c)
- Test: `tests/devcontainer.test.sh` (new cases after `start_leaves_no_temp_file_when_mv_fails`, listed in `cases`)

**Interfaces:**
- Produces: the TODO texts `<file> is not valid JSON and was left alone: fix it, then trust <top> in Claude Code` and `<file> is not a JSON object and was left alone: …` and `<file> has a projects value that is not an object and was left alone: …` and `could not write <file>: <top> is not trusted in Claude Code`.

- [ ] **Step 1: Write the failing tests.** All use `ds_setup`, `ds_identity` and `ds_ready_run`. `$ds_dir/claude` is `CLAUDE_CONFIG_DIR`, and the trust key is `$(cd "$ds_dir/codeo-home" && pwd -P)`:
  - `start_trusts_the_clone_in_claude`: no `.claude.json` beforehand. Afterwards `jq -e --arg p "$key" '.projects[$p].hasTrustDialogAccepted == true'` holds, `.projects | keys` is exactly `[$key]` (so no parent is trusted), the exit is 0 and the file's mode is `600`.
  - `start_trust_keeps_other_keys`: the file starts as `{"numStartups":3,"projects":{"/x":{"a":1},"<key>":{"allowedTools":["Bash"]}}}`. After two runs, `numStartups == 3`, `.projects["/x"].a == 1`, `.projects[$key].allowedTools == ["Bash"]` and `.projects[$key].hasTrustDialogAccepted == true`.
  - `start_malformed_claude_state_is_a_todo`: the file is `{not json`. It is byte-for-byte unchanged, `ds_todos '.claude.json'` is 1, and the exit is 0.
  - `start_claude_state_not_an_object_is_a_todo`: the file is `[1]`. Unchanged, one TODO naming `.claude.json`.
  - `start_trust_with_projects_not_an_object_is_a_todo`: the file is `{"projects":[]}`. Unchanged, one TODO naming `.claude.json`.
  - `start_trust_uses_the_resolved_top_level`: run the script through a symlink to the clone (`DS_REPO=<symlink>`). The only key is the resolved path.
  - `start_trust_leaves_no_temp_file`: after a run, `$ds_dir/claude` holds no `.claude.json.*` file.
- [ ] **Step 2: Run `bash tests/devcontainer.test.sh`.** Expected: FAIL on each new case (`.claude.json` missing, or no trust key).
- [ ] **Step 3: Implement step 3d.** It goes after step 3c in `devcontainer-start.sh`, and the header comment's first paragraph gains "records the clone as trusted in Claude Code". The step mirrors step 3c: `claude_state=${CLAUDE_CONFIG_DIR:+$CLAUDE_CONFIG_DIR/.claude.json}`, else `$HOME/.claude.json`. A missing file is created as `{}` under `umask 077`. Classify it with the same `jq -rn '[inputs] | …'` probe as step 3c, extended to report `projects-not-object` when `.projects` exists and is not an object. Write through `mktemp "$(dirname "$target")/.claude.json.XXXXXX"` with `jq --arg p "$top" '.projects[$p] = ((.projects[$p] // {}) + {hasTrustDialogAccepted: true})'`, then `chmod --reference`, then `mv`. On failure, remove the temp file and add one TODO. The key is `$top` from step 2 (falling back to `$clone` when step 2 had no top level). Step 3d runs after step 3 (`plugins.sh`) because `claude plugin …` writes `.claude.json`.
- [ ] **Step 4: Run `bash tests/run.sh`.** Expected: `all cases passed`, exit 0.
- [ ] **Step 5: Commit** `.devcontainer/scripts/devcontainer-start.sh` and `tests/devcontainer.test.sh` with `feat: the dev container trusts its clone folder in Claude Code (#99, #114)`.

### Task 2: Document the folder trust

**Files:**
- Modify: `.devcontainer/README.md` (section "What the start script does": one new bullet)
- Modify: `CHANGELOG.md` (`## Unreleased`: one bullet)
- Test: `tests/devcontainer.test.sh` (`docs_readme_describes_folder_trust`, `docs_changelog_names_folder_trust`)

- [ ] **Step 1: Write the failing tests.** `grep -q 'hasTrustDialogAccepted' .devcontainer/README.md` and `grep -q 'Trust this folder' .devcontainer/README.md`. Also `grep -q 'Trust this folder' CHANGELOG.md`.
- [ ] **Step 2: Run `bash tests/devcontainer.test.sh`.** Expected: FAIL on both.
- [ ] **Step 3: Write the text.** The README bullet says the start script records the clone folder (only that folder) as trusted in Claude Code, in `projects["<clone>"].hasTrustDialogAccepted` of `$CLAUDE_CONFIG_DIR/.claude.json`, so the "Trust this folder in Claude Code?" dialog does not appear and the folder's `.claude/settings.json` is in effect in the first session. It keeps every other key. A file that is not valid JSON or not an object is left alone and listed as a TODO. It runs on every create and rebuild because `~/.claude` is not on a volume. The CHANGELOG bullet says the same in one sentence and names #114. Merge `origin/main` first if #116 has merged.
- [ ] **Step 4: Run `bash tests/run.sh`.** Expected: `all cases passed`.
- [ ] **Step 5: Commit** the two files and the test with `docs: describe the dev container's folder trust (#99, #114)`.

## Part 2: correct the evaluation page (#94)

### Task 3: Wording the recorded output already settles

**Files:**
- Modify: `docs/dev-environment-sbx-evaluation.md` (Host; D3; U4; Trials introduction; T10 Result; Recommendation "Why not stay" and "Fragility"; Follow-up issues; status banner)

Proof is a documentation check (no test file changes). Each edit names only what the output recorded in `.codeo/done/73/implement.md` shows:
- [ ] **Step 1: Image digests (F32).** Quote, in T3's, T8's and T10's Results, the `Image:` / kit line as recorded: `docker.io/sbx/claude@sha256:4df39400…` at T3 and T8, and `docker.io/sbx/claude@sha256:0fb3e2c5…` at T10. Add that the digests were recorded shortened. State that the image digest changed between T8 and T10, both on 2026-11-15. Delete "Whether the base image changed was not checked" in T10 and in "Fragility", and replace it with that statement.
- [ ] **Step 2: Naming sentence (F34).** Replace the last sentence of "Why not stay" with one statement: there is no volume or folder-naming rule to work around; names stay a convention that a start script checks (#85, done in `.sbx/codeo-sandbox.sh`); a name is unique among existing sandboxes (T9) and free again after `sbx rm` (T8).
- [ ] **Step 3: Inferred or leftover wording (F36).** In D3, `1m47s (image pull)` becomes `1m47s (the first create; T8's recreate printed "assembled kit image ready (cached)", so the first likely included the pull)`. U4's mode claim names the files checked (`tests/run.sh` and the files under `scripts/`) and nothing wider. The Host paragraph says "the Linux-in-WSL2 route was not tried" once. The Trials introduction's "Paste every output… when it is run" becomes a past-tense statement of how the outputs were recorded.
- [ ] **Step 4: Follow-ups (F35).** The Follow-up issues section says #85 and #86 were consolidated into #99. Under #85 it adds U6 and U8. Under #86 it adds U14 and cites "trials T8 to T12". The status banner names #99.
- [ ] **Step 5: Check.** Run `bash tests/run.sh`; expect `all cases passed`. Then run `grep -c 'was not tried' docs/dev-environment-sbx-evaluation.md` before and after; expect the count lower by exactly one. Expect `grep -n 'not checked' docs/dev-environment-sbx-evaluation.md` to print no line about the image. Expect `grep -n 'Paste' docs/dev-environment-sbx-evaluation.md` to print nothing.
- [ ] **Step 6: Commit** the page with `docs: correct the sbx evaluation against its recorded output (#99, #94)`.

### Task 4: #86's text in #99's body

**Files:** none in the repository. The GitHub issue #99 body, "Part of #86" section.

- [ ] **Step 1: Edit through a scratch file.** Save the body (`gh issue view 99 --json body -q .body > <scratch>/body.md`) and edit only the "Part of #86" section. "trials T5 to T12" becomes "trials T8 to T12". The image bullet becomes "The `Image:` line printed at create carried a different `docker.io/sbx/claude` digest at T10 than at T8, both on 2026-11-15 (`0fb3e2c5…` against `4df39400…`), so a sandbox is not reproducible from its name." Write it back with `gh issue edit 99 --body-file <scratch>/body.md`.
- [ ] **Step 2: Check.** `gh issue view 99 --json body -q .body | grep -c 'T5 to T12'` prints `0`. `… | grep -c 'T8 to T12'` prints at least `2`. The other sections are byte-identical (`diff` of the saved body against the new one shows only those lines).

## Part 3: the trials (engineer)

### Task 5: Run trials S1-S9

Runs on: the engineer's host

The commands are `.codeo/99/plan.md` → Notes → Trials, S1-S9, run in WSL2 bash from the folder that holds the clones. Each is one plain command. The engineer pastes the outputs, with tokens and account names removed, into `.codeo/99/implement.md` under `## Trials`. The implementer then records these decisions there, each one line:
- **D-token:** S2's sandbox token is the host's real token, a placeholder, or the trial could not run.
- **D-start:** S5's `devcontainer-start.sh` ran in the sandbox (yes/no, and its TODO lines).
- **D-exec:** `sbx exec`'s working directory (S3 `pwd`), and whether `exec` takes `-e` (S8). The plan uses `env VAR=… bash …` either way.
- **D-image:** the flag `create` takes for a specific image or kit reference (S8 `create --help`: `-t/--template`, `--kit` or a positional agent reference), and the full digest S1 printed.
- **D-rm:** whether `sbx rm` has a no-prompt flag (S8 `rm --help`). Without one, the script answers the prompt by piping `y`.
- **D-open:** whether `code --folder-uri vscode-remote://ssh-remote+codeo-t.sbx<path>` opened the folder (S6).
- **D-push:** whether S4's push and fetch worked after `gh auth setup-git`.

Proof: `.codeo/99/implement.md` has a `## Trials` section with one block per S1-S9 and the seven D- lines.

### Task 6: T13 and what it changes on the page

**Files:**
- Modify: `docs/dev-environment-sbx-evaluation.md` (new trial T13 after T12; D1; U8; Recommendation "Why not stay" and "Credentials"; status banner "T1 to T13")
- GitHub: #73's result comment (counts)

- [ ] **Step 1: Write T13** from S2, in the page's trial format: a heading, the commands, Expected, and Result with the date and host. Quote the masked comparison only, never a token.
- [ ] **Step 2: Cite T13 per D-token.** If the token is the real one: D1's "credentials stay outside the VM" is qualified as not holding for the `gh` token (tried T13), and "Why not stay" no longer counts credentials among the cited gains. If it is a placeholder: D1 and the Credentials bullet say the real token stays outside and the sandbox gets a placeholder with the host token's scopes (tried T13). If the trial could not run: they say so and count no credential isolation as gained. In every case D1's Evidence cell and the Credentials bullet cite `tried T13, <date>`.
- [ ] **Step 3: Counts.** Recount the rows (28), and count `tried` against `cited` in the Evidence cells. Update the banner. If #73's comment (`https://github.com/kbajpai/codeo/issues/73#issuecomment-6887700427`, "12 trials and 28 compared rows (21 tried, 7 cited)") no longer matches, edit it with `gh api -X PATCH repos/kbajpai/codeo/issues/comments/6887700427 -F body=@<scratch file>`, changing only that sentence.
- [ ] **Step 4: Check.** `bash tests/run.sh` gives `all cases passed`. `grep -c 'T13' docs/dev-environment-sbx-evaluation.md` gives at least `4` (trial, D1, Why not stay or Credentials, banner). `git diff --stat <Task 3's parent>..HEAD -- .devcontainer skills` prints nothing.
- [ ] **Step 5: Commit** the page with `docs: record T13, whether the sandbox's gh token is the real one (#99, #94)`.

## Part 4: start an issue sandbox (#85)

### Task 7: The host script's frame

**Files:**
- Create: `.sbx/codeo-sandbox.sh` (executable, `#!/usr/bin/env bash`, `set -euo pipefail`)
- Create: `tests/sandbox.test.sh`
- Modify: `.codeo/config.json` (`suites[0].paths` gains `".sbx/**"`)

**Interfaces:**
- Produces: `usage` (exit 2, `usage: codeo-sandbox.sh issue <N> <branch> | open <N> | shell <N> | end <N> [--force]`), `die <msg> [rc]` (`codeo-sandbox: <msg>` on stderr), `pick_sbx` (sets `sbx` to the program; sets `windows=1` when it ends in `.exe`), `valid_number <N>`, `valid_branch <branch>`, and `sandbox_state <name>`, which prints `missing`, `stopped` or `running` from `"$sbx" ls`. Tests: `sb_setup <case>` (a scratch dir with stub `sbx`/`sbx.exe`/`git`/`git.exe`/`code` in `bin/` that log to `calls`), `sb_run <args…>` (sets `sb_rc`, `sb_out`, `sb_err`).
- The stub `sbx ls` output format is copied from T9 (`codeo-a  claude  running (detached)`). The script reads the name in column 1 and the state word in column 3.

- [ ] **Step 1: Write the failing tests.**
  - `usage_without_arguments_exits_2`.
  - `bad_numbers_and_branches_exit_2_before_any_call`: `0`, `07`, `-1`, `1a`, `''` and branches `-x`, `a..b`, `a b`, `a;b`, `$(x)`. `calls` is empty.
  - `no_sbx_is_one_line`: `PATH` has neither stub. Exit 1, stderr is one line starting `codeo-sandbox: sbx is not installed`.
  - `sbx_is_preferred_over_sbx_exe` and `codeo_sbx_overrides_both`.
  - `the_script_is_committed_executable_with_a_bash_shebang` (`git ls-files -s` mode `100755`).
  - `config_suite_covers_the_sandbox_folder`: `jq -e '.suites[0].paths | index(".sbx/**")' .codeo/config.json`.
- [ ] **Step 2: Run `bash tests/sandbox.test.sh`.** Expected: FAIL (script missing).
- [ ] **Step 3: Implement** the functions above and a `main` that dispatches `issue|open|shell|end`; unknown commands go to `usage`. The sub-commands are stubs that `die 'not yet'` until their tasks. Add the config path.
- [ ] **Step 4: Run `bash tests/run.sh`.** Expected: `all cases passed`.
- [ ] **Step 5: Commit** with `feat: the sbx issue sandbox host script's frame (#99, #85)`.

### Task 8: `issue <N> <branch>`

**Files:**
- Modify: `.sbx/codeo-sandbox.sh` (`cmd_issue`, `ensure_host_clone`, `ensure_windows_trust`, `ensure_sandbox`, `run_start`, `check_name`)
- Test: `tests/sandbox.test.sh`

**Interfaces:**
- Consumes: Task 7's functions; Task 5's D-exec and D-start.
- Produces: `run_start <name>` (also used by `open`), and `sandbox_path <name>`, which prints the clone's path inside the sandbox from `"$sbx" exec <name> pwd`.

- [ ] **Step 1: Write the failing tests.**
  - `issue_clones_the_branch_on_the_host`: with no `./codeo-113`, `calls` has `git clone --branch fix/x <repo_url> codeo-113`. `CODEO_REPO_URL` defaults to `https://github.com/kbajpai/codeo.git`.
  - `issue_refuses_a_host_clone_on_another_branch`: the stub git reports `other`. Exit 1, one line naming `'other'` and `fix/x`, and no `create` in `calls`.
  - `issue_refuses_a_folder_that_is_not_a_clone`.
  - `issue_adds_the_windows_trust_line_once`: with `sbx.exe`, `git.exe config --global --add safe.directory %(prefix)///wsl.localhost/<WSL_DISTRO_NAME><abs path>/codeo-113` is called once when `--get-all` lacks it, and not at all when it has it.
  - `issue_skips_the_windows_trust_with_linux_sbx`: no `git.exe` call at all.
  - `issue_without_git_exe_prints_the_trust_command`: one `todo:` line carrying the command; `create` is still called.
  - `issue_creates_with_the_limits`: `create --clone --name codeo-113 --cpus 2 --memory 4g` with the agent and the clone path. (The image argument comes in Task 10.)
  - `issue_runs_the_start_script_with_the_identity`: the exec line is `exec codeo-113 env CODEO_CMD_MODE=1 GIT_AUTHOR_NAME=… GIT_AUTHOR_EMAIL=… bash .devcontainer/scripts/devcontainer-start.sh`, and its output reaches stdout. A key with no value is left out.
  - `issue_rerun_on_an_existing_sandbox_creates_nothing`: on a running sandbox, no `create`, and the start script runs again. On a stopped one, `run -d --name codeo-113` comes first.
  - `issue_name_that_disagrees_with_the_lock_is_one_todo`: the stub `container-name.sh --docker` exec prints `codeo-98`. Exactly one line `todo: the sandbox is codeo-113 but its lock is for codeo-98: end it and run issue 98 <branch>`.
- [ ] **Step 2: Run `bash tests/sandbox.test.sh`.** Expected: FAIL on each.
- [ ] **Step 3: Implement.** `cmd_issue N branch` runs `ensure_host_clone`, then `ensure_windows_trust` (only when `windows=1`; the path is `%(prefix)///wsl.localhost/$WSL_DISTRO_NAME$(cd codeo-N && pwd -P)`), then `ensure_sandbox`, then `run_start`, then `check_name`. The identity is read as in `codeo-container.sh`'s `run_start`. If D-start says the start script cannot run, stop here and report.
- [ ] **Step 4: Run `bash tests/run.sh`.** Expected: `all cases passed`.
- [ ] **Step 5: Commit** with `feat: start an sbx issue sandbox on the pushed branch (#99, #85)`.

## Part 5: work in and end a sandbox (#86)

### Task 9: Session titles in a sandbox

**Files:**
- Modify: `.devcontainer/scripts/session-title.sh` (the guard line and its header comment)
- Modify: `.sbx/codeo-sandbox.sh` (`ensure_sandbox` writes the marker)
- Test: `tests/devcontainer.test.sh`, `tests/sandbox.test.sh`

**Interfaces:**
- Produces: the marker file `${CODEO_SANDBOX_MARK:-$HOME/.codeo-sandbox}`, written inside the sandbox by `"$sbx" exec <name> bash -c ': > "$HOME/.codeo-sandbox"'`. Its presence means "in an issue sandbox, VS Code may be attached".

- [ ] **Step 1: Write the failing tests.**
  - `session_title_in_a_sandbox_names_the_issue`: neither variable is set and `CODEO_SANDBOX_MARK` names an existing file. The hook prints `codeo [#<N>] · <8 hex>` and refreshes `.vscode/settings.json` as with `REMOTE_CONTAINERS=true`.
  - `session_title_is_silent_with_no_marker` (the existing silence case keeps passing).
  - `issue_writes_the_sandbox_marker`: `calls` has the marker exec, before the start script.
- [ ] **Step 2: Run** both test files. Expected: FAIL.
- [ ] **Step 3: Implement.** The guard becomes "REMOTE_CONTAINERS=true, or a non-empty CODEO_CMD_MODE, or the marker file exists". The window-title refresh runs when `REMOTE_CONTAINERS=true` or the marker exists.
- [ ] **Step 4: Run `bash tests/run.sh`.** Expected: `all cases passed`.
- [ ] **Step 5: Commit** with `feat: title Claude sessions in an sbx issue sandbox (#99, #86)`.

### Task 10: Pin the Claude image

**Files:**
- Create: `.sbx/claude-image` (one line, the full digest from D-image)
- Modify: `.sbx/codeo-sandbox.sh` (`ensure_sandbox` passes it)
- Test: `tests/sandbox.test.sh`

- [ ] **Step 1: Write the failing tests.**
  - `issue_creates_at_the_pinned_image`: the `create` call carries the flag from D-image with the file's reference.
  - `a_pin_that_is_not_a_digest_is_refused`: the file holds `docker.io/sbx/claude:latest`. Exit 1 with one line, no `create`.
  - `the_pin_file_is_a_digest`: the committed file matches `^docker\.io/sbx/claude@sha256:[0-9a-f]{64}$`.
- [ ] **Step 2: Run.** Expected: FAIL.
- [ ] **Step 3: Implement.** Read the file next to the script (`CODEO_SBX_IMAGE` overrides the path, for tests) and pass it with D-image's flag. If D-image found no flag that takes a digest, stop and report to the engineer: the pin criterion cannot be met as planned, and a new question goes in the dossier.
- [ ] **Step 4: Run `bash tests/run.sh`.** Expected: `all cases passed`.
- [ ] **Step 5: Commit** with `feat: pin the sbx Claude image to a digest (#99, #86)`.

### Task 11: `open <N>` and `shell <N>`

**Files:**
- Modify: `.sbx/codeo-sandbox.sh` (`cmd_open`, `cmd_shell`)
- Test: `tests/sandbox.test.sh`

- [ ] **Step 1: Write the failing tests.**
  - `open_writes_the_title_and_opens_the_clone_folder`: the calls are, in order, `exec codeo-113 bash .devcontainer/scripts/window-title.sh`, `exec codeo-113 pwd`, then `code --folder-uri vscode-remote://ssh-remote+codeo-113.sbx<pwd>`. `CODEO_CODE` overrides `code`.
  - `open_starts_a_stopped_sandbox_first`.
  - `open_on_a_missing_sandbox_names_the_command_that_creates_it`.
  - `shell_execs_bash_in_the_clone`: the last call is `exec -it codeo-113 bash -l` (`-i` alone without a terminal).
- [ ] **Step 2: Run.** Expected: FAIL.
- [ ] **Step 3: Implement.** If D-open says `--folder-uri` did not open the folder, use the form S6 showed working and record it in implement.md.
- [ ] **Step 4: Run `bash tests/run.sh`.** Expected: `all cases passed`.
- [ ] **Step 5: Commit** with `feat: open an sbx issue sandbox in VS Code (#99, #86)`.

### Task 12: `end <N> [--force]`

**Files:**
- Modify: `.sbx/codeo-sandbox.sh` (`cmd_end`, `unpushed_commits`)
- Test: `tests/sandbox.test.sh`

**Interfaces:**
- Produces: `unpushed_commits <clone> <name>`, which prints `git -C <clone> rev-list --oneline <refs/sandboxes/name/*…> --not --remotes=origin`. It returns 0 when that list is empty.

These tests use a real git in a scratch directory for the clone, `origin` and the `refs/sandboxes` refs; only `sbx` is stubbed. Its `git fetch sandbox-…` is simulated by the stub writing the refs.
- [ ] **Step 1: Write the failing tests.** The behaviour is the flowchart above:
  - `end_with_nothing_to_lose_removes_the_sandbox`: `rm codeo-113` (with D-rm's no-prompt form) is called, and stdout says `removed codeo-113`.
  - `end_with_an_unpushed_commit_removes_nothing`: exit 1, the commit's subject is printed, `end 113 --force` is named, and no `rm`.
  - `end_force_removes_and_says_where_the_commits_are`: stdout names `refs/sandboxes/codeo-113/` in `./codeo-113`.
  - `end_without_origin_removes_nothing`.
  - `end_starts_a_stopped_sandbox_first`.
  - `end_on_a_missing_sandbox_is_one_line`.
  - `end_lists_at_most_ten_commits`: with 12 unpushed, it prints 10 and `and 2 more`.
- [ ] **Step 2: Run.** Expected: FAIL.
- [ ] **Step 3: Implement** per the flowchart.
- [ ] **Step 4: Run `bash tests/run.sh`.** Expected: `all cases passed`.
- [ ] **Step 5: Commit** with `feat: end an sbx issue sandbox without losing work (#99, #86)`.

### Task 13: Document the sandbox route

**Files:**
- Create: `.sbx/README.md`
- Modify: `.devcontainer/README.md` (one paragraph under the intro pointing at `.sbx/README.md`)
- Modify: `.codeo/overlays/init.md` (the hand-off's routes gain a third: `bash codeo-sandbox.sh issue <N> <branch>`)
- Modify: `CHANGELOG.md` (one bullet)
- Test: `tests/sandbox.test.sh` (`docs_*` cases); `tests/init-overlay.test.sh` (if it pins the hand-off's routes, its case gains the third)

- [ ] **Step 1: Write the failing tests.**
  - `docs_readme_documents_each_sub_command`: `issue`, `open`, `shell` and `end` each appear in a table row.
  - `docs_readme_gives_the_download_line`.
  - `docs_readme_gives_the_default_extensions_setting`: the exact `remote.SSH.defaultExtensions` JSON.
  - `docs_readme_says_end_replaces_the_docker_rm_line`.
  - `docs_readme_states_the_stops`: a "Stopped sandboxes" section exists.
  - `docs_readme_says_how_to_move_the_pin`.
  - `docs_changelog_names_the_sandbox_route`.
- [ ] **Step 2: Run.** Expected: FAIL.
- [ ] **Step 3: Write `.sbx/README.md`,** following `.devcontainer/README.md`'s style. Sections:
  - What it is for: issue work in a sandbox; the home container stays a dev container.
  - Prerequisites: `sbx` v0.53.0 or `sbx.exe` from WSL2, `sbx login`, `sbx secret set github --command 'gh auth token'`, `sbx setup ssh`, and the VS Code user setting.
  - The download line: `curl -fsSL -o codeo-sandbox.sh https://raw.githubusercontent.com/kbajpai/codeo/main/.sbx/codeo-sandbox.sh`.
  - A table of the four sub-commands with what each prints, and the sequence diagram above.
  - Ending a sandbox: the flowchart above, and that for a sandbox it replaces the `docker rm …` line.
  - The image pin and how to move it.
  - "Stopped sandboxes": the cause, or the repeat count from Task 14, filled in after Task 14. Until then, the recovery `sbx run -d --name codeo-<N>`.
  - Not tried: Remote Control in a sandbox.
  - It also says the start script turns on `remoteControlAtStartup` in the sandbox, which is untried there.

  Merge `origin/main` first if #116 has merged.
- [ ] **Step 4: Run `bash tests/run.sh`.** Expected: `all cases passed`.
- [ ] **Step 5: Commit** with `docs: the sbx issue sandbox route (#99, #85, #86)`.

## Part 6: acceptance on the engineer's host

### Task 14: Run the acceptance criteria

Runs on: the engineer's host

Each line is one command, run in WSL2 bash from the folder that holds the clones, unless the line says VS Code. Paste each output into `.codeo/99/implement.md` under `## Acceptance`:

1. `curl -fsSL -o codeo-sandbox.sh https://raw.githubusercontent.com/kbajpai/codeo/feat/make-sbx-issue-sandbox-usable/.sbx/codeo-sandbox.sh`
2. `bash codeo-sandbox.sh issue 99 feat/make-sbx-issue-sandbox-usable`. The output ends with `lock: took the lock for #99 on feat/make-sbx-issue-sandbox-usable`, and no `dubious ownership`.
3. `sbx.exe exec codeo-99 git config user.name`, then `… user.email`, then step 2 again, then the two again. The values are the same before and after.
4. `sbx.exe exec codeo-99 claude plugin list`. It shows `superpowers` and `codeo` at the pin.
5. `sbx.exe exec codeo-99 git push origin HEAD:refs/heads/scratch/sbx-99-push`, then `git push origin --delete scratch/sbx-99-push` run in `codeo-99` on the host. No login prompt.
6. `bash codeo-sandbox.sh open 99`. In VS Code: the folder is open, the title is `codeo [#99]`, and the three extensions are listed. Start `claude` in its terminal; the session title starts `codeo [#99]`.
7. Create a second sandbox for any open issue N2 (`bash codeo-sandbox.sh issue <N2> <its branch>`), then run `bash codeo-sandbox.sh open <N2>`. The two window titles differ.
8. `sbx.exe exec codeo-99 git commit --allow-empty -m scratch`, then `bash codeo-sandbox.sh end 99`. Exit 1, the commit is named, and the sandbox still exists (`sbx.exe ls`).
9. Stops: with codeo-99 running, `sbx.exe stop <N2's sandbox>` then `sbx.exe run -d --name <N2's sandbox>` then `sbx.exe ls`, ten times. Record each `ls`.
10. Next day: `bash codeo-sandbox.sh end <N2> --force`, then `bash codeo-sandbox.sh issue <N2> <branch>`. The create output's `Image:` digest equals `.sbx/claude-image`'s.
11. `bash codeo-sandbox.sh end 99 --force` (cleanup).
12. Dev container (#114), home: in VS Code, **Dev Containers: Clone Repository in Named Container Volume…** for `https://github.com/kbajpai/codeo/tree/feat/make-sbx-issue-sandbox-usable`, volume and folder `codeo-home` (remove an existing `codeo-home` first, once `git status` in it shows nothing unpushed). Open Claude Code: no "Trust this folder" dialog, `/plugin` lists codeo enabled, the session has a title. Then **Dev Containers: Rebuild Container** and check again.
13. Dev container (#114), issue: the same for N2's branch with volume and folder `codeo-<N2>` (after `bash codeo-sandbox.sh end <N2> --force`): no dialog, codeo enabled, session titled `codeo [#<N2>]`.

After the run, the implementer writes line 9's repeat count and result into `.sbx/README.md`'s "Stopped sandboxes" section, and commits it with `docs: record the sandbox stop trials (#99, #86)`.

Proof: `.codeo/99/implement.md` `## Acceptance` holds one block per line 1-13. Then `bash tests/run.sh` gives `all cases passed`.
