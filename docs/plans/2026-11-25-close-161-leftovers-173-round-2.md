# Close the #161 leftovers (#173), round 2 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Clear the findings of `/codeo:qc` round 1: the stop-failure line is printed only when `codeo rm` refuses, the corrected v1.0.8 `Shared state:` line is true of every read in `dossier-check.sh`, and the pages name what round 1 left out.

**Architecture:** One small code change, test-first: `stop_started` reports a failed stop only when its caller will refuse, which `cmd_rm` tells `container_check` with a third argument under `--force`. Whether the container is stopped does not change. The rest is wording, each sentence checked against the code or the tag before it is written.

**Tech Stack:** bash, the repository's `tests/*.test.sh` harness (`bash tests/run.sh`), Markdown.

**Spec:** `.codeo/173/qc.md` (`## Outcome`, round 1: findings F1-F7), `.codeo/173/init.md` (the eight acceptance criteria) and round 1's plan, `docs/plans/2026-11-25-close-161-leftovers-173.md`, whose Global Constraints still bind.

## Global Constraints

- Round 1's plan is not edited; this plan adds to its work on the same branch.
- Out of scope, from the issue: redesigning the `codeo rm` check or its restart; removing the hook.
- `codeo rm` stops and starts exactly the containers it did before this round, `--force` included. Only whether the stop-failure line is printed changes.
- The line stays `codeo: could not stop codeo-<N> again; it is left running`, on stderr, and is printed only on a run that removes nothing (a refusal or a check that could not run, without `--force`).
- Released changelog sections are corrected in place; release notes and tags are not touched. `docs/updating.md` is named by the checklist and is not itself edited.
- No invariants document, no shared environment, no `wiki` module: no lease marker, every task runs in this checkout, and none runs on the engineer's host.
- Documentation the change moves: `.devcontainer/README.md` (Task 3), `CHANGELOG.md` (Task 2), `docs/release-checklist.md` (Task 4).
- Proof of done for every task is the `shell` suite, `bash tests/run.sh`, ending `all cases passed`. `bash tests/run.sh <pattern>` runs one file while iterating. Commit after each task, staging files by name.

## Decision: how the `--force` path stops printing a false line (F2)

| Option | What it does | Verdict |
|---|---|---|
| A. Gate the line | Under `--force` the container is still stopped as before; a failed stop prints nothing, since the removal follows | **Chosen.** Smallest change; no behaviour other than the new line moves |
| B. Skip the stop under `--force` | A container about to be removed is not stopped at all | Rejected: changes what `--force` does to a container when the later `docker rm -f` fails, which borders on the out-of-scope redesign |
| C. Reword the line | Drop "it is left running" so it is true on both paths | Rejected: the wording was chosen in round 1 (Q1) and is the useful half on a refusal |

## Review Focus

1. `--force` with a failing stop after a check that could not run, and after a dirty read: no line, and the removal still happens (Task 1).
2. `--force` still calls `docker stop` on a container `codeo` started: the stop itself is unchanged (Task 1).
3. Without `--force`, round 1's `t_rm_reports_a_failed_stop` still passes unedited (Task 1).

## File Structure

| File | Change |
|---|---|
| `.devcontainer/codeo` | `stop_started` takes a quiet argument; `container_check` passes it on; `cmd_rm` sets it under `--force`; one header comment |
| `tests/codeo-command.test.sh` | one new case |
| `CHANGELOG.md` | the v1.0.8 `Shared state:` clause; one `## Unreleased` bullet |
| `.devcontainer/README.md` | one sentence in the "A refusal removes nothing" paragraph |
| `.claude/hooks/session-start.sh` | one header comment line |
| `docs/release-checklist.md` | step 6's three groups |

---

### Task 1: the stop-failure line is printed only on a refusal (F2, F6)

**Files:**
- Modify: `.devcontainer/codeo` (`stop_started` near `:475-482`, `container_check` near `:513-551`, its call in `cmd_rm` near `:642`)
- Test: `tests/codeo-command.test.sh` (after `t_rm_reports_a_failed_stop`; the `cases` list)

**Interfaces:**
- Produces: `container_check <N> [--no-restart] [--quiet-stop]` and `stop_started <name> <started> [quiet]`. `cmd_rm` calls `container_check "$n" "$no_restart" ${force:+--quiet-stop}`.

- [ ] **Step 1: Write the failing test** `t_rm_force_does_not_report_a_failed_stop`, and add it to `cases` after `t_rm_reports_a_failed_stop`. The `stop_fail` stub file already exists in `rm_stubs`.

```bash
t_rm_force_does_not_report_a_failed_stop() {
    # the check cannot run, the stop fails, --force removes anyway
    cm_setup "$current"
    rm_stubs
    echo exited >"$cm_dir/dstate"
    touch "$cm_dir/prfetch_fail" "$cm_dir/stop_fail"
    cm_run rm 5 --force --container
    [[ "$cm_status" -eq 0 ]] || fail "cannot-check: exit $cm_status, err: $cm_err"
    grep -q '^docker stop codeo-5' "$cm_dir/calls" || fail "cannot-check: stop no longer called"
    grep -q '^docker rm -f codeo-5' "$cm_dir/calls" || fail "cannot-check: not removed"
    ! grep -qF 'could not stop' <<<"$cm_err" || fail "cannot-check: $cm_err"
    grep -qF -- '--force: could not check codeo-5 for unsaved work; removing anyway' <<<"$cm_out" || fail "cannot-check: stdout: $cm_out"
    # a dirty read, the stop fails, --force removes anyway
    cm_setup "$current-2"
    rm_stubs
    echo exited >"$cm_dir/dstate"
    touch "$cm_dir/stop_fail"
    printf 'abc1234\n' >"$cm_dir/g_rev-list"
    cm_run rm 5 --force
    [[ "$cm_status" -eq 0 ]] || fail "dirty: exit $cm_status, err: $cm_err"
    grep -q '^docker stop codeo-5' "$cm_dir/calls" || fail "dirty: stop no longer called"
    grep -q '^docker rm -f codeo-5' "$cm_dir/calls" || fail "dirty: not removed"
    ! grep -qF 'could not stop' <<<"$cm_err" || fail "dirty: $cm_err"
}
```

- [ ] **Step 2: Run it and see it fail.**

Run: `bash tests/run.sh codeo-command`
Expected: `=== FAIL: codeo-command.test.sh`, naming `t_rm_force_does_not_report_a_failed_stop` with `cannot-check: codeo: could not stop codeo-5 again; it is left running`.

- [ ] **Step 3: Gate the line.** `stop_started <name> <started> [quiet]` stops as it does now and prints the line only when the third argument is empty. `container_check` passes a non-empty third argument to each of its three `stop_started` calls when its own third argument is `--quiet-stop`. `cmd_rm` calls `container_check "$n" "$no_restart" ${force:+--quiet-stop}`. Nothing else in `container_check` reads the new argument: which containers are stopped, started and restarted is unchanged.

- [ ] **Step 4: The comments.** Above `stop_started`: "…a failing stop is reported on stderr unless `quiet` is given (the caller is about to remove the container), and changes nothing else". In the `container_check` header, name the new argument in the signature line and replace the sentence that ends with two parentheses in a row with: "When it returns non-zero it stops again a container it knows it started, and reports a stop that fails unless `--quiet-stop` is given; after a failed restart it stops nothing, because the state is then unknown." Keep comment lines within 120 columns.

- [ ] **Step 5: Proof of done.**

Run: `bash tests/run.sh`
Expected: last line `all cases passed` (round 1's `t_rm_reports_a_failed_stop` passes unedited).

- [ ] **Step 6: Commit.**

```bash
git add .devcontainer/codeo tests/codeo-command.test.sh
git commit -m "fix(codeo): codeo rm --force no longer says a container it removes is left running (#173)"
```

---

### Task 2: `CHANGELOG.md` (F1, and Task 1's bullet)

**Files:**
- Modify: `CHANGELOG.md` (the `Shared state:` line under `## v1.0.8`; the first `(#173)` bullet under `## Unreleased`)

- [ ] **Step 1: Confirm each read of `dossier-check.sh` against the tags.**

Run, one at a time:
`git show v1.0.7:scripts/dossier-check.sh | grep -nF 'index($3, name " ") == 1'`
`git show v1.0.7:scripts/dossier-check.sh | grep -nF '/^## Outcome/ {'`
`git show v1.0.8:scripts/dossier-check.sh | grep -nF 'name != "Outcome"'`
`git show v1.0.8:scripts/dossier-check.sh | grep -nF '/^## Outcome[[:space:]]*$/ {'`
Expected: exactly one line each (near `:131`, `:479`, `:133`, `:481`). The first is `section_range`, which at v1.0.7 matched the heading or the heading plus a space; the second is `last_round_clear`, behind the `finished-qc-clear` check, which matched the prefix. If any prints nothing, stop and report.

- [ ] **Step 2: The v1.0.8 `Shared state:` line.** Replace the clause "`scripts/inflight.sh` and `scripts/qc-verdict.sh` match `## Outcome` exactly, so `## Outcomes` and `## Outcome notes` no longer count there, and `scripts/dossier-check.sh` does too, where `## Outcomes` never counted and `## Outcome notes` no longer does" with: "`scripts/inflight.sh` and `scripts/qc-verdict.sh` match `## Outcome` exactly, so `## Outcomes` and `## Outcome notes` no longer count there; `scripts/dossier-check.sh` does too: its section reads never counted `## Outcomes` and no longer count `## Outcome notes`, and its `finished-qc-clear` read of `qc.md` no longer counts either". The rest of the line stays.

- [ ] **Step 3: The `## Unreleased` stop bullet.** After its first sentence, which ends "it is left running`.", add: "A `--force` removal prints no such line." The rest of the bullet stays.

- [ ] **Step 4: Proof of done.**

Run: `bash tests/run.sh`
Expected: last line `all cases passed`.

- [ ] **Step 5: Commit.**

```bash
git add CHANGELOG.md
git commit -m "docs: the v1.0.8 Shared state line names each read of dossier-check.sh (#173)"
```

---

### Task 3: the README sentence and the hook comment (F4, F5)

**Files:**
- Modify: `.devcontainer/README.md` (the paragraph that begins "A refusal removes nothing and names `codeo rm <N> --force`", near `:199`); `.claude/hooks/session-start.sh` (header comment, line 4)

**Interfaces:**
- Consumes: Task 1's behaviour (the line only without `--force`).

- [ ] **Step 1: The README.** After the paragraph's second sentence (the one ending "says how to remove the container by hand."), add: "In both cases a container `codeo` knows it started is stopped again first, and when that `docker stop` fails `codeo` prints `codeo: could not stop codeo-<N> again; it is left running`." After the sentence about `--force` ("…removes also when the check cannot run, saying so."), add: "It prints no stop-failure line, because the container is removed." Check both against `container_check` and `cmd_rm` in `.devcontainer/codeo` before writing; the existing sentence about the stop in the `docker inspect` paragraph stays.

- [ ] **Step 2: The hook comment.** Replace the comment's clause "read from `claude plugin list --json` as install.sh reads it." with "read from `claude plugin list --json`, parsed as install.sh parses it; any enabled `superpowers@*` entry counts." Keep each comment line within 100 columns (re-wrap the comment if needed); no code line changes.

- [ ] **Step 3: Proof of done.**

Run: `bash tests/run.sh`
Expected: last line `all cases passed`.

- [ ] **Step 4: Commit.**

```bash
git add .devcontainer/README.md .claude/hooks/session-start.sh
git commit -m "docs: say where codeo rm prints the stop-failure line, and what the hook's skip check counts (#173)"
```

---

### Task 4: release checklist step 6 names `docs/updating.md` and the refused stub (F3, F7)

**Files:**
- Modify: `docs/release-checklist.md` (step 6's three bullets, near `:74-83`)

- [ ] **Step 1: Confirm the roles in `docs/updating.md`.**

Run: `grep -n "v1\.0\.[0-9]" docs/updating.md`
Expected: `v1.0.9` as the latest release (the `install: release` and `done` lines and the right side of `codeo v1.0.8 -> v1.0.9` in the update and replace transcripts, and the `is installed at project scope` example), and `v1.0.8` as the release before it (the left side of those lines, the downgrade's target with its `release v1.0.8`, `v1.0.9 -> v1.0.8` and `done` lines, and the `is no longer installed … v1.0.8` lines). A version in another role goes in the group its role belongs to; say so in the commit message.

- [ ] **Step 2: Extend the bullets.**
  - **move to the release being cut:** append "; in `docs/updating.md`, every version that stands for the latest release";
  - **move to the release before it:** append "; in `docs/updating.md`, every version that stands for the release before it (the installed side of the update transcripts, the downgrade's target and the dropped-install lines)";
  - **do not move:** add `v1.0.9;x` to the list of stubs, as a refused value that stays refused whatever the release.

  Keep the list's indentation and the wrap near 100 columns.

- [ ] **Step 3: Proof of done.**

Run: `bash tests/run.sh`
Expected: last line `all cases passed`.

- [ ] **Step 4: Commit.**

```bash
git add docs/release-checklist.md
git commit -m "docs: release checklist step 6 names docs/updating.md and the refused stub (#173)"
```

---

### Task 5: the whole suite and the findings

**Files:** none changed, unless a check below fails.

- [ ] **Step 1: Run the suite on the finished branch.**

Run: `bash tests/run.sh`
Expected: last line `all cases passed`.

- [ ] **Step 2: Check each finding of `.codeo/173/qc.md` round 1 against the diff since `3ecff84`:** F1 (Task 2 Step 2), F2 (Task 1), F3 and F7 (Task 4), F4 and F5 (Task 3), F6 (Task 1 Step 4).

Run: `grep -c "could not stop" .devcontainer/README.md CHANGELOG.md`
Expected: `.devcontainer/README.md:2` and `CHANGELOG.md:1` (the count is of lines; it was `1` and `1` before this round), each occurrence quoting the line exactly as `.devcontainer/codeo` prints it.
