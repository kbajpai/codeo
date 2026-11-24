# Live-session signal leftovers from #138 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A web session's live signal can no longer abort `live.sh fetch`, keeps one label for the life of a checkout, stops triggering CI, and its leftover `codeo-live/<issue>/*` branches are removed by `/codeo:close` or named by `/codeo:cleanup`.

**Architecture:** `scripts/live.sh` fetches the web branches into their own local namespace, `refs/codeo/live-web/*`, and `list` reads both namespaces (F22). A web beat reuses the label saved in `<git dir>/codeo-live-machine` (F25) and puts `[skip ci]` in its commit subject (F23). A new verb `live.sh sweep` deletes the issue's `codeo-live/<issue>/*` branches on origin, and `/codeo:close` runs it with `clear`. `scripts/cleanup.sh` prints a delete command for a proven issue's leftovers. What a web session writes on origin does not change.

**Tech Stack:** bash 4.3+, git, the `shell` suite (`bash tests/run.sh`).

**Spec:** the issue's acceptance criteria (`.codeo/157/init.md`) and Q1-Q3 of `.codeo/157/plan.md`, which chose A in each. No reference doc: nothing here is a standing decision.

## Global Constraints

- No invariants document is configured, so there is no invariant check to make.
- No shared environment is configured: no task carries `Needs lease:`, and every task is proved in this checkout.
- Out of scope, as the issue says: F24 (`timeout 8` around `lock.sh take web`) and which ref namespace a web session writes (`refs/heads/codeo-live/<issue>/<machine>` stays).
- `live.sh` exits 0 whatever happens and a failure is one `live:` stderr line; `sweep` follows the same rule.
- A signal carries no email address and no field `list` does not already read; the new `[skip ci]` goes in the subject line only.
- The cleanup skill prints only what `scripts/cleanup.sh` printed and never runs a container or git-delete command itself (rules cleanup-03, cleanup-04); the delete command is built in the script.
- Pages that move: `docs/handoff.md` ("Who is working right now" and its sequence diagram), the header comment of `scripts/live.sh`, `skills/close/SKILL.md`, `skills/cleanup/SKILL.md`, `docs/skills.md` (the `close` and `cleanup` paragraphs), `CHANGELOG.md` (`## Unreleased`). Each is task 7's, except the two skills, which tasks 5 and 6 edit with their pins.
- The `shell` suite has no single-test filter. A task's proof is `bash tests/run.sh <file pattern>`, which runs the test files whose name contains the pattern, then the whole `bash tests/run.sh` in the last task.

## Review Focus

- `sweep` for issue 10 must not delete `codeo-live/104/*` (a prefix match without the slash would): task 4 pins it.
- A branch on origin named with shell metacharacters (`codeo-live/7/x;touch-y`) must not reach a command `/codeo:cleanup` prints: task 6 pins it.
- `sweep` with an unreachable origin or a refused delete prints one `live:` line, exits 0 and the lock still goes: task 4 pins it.
- A saved label file that is empty or holds unsafe text is ignored, not used: task 2 pins it.
- A web session still beating after `/codeo:close` republishes its branch: stated in the docs (task 7), not prevented.

```mermaid
flowchart LR
    W[web session beat] -->|force-push, [skip ci]| B[(origin: codeo-live/N/web-xxxxxxxx)]
    B -->|fetch to refs/codeo/live-web/*| L[live.sh list]
    C[container or local signal] -->|refs/codeo/live/N/m| L2[(origin)] -->|fetch to refs/codeo/live/*| L
    CL[/codeo:close, not in a web session/] -->|live.sh sweep N| B
    CU[/codeo:cleanup, proven issue/] -->|prints git push origin --delete| B
```

## File Structure

- `scripts/live.sh` — fetch refspecs, `list` prefixes, label file, `[skip ci]` subject, new `sweep` verb, header comment.
- `scripts/cleanup.sh` — one `leftover` line per proven issue with `codeo-live/<N>/*` branches.
- `skills/close/SKILL.md` — step 16's command, and the stash and abandon sentences that point at it.
- `skills/cleanup/SKILL.md` — step 1 relays `leftover` lines.
- `docs/handoff.md`, `docs/skills.md`, `CHANGELOG.md` — the documentation.
- Tests: `tests/live.test.sh`, `tests/live-signal.test.sh`, `tests/close-skill.test.sh`, `tests/cleanup.test.sh`, `tests/cleanup-skill.test.sh`.

---

### Task 1: F22 — equal labels no longer abort `fetch`

**Files:**
- Modify: `scripts/live.sh` (`fetch` at `:206-211`, `list`'s `for-each-ref` at `:236`, header comment `:20-23`)
- Test: `tests/live.test.sh` (new cases under `# --- fetch and list ---`)

**Interfaces:**
- Produces: web branches arrive in clones as `refs/codeo/live-web/<issue>/<machine>`; `live.sh list` reads `refs/codeo/live/` and `refs/codeo/live-web/`. Task 4 and the docs rely on the namespace name.

- [ ] **Step 1: Write the failing tests** in `tests/live.test.sh`, using `new_world`, `clone_of`, `plant`, `signal`, `live`:
  - `fetch_survives_a_web_and_a_container_signal_with_equal_labels`: plant `refs/codeo/live/104/same` (`signal 104 alice same container <now>`) and `refs/heads/codeo-live/104/same` (`signal 104 bob same web <now>`) on origin; in `other=$(clone_of "$origin")`, `live "$other" fetch` exits 0 (assert `rc` through `|| rc=$?`), and `live "$other" list --tsv | cut -f1-4` contains both `104<TAB>alice<TAB>same<TAB>container` and `104<TAB>bob<TAB>same<TAB>web` (order is not asserted).
  - `fetch_prunes_a_web_copy_the_old_refspec_left_in_refs_codeo_live`: plant only `refs/heads/codeo-live/104/web-old`; in `other`, run `git fetch -q origin '+refs/heads/codeo-live/*:refs/codeo/live/*'` (what v1.0.8 did), then `live "$other" fetch`; `git -C "$other" for-each-ref refs/codeo/live/` prints nothing, and `list --tsv` still shows the row.
- [ ] **Step 2: Run** `bash tests/run.sh live.test`. Expected: FAIL, the first case with `Cannot fetch both` and exit 128.
- [ ] **Step 3: Implement.** `fetch` passes `'+refs/codeo/live/*:refs/codeo/live/*'` and `'+refs/heads/codeo-live/*:refs/codeo/live-web/*'`; `list` passes both `refs/codeo/live/` and `refs/codeo/live-web/` to `git for-each-ref`. Update the `fetch` and `list` lines of the header comment to name both namespaces.
- [ ] **Step 4: Run** `bash tests/run.sh live.test`. Expected: PASS (`all cases passed`), including the existing `fetch_maps_web_branches_to_signals`.
- [ ] **Step 5: Commit** `fix: fetch a web session's live branches into their own namespace (#157)`.

### Task 2: F25 — a web checkout keeps its first label

**Files:**
- Modify: `scripts/live.sh` (`machine_label` `:109-127`, `beat` `:161-194`, `clear` `:196-204`, header `Limits` and `machine` lines)
- Test: `tests/live.test.sh` (under `# --- web machine label and user ---`)

**Interfaces:**
- Produces: `label_file() -> path` (`git rev-parse --git-path codeo-live-machine`, like `stamp`). For a web host with `CODEO_MACHINE` unset, `machine_label` returns the saved label when the file holds a non-empty line that `ref_label` leaves unchanged; `beat` writes the label to the file before it pushes; `clear` removes the file with the stamp.

- [ ] **Step 1: Write the failing tests:**
  - `web_label_stays_when_the_session_id_changes`: `clone_with_lock 104 web abcdef0123456789`, `run beat --force`; rewrite the lock with `clone_with_lock 104 web 99999999aaaaaaaa`, `run beat --force`; `assert_eq "one branch" refs/heads/codeo-live/104/web-abcdef01 "$(heads)"`.
  - `web_clear_forgets_the_label`: after the case above, `run clear`, rewrite the lock to `99999999aaaaaaaa`, `run beat --force`; `heads` lists both `web-abcdef01` and `web-99999999`.
  - `codeo_machine_is_not_saved_as_the_web_label`: `CODEO_MACHINE=boxA run beat --force` with a web lock, then `run beat --force` without it: `heads` lists `104/boxA` and `104/web-abcdef01`.
  - `a_saved_label_with_unsafe_text_is_ignored`: write `a b;c` to the checkout's `codeo-live-machine` file, `run beat --force`: the branch is `web-abcdef01`.
- [ ] **Step 2: Run** `bash tests/run.sh live.test`. Expected: FAIL in `web_label_stays_when_the_session_id_changes` (two branches).
- [ ] **Step 3: Implement** the interface above. Only the web route reads or writes the file; container and local labels are unchanged.
- [ ] **Step 4: Run** `bash tests/run.sh live.test`. Expected: PASS.
- [ ] **Step 5: Commit** `fix: a web session keeps one live-signal label per checkout (#157)`.

### Task 3: F23 — the web signal does not trigger CI

**Files:**
- Modify: `scripts/live.sh` (`beat`'s `printf` at `:177`, header message format `:31-42`)
- Test: `tests/live.test.sh` (under `# --- web session ---`)

**Interfaces:**
- Produces: a web signal's subject is `codeo live signal [skip ci]`; every other host's stays `codeo live signal`. `list` reads fields by line prefix and is unchanged.

- [ ] **Step 1: Write the failing test** `web_signal_subject_says_skip_ci_and_others_do_not`: a web beat's `git -C "$origin" log -1 --format=%s refs/heads/codeo-live/104/web-abcdef01` equals `codeo live signal [skip ci]`; a container beat's subject on `refs/codeo/live/104/codeo-104` equals `codeo live signal`; `live "$other" list --tsv` after fetching both still lists both rows.
- [ ] **Step 2: Run** `bash tests/run.sh live.test`. Expected: FAIL, subject `codeo live signal`.
- [ ] **Step 3: Implement** the subject as a variable chosen by `$host` in `beat`; document it in the header's message format.
- [ ] **Step 4: Run** `bash tests/run.sh live.test`. Expected: PASS.
- [ ] **Step 5: Commit** `fix: mark the web live signal [skip ci] (#157)`.

### Task 4: F23 — `live.sh sweep` deletes an issue's web branches

**Files:**
- Modify: `scripts/live.sh` (new `sweep`, dispatch `case` at `:247`, usage line, header)
- Test: `tests/live.test.sh` (new `# --- sweep ---` section)

**Interfaces:**
- Produces: `live.sh sweep` — reads the lock like `clear` (`read_lock || return 0`), does nothing for a web host, lists `refs/heads/codeo-live/<issue>/*` on origin with `bounded git ls-remote --heads`, deletes them in one `bounded git push -q --no-verify origin --delete <refs…>`, and exits 0 whatever happens. No REST fallback. A failed listing or delete prints one `live: could not sweep — <last line>` to stderr. Task 5 calls it; task 6's docs describe it.

- [ ] **Step 1: Write the failing tests:**
  - `sweep_deletes_this_issues_web_branches_only`: container lock for 10; plant `refs/heads/codeo-live/10/web-a`, `…/10/web-b`, `…/104/web-c`, `…/11/web-d` and `refs/codeo/live/10/codeo-10` on origin; `run sweep`: `rc` 0, `heads` lists only `104/web-c` and `11/web-d`, and `refs` still lists `refs/codeo/live/10/codeo-10`.
  - `sweep_from_a_web_session_deletes_nothing`: web lock, plant `refs/heads/codeo-live/104/web-a`, `run sweep`: `rc` 0, the branch stays, `$err` empty.
  - `sweep_without_a_lock_deletes_nothing`.
  - `sweep_with_a_refused_delete_warns_once_and_exits_0`: a `pre-receive` hook as in `web_push_refused_warns_once_and_does_not_fall_back` but refusing deletions; `rc` 0, one `live: could not sweep` line.
  - `sweep_with_nothing_to_delete_is_quiet`.
- [ ] **Step 2: Run** `bash tests/run.sh live.test`. Expected: FAIL, the usage line and exit 1 for `sweep`.
- [ ] **Step 3: Implement** `sweep` as above; dispatch `sweep) sweep || true; exit 0 ;;`; add `sweep` to the usage line and the header (verb description, and the `Limits` bullet about a web signal being "never deleted" now reads: a web session cannot delete it; `sweep` from another session does).
- [ ] **Step 4: Run** `bash tests/run.sh live.test`. Expected: PASS.
- [ ] **Step 5: Commit** `feat: live.sh sweep removes an issue's codeo-live branches (#157)`.

### Task 5: `/codeo:close` sweeps with the signal clear

**Files:**
- Modify: `skills/close/SKILL.md` (step 16 at `:511-518`; the stash sentence at `:638-639`; the abandon sentence at `:680-681`)
- Test: `tests/close-skill.test.sh` (`:341-343`)

**Interfaces:**
- Consumes: `live.sh sweep` (task 4).

- [ ] **Step 1: Change the three pins first.** `step_contains … 16` expects `live.sh" clear; bash "${CLAUDE_PLUGIN_ROOT}/scripts/live.sh" sweep; rm -f .codeo/active`; the stash pin expects `with the signal cleared and its web branches swept`; the abandon pin the same in its sentence.
- [ ] **Step 2: Run** `bash tests/run.sh close-skill`. Expected: FAIL on the three pins.
- [ ] **Step 3: Edit the skill.** Step 16's command becomes `bash "${CLAUDE_PLUGIN_ROOT}/scripts/live.sh" clear; bash "${CLAUDE_PLUGIN_ROOT}/scripts/live.sh" sweep; rm -f .codeo/active`, with one added sentence: `sweep` deletes the issue's `codeo-live/<issue>/*` branches on origin, does nothing in a hosted web session (which cannot delete a branch), and when it fails prints one `live:` line and the lock still goes, as with `clear`. The stash and abandon sentences say "with the signal cleared and its web branches swept".
- [ ] **Step 4: Run** `bash tests/run.sh close-skill`. Expected: PASS.
- [ ] **Step 5: Commit** `fix: /codeo:close sweeps the web signal branches with the clear (#157)`.

### Task 6: `/codeo:cleanup` prints the leftovers' delete command

**Files:**
- Modify: `scripts/cleanup.sh` (header `:1-24`, the main loop `:95-111`), `skills/cleanup/SKILL.md` (step 1 and step 3)
- Test: `tests/cleanup.test.sh`, `tests/cleanup-skill.test.sh`

**Interfaces:**
- Produces: after the `proven` line of an issue, when `refs/remotes/origin/codeo-live/<N>/*` exist, one more line `<N><TAB>leftover<TAB>git push origin --delete codeo-live/<N>/<m> …`. Only proven issues get one; only names matching `^codeo-live/[0-9]+/[A-Za-z0-9._-]+$` for that `<N>` go into the command. No leftovers means no line, so existing output is unchanged.

- [ ] **Step 1: Write the failing tests** in `tests/cleanup.test.sh`, in the style of the case `all five proofs pass`:
  - `leftover_branches_of_a_proven_issue_are_printed_after_its_line`: push `codeo-live/7/web-a` and `codeo-live/7/web-b` to the scratch origin; the output has the `7<TAB>proven…` line followed by `7<TAB>leftover<TAB>git push origin --delete codeo-live/7/web-a codeo-live/7/web-b`.
  - `an_issue_that_failed_a_proof_gets_no_leftover_line`.
  - `a_leftover_branch_with_metacharacters_is_not_printed`: a branch `codeo-live/7/x;touch-y` is absent from the output while `web-a` is present.
  - `leftovers_of_another_issue_are_not_printed`: `codeo-live/70/web-z` does not appear for issue 7.
  In `tests/cleanup-skill.test.sh` add a pin that the skill names `leftover` and `git push origin --delete` as printed by the script (same `grep -qF … || check_fail` form as line 21).
- [ ] **Step 2: Run** `bash tests/run.sh cleanup`. Expected: FAIL in the four script cases and the pin.
- [ ] **Step 3: Implement** a `leftover_proof` beside `name_proof` that reads `git for-each-ref --format='%(refname:strip=3)' "refs/remotes/origin/codeo-live/$n/"` (from the refs the fetch already pruned, never `ls-remote`, as the branch proof says) and prints the line; call it after each `proven` case. Update the header's output list and the `only place a command is built` sentence. In the skill: step 1 adds a third list, **Leftover web signal branches**, each `leftover` line as printed, with the note that the command deletes remote branches and runs on the host; step 3's "the two lists" becomes "the lists".
- [ ] **Step 4: Run** `bash tests/run.sh cleanup`. Expected: PASS for `cleanup.test.sh` and `cleanup-skill.test.sh`.
- [ ] **Step 5: Commit** `feat: /codeo:cleanup prints the delete command for leftover codeo-live branches (#157)`.

### Task 7: documentation

**Files:**
- Modify: `docs/handoff.md` ("Who is working right now" paragraph `:167-243`, the sequence diagram `:222-239`), `scripts/live.sh` (header `Limits`, verb list), `docs/skills.md` (`close` at `:193`, `cleanup` at `:252`), `CHANGELOG.md` (`## Unreleased`)
- Test: `tests/live-signal.test.sh` (`:169-186`, the handoff pins)

**Interfaces:** consumes tasks 1-6; writes what the system now does.

- [ ] **Step 1: Change the pins first.** `tests/live-signal.test.sh:170` expects the diagram line `S->>O: /codeo:close runs live.sh clear and live.sh sweep, and deletes the lock in one command`; the list at `:183` drops `'never deleted'` and adds `'live.sh sweep'`, `'[skip ci]'`, `'codeo-live/**'`, `'refs/codeo/live-web/'`, `'codeo-live-machine'`.
- [ ] **Step 2: Run** `bash tests/run.sh live-signal`. Expected: FAIL on those phrases.
- [ ] **Step 3: Edit `docs/handoff.md`.** The paragraph says: the web branches are fetched into `refs/codeo/live-web/*`, and a web and a container signal with one `<issue>/<machine>` show as two rows; a web session cannot delete a branch, so `/codeo:close` run outside a web session sweeps the issue's `codeo-live/<issue>/*` branches (`live.sh sweep`), `/codeo:cleanup` prints `git push origin --delete …` for a finished issue's leftovers, and by hand the command is `git push origin --delete codeo-live/<issue>/<machine>`; a web session still working the issue republishes on its next beat. The CI trigger: in a project whose workflow runs `on: push` for all branches every beat is a push; the web signal's subject carries `[skip ci]`, which GitHub Actions honours for push events, and another CI system may not, so excluding `codeo-live/**` from its branch filter is the sure way. The label: kept in `<git dir>/codeo-live-machine` from the first beat until `clear`, so a session whose id changes shows as one row; a session in a new checkout (a reclaimed VM) gets a new label and the old row shows for up to the TTL. Update the diagram's fetch, close and SessionEnd lines to match. In `docs/skills.md`, `close` says it also sweeps; `cleanup` says it also prints the leftover branches' delete command. In the `live.sh` header, the verb list and `Limits` bullet match task 4's wording. `CHANGELOG.md` gets one bullet under `## Unreleased` per fix (F22, F23, F25) in the file's existing style.
- [ ] **Step 4: Run** `bash tests/run.sh live-signal`, then `bash tests/run.sh skills`. Expected: `all cases passed` for each (`skills` runs `skills-doc`, `skills-lint` and `skills`, which check `docs/skills.md` and the skill files).
- [ ] **Step 5: Commit** `docs: the live signal's web branches, CI trigger and label (#157)`.

### Task 8: whole suite

- [ ] **Step 1: Run** `bash tests/run.sh`. Expected: `all cases passed`.
- [ ] **Step 2: Mutation check, recorded in `implement.md`.** Revert the `fetch` refspec of task 1 to the old two-source form and see `fetch_survives_a_web_and_a_container_signal_with_equal_labels` fail; restore it.

---

## Self-review

- **Coverage:** criterion 1 → task 1; criterion 2 → tasks 4, 5, 6 and 7 (the by-hand command); criterion 3 → tasks 3 and 7; criterion 4 → tasks 2 and 7. Out of scope untouched.
- **Names:** `live-web` namespace (tasks 1, 7), `codeo-live-machine` (tasks 2, 7), `sweep` (tasks 4, 5, 7), `leftover` (task 6) are spelled the same where they recur.
- **Footprint, for `plan.md`:**

```
files:      scripts/live.sh, scripts/cleanup.sh, skills/close/SKILL.md, skills/cleanup/SKILL.md, docs/handoff.md, docs/skills.md, CHANGELOG.md, tests/live.test.sh, tests/live-signal.test.sh, tests/close-skill.test.sh, tests/cleanup.test.sh, tests/cleanup-skill.test.sh, docs/plans/2026-11-23-live-signal-leftovers-157.md
wiki:       none
exclusive:  none
sequenced:  none
```
