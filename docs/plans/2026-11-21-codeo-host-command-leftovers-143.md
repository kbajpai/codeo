# `codeo` Host Command Leftovers Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Close what #133 left in `.devcontainer/codeo` (#143): `rm` never removes on stale, hidden or racing evidence and never prints a false or unsafe line, concurrent first use is safe, and the help, READMEs, comments and changelog say what the command does.

**Architecture:** All code changes are in the one bash script `.devcontainer/codeo` and its stub-driven test file `tests/codeo-command.test.sh`; `codeo-container.sh` and `codeo-sandbox.sh` do not change. `container_check` gains `--prune`, an explicit untracked setting and a restart-and-reread step (Q1 A); `cmd_rm` gains a mount check (Q4 A) and tracks what it removed (F30); the first-use download and the lookup clone each get their own temporary path and a `flock` (concurrency); the rest are one-line fixes and documentation.

**Tech Stack:** bash 4.3+, `docker`, `sbx`, `git`, `curl`, `flock` (util-linux); the `shell` suite (`bash tests/run.sh`).

**Spec:** none. The decisions are the answers to Q1-Q6 in `.codeo/143/plan.md`; the issue is #143. No reference doc: the two READMEs are the standing reference and Task 8 updates them.

```mermaid
flowchart TD
    A[codeo rm N, container] --> B[start if stopped; fetch --prune origin; fetch pull-request heads]
    B --> C{read: status --untracked-files=normal, stash, detached HEAD, unpushed}
    C -- dirty --> R[refuse, or with --force say what is not kept]
    C -- cannot run --> X[nothing removed, or removed with --force]
    C -- clean, was running --> D[docker restart: ends attached shells and agents]
    D --> E{read again, no fetch}
    E -- dirty --> R
    E -- clean --> F{docker inspect: /workspaces is volume codeo-N?}
    C -- clean, started by us --> F
    F -- yes --> G[docker rm -f, volume rm, rmi]
    F -- no, no --force --> H[remove container and image, keep the volume, say so]
    F -- inspect failed, no --force --> X
```

## Global Constraints

- **Invariants:** none configured (`.invariants` is absent), so there is no invariants check. **Shared environment:** none (`.environment.resource` absent), so no task needs a lease and every task is proved in this checkout. **Wiki:** no `wiki` module, so `wiki: none`.
- **Documentation moved:** `.devcontainer/README.md` (the command table, *Installing the `codeo` command*, *Removing a finished container*), `.sbx/README.md` (*Ending a sandbox*) and `CHANGELOG.md` (the `codeo` bullet under `## Unreleased`). Task 8 owns all three, so `/codeo:qc` can tell a deliberate edit from a forgotten one.
- `.devcontainer/codeo-container.sh` and `.sbx/codeo-sandbox.sh` are not edited (issue, Out of Scope).
- No new command or option. The only new requirement on the host is `flock`.
- Every comment line added or changed in `.devcontainer/codeo` is at most 120 columns (Task 7 pins it).
- Every task's proof is the whole suite, because the `shell` suite has no single-test filter: `bash tests/run.sh` exits 0 and prints `all cases passed`. The failing-first steps use `bash tests/codeo-command.test.sh`, which prints one `FAIL <case>: <detail>` line per failure and exits 1.
- Stubs only, apart from Task 9: `--prune` against a real remote, `docker restart` and the `docker inspect` format are what a stub answers however a test tells it to, so Task 9 runs them once on the engineer's host.
- Not touched, on purpose: F2 (a stopped container's branch is `-`) and F32 (bare hashes in the refusal).

## Review Focus

- `docker restart` fails after a clean first read: the container may now be stopped, so `rm` must say it could not check and remove nothing without `--force` (Task 2, `t_rm_restart_fails`).
- A commit or file appears between the first read and the second: `rm` refuses, removes nothing and leaves the container running (Task 2, `t_rm_write_after_check_refused`).
- `CODEO_HOME` unset with `~/codeo` a git checkout: `help`, a usage error and `default` with a bad argument still work, because they write nothing (Task 6, `t_home_checkout_collision`).
- `rm --force` on a container whose `/workspaces` is a bind mount: the volume is removed too, with the line saying it was not checked (Task 3, `t_rm_bind_mount_force`).
- Two first-use commands on a fresh home where the second finishes first: the installed scripts and `.lookup.git` are complete either way and `clone` runs once (Task 5, `t_concurrent_first_use`).

## File Structure

- `.devcontainer/codeo` (modify): `ensure_home`, `find_branch`, `home_dir`, `cmd_default`, `main`, `container_check` (split into `container_read` and the rest), `cmd_rm`, comments.
- `tests/codeo-command.test.sh` (modify): the stubs (`cm_sys`, git, curl, `rm_stubs`), the cases listed per task, and the `cases=( … )` array.
- `.devcontainer/README.md`, `.sbx/README.md`, `CHANGELOG.md` (modify): Task 8.

## Footprint

```
files:      .devcontainer/codeo, .devcontainer/README.md, .sbx/README.md, tests/codeo-command.test.sh, CHANGELOG.md, docs/plans/2026-11-21-codeo-host-command-leftovers-143.md
wiki:       none
exclusive:  none
sequenced:  none
```

#144 and #145 were both at `init` with no footprint when this was drafted; `inflight.sh` showed no changed files for either. All three add or edit a bullet under `## Unreleased` in `CHANGELOG.md`, so whichever merges second keeps both entries, as in #133 (its Q6).

---

### Task 1: The safety check prunes stale refs and sees untracked files

Closes threads …636234 and …636301 (and F20's stale-ref case).

**Files:**
- Modify: `.devcontainer/codeo` (`container_check`, the two `git` calls named below)
- Test: `tests/codeo-command.test.sh`

**Interfaces:**
- Consumes: `rm_stubs`, `cm_setup`, `cm_run`, `expect_refused` (existing).
- Produces: nothing new; later tasks edit the same function.

- [ ] **Step 1: Write the failing test** `t_rm_check_prunes_and_sees_untracked`. Run `rm 5 --container` against `rm_stubs`. Assert the calls file holds `docker exec codeo-5 git -C /workspaces/codeo-5 fetch --prune origin` on a line before the one containing `refs/pull/*/head`, and holds `status --porcelain --untracked-files=normal`. Add it to `cases`. Also change the `want` in `t_rm_container_clean` to the new call sequence: the first fetch is `fetch --prune origin` and the status call ends `--untracked-files=normal` (Task 2 and 3 change it again).
- [ ] **Step 2: Run** `bash tests/codeo-command.test.sh`. Expected: FAIL `t_rm_check_prunes_and_sees_untracked` ("no fetch --prune") and `t_rm_container_clean` ("calls: …").
- [ ] **Step 3: Edit** the first `docker exec … git … fetch origin` to `fetch --prune origin`, and `status --porcelain` to `status --porcelain --untracked-files=normal`. The pull-request fetch stays after the prune, since the prune drops `refs/remotes/origin/pr/*` and the fetch brings them back. Update the README sentence in Task 8, not here.
- [ ] **Step 4: Run** `bash tests/codeo-command.test.sh`. Expected: `all cases passed`.
- [ ] **Step 5: Proof of done** — `bash tests/run.sh` exits 0, prints `all cases passed`. Commit: `git add .devcontainer/codeo tests/codeo-command.test.sh && git commit -m "fix(codeo): rm prunes stale origin refs and counts untracked files (#143)"`.

### Task 2: Close the window between the check and the removal (Q1 A)

Closes thread …636391.

**Files:**
- Modify: `.devcontainer/codeo` (`container_check`, new `container_read`)
- Test: `tests/codeo-command.test.sh` (`rm_stubs`, new cases)

**Interfaces:**
- Produces: `container_read <name>` → prints one heading per kind found (the same four headings and 10-line limit `container_check` prints today), returns 0 clean, 1 dirty, 2 when a `docker exec` failed. It runs `status --porcelain --untracked-files=normal`, `stash list`, `branch --show-current`, the detached-HEAD `branch -r --contains HEAD` when there is no current branch, and `rev-list --branches --not --remotes=origin`; it does not fetch. `container_check <N>` keeps its signature and return codes 0/1/2/3.
- Consumes: `stop_started <name> <started>` (existing).

- [ ] **Step 1: Extend `rm_stubs`.** `docker restart` fails when `restart_fail` exists. A file `g2_<sub>` replaces `g_<sub>` as the output of `docker exec … git -C <dir> <sub>` once `docker restart` is in the calls file. Document both in the comment above `rm_stubs`.
- [ ] **Step 2: Write the failing tests**, each added to `cases`:
  - `t_rm_restarts_running_container_and_reads_again`: running container, nothing dirty. Assert exit 0; `docker restart codeo-5` is in the calls after the first `rev-list` call and before `docker rm -f`; the four reads (`status`, `stash list`, `branch --show-current`, `rev-list`) each appear twice; `fetch` appears exactly twice (one `--prune`, one pull-request), not four times. Update `t_rm_container_clean`'s `want` to the full sequence: host_kinds calls, the container listing, `fetch --prune`, the pull-request fetch, the four reads, `docker restart codeo-5`, the four reads again, then `docker rm -f`, `volume rm`, `rmi` (Task 3 adds an `inspect` line before `docker rm -f`).
  - `t_rm_write_after_check_refused`: `g2_status` holds `?? new` (`g_status` empty). Assert `expect_refused '?? new'`, `docker restart` was called, no `docker stop`.
  - `t_rm_restart_fails`: `restart_fail` exists. Assert `expect_refused 'could not check'`; and with `--force` exit 0 and `docker rm -f codeo-5` called.
  - `t_rm_started_container_not_restarted`: `dstate` is `exited` and nothing is dirty. Assert no `docker restart` call, exit 0.
- [ ] **Step 3: Run** `bash tests/codeo-command.test.sh`. Expected: FAIL for the four new cases and `t_rm_container_clean`.
- [ ] **Step 4: Implement.** Move the four reads and the report printing out of `container_check` into `container_read`; `container_check` calls it after the two fetches, and when it returns 0 and the container was running (not started by `container_check`), runs `docker restart "$name"` (return 2 when it fails; the container's state is unknown, so no `stop_started`), then calls `container_read` again and returns its result. Any non-zero result still goes through `stop_started` as today. Update the function's header comment (at most 120 columns a line).
- [ ] **Step 5: Run** `bash tests/codeo-command.test.sh`. Expected: `all cases passed`.
- [ ] **Step 6: Proof of done** — `bash tests/run.sh` exits 0, `all cases passed`. Commit: `git add .devcontainer/codeo tests/codeo-command.test.sh && git commit -m "fix(codeo): rm restarts a running container and reads it again before removing (#143)"`.

### Task 3: `rm` checks the volume it removes and says only what it removed (Q4 A, F30, F27)

Closes thread …636455 and F30.

**Files:**
- Modify: `.devcontainer/codeo` (`cmd_rm`, new `workspace_mount`)
- Test: `tests/codeo-command.test.sh` (`rm_stubs`, new cases)

**Interfaces:**
- Produces: `workspace_mount <name>` → prints `volume` when the container's mount at `/workspaces` is the named volume `<name>`, `other` when it is anything else (a bind mount, another volume, none), returns 1 when `docker inspect` fails. It runs `docker inspect -f '{{range .Mounts}}{{if eq .Destination "/workspaces"}}{{.Type}} {{.Name}}{{end}}{{end}}' <name>`; the answer `volume <name>` is `volume`.
- Consumes: `container_check` return codes (Task 2).

- [ ] **Step 1: Extend `rm_stubs`.** `docker inspect` prints the contents of `$d/mounts` (default `volume codeo-5`) and fails when `inspect_fail` exists. `docker volume inspect|rm` fail when `vol_gone` exists (the existing `vol_fail` stays for `volume rm` only).
- [ ] **Step 2: Write the failing tests**, added to `cases`:
  - `t_rm_container_not_found_force`: `gone`, `start_fail`, `rm_fail`, `vol_gone`, `rmi_fail` exist; `rm 5 --container --force`. Assert exit 1, stderr is exactly `codeo: nothing named codeo-5 to remove`, and neither stdout nor stderr contains `removed container`.
  - `t_rm_force_volume_only`: same but the volume exists. Assert exit 0, stdout names the volume as removed and does not say `removed container`.
  - `t_rm_bind_mount_keeps_volume`: `mounts` holds `bind `. Assert exit 0, `docker rm -f codeo-5` and `docker rmi` called, `docker volume rm` not called, stdout names `docker volume rm codeo-5`.
  - `t_rm_bind_mount_force`: same with `--force`. Assert `docker volume rm codeo-5` called and the output says the volume was not checked.
  - `t_rm_inspect_fails`: `inspect_fail` exists. Assert `expect_refused 'could not check'`; with `--force` exit 0 and the volume removed.
  - Change `t_rm_container_clean`'s `want`: one `docker inspect -f … codeo-5` line before `docker rm -f`.
- [ ] **Step 3: Run** `bash tests/codeo-command.test.sh`. Expected: FAIL for the five new cases and `t_rm_container_clean`.
- [ ] **Step 4: Implement** `workspace_mount`; in `cmd_rm`, after the check and before `docker rm -f` (skipped when `container_check` returned 3, since there is no container), call it: failure without `--force` dies `could not check what /workspaces of codeo-N mounts; nothing removed (…docker rm -f / volume rm by hand)`; `other` without `--force` sets `keep_volume=1` and later prints one line naming `docker volume rm codeo-<N>`; with `--force` it removes the volume and prints that it was not checked. Track what went: set `removed_container=1` only when `docker rm -f` succeeds; when `docker volume rm` fails, say `removed container …` only if `removed_container` is 1, else `could not remove volume`, and treat a `docker volume inspect` failure as "no volume" (not an error); finish with `nothing named $name to remove` (exit 1) when nothing at all was removed, else `removed $name` with the login note when container and volume both went, else one line listing exactly what went. The existing `t_rm_volume_failure_says_container_removed` must keep passing.
- [ ] **Step 5: Run** `bash tests/codeo-command.test.sh`. Expected: `all cases passed`.
- [ ] **Step 6: Proof of done** — `bash tests/run.sh` exits 0, `all cases passed`. Commit: `git add .devcontainer/codeo tests/codeo-command.test.sh && git commit -m "fix(codeo): rm checks which volume it removes and says only what it removed (#143)"`.

### Task 4: The hint after a failed sandbox `end` (Q3 A, F29)

**Files:**
- Modify: `.devcontainer/codeo` (`cmd_rm`, the sandbox branch)
- Test: `tests/codeo-command.test.sh` (`t_rm_sandbox`, new cases)

**Interfaces:** none new. `codeo-sandbox.sh end` keeps exiting 1 for every failure and prints its own `to remove it anyway run: sbx rm --force codeo-<N>` when nothing could be read.

- [ ] **Step 1: Write the failing tests.** In the stub `codeo-sandbox.sh` (in `cm_setup`) print `$d/stderr_text` to stderr when that file exists. Rewrite the middle part of `t_rm_sandbox` and add `t_rm_sandbox_hints`, in `cases`:
  - `rm 5 --sandbox` with `status` 1: stderr contains `codeo rm 5 --force removes it anyway` and does **not** contain `sbx rm --force`.
  - `rm 5 --sandbox --force` with `status` 1 and no `stderr_text`: stderr ends with `codeo: to remove it anyway, discarding whatever it holds: sbx rm --force codeo-5`.
  - the same with `stderr_text` holding the script's own `…to remove it anyway run: sbx rm --force codeo-5`: stderr carries that line once and no second `sbx rm --force` line from `codeo`.
  - exit status is the script's in every case; success prints neither hint (the existing assertion).
- [ ] **Step 2: Run** `bash tests/codeo-command.test.sh`. Expected: FAIL `t_rm_sandbox` / `t_rm_sandbox_hints`.
- [ ] **Step 3: Implement.** Run the script with its stderr into a `mktemp` file in the home directory, replay it on stderr after the script exits, remove the file; on a non-zero exit print the hint chosen by `--force` as above, the second only when the replayed stderr lacks `rm --force codeo-$n`. The hint without `--force` names the clone directory `<home>/codeo-<N>` where the commits are kept.
- [ ] **Step 4: Run** `bash tests/codeo-command.test.sh`. Expected: `all cases passed`.
- [ ] **Step 5: Proof of done** — `bash tests/run.sh` exits 0, `all cases passed`. Commit: `git add .devcontainer/codeo tests/codeo-command.test.sh && git commit -m "fix(codeo): rm of a sandbox names sbx rm --force only when --force itself failed (#143)"`.

### Task 5: Concurrent first use, and the lookup resolves the branch, not a tag

Closes threads …636491 and …636540, and the remainder of …636654.

**Files:**
- Modify: `.devcontainer/codeo` (`ensure_home`, `find_branch`)
- Test: `tests/codeo-command.test.sh` (`cm_sys`, the git and curl stubs, `t_lookup_clone_atomic`, `t_lookup_checks_file_without_blob`, new case)

**Interfaces:**
- Produces: nothing new for other tasks. `find_branch <N>` and `ensure_home` keep their signatures and output.

- [ ] **Step 1: Extend the stubs.** Add `flock` to the tool list in `cm_sys`. The curl stub sleeps 0.3 s after writing its `-o` target when `$d/slow` exists; the git stub's `clone` sleeps 0.3 s first when `$d/slow` exists. The git stub's `*:.codeo/*/init.md` match strips a leading `refs/heads/` before comparing with `has`.
- [ ] **Step 2: Write the failing tests**, in `cases`:
  - `t_concurrent_first_use`: remove the stub scripts from `$cm_home`, create `slow`, put `feat/a` in `branches` and `has`. Start two `env -i … codeo issue 5` processes in the background with the same `$cm_home` (copy the `env -i` line of `cm_run` with separate out files), wait for both. Assert both exit 0, `codeo-container.sh` and `codeo-sandbox.sh` in `$cm_home` are non-empty and start with `#!`, `$cm_home/.lookup.git` exists, nothing else named `.lookup.*` or `*.part` or `.codeo-*` remains in `$cm_home`, and the calls file holds exactly one `clone` line.
  - Update `t_lookup_clone_atomic`: the clone's target is a directory under `$cm_home` named `.lookup.*` that is not `.lookup.git`, and after the run it is gone, `.lookup.git` exists, and a leftover `.lookup.git.part` from an older run is not read as the clone.
  - Update `t_lookup_checks_file_without_blob`: the `rev-parse` argument is `refs/heads/feat/a:.codeo/5/init.md`.
- [ ] **Step 3: Run** `bash tests/codeo-command.test.sh`. Expected: FAIL for the three (`t_concurrent_first_use`: one process exits non-zero or a script is missing; the others on the old `.part` name and the old argument).
- [ ] **Step 4: Implement.** `ensure_home`: download each script to `mktemp "$dir/.$name.XXXXXX"` (removed on any failure), check `#!`, then `mv -f` onto `$dir/$name`. `find_branch`: open `$dir/.lookup.lock` and `flock` it for the whole lookup (clone, `remote set-url`, fetch, ref listing, the per-branch checks); clone into `mktemp -d "$dir/.lookup.XXXXXX"` and `mv` it to `.lookup.git` while holding the lock; the per-branch check uses `refs/heads/$b:.codeo/$n/init.md`. A failed clone removes its temporary directory.
- [ ] **Step 5: Run** `bash tests/codeo-command.test.sh`. Expected: `all cases passed`.
- [ ] **Step 6: Proof of done** — `bash tests/run.sh` exits 0, `all cases passed`. Commit: `git add .devcontainer/codeo tests/codeo-command.test.sh && git commit -m "fix(codeo): first-use downloads and the lookup clone are safe to run together (#143)"`.

### Task 6: `~/codeo` collision, relative overrides, and `default`'s `mkdir` (Q2 A, thread …636698, F8)

**Files:**
- Modify: `.devcontainer/codeo` (`home_dir`, `cmd_default`, `main`, new `abs_path_env`)
- Test: `tests/codeo-command.test.sh` (`cm_run`, the stub scripts in `cm_setup`, new cases)

**Interfaces:**
- Produces: `abs_path_env <VAR> <always|slash>` → rewrites an exported variable that is set and non-empty to an absolute path against `$PWD`: with `always` whenever the value is not absolute, with `slash` only when it contains a `/` and is not absolute. `main` calls it first for `CODEO_CONTEXT` and `CODEO_SBX_IMAGE` (`always`) and `CODEO_SBX` (`slash`: a bare program name stays a name).

- [ ] **Step 1: Extend the harness.** `cm_run` passes `CODEO_CONTEXT`, `CODEO_SBX_IMAGE` through `env -i` when set, as it does `CODEO_SBX`. The stub scripts in `cm_setup` also write `ctx=${CODEO_CONTEXT-} img=${CODEO_SBX_IMAGE-} sbx=${CODEO_SBX-}` to `$d/env`.
- [ ] **Step 2: Write the failing tests**, in `cases`:
  - `t_relative_overrides_made_absolute`: `mkdir -p "$cm_dir/w"`, `cd "$cm_dir/w"`, run `home` with `CODEO_CONTEXT=./ctx` and `CODEO_SBX_IMAGE=pin`, then `cd "$repo"`. Assert `$cm_dir/env` holds `ctx=$cm_dir/w/./ctx` (or the normalised `$cm_dir/w/ctx`; accept either) and `img=$cm_dir/w/pin`. A second run with `CODEO_SBX=mysbx` keeps `sbx=mysbx`; with `CODEO_SBX=./mysbx` it becomes absolute.
  - `t_home_checkout_collision`: `HOME` is `$cm_dir/h`, `CODEO_HOME` unset (add a way for `cm_run` to leave it unset, for example a `cm_nohome=1` variable), and `$cm_dir/h/codeo/.git` is a directory. `list` exits 1 with stderr `codeo: ~/codeo is a git checkout; set CODEO_HOME to the directory codeo should keep its files in` and nothing is written into `$cm_dir/h/codeo`; `help` exits 0; `rm 5 --bogus` exits 2 with a usage. With `CODEO_HOME` set, the same layout is accepted.
  - `t_default_mkdir_failure_is_one_line`: `CODEO_HOME` is a path under a regular file; `default sandbox` exits 1 with one `codeo: could not create …` line and no `mkdir:` text.
- [ ] **Step 3: Run** `bash tests/codeo-command.test.sh`. Expected: FAIL for the three.
- [ ] **Step 4: Implement.** `home_dir` dies with the line above when `CODEO_HOME` is unset and `$HOME/codeo/.git` exists. Call it where the home is first needed; the `die` inside `$(home_dir)` must still stop the command, so confirm with the test that the exit status is 1 and no later command ran. `cmd_default` computes the directory once and uses `mkdir -p "$d" 2>/dev/null || die "could not create $d"`.
- [ ] **Step 5: Run** `bash tests/codeo-command.test.sh`. Expected: `all cases passed`.
- [ ] **Step 6: Proof of done** — `bash tests/run.sh` exits 0, `all cases passed`. Commit: `git add .devcontainer/codeo tests/codeo-command.test.sh && git commit -m "fix(codeo): relative path overrides, the ~/codeo checkout collision and default's mkdir error (#143)"`.

### Task 7: Pin F19 for `rm`, and keep comments short (F17)

**Files:**
- Modify: `.devcontainer/codeo` (the four comments at about `:441`, `:445`, `:449-450` and `:497`, wherever they sit after Tasks 1-6)
- Test: `tests/codeo-command.test.sh`

- [ ] **Step 1: Write the tests**, in `cases`:
  - `t_rm_one_listing_fails_needs_a_kind`: docker fails to list (`ps_fail` in `rm_stubs`) while `sbx_out` lists `codeo-5`; `rm 5` exits 1, stderr names `--container` or `--sandbox`, and neither `codeo-sandbox.sh` nor any `docker rm` ran. The reverse: sbx fails (a stub `sbx` that exits 1) while docker lists `codeo-5`: the same, and no `docker rm`.
  - `t_comments_within_120_columns`: no line of `.devcontainer/codeo` that starts, after spaces, with `#` is longer than 120 characters (`awk` on the script, `fail` with the line number).
- [ ] **Step 2: Run** `bash tests/codeo-command.test.sh`. Expected: the first passes already (F19 is fixed on `main`, `detect_kind` dies); `t_comments_within_120_columns` fails naming the long comments.
- [ ] **Step 3: Re-wrap** the over-long comments to at most 120 columns, changing no code.
- [ ] **Step 4: Run** `bash tests/codeo-command.test.sh`. Expected: `all cases passed`.
- [ ] **Step 5: Proof of done** — `bash tests/run.sh` exits 0, `all cases passed`. Commit: `git add .devcontainer/codeo tests/codeo-command.test.sh && git commit -m "test(codeo): pin rm with one failing listing; keep comments within 120 columns (#143)"`.

### Task 8: Documentation — the READMEs and the changelog

**Files:**
- Modify: `.devcontainer/README.md`, `.sbx/README.md`, `CHANGELOG.md`

What each must say after Tasks 1-7 (describe the command as it is; no "now", "no longer" or issue numbers in the READMEs):

- **`.devcontainer/README.md`**
  - The first table (`:45-47`): `codeo shell home` or `codeo shell <N>` carries `[--container|--sandbox]` on the issue form. The command table (`:104-109`): the `codeo issue` row carries `[--container|--sandbox]`; add rows for `codeo open <N> [--container|--sandbox]` (`bash codeo-sandbox.sh open <N>`, sandbox only) and `codeo default [container|sandbox]` (none).
  - *Installing the `codeo` command*: add `flock` to the host's requirements (`curl`, `git`, `flock`). Say the scripts and the lookup clone are fetched under a lock, so two first-use commands started together are safe. Say that with `CODEO_HOME` unset and `~/codeo` a git checkout (what `git clone` of this repository makes), `codeo` stops with one line and asks for `CODEO_HOME`. Say a relative `CODEO_CONTEXT`, `CODEO_SBX_IMAGE` or `CODEO_SBX` is read against the directory `codeo` was started in.
  - *Removing a finished container*: the list uses `git status --porcelain --untracked-files=normal` and says `git fetch --prune origin`; after a clean first read, a container that was running is restarted (this ends any shell or agent attached to it) and read again, and a change found then refuses the removal; the mount at `/workspaces` is checked, and when it is not the volume `codeo-<N>` the container and image go, the volume stays and the line names `docker volume rm codeo-<N>` (with `--force` it goes too, unchecked); the removal reports only what it removed, and says `nothing named codeo-<N> to remove` when nothing existed; the sandbox sentence names `codeo rm <N> --force` on a refusal and `sbx rm --force codeo-<N>` only after `--force` itself failed.
  - Mermaid: add the `flowchart` of this plan's *Architecture* block, or one that matches it, to *Removing a finished container*.
- **`.sbx/README.md`**: *Ending a sandbox* (`:78`, `:107`) describes the same two hints; the `codeo rm` row stays as it is.
- **`CHANGELOG.md`**: rewrite the `codeo` bullet under `## Unreleased` in place, once, so it states what the command does as it stands (commands and flags, container check including `--prune`, untracked files, the restart and second read, the mount check, what `rm` reports, the sandbox hint, `flock`, the `~/codeo` checkout stop, relative overrides, `CODEO_SBX`), with no phrase that reads as a fix to something a release had; cite `(#133, #143)`. Leave every other bullet and the header lines under `## Unreleased` as they are.

- [ ] **Step 1: Edit the three files** as above, matching the wording and table style already in them.
- [ ] **Step 2: Check the documentation** — `grep -n 'all or nothing' .devcontainer/README.md CHANGELOG.md` prints nothing; `grep -c -- '--container|--sandbox' .devcontainer/README.md` prints at least 6 and `.sbx/README.md` still carries the flag on its `shell`, `open` and `rm` rows; the changelog diff against `origin/main` touches only the `codeo` bullet (`git diff origin/main -- CHANGELOG.md`).
- [ ] **Step 3: Proof of done** — `bash tests/run.sh` exits 0, `all cases passed`. Commit: `git add .devcontainer/README.md .sbx/README.md CHANGELOG.md && git commit -m "docs(codeo): the host command's removal check, first-use safety and hints (#143)"`.

### Task 9: One run against real Docker

Runs on: the engineer's host

**Files:** none.

Run these on the host, in a Linux terminal, from an empty directory, one at a time. `99999` is a throwaway issue number. The branch must be pushed first: `git push` in this container.

- [ ] **Step 1:** `curl -fsSL -o codeo-branch https://raw.githubusercontent.com/kbajpai/codeo/fix/codeo-host-command-close-leftovers/.devcontainer/codeo` — creates the file `codeo-branch`.
- [ ] **Step 2:** `bash codeo-branch issue 99999 main --container` — builds and starts the container `codeo-99999`; ends in a shell prompt, so type `exit`.
- [ ] **Step 3:** `bash codeo-branch list` — prints a row `#99999  container  running  main`.
- [ ] **Step 4:** `docker exec codeo-99999 touch /workspaces/codeo-99999/untracked.txt`, then `bash codeo-branch rm 99999` — exits 1, prints `?? untracked.txt` and `nothing removed`, and the container is still running (`docker ps` lists `codeo-99999`).
- [ ] **Step 5:** `docker exec codeo-99999 git -C /workspaces/codeo-99999 config status.showUntrackedFiles no`, then `bash codeo-branch rm 99999` — exits 1 and still names `untracked.txt` (the setting does not hide it).
- [ ] **Step 6:** `docker exec codeo-99999 rm /workspaces/codeo-99999/untracked.txt`, then `bash codeo-branch rm 99999` — exits 0 after a `docker restart` (the container's `Created`/uptime resets, `docker ps` shows `Up` seconds), prints `removed codeo-99999`, and `docker ps -a` and `docker volume ls` list neither the container nor the volume.
- [ ] **Step 7:** `bash codeo-branch rm 99999 --container --force` — exits 1 and prints `codeo: nothing named codeo-99999 to remove`, and no line says `removed container`.
- [ ] **Step 8:** report each step's output in this plan's `implement.md`; delete `codeo-branch` and `~/codeo/.lookup.git` only if you want them gone. Proof of done: every step's output above, as the engineer reports it.

## Self-review

- **Spec coverage:** F19 (Task 7 pins; fixed on `main`), F29 (4), F30 (3), prune and untracked (1), the write after check (2), the bind mount (3), concurrent first use (5), the tag-qualified lookup (5), relative overrides (6), F8 (6), F21 (6), F5/F16 rows (8), F6/F31 (8), F17 (7), the table in Q5 for the rest (ruled out: fixed, with the test already named there), real Docker (9).
- **Consistency:** `container_read` (Task 2) is the only function Tasks 1 and 2 both edit; Task 3 edits `cmd_rm` and the `rm_stubs` stub that Task 2 also extends (`restart`/`g2_` in Task 2, `inspect`/`vol_gone` in Task 3), and each task updates `t_rm_container_clean`'s `want` for its own calls, so they run in order 1, 2, 3.
- **Proportion:** nine tasks for one script; the code bodies are left to the implementer, the tests are named with their assertions.
