# Close the non-blocking findings #143 and #144 left: `codeo rm`, a relative `CODEO_HOME`, skill wording and test pins Implementation Plan (#149)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `codeo rm` no longer prints advice that does not apply or ends sessions it then refuses to act on, a relative `CODEO_HOME` works, the READMEs and help text agree with the code, and the #144 wording and test-pin leftovers are closed, with `bash tests/run.sh` ending `all cases passed`.

**Architecture:** Three small code changes in `.devcontainer/codeo`, each test first (Task 1 a relative `CODEO_HOME`, Task 2 the mount check before the restart, Task 3 the `--force` hint decided by `sbx ls`); then the prose that describes them (Task 4); then the #144 leftovers, which touch only skill text and tests (Tasks 5-8); then the CHANGELOG (Task 9). `.sbx/codeo-sandbox.sh` is not edited, and what `rm` refuses or removes does not change.

**Tech Stack:** bash, git, awk; the `shell` suite (`bash tests/run.sh`, or one file with `bash tests/run.sh <name>`).

**Spec:** `.codeo/149/init.md` `## Outcome` (the issue's acceptance criteria) and `.codeo/149/plan.md` Q1-Q6, whose answers are the design. Reference doc: none; nothing here is a standing decision.

## Global Constraints

- **Q1 (A): a relative `CODEO_HOME` works.** `main` makes it absolute against the starting directory once, before any `cd`, with the same `abs_path_env … always` call the other three path variables use. Every command then reads one directory.
- **Q2 (A): the mount check runs before the restart.** `docker inspect` works on a stopped container, so `cmd_rm` asks it first. When it fails and `--force` is not given, the container is read once and never restarted, and `rm` refuses with today's message. With `--force`, or when it works, nothing changes except the order of two calls. What can still follow a restart without `--force` is a dirty second read, a failed restart, or a failed `docker rm`; the README says so.
- **Q3 (A): the `--force` hint is decided by the sandbox's state, not the script's wording.** After a failed `end --force`, `codeo` lists once more and prints `to remove it anyway, discarding whatever it holds: sbx rm --force codeo-<N>` only when `codeo-<N>` is still listed or the listing fails (unknown, so the hint stays) and the script's own stderr does not already name it. A row counts only when its first column is exactly `codeo-<N>`, as `host_kinds` already reads it, and one helper does that match for both.
- **Q4 (A): the README and a code comment change, the script's messages do not.** `.sbx/codeo-sandbox.sh` keeps every message it has.
- **Q5 (A): the flowchart is completed**, not labelled partial.
- **Q6: the #144 leftovers.** F3, F5a and F5b are done as written below. F5c is done: the mutation was run while planning (`scripts/inflight.sh:209` tightened to `/^## Outcome$/`, `bash tests/run.sh outcome-heading`) and it **passes**, so the gap is real. F5d (`CHANGELOG.md` calls the no-lock closing block "unchanged") is **dismissed**: the issue does not list it and it rewords a past entry for no reader's benefit.
- **Not changed:** what `rm` refuses or removes; temp files left by an interrupted download or clone, `.lookup.git.part` and the other minors in `.codeo/done/143/implement.md`; #144's F2 (`docs/skills.md`).
- **Documentation moves**, one task each: `.devcontainer/README.md` (Tasks 1, 2, 4), `.sbx/README.md` (Task 4), the `codeo help` text (Task 4), `skills/implement`, `skills/close` (Task 5), `skills/init` (Task 6), the stop sentence in `skills/plan`, `skills/implement`, `skills/qc`, `skills/close` and `docs/handoff.md` (Task 7), `CHANGELOG.md` (Task 9). `docs/skills.md`, `docs/skills-inventory.md` and `tests/fixtures/skills-inventory.rules.sha256` are not edited; `bash tests/run.sh skills` must still pass untouched, which is what catches an edit that moved a rule-marked paragraph. No wiki module.
- **No environment, no lease, no host tasks.** No shared environment, wiki module, invariants document or exclusive resource is configured, and the lock's host is `container`: every task runs in this checkout and none carries `Needs lease:` or `Runs on:`. No task is ordered around a lease.
- **A mutation is a proof.** Where a step says "mutate", change the file and revert it with `git checkout -- <file>` straight after; none is committed.
- **Invariants:** none configured.
- **Footprint check (step 8):** `inflight.sh --except 149` lists #151 (`docs/install-codeo-one-command-document`) and #138 (`fix/live-session-signal-does-not`), both at `init`, no footprint, nothing changed. Nothing to compare yet; `overlap.sh` runs on the written footprint after approval.

## Review Focus

- Task 2 moves a call, not a decision: the existing tests that pin the order of `docker` calls (`t_rm_container_clean`) change, and a reviewer should check the new order is the only difference.
- Task 3's `sbx ls` runs only after a failed `end --force`; a successful `rm` makes no extra call (`t_rm_sandbox`'s success cases still assert the exact calls).
- Task 8's two mutations must fail after the change and pass before it; the plan records the "before" result for `inflight.sh:209` (passes today).
- Task 7 rewords one sentence in seven places; `tests/overlap-stop.test.sh` counts them, and `bash tests/run.sh skills` guards the rule-marked paragraphs around them.

---

## File Structure

| File | Change |
|---|---|
| `.devcontainer/codeo` | `main` makes `CODEO_HOME` absolute; `cmd_rm` asks `workspace_mount` before `container_check`, which takes `--no-restart`; `sbx_has` helper, used by `host_kinds` and by the `--force` hint; a corrected comment; one line in `codeo help` |
| `.devcontainer/README.md` | `CODEO_HOME` clause (`:98`), the home-directory stop's scope (`:98`), the restart/mount order (`:178-182`), the flowchart (`:186-200`), the sandbox paragraph (`:202`) |
| `.sbx/README.md` | a failed listing warns and exits 1 (`:49`); the `--force` hint rule (`:78`) |
| `tests/codeo-command.test.sh` | new and changed `t_rm_*`, `t_relative_codeo_home_rm`, `t_help_lists_commands` |
| `skills/implement/SKILL.md`, `skills/close/SKILL.md` | the overlap sentences move after "The step stops until it is answered" |
| `skills/init/SKILL.md` | step 11: either TODO case ends the turn |
| `skills/plan/SKILL.md`, `skills/implement/SKILL.md`, `skills/qc/SKILL.md`, `skills/close/SKILL.md`, `docs/handoff.md` | the stop sentence |
| `tests/implement-skill.test.sh`, `tests/close-skill.test.sh`, `tests/init-skill.test.sh`, `tests/overlap-stop.test.sh` | order, closing-block and sentence pins |
| `tests/outcome-heading.test.sh` | an eighth reader (`qc-verdict.sh:134`); the send-back reader varies `close.md` alone |
| `CHANGELOG.md` | one `## Unreleased` bullet |

---

### Task 1: A relative `CODEO_HOME` (F14)

**Files:**
- Modify: `tests/codeo-command.test.sh` (new `t_relative_codeo_home_rm` beside `t_relative_codeo_home`; add it to the list at the bottom)
- Modify: `.devcontainer/codeo` (`main`)
- Modify: `.devcontainer/README.md:98`

**Interfaces:**
- Consumes: `abs_path_env <VAR> <always|slash>` (`.devcontainer/codeo:64`).
- Produces: `CODEO_HOME` is absolute from `main` on; Tasks 2-4 do not depend on it.

- [ ] **Step 1: Write the failing test.** `t_relative_codeo_home_rm` is `t_relative_codeo_home` with the command `rm 5 --sandbox`: `cm_setup`, `cd "$cm_dir"`, run `env -i HOME="$cm_dir/h" CODEO_HOME=home PATH="$cm_dir/bin:$cm_dir/sys" "$bash_abs" "$script" rm 5 --sandbox`, `cd "$repo"`. Assert exit 0, `expect_call "codeo-sandbox.sh end 5 pwd=$cm_home"`, and that stderr holds no `mktemp` text and no `home/home`. (`cm_home` is `$cm_dir/home`, which is what `CODEO_HOME=home` names from `$cm_dir`.)
- [ ] **Step 2: Run it and see it fail.** Run: `bash tests/run.sh codeo-command`. Expected: one failure naming `t_relative_codeo_home_rm`, exit 1, stderr `mktemp: failed to create file via template '…/home/home/.rm-err.XXXXXX'` and `codeo: could not create a temporary file in …/home/home`.
- [ ] **Step 3: Fix it.** In `main`, before the three existing `abs_path_env` lines, add `abs_path_env CODEO_HOME always`. Leave `home_dir`'s own `case $d in /*)` line: it still serves a relative `HOME`.
- [ ] **Step 4: Prove it.** Run: `bash tests/run.sh codeo-command`. Expected: `all cases passed`; `t_relative_codeo_home` (the `home` command) passes as before.
- [ ] **Step 5: Document it.** In `.devcontainer/README.md:98`, the sentence "A relative `CODEO_CONTEXT` or `CODEO_SBX_IMAGE`, and a `CODEO_SBX` that holds a `/`, is read against the directory `codeo` was started in" becomes "A relative `CODEO_HOME`, `CODEO_CONTEXT` or `CODEO_SBX_IMAGE`, and a `CODEO_SBX` that holds a `/`, are read against …" (this also settles #143's F8, whose reading of the `/` condition applied to all three). The sentence ends "… so a later `cd` inside `codeo` cannot change what it names".
- [ ] **Step 6: Commit** the test, `.devcontainer/codeo` and the README with `fix: make a relative CODEO_HOME absolute once, so codeo rm of a sandbox works (#149)`.

**Proof of done:** `bash tests/run.sh codeo-command` prints `all cases passed`, and `bash tests/run.sh` prints `all cases passed`.

---

### Task 2: The mount check comes before the restart (F6)

**Files:**
- Modify: `tests/codeo-command.test.sh` (`t_rm_container_clean`'s expected calls; a new `t_rm_inspect_fails_no_restart`; the existing `docker inspect` failure tests, found with `grep -n inspect_fail tests/codeo-command.test.sh`)
- Modify: `.devcontainer/codeo` (`container_check`, `cmd_rm`)
- Modify: `.devcontainer/README.md:178-182`

**Interfaces:**
- Consumes: `workspace_mount <name>` (prints `volume` or `other`, returns 1 when `docker inspect` fails).
- Produces: `container_check <N> [--no-restart]`: with `--no-restart` the container is read once and never restarted. Nothing later depends on it.

- [ ] **Step 1: Write the failing test.** `t_rm_inspect_fails_no_restart`: `cm_setup`, `rm_stubs`, `touch "$cm_dir/inspect_fail"`, `cm_run rm 5`. Assert `expect_refused 'could not check what /workspaces of codeo-5 mounts'` (exit 1, message, nothing removed) and `! grep -q '^docker restart' "$cm_dir/calls"` and `! grep -q '^docker stop' "$cm_dir/calls"`. A second half with `--force`: exit 0, `docker restart codeo-5` present, `docker rm -f codeo-5` present, stdout has `--force: could not check what /workspaces of codeo-5 mounts; removing the volume anyway`.
- [ ] **Step 2: Run it and see it fail.** Run: `bash tests/run.sh codeo-command`. Expected: `t_rm_inspect_fails_no_restart` fails with `docker restart` in the calls.
- [ ] **Step 3: Move the call.** In `cmd_rm`'s container branch, before `report=$(container_check …)`: `mount=$(workspace_mount "$name") || mount=""` and `no_restart=""; [[ -n "$mount" || -n "$force" ]] || no_restart=--no-restart`; call `container_check "$n" "$no_restart"`. In `container_check`, the restart branch's condition gains `&& [[ "${2:-}" != --no-restart ]]`, and the function's header comment says so. Delete the later `mount=$(workspace_mount "$name") || mount=""` line; the `case "$mount"` block that follows is unchanged and still skipped for `rc` 3 (no such container). The report and the process are unchanged otherwise: a failed inspect without `--force` now falls to the existing `could not check what /workspaces of … mounts; nothing removed` die with no restart behind it.
- [ ] **Step 4: Update the call-order test.** In `t_rm_container_clean`, the expected `calls` string moves the line `docker inspect -f {{range .Mounts}}…codeo-5` from after the second read to directly after `sbx ls` (before `docker ps -a --format {{.Names}} {{.State}}`). Nothing else in that string changes.
- [ ] **Step 5: Prove it.** Run: `bash tests/run.sh codeo-command`. Expected: `all cases passed`. Then `bash tests/run.sh`. Expected: `all cases passed`.
- [ ] **Step 6: Mutate.** Put the `workspace_mount` call back after `container_check` in a scratch edit and run `bash tests/run.sh codeo-command`. Expected: `t_rm_inspect_fails_no_restart` and `t_rm_container_clean` fail. `git checkout -- .devcontainer/codeo`, redo Step 3's edit if it was lost, rerun, `all cases passed`.
- [ ] **Step 7: Document it.** In `.devcontainer/README.md:178-182`: the check "asks `docker inspect` what is mounted at `/workspaces` first (it works on a stopped container), then reads the repository; when `docker inspect` fails and `--force` is not given, the container is read once, not restarted, and nothing is removed, so no shell or agent is ended for a refusal". Replace the sentence "Before it removes anything, `codeo` asks `docker inspect` …" accordingly and add: "A refusal after the restart can still come from the second read, a failed restart or a failed `docker rm`."
- [ ] **Step 8: Commit** with `fix: codeo rm checks what /workspaces mounts before it restarts the container (#149)`.

**Proof of done:** `bash tests/run.sh codeo-command` prints `all cases passed`, and `bash tests/run.sh` prints `all cases passed`.

---

### Task 3: The `--force` hint follows the sandbox's state (F13)

**Files:**
- Modify: `tests/codeo-command.test.sh` (`t_rm_sandbox_hints` sets `sbx_out`; new `t_rm_sandbox_force_gone`; one case with the failing `sbx_down_stub`)
- Modify: `.devcontainer/codeo` (`sbx_has`, `host_kinds`, `cmd_rm`)

**Interfaces:**
- Consumes: `sbx_prog`, `sbx_down_stub` (the test stub that makes `sbx` exit 1).
- Produces: `sbx_has <name> <listing>`: status 0 when a row's first column is exactly `<name>`; Task 4's prose describes the rule.

- [ ] **Step 1: Write the failing tests.** `t_rm_sandbox_force_gone`: three cases with `echo 1 >"$cm_dir/status"`, `printf 'NAME AGENT STATUS\n' >"$cm_dir/sbx_out"` (no row for `codeo-5`) and `cm_run rm 5 --sandbox --force`, with `stderr_text` set to (a) `codeo-sandbox: no sandbox codeo-5`, (b) `codeo-sandbox: removed codeo-5, but could not set aside its refs under refs/sandboxes/codeo-5/ in ./codeo-5`, (c) `codeo-sandbox: removed codeo-5, but could not delete its refs under refs/sandboxes/codeo-5/ in ./codeo-5`. Each asserts exit 1, the script's own line replayed, and `! grep -q '^codeo: to remove it anyway' <<<"$cm_err"`. A fourth case: `sbx_out` has the row `x codeo-5 running` (`codeo-5` in the second column) and no row for it in the first: still no hint. Two cases where the hint must stay: `sbx_out` lists `codeo-5 claude running`, and `sbx_down_stub` (`sbx ls` fails): `$cm_err` has the line `codeo: to remove it anyway, discarding whatever it holds: sbx rm --force codeo-5`. In `t_rm_sandbox_hints`, the cases that expect the hint with `--force` now set `sbx_out` to list `codeo-5` (or `codeo-1` for the `rm 1` case), since the sandbox must still be listed.
- [ ] **Step 2: Run them and see them fail.** Run: `bash tests/run.sh codeo-command`. Expected: `t_rm_sandbox_force_gone` fails on cases (a)-(d), because `codeo` prints the hint after every failure that does not itself name the command.
- [ ] **Step 3: Add the helper and use it.** `sbx_has <name> <listing>` returns 0 when some line's first whitespace-separated word equals `<name>` (the loop `while read -r row _; … [[ "$row" == "$name" ]]` from `host_kinds`). `host_kinds` calls it in place of its inline loop. In `cmd_rm`'s `elif ! grep -qE "rm --force codeo-$n…" "$errf"` branch, print the hint only when `sbx=$(sbx_prog)` fails, or `listing=$("$sbx" ls 2>&1)` fails, or `sbx_has "codeo-$n" "$listing"` is true. A comment says why: after a failed `end --force`, a sandbox that is no longer listed has nothing left to remove. A successful `rm` and a refusal without `--force` make no extra call.
- [ ] **Step 4: Prove it.** Run: `bash tests/run.sh codeo-command`. Expected: `all cases passed`, including every `host_kinds` test. Then `bash tests/run.sh`. Expected: `all cases passed`.
- [ ] **Step 5: Mutate.** Revert the `sbx_has` condition so the hint prints unconditionally, in a scratch edit, and run `bash tests/run.sh codeo-command`. Expected: `t_rm_sandbox_force_gone` fails. `git checkout -- .devcontainer/codeo`, redo Step 3 if lost, rerun, `all cases passed`.
- [ ] **Step 6: Commit** with `fix: codeo rm --force does not advise removing a sandbox that is already gone (#149)`.

**Proof of done:** `bash tests/run.sh codeo-command` prints `all cases passed`, and `bash tests/run.sh` prints `all cases passed`.

---

### Task 4: The prose that describes the code (F12, F15, F16, F9)

**Files:**
- Modify: `tests/codeo-command.test.sh` (`t_help_lists_commands`)
- Modify: `.devcontainer/codeo` (the comment at `:561-562`; one line in `cmd_help`)
- Modify: `.devcontainer/README.md` (`:98`, `:186-200`, `:202`)
- Modify: `.sbx/README.md` (`:49`, `:78`)

**Interfaces:**
- Consumes: the behaviour from Tasks 1-3.
- Produces: nothing a later task uses.

- [ ] **Step 1: Write the failing test.** In `t_help_lists_commands`, assert `grep -qF 'exits 1' <<<"$cm_out"` and `grep -qF 'warns on stderr' <<<"$cm_out"`.
- [ ] **Step 2: Run it and see it fail.** Run: `bash tests/run.sh codeo-command`. Expected: `t_help_lists_commands` fails, `help does not say a failed listing warns and exits 1` (or the assertion's own message).
- [ ] **Step 3: The help text (F16).** In `cmd_help`, after the command list and before the PATH note, print one line: `codeo list prints what it can; when docker or sbx fails to list it warns on stderr and exits 1.` (the `usage` text is not changed: its lines are a table the tests pin.)
- [ ] **Step 4: The comment (F12).** The comment at `.devcontainer/codeo:561-562` ("every other refusal is a `codeo-sandbox:` line on stderr, and --force would not get past it") becomes: every other refusal is a `codeo-sandbox:` line on stderr and gets no hint, because most of them name their own remedy or one that does not need `--force`; `--force` passes only the no-branches refusal.
- [ ] **Step 5: `.devcontainer/README.md:98` (F15).** The sentence "`codeo` stops with one line …" says which commands it covers: every command that reads the home directory (`home`, `issue`, `shell`, `list`, `default`, `update`, and `rm` or `open` of a sandbox); `help`, a usage error and `rm` of a container never read it, so they go ahead. Before writing it, check the list against `grep -n 'home_dir\|ensure_home' .devcontainer/codeo`; the grep, not this sentence, is the source.
- [ ] **Step 6: `.devcontainer/README.md:202` (F12, F13).** Rewrite the sandbox paragraph: the script's own `codeo-sandbox: ` line says what went wrong and, where a command applies, names it (`sbx rm --force codeo-<N>` when nothing in the sandbox could be read, `end <N> --force` when the fetch left no branches); the refusals for a missing clone, a failed `git fetch origin`, the pull-request heads, listing the commits or checking for uncommitted work name no command, and the remedy is to fix what failed and run it again. With `--force`, `codeo` adds `to remove it anyway, discarding whatever it holds: sbx rm --force codeo-<N>` only when `sbx ls` still lists `codeo-<N>` (or cannot list) and the script's own message does not already name it; after `no sandbox codeo-<N>` or `removed codeo-<N>, but could not … its refs` it adds nothing.
- [ ] **Step 7: `.sbx/README.md`.** At `:78`, the same `--force` hint rule (replace "left out when the script already named that command" with "left out when the script already named that command or `sbx ls` no longer lists the sandbox"). At `:49`, after the `codeo list` description, add: when `sbx` fails to list, `codeo list` warns on stderr, still prints what the other program shows, and exits 1 (the full rule is in `.devcontainer/README.md`).
- [ ] **Step 8: The flowchart (F9).** Replace the `mermaid` block under *Removing a finished container* with this draft, checking each edge against `cmd_rm` and `container_check` as they stand after Task 2 and correcting the diagram, not the code:

  ```mermaid
  flowchart TD
      A["codeo rm N, container"] --> M["docker inspect: what is mounted at /workspaces"]
      M --> B["start if stopped; fetch --prune origin; fetch pull-request heads"]
      B -- "no such container" --> N0["no --force: refuse, nothing removed; --force: remove the volume and image anyway"]
      B --> C{"read: status --untracked-files=normal, stash, detached HEAD, unpushed"}
      C -- "dirty" --> R["no --force: refuse; --force: say what is not kept, then remove"]
      C -- "cannot run" --> X["no --force: refuse, nothing removed; --force: remove anyway"]
      C -- "clean, started by codeo" --> F
      C -- "clean, was running, inspect failed, no --force" --> X
      C -- "clean, was running" --> D["docker restart: ends attached shells and agents"]
      D -- "restart failed" --> X
      D --> E{"read again, no fetch"}
      E -- "dirty" --> R
      E -- "clean" --> F{"/workspaces is volume codeo-N?"}
      F -- "yes, or --force" --> G["docker rm -f, volume rm, docker rmi"]
      F -- "no, no --force" --> H["remove container and image, keep the volume, say so"]
      G --> Z["last line: what was removed; or nothing named codeo-N to remove"]
      H --> Z
      R --> F
      X --> F
  ```

  The `R --> F` and `X --> F` edges stand for "with `--force`, the removal goes on"; where the drawn edge says otherwise, the README prose is right and the diagram changes. No renderer is installed here, so read it as Mermaid syntax by eye: every label is quoted, every node id is defined once.
- [ ] **Step 9: Prove it.** Run: `bash tests/run.sh codeo-command`. Expected: `all cases passed`. Then: `grep -c 'sbx ls' .devcontainer/README.md` prints `1` or more, `grep -c 'exits 1' .sbx/README.md` prints `1` or more, `grep -n 'says what to do then' .devcontainer/README.md` prints nothing. Then `bash tests/run.sh`. Expected: `all cases passed`.
- [ ] **Step 10: Commit** with `docs: codeo rm's READMEs, help text and flowchart say what the code does (#149)`.

**Proof of done:** `bash tests/run.sh codeo-command` prints `all cases passed`, `grep -n 'says what to do then' .devcontainer/README.md` prints nothing, and `bash tests/run.sh` prints `all cases passed`.

---

### Task 5: The overlap sentences sit after "The step stops until it is answered" (#144 F4)

**Files:**
- Modify: `tests/implement-skill.test.sh`, `tests/close-skill.test.sh` (one ordering assertion each)
- Modify: `skills/implement/SKILL.md:84-92`, `skills/close/SKILL.md:216-226`

**Interfaces:**
- Consumes: the order `skills/qc/SKILL.md:92-102` already has.
- Produces: nothing a later task uses (Task 7 rewords the moved sentence).

- [ ] **Step 1: Write the failing assertions.** In each test file add `must_precede <case> <first> <second>`: it joins `$skill`'s lines with single spaces and fails unless `<first>` occurs and its offset is lower than `<second>`'s (`awk 'BEGIN{…}'` or `grep -ob`). Assert `The step stops until it is answered` precedes `A non-zero exit, with an` in both files.
- [ ] **Step 2: Run them and see them fail.** Run: `bash tests/run.sh implement-skill`, `bash tests/run.sh close-skill`. Expected: one `FAIL:` each, naming the order.
- [ ] **Step 3: Move the sentences.** In `skills/implement/SKILL.md` the text becomes "… and the same three options — *proceed and coordinate* · *sequence after #M* · *re-scope*. The step stops until it is answered, as at step 4. A non-zero exit, with an … is a stop to report, never "no overlap". An `overlap: skipping #<M>'s changed paths` warning with exit 0 is quoted to the engineer, and the step carries on with that workflow's footprint alone." In `skills/close/SKILL.md`: "… *re-scope*. The step stops until it is answered: append this invocation's `## Log` line with its cost, commit `close.md`, staged by name, with the subject `docs(codeo): close dossier for #<N> — Q<a>-Q<b> raised`, push, print the path and the open numbers, and end the turn. A non-zero exit, with an … alone." Same words, new order; keep each file's wrap width.
- [ ] **Step 4: Prove it.** Run: `bash tests/run.sh implement-skill`, `bash tests/run.sh close-skill`, `bash tests/run.sh overlap-stop`, `bash tests/run.sh skills`. Expected: each `all cases passed` (the stop-sentence counts are unchanged, since the test flattens line breaks).
- [ ] **Step 5: Commit** with `docs: the overlap sentences follow the stop, as in qc (#149)`.

**Proof of done:** `bash tests/run.sh implement-skill`, `close-skill`, `overlap-stop` and `skills` each print `all cases passed`.

---

### Task 6: Either TODO case ends the turn (#144 F5a)

**Files:**
- Modify: `tests/init-skill.test.sh`
- Modify: `skills/init/SKILL.md:350-353`
- Check: `docs/handoff.md`'s init rows (edit only if they disagree)

**Interfaces:**
- Consumes: `step_contains <case> <n> <string>` in `tests/init-skill.test.sh`.
- Produces: nothing a later task uses.

- [ ] **Step 1: Write the failing assertion.** `step_contains "either TODO case ends the turn" 11 'Either way, end the turn with the block for the case and do not invoke '` followed by the rest of the sentence below, as one fixed string.
- [ ] **Step 2: Run it and see it fail.** Run: `bash tests/run.sh init-skill`. Expected: one `FAIL:` naming `either TODO case ends the turn`.
- [ ] **Step 3: Reword.** The sentence "With no lock, end the turn with this paragraph's block and do not hand off to `/codeo:plan`:" becomes "Either way, end the turn with the block for the case and do not invoke `/codeo:plan` in this turn; with the lock taken, the block names `/codeo:plan` as the step after the fix:". The two `**Closing block — …**` paragraphs keep their text.
- [ ] **Step 4: Check the others.** Run `bash tests/run.sh closing-exits`, `bash tests/run.sh skills` and `grep -n 'lock taken' docs/handoff.md`; the handoff row for the lock-taken TODO must say the same (init ends the turn and `/codeo:plan` is the second step). Edit it only if it does not.
- [ ] **Step 5: Prove it.** Run: `bash tests/run.sh init-skill`, `bash tests/run.sh closing-exits`, `bash tests/run.sh skills`. Expected: each `all cases passed`.
- [ ] **Step 6: Commit** with `docs: init ends the turn after a TODO whether or not the lock was taken (#149)`.

**Proof of done:** `bash tests/run.sh init-skill`, `closing-exits` and `skills` each print `all cases passed`.

---

### Task 7: The stop rule names a non-zero exit with neither line (#144 F5b)

**Files:**
- Modify: `tests/overlap-stop.test.sh:17`
- Modify: `skills/plan/SKILL.md` (two places, near `:306` and `:317`), `skills/implement/SKILL.md`, `skills/qc/SKILL.md` (two places, near `:100` and `:171`), `skills/close/SKILL.md`, `docs/handoff.md` (the footprint bullet)

**Interfaces:**
- Consumes: the seven places `tests/overlap-stop.test.sh`'s table counts (2, 1, 2, 1, 1).
- Produces: the new wording.

- [ ] **Step 1: Write the failing test.** Change `STOP` in `tests/overlap-stop.test.sh` to ``A non-zero exit, with or without an `overlap: cannot diff …` or `overlap: cannot resolve …` line, is a stop to report, never "no overlap".``
- [ ] **Step 2: Run it and see it fail.** Run: `bash tests/run.sh overlap-stop`. Expected: five `FAIL:` lines for STOP (`skills/plan/SKILL.md` wanted 2, found 0, and so on), exit 1.
- [ ] **Step 3: Reword the seven sentences**, each by hand because each wraps differently; the words are the new `STOP`, and the handoff bullet keeps its present tense ("A non-zero exit, with or without … line, is a stop"; if the handoff wording differs from the skills', change it to the same string).
- [ ] **Step 4: Prove it.** Run: `bash tests/run.sh overlap-stop`, `bash tests/run.sh skills`, then `bash tests/run.sh`. Expected: each `all cases passed`.
- [ ] **Step 5: Commit** with `docs: a non-zero overlap.sh exit is a stop whether or not it printed a line (#149)`.

**Proof of done:** `bash tests/run.sh overlap-stop` prints `all cases passed`, and `bash tests/run.sh` prints `all cases passed`.

---

### Task 8: Pin `qc-verdict.sh:134` and `inflight.sh:209`'s trailing-space direction (#144 F3, F5c)

**Files:**
- Modify: `tests/outcome-heading.test.sh`

**Interfaces:**
- Consumes: `new_repo`, `qc_with`, `crlf`, `plugin`, `stub_bin`, `inflight_with` and `waits_is` (all in the file).
- Produces: an eighth reader, `qc_verdict_replan`, in the `readers` array.

- [ ] **Step 1: Record the gap.** Run the F5c mutation: in `scripts/inflight.sh:209` change `/^## Outcome[[:space:]]*$/` to `/^## Outcome$/` and run `bash tests/run.sh outcome-heading`. Expected today: `all cases passed` (the test does not notice). Run the F3 mutation: in `scripts/qc-verdict.sh:134`, the `plan_round` awk's `/^## Outcome[[:space:]]*$/`, change it to `/^## Outcome/` and run the same command. Expected today: `all cases passed`. Revert both with `git checkout -- scripts`. These two results go in `implement.md` as the evidence the gap was real.
- [ ] **Step 2: F5c, vary `close.md` alone.** `recognised_by_inflight_send_back` calls `inflight_with "## Outcome" "$1"` (qc exact, close varied) instead of `"$1" "$1"`; its comment says so, and that `recognised_by_inflight_qc_round` varies `qc.md` alone, so each of lines 180/209/224 has a reader that can fail on its own. The expectation is unchanged (`waits_is … /codeo:implement` when unread).
- [ ] **Step 3: F3, the eighth reader.** `recognised_by_qc_verdict_replan <heading>`: `new_repo`; `git commit` a base; on top, add `a.txt`, `b.txt`, `.codeo/config.json` (`{"schema":1,"repo":{"owner":"o","name":"n"},"baseBranch":"main"}`), `.codeo/done/7/qc.md` (`qc_with '## Outcome'`, the fixture, clear) and `.codeo/done/7/plan.md` holding `## Outcome` replaced by `$1` (the carriage return added to that one line only when `crlf` is set, so the footprint block still parses), then `First planning round.`, `### Round 2 — 2026-09-02`, `Re-planned.`, and a `### Footprint` fence with `files:      b.txt`, `wiki:       none`, `exclusive:  none`, `sequenced:  none`; commit; run `qc-verdict.sh "$base" HEAD` from the repo with `PATH="$stub_bin:$PATH"`. Recognised (status 0) when the output contains `round 2 footprint omits: a.txt`; not recognised (1) otherwise. Add `qc_verdict_replan` to `readers`.
- [ ] **Step 4: Prove it.** Run: `bash tests/run.sh outcome-heading`. Expected: `all cases passed`, with the six heading variants each checked by eight readers that must agree.
- [ ] **Step 5: Mutate again.** Redo Step 1's two mutations. Expected: each now fails `bash tests/run.sh outcome-heading`, the F5c one on the `## Outcome with trailing spaces` variant for `inflight_send_back` and the F3 one on `## Outcomes`, `## Outcome notes` or `## Outcome:` for `qc_verdict_replan` (a re-planned archive wrongly read as round 2). Revert both with `git checkout -- scripts`; rerun, `all cases passed`.
- [ ] **Step 6: Commit** with `test: pin qc-verdict.sh's plan round and inflight.sh's close.md reader apart (#149)`.

**Proof of done:** `bash tests/run.sh outcome-heading` prints `all cases passed` on the unmutated tree and fails under each of the two mutations in Step 5.

---

### Task 9: The CHANGELOG

**Files:**
- Modify: `CHANGELOG.md` (one bullet under `## Unreleased`, after the existing ones, in the file's present-tense style)

**Interfaces:**
- Consumes: the changes above.
- Produces: nothing.

- [ ] **Step 1: Write the bullet.** One bullet, `(#149)` at its end: `codeo rm` makes a relative `CODEO_HOME` absolute, so it works for a sandbox; checks what `/workspaces` mounts before it restarts a container, so a refusal for a failed `docker inspect` no longer ends sessions first; and after a failed `rm --force` of a sandbox prints the `sbx rm --force` hint only when `sbx ls` still lists it. The READMEs and `codeo help` agree with the code on the script's own messages, the home-directory stop and a failed listing; the overlap sentences in `skills/implement` and `skills/close` follow the stop, init ends the turn after either TODO, a non-zero `overlap.sh` exit is a stop with or without a line, and `tests/outcome-heading.test.sh` pins `qc-verdict.sh`'s plan round and `inflight.sh`'s `close.md` reader.
- [ ] **Step 2: Prove it.** Run: `grep -c '(#149)' CHANGELOG.md`. Expected: `1`. Then `bash tests/run.sh`. Expected: `all cases passed`.
- [ ] **Step 3: Commit** with `docs: changelog entry for #149`.

**Proof of done:** `grep -c '(#149)' CHANGELOG.md` prints `1`, and `bash tests/run.sh` prints `all cases passed`.

---

## Acceptance map

| Criterion (`init.md`) | Task |
|---|---|
| With `--force`, none of the three outputs is followed by the hint; a test fails if it returns | 3 |
| `CODEO_HOME=rel codeo rm <N> --sandbox` completes; a test covers it | 1 |
| A refusal without `--force` does not restart first | 2 |
| No README or help sentence contradicts the code (F12, F15, F16); the flowchart matches | 4 |
| The two skill sentences sit after "The step stops until it is answered" | 5 |
| `qc-verdict.sh:134` is pinned; each F5 item is done or dismissed in writing | 8 (F3, F5c), 6 (F5a), 7 (F5b); F5d dismissed under Global Constraints |
| `bash tests/run.sh` ends `all cases passed` | every task's last step |
