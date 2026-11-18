# sbx issue sandbox, QC round 2 fixes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Close `/codeo:qc` round 2's findings on #99. When this round is done:
- one documented route gives a sandbox window with the three extensions;
- an issue sandbox stays up while idle;
- `end` does not silently drop uncommitted work;
- the round's polish is done.

**Architecture:** Most of the work is in `.sbx/codeo-sandbox.sh`, with each change test-first in `tests/sandbox.test.sh`:
- `sandbox_state` learns the real `sbx ls` layout and the `detached` state.
- `issue` and `open` leave the sandbox running detached.
- `end` checks for uncommitted work in the sandbox before it removes anything.

Around those code changes:
- A short trial on the engineer's host comes first, because it decides the extension route the docs give and settles one `run -d` behaviour.
- The README, the CHANGELOG and the evaluation page follow the code.
- The round ends with a host acceptance run.

**Tech Stack:** bash, git, `bash tests/run.sh` (the `shell` suite).

**Spec:** `.codeo/99/qc.md` (`### Round 2`, findings F9-F16), `.codeo/99/plan.md` (Q14-Q17, answered), `.codeo/99/init.md` (the acceptance criteria). Plans `docs/plans/2026-11-17-sbx-issue-sandbox.md` (Tasks 1-14) and `…-round-2.md` (Tasks 15-22) are done. This plan's tasks are numbered 23-30.

## Global Constraints

- **Scope.** F9-F16 as Q14-Q17 settled them, plus one defect found while planning (below). No file under `scripts/`, `hooks/` or `skills/` changes.
- **Extension route (Q14).** The route is decided by Task 23's result:
  - **Route A** applies if the trial passes. One `sbx` policy rule per machine allows `*.gallery.vsassets.io` and `*.gallerycdn.vsassets.io`, and `remote.SSH.defaultExtensions` stays.
  - **Route B** applies if it fails. `remote.downloadExtensionsLocally: true` is set, and the three are installed by hand ("Install in SSH") once per sandbox. `remote.SSH.defaultExtensions` is removed from the docs, which then say not to set it, because it breaks the remote extension host.
- **Detached (Q15).** `issue` (as its last step) and `open` (before VS Code starts) run `sbx run -d --name codeo-<N>` unless the sandbox is already `running (detached)`. `shell` and `end` are unchanged.
- **Lock line (Q16).** The engineer reads the #85 criterion "ends with `lock: took the lock …`" as: the lock line is printed and the lock is taken. The order of the start script's output does not change. The `scripts/lock.sh:145` `volume:` TODO in a sandbox is filed as its own issue through `/codeo:issue`, not fixed here.
- **Uncommitted work (Q17).** Before `sbx rm`, `end` checks the sandbox's clone for three things:
  - changed or untracked files;
  - stashes;
  - a detached HEAD.

  Without `--force`, any one of them makes `end` list it, remove nothing and exit 1. `--force` removes the sandbox and says that the uncommitted work was not kept.
- **Found while planning.** The real `sbx ls` prints a header row (`SANDBOX AGENT STATUS …`) and a `●` or `○` before the status (Acceptance step 9). `sandbox_state` reads column 3, so on the host it reads `●` and reports every sandbox that exists as `stopped`. Q15's check needs the real status, so Task 24 fixes this.
- **Documentation this round moves:**
  - `.sbx/README.md`: Prerequisites, the Commands table, Ending a sandbox (text and flowchart), Stopped sandboxes.
  - `CHANGELOG.md`, the sbx bullet on line 9.
  - `docs/dev-environment-sbx-evaluation.md`: D1, D4, T13 Result, Fragility, the #86 follow-up bullet.

## Review Focus

1. **The real `sbx ls` output.** A header row, `●`/`○` markers and `running (detached)` versus `running` must each give the right state. Task 24 pins all of them.
2. **`run -d` on a sandbox that `exec` started.** `issue` hits this every time. Task 23 tries it on the host, and Task 25 follows the result.
3. **A sandbox that has unpushed commits *and* uncommitted work.** Both lists print, followed by one "nothing removed" line. Task 26 pins this.
4. **CR line endings from `sbx.exe exec`.** The status and stash output must not produce false "dirty" lines. Task 26 strips `\r`, as `check_name` does.
5. **A failed `sbx ls`.** It must stop the script with one line, not run on as if the sandbox were present. Task 24 pins this.

---

### Task 23: Trial the extension route and `run -d` on a running sandbox

Runs on: the engineer's host
Shell: bash (WSL2), from `D:\Downloads\task22`

- [ ] **Step 1: Allow the two download hosts.** `sbx.exe policy allow network "*.gallery.vsassets.io,*.gallerycdn.vsassets.io"`, then `sbx.exe policy ls`. Expected: the two hosts appear as allowed.
- [ ] **Step 2: Create a sandbox.** `bash codeo-sandbox.sh issue 99 feat/make-sbx-issue-sandbox-usable`. Expected: as in Acceptance step 2.
- [ ] **Step 3: `run -d` on a running sandbox.** At once, `sbx.exe ls`, then `sbx.exe run -d --name codeo-99`, then `sbx.exe ls`. Record whether the status goes from `running` to `running (detached)`, and anything `run -d` prints.
- [ ] **Step 4: VS Code settings.** In the Windows VS Code user settings, set `"remote.SSH.defaultExtensions": ["anthropic.claude-code", "timonwong.shellcheck", "bierner.markdown-mermaid"]` and remove `remote.downloadExtensionsLocally`.
- [ ] **Step 5: Open the sandbox.** `bash codeo-sandbox.sh open 99`. Expected for route A: no `Server returned 403`, and the Extensions view lists the three under `SSH: codeo-99.sbx`.
- [ ] **Step 6: Clean up.** `bash codeo-sandbox.sh end 99`. If step 5 failed, also run `sbx.exe policy rm network --resource "*.gallery.vsassets.io,*.gallerycdn.vsassets.io"` (or remove each host on its own), and put `remote.downloadExtensionsLocally` back.

**Proof of done:** the output of steps 1, 3 and 5 is recorded in `.codeo/99/implement.md`, with the route taken (A or B) and the result of step 3.
- If step 3 shows that `run -d` refuses a running sandbox, or leaves it `running` without `(detached)`, Task 25 runs `sbx stop codeo-<N>` before `run -d` when the state is `running`. The ledger records this.

### Task 24: `sandbox_state` reads the real `sbx ls` layout

**Files:**
- Modify: `.sbx/codeo-sandbox.sh` (`sandbox_state`, and its callers `ensure_host_clone`, `ensure_sandbox`, `require_sandbox`)
- Test: `tests/sandbox.test.sh`

**Interfaces:**
- Produces: `sandbox_state <name>` prints exactly one of `missing`, `stopped`, `running`, `detached`. Every caller assigns its output to a variable before testing it, so a `die` inside stops the script under `set -e`.

- [ ] **Step 1: Write the failing tests.**
  - Extend `sandbox_state_reads_the_ls_rows` with this listing. The header row and `codeo-x` must not be read as sandboxes.
    ```
      SANDBOX     AGENT    STATUS                 PORTS                        WORKSPACE      CREATED
      codeo-a     claude   ● running (detached)   127.0.0.1:60030->9418/tcp4   D:\w\codeo-a   6m
      codeo-b     claude   ○ stopped                                           D:\w\codeo-b   1m
      codeo-c     claude   ● running              127.0.0.1:60031->9418/tcp4   D:\w\codeo-c   1m
    ```
    Assert `codeo-a=detached`, `codeo-b=stopped`, `codeo-c=running`, `codeo-x=missing`, and `SANDBOX=missing`.
  - Add a second listing with no markers (`codeo-a claude running (detached)`), and assert the same states.
  - Add `a_failed_ls_stops_issue_with_one_line`. A stub `sbx ls` exits 1. Assert that `issue 113 fix/x` exits 1, that stderr is exactly `codeo-sandbox: could not list sandboxes with sbx`, and that no `sbx create` or `sbx exec` call is logged.
- [ ] **Step 2: Run them, and see them fail.** `bash tests/sandbox.test.sh`. Expected: `FAIL sandbox_state_reads_the_ls_rows` (codeo-a reads `stopped`) and `FAIL a_failed_ls_stops_issue_with_one_line`.
- [ ] **Step 3: Implement.**
  - Read each row as name, agent and the rest. Drop a leading `●` or `○` word from the rest.
  - `running (detached)…` gives `detached`, `running…` gives `running`, and anything else gives `stopped`.
  - Change each caller to `state=$(sandbox_state …)` before its test. Callers that compared against `running` now treat `running` and `detached` as up.
- [ ] **Step 4: Run them, and see them pass.** `bash tests/sandbox.test.sh`. Expected: `all cases passed`.
- [ ] **Step 5: Commit.** `fix: read the real sbx ls layout in codeo-sandbox.sh (#99)`

**Proof of done:** `bash tests/run.sh` prints `all cases passed`.

### Task 25: `issue` and `open` leave the sandbox running detached

**Files:**
- Modify: `.sbx/codeo-sandbox.sh` (new `ensure_detached`; `cmd_issue`, `cmd_open`)
- Modify: `.sbx/README.md` (the Commands rows for `issue` and `open`; Stopped sandboxes)
- Test: `tests/sandbox.test.sh`

**Interfaces:**
- Consumes: `sandbox_state` from Task 24.
- Produces: `ensure_detached <name>`. Unless the state is `detached`, it runs `"$sbx" run -d --name <name>` with stdout discarded. A failure dies with `could not start <name> detached: run <sbx> run -d --name <name>`. If Task 23 showed that `run -d` needs it, a `running` state is first stopped with `"$sbx" stop <name>`.

- [ ] **Step 1: Write the failing tests.**
  - `issue_leaves_the_sandbox_running_detached`: with no sandbox, the last logged call is `sbx run -d --name codeo-113`, and it comes after the `devcontainer-start.sh` exec and the `container-name.sh` exec.
  - Amend `issue_rerun_on_an_existing_sandbox_creates_nothing` (it now loops over `'running (detached)'`, `running` and `stopped`). No state creates anything. `running (detached)` logs no `sbx run`. `stopped` and `running` each log `sbx run -d --name codeo-113` once.
  - Replace `open_starts_a_stopped_sandbox_first` with `open_starts_a_stopped_sandbox_detached`. Call 2 is `sbx run -d --name codeo-113`, and call 3 is `sbx exec codeo-113 bash .devcontainer/scripts/window-title.sh`.
  - `open_on_a_detached_sandbox_runs_nothing_more`: no `sbx run` call.
  - `a_failed_run_d_is_one_line`: the stub `sbx run` exits 1. `open 113` exits 1 with one stderr line containing `run -d --name codeo-113`, and does not launch VS Code.
  - `docs_readme_says_issue_and_open_run_detached`: the Stopped sandboxes section contains `run -d` and names both `issue` and `open`.
- [ ] **Step 2: Run them, and see them fail.** `bash tests/sandbox.test.sh`. Expected: a FAIL line for each new or amended case.
- [ ] **Step 3: Implement.**
  - `ensure_detached` as above. `cmd_issue` calls it after `check_name`. `cmd_open` calls it after `require_sandbox`, before the window-title exec.
  - README:
    - The `issue` row ends: "and leaves the sandbox running detached (`sbx run -d`), so it does not stop when idle."
    - The `open` row says it starts the sandbox detached first when it is not.
    - Stopped sandboxes keeps the cause, and says that `issue` and `open` both start the sandbox with `run -d`. `shell` and `end` start a stopped sandbox through `exec`, so after them the sandbox stops again when idle. `open <N>` brings it back.
- [ ] **Step 4: Run them, and see them pass.** `bash tests/sandbox.test.sh`. Expected: `all cases passed`.
- [ ] **Step 5: Commit.** `feat: keep an issue sandbox running detached (#99, #86)`

**Proof of done:** `bash tests/run.sh` prints `all cases passed`.

### Task 26: `end` refuses uncommitted work unless `--force`

**Files:**
- Modify: `.sbx/codeo-sandbox.sh` (new `uncommitted_work`; `cmd_end`)
- Modify: `.sbx/README.md` (Ending a sandbox: the flowchart and the text, replacing the paragraph "`end` checks commits only…")
- Modify: `CHANGELOG.md:9` (replace "It checks commits only: uncommitted changes, stashes and a detached HEAD are not seen.")
- Test: `tests/sandbox.test.sh`

**Interfaces:**
- Produces: `uncommitted_work <name>` prints the report and returns 0 (empty when clean). It returns 1 when an exec fails. It runs `"$sbx" exec <name> git status --porcelain --branch` and `"$sbx" exec <name> git stash list`, with `\r` removed. It prints these sections, each list cut at 10 lines plus `and <K> more`:
  - `<name> has uncommitted changes:` and the status lines after the `##` line;
  - `<name> has <K> stash(es):` and the stash lines;
  - `<name> is on a detached HEAD`, when the `##` line is `## HEAD (no branch)`.

- [ ] **Step 1: Write the failing tests.** Extend the stub's `sbx exec` case: `*"git status --porcelain --branch"` prints the `status` file if there is one (else `## fix/x`), and `*"git stash list"` prints the `stashes` file if there is one. Then add:
  - `end_with_uncommitted_changes_removes_nothing` (status ` M a.txt` and `?? b.txt`): exit 1, stdout has both lines, the last stdout line is `nothing removed: commit and push it from the sandbox, or run: codeo-sandbox.sh end 113 --force`, and no ` rm ` call.
  - `end_with_a_stash_removes_nothing`: exit 1, stdout has `has 1 stash(es):`.
  - `end_on_a_detached_head_removes_nothing` (status `## HEAD (no branch)`): exit 1, stdout has `is on a detached HEAD`.
  - `end_with_unpushed_and_uncommitted_lists_both`: stdout has `has 1 commit(s)` and `has uncommitted changes:`, and ends with the uncommitted "nothing removed" line.
  - `end_force_with_uncommitted_work_says_it_is_not_kept`: exit 0, `sbx rm --force codeo-113` is called, and the last stdout line is `its uncommitted work was not kept`.
  - `end_with_a_failed_status_check_removes_nothing`: the stub exec of `git status` exits 1. Exit 1, stderr is `codeo-sandbox: could not check codeo-113 for uncommitted work, nothing removed`, and no ` rm ` call.
  - `end_with_crlf_status_is_clean`: status file `## fix/x\r`. `end` removes the sandbox.
  - Amend `docs_changelog_*`/README checks if one asserts "checks commits only".
- [ ] **Step 2: Run them, and see them fail.** `bash tests/sandbox.test.sh`. Expected: a FAIL line for each new case.
- [ ] **Step 3: Implement.**
  - In `cmd_end`, after `commits` is computed and before `sbx rm`, run `uncommitted_work`. If it fails, die with the line above.
  - Without `--force`, if commits or the report is non-empty, print the commit section (unchanged) and then the report. The last line is the uncommitted "nothing removed" line when the report is non-empty, else the existing commit line. Return 1.
  - With `--force`, after the existing removal line, print `its uncommitted work was not kept` when the report was non-empty.
  - README and CHANGELOG say what `end` now checks. The flowchart gains a decision before `sbx rm`: uncommitted work? (none → go on; some, no `--force` → list it, exit 1; some, `--force` → remove, say it was not kept).
- [ ] **Step 4: Run them, and see them pass.** `bash tests/sandbox.test.sh`. Expected: `all cases passed`.
- [ ] **Step 5: Commit.** `feat: end refuses uncommitted sandbox work without --force (#99, #86)`

**Proof of done:** `bash tests/run.sh` prints `all cases passed`.

### Task 27: Document the extension route Task 23 chose

**Files:**
- Modify: `.sbx/README.md` (Prerequisites, the VS Code bullet and its JSON block; the `open` row)
- Modify: `CHANGELOG.md:9` (the clause "with the extensions from the user setting `remote.SSH.defaultExtensions`")
- Test: `tests/sandbox.test.sh` (replace `docs_readme_gives_the_default_extensions_setting` with `docs_readme_gives_the_extension_route`)

**Interfaces:**
- Consumes: Task 23's result (route A or B), recorded in `.codeo/99/implement.md`.

- [ ] **Step 1: Write the failing test.** `docs_readme_gives_the_extension_route`:
  - **Route A:** the README holds `sbx policy allow network "*.gallery.vsassets.io,*.gallerycdn.vsassets.io"` and the `remote.SSH.defaultExtensions` line as it is now.
  - **Route B:** the README holds `"remote.downloadExtensionsLocally": true`, `Install in SSH` and each of `anthropic.claude-code`, `timonwong.shellcheck`, `bierner.markdown-mermaid`, and holds no `"remote.SSH.defaultExtensions":` setting line.
  - Either way, `CHANGELOG.md` line 9 no longer says the extensions come from `remote.SSH.defaultExtensions` alone.
- [ ] **Step 2: Run it, and see it fail.** `bash tests/sandbox.test.sh`. Expected: `FAIL docs_readme_gives_the_extension_route`.
- [ ] **Step 3: Write the docs.**
  - **Route A:** the Prerequisites gain the policy line as a one-time step, done before `remote.SSH.defaultExtensions` is set. The README says why: under the default `balanced` policy the server's download gets 403, and the failed install stops the remote extension host. It gives the `sbx policy rm network --resource …` line that undoes the rule.
  - **Route B:** the VS Code bullet gives `remote.downloadExtensionsLocally` and the once-per-sandbox install, and says not to set `remote.SSH.defaultExtensions`, with the same reason.
  - The CHANGELOG clause says the same in one sentence.
- [ ] **Step 4: Run it, and see it pass.** `bash tests/sandbox.test.sh`. Expected: `all cases passed`.
- [ ] **Step 5: Commit.** `docs: the sbx extension route that works under the sandbox policy (#99, #86)`

**Proof of done:** `bash tests/run.sh` prints `all cases passed`.

### Task 28: Script polish (F13)

**Files:**
- Modify: `.sbx/codeo-sandbox.sh` (`ensure_windows_trust`; the comment and directive at `pick_sbx`)
- Modify: `.devcontainer/scripts/devcontainer-start.sh` (step 3a′)
- Test: `tests/sandbox.test.sh`, `tests/devcontainer.test.sh`

- [ ] **Step 1: Write the failing tests.**
  - `issue_without_wsl_distro_name_prints_the_trust_todo`: with `sbx.exe` and `WSL_DISTRO_NAME` unset, `issue` prints one line starting `todo: WSL_DISTRO_NAME is not set` that contains `safe.directory`, and logs no `git.exe config --global --add` call.
  - In `tests/devcontainer.test.sh`, `start_in_a_sandbox_skips_the_folder_check`: follow the `start_trust_*` cases' setup. With `CODEO_SANDBOX_MARK` pointing at an existing file, the start script on a `main` clone in a `codeo-122` folder prints no TODO containing `docker ps`. Without the marker, that TODO still prints (the existing case covers this).
- [ ] **Step 2: Run them, and see them fail.** `bash tests/run.sh`. Expected: the two new FAIL lines.
- [ ] **Step 3: Implement.**
  - `ensure_windows_trust` with `windows == 1` and an empty `WSL_DISTRO_NAME` prints `todo: WSL_DISTRO_NAME is not set, so the clone's Windows path is not known: run git.exe config --global --add safe.directory %(prefix)///wsl.localhost/<distro><path>` (with `<path>` the clone's `pwd -P`), and returns 0.
  - Step 3a′ of the start script is skipped when `${CODEO_SANDBOX_MARK:-$HOME/.codeo-sandbox}` exists. That is the marker `session-title.sh` reads. `check_name` gives the sandbox's own advice.
  - Remove the stale `# shellcheck disable=SC2034 # read by the sub-commands to come` (`windows` is read now).
  - Add `# shellcheck disable=SC2016` above `issue_writes_the_sandbox_marker`'s `local mark=…` line.
- [ ] **Step 4: Run them, and see them pass.** `bash tests/run.sh`. Expected: `all cases passed`.
- [ ] **Step 5: Commit.** `fix: sbx polish from QC round 2 (#99)`

**Proof of done:** `bash tests/run.sh` prints `all cases passed`.

### Task 29: Evaluation page and README wording (F14-F16)

**Files:**
- Modify: `docs/dev-environment-sbx-evaluation.md` (the #86 follow-up bullet `:478`; T13 Result and the D1 row; the D4 row `:79`; the Fragility bullet `:461`)
- Modify: `.sbx/README.md:11` (the `sbx secret set github` bullet)

- [ ] **Step 1: The #86 bullet.** It cites one range, `T<a> to T<b>`, where `a` and `b` are the lowest and highest trial numbers in the last column of the rows it names (D2, D3, D4, U13, U14, U18). Every other trial list goes from the bullet.
- [ ] **Step 2: The token.** T13 Result and D1 say that inside the sandbox `gh auth token` and `GH_TOKEN` print a placeholder and a push works, and that where the real token is held was not shown. README:11 says the same in place of "the real token stays on the host".
- [ ] **Step 3: The stops.** The D4 row and the Fragility bullet state the cause, citing `.sbx/README.md` (Stopped sandboxes): a sandbox that only `create` and `exec` started stops about a minute after the last `exec`, and `run -d` keeps it up. They keep T9's observation as recorded.
- [ ] **Step 4: Check.** `grep -c 'stays outside the VM\|never holds the real token' docs/dev-environment-sbx-evaluation.md` prints `0`, and `grep -c 'cause unknown\|cause is not shown' docs/dev-environment-sbx-evaluation.md` prints `0`.
- [ ] **Step 5: Commit.** `docs: correct the sbx evaluation's token, stop and range wording (#99)`

**Proof of done:** step 4's two greps print `0`, and `bash tests/run.sh` prints `all cases passed`.

### Task 30: Host acceptance, round 3

Runs on: the engineer's host
Shell: bash (WSL2), from `D:\Downloads\task22`

- [ ] **Step 1: Get this branch's script.** `curl -fsSL -o codeo-sandbox.sh https://raw.githubusercontent.com/kbajpai/codeo/feat/make-sbx-issue-sandbox-usable/.sbx/codeo-sandbox.sh`
- [ ] **Step 2: Create, and stay up.** `bash codeo-sandbox.sh issue 99 feat/make-sbx-issue-sandbox-usable`, then `sbx.exe ls`. Expected: `codeo-99` is `● running (detached)`. Wait three minutes, then run `sbx.exe ls` again. Expected: still `running (detached)`.
- [ ] **Step 3: Open, and stay connected.** `bash codeo-sandbox.sh open 99`. Expected:
  - The three extensions are present: installed by themselves (route A), or by hand once (route B).
  - After three idle minutes the window is still connected.
- [ ] **Step 4: Reopen a stopped sandbox.** `sbx.exe stop codeo-99`, then `bash codeo-sandbox.sh open 99`, then `sbx.exe ls`. Expected: `running (detached)`.
- [ ] **Step 5: Uncommitted work.** `sbx.exe exec codeo-99 touch scratch-uncommitted`, then `bash codeo-sandbox.sh end 99`. Expected: `?? scratch-uncommitted`, the uncommitted "nothing removed" line, and `codeo-99` still listed.
- [ ] **Step 6: Clean, then end.** `sbx.exe exec codeo-99 rm scratch-uncommitted`, then `bash codeo-sandbox.sh end 99`. Expected: `removed codeo-99`.

**Proof of done:** the output and screenshots of steps 2-6 are recorded under `## Acceptance` in `.codeo/99/implement.md`, each step marked met or not met.
