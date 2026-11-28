# Issue #217 — qc

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/217 |
| Branch | `feat/217-add-codeo-go-codeo-done` |
| Updated | 2026-11-28 |

## Where this stands

Round 3, done: clear, forward to `/codeo:close`. The branch was re-graded after merging `origin/main` (#181); the build and full `shell` suite pass and no blocking finding was raised. Round 2, for the record: clear. The build and the full `shell` suite pass on the tree merged with `origin/main`, all seven criteria are met, F1-F11 of round 1 are closed, and the round's independent review found no blocking defect. Seven non-blocking findings (F12-F18) are recorded for `/codeo:triage`.

## Questions

None.

## Notes

- `scope.sh origin/main HEAD` printed `suite.shell=true`; its unclassified paths were `.codeo/217/*.md`, `CHANGELOG.md`, `README.md` and `templates/containers/.devcontainer/codeo`.
- No environment, invariants file or `wiki` module is configured, so there is no environment step. `models.reviewer` is unset: the reviewer ran on opus.
- `overlap.sh 217` printed nothing after Q7 and Q8 of `plan.md`; `overlap.sh --outside 217` printed `tests/inventory.test.sh` (F12).
- The macOS keychain path and the real `claude -p /codeo:init … --approved` run are not exercised here; the engineer ran the listing and flag checks by hand on a Mac (`implement.md`).
- Follow-up promised, not filed (the role check refuses `/codeo:issue` in this checkout): `codeo update` says `(already the newest)` when the downloaded `CODEO_VERSION` equals the installed one although the files may be new, because the constant moves only at a release; use a wording that does not claim it, and say the files changed (F13).
- Follow-up promised, not filed: two more wording nits from round 3 (F19 the "downloads none of the scripts" sentence limited to the `home` step; F20 the `board: not configured, skipped` line sharing the failure-line prefix).
- Follow-up promised, not filed: five inexact statements in `.devcontainer/README.md` and `README.md` (the `done`-after-manual-removal message, the home directory downloads, `done` not needing `claude`, the diagram's missing board-not-configured branch, the retry message's "card is In progress"), `go` writing the board before it checks `jq` and `claude`, a keychain test that never reaches `security`, and the wording of the recorded `--approved` note (F14-F18).

## Outcome

### Round 1 — 2026-11-28

**Commands run** (this pass):
- `bash .../sync-main.sh --abort-on-conflict` → `sync-main: the branch already contains origin/main`.
- `bash .../overlap.sh 217` → nothing; `overlap.sh --outside 217` → `tests/inventory.test.sh`.
- `bash .../scope.sh origin/main HEAD` → `suite.shell=true`.
- Build: the `shell` suite's `build` is `true` → exit 0.
- Suite: `bash tests/run.sh` → `all cases passed`, exit 0 (1m07s).
- `overlay.sh qc invariants-extra` and `qc wiki-rules` → exit 3 (no overlay text).

**Criteria** (`init.md`):

| Criterion | Verdict | Settled by |
|---|---|---|
| `codeo go <N>` on a Ready or Backlog issue ends with the container running and its name and branch printed | not met | F1: `cmd_go` never creates `CODEO_HOME`, so the branch lookup fails on a first use; F2: a Ready card is refused when the board names Ready otherwise. Where `~/codeo` exists and the board uses the default names, `t_go_runs_the_steps_in_order`, `t_go_none_and_unset_cards_are_set_to_ready` and `t_go_ready_card_is_not_moved` show the ending |
| A failed step in `go` prints one line naming it and leaves later steps unrun | met, with F3 | `t_go_stops_on_each_init_failure`, `t_go_odd_claude_output_is_one_init_line`, `t_go_existing_branch_stops_before_the_board`; the reason is missing when `claude` fails before printing JSON (F3) |
| `codeo done <N>` removes the container only when every proof passes, and otherwise prints the failed proof and removes nothing | met | `t_done_removes_when_every_proof_passes`, `t_done_names_the_failed_proof_and_removes_nothing`, `t_done_never_passes_force`; `tests/cleanup.test.sh` `prove_*` |
| `codeo --version` and `-v` print the version; the test fails when it differs from `plugin.json` | met | `t_version_flags_print_the_constant`, `t_version_equals_plugin_json` (both copies) |
| `codeo update` prints old and new version and a line per file; the failure paths still change nothing installed | met, with F6 | `t_update_prints_versions_and_each_file`, `t_update_same_version_says_so`, `t_update_old_download_says_unknown`, the existing `t_update_*` failure cases |
| With a stubbed `security` reporting a locked keychain, `go` and `done` stop before any board, git or Docker call and print the unlock command; unlocked or non-macOS, they go on | met, with F7 and F11 | `t_keychain_locked_stops_before_any_call`, `t_go_keychain_locked_makes_no_other_call`, `t_keychain_unlocked_goes_on`, `t_keychain_skipped_off_macos` |
| README, the keychain section and the release checklist are updated | met, with F4 | `README.md`, `.devcontainer/README.md` (*The keychain over SSH on macOS*), `docs/release-checklist.md` step 6, `tests/readme.test.sh` `host-command-go-done`; four statements in the new section are untrue (F4) |

**Documentation check.** Every page the diff changes (`README.md`, `.devcontainer/README.md`, `docs/home-checkout.md`, `docs/release-checklist.md`, `CHANGELOG.md`, `docs/skills.md`, `docs/skills-inventory.md`) is in present tense with no issue number inside a page and no "now" or "no longer"; `CHANGELOG.md` carries the one `(#217)`. The release checklist names both copies of `CODEO_VERSION`. The plan named these pages and the diff touches all of them. Four statements in the `codeo go` section are untrue as written (F4).

**Independent review** (opus, handed the criteria and the diff only): ready to merge with fixes. Its findings are quoted in plain text and classified below. It reproduced F1 with local stubs.

**Root cause of F1.** `cmd_issue` calls `ensure_home` before `find_branch`; `cmd_go` calls `go_branches` → `branches_for` first, and `branches_for` opens `$dir/.lookup.lock`, which fails when `$dir` does not exist (`.devcontainer/codeo:171`). The tests build `$cm_home` in `cm_setup` and never run `go` without it. **Root cause of F2.** `cmd_go` compares the card's status with the literal `Ready` (`.devcontainer/codeo:923`) but reads the Backlog name from `board.statuses.backlog`; `board.sh status` prints the board's own option name, which `board.statuses.ready` renames.

**Findings**

- **F1 — blocking, `/codeo:implement`'s.** `codeo go <N>` fails at the `branch` step with `could not open the lookup lock in <home>` when `CODEO_HOME` (default `~/codeo`) does not exist: a first command after installing the command (`.devcontainer/codeo:171`, via `cmd_go` ~line 908). Create the home directory (as `cmd_issue` does with `ensure_home`, or `mkdir -p`) before the branch step, and add a test that runs `go` with no home directory.
- **F2 — blocking, `/codeo:implement`'s.** The Ready name is hard-coded (`.devcontainer/codeo:923`); a project that maps `ready` to another name has every Ready card refused with "not Ready or Backlog". Read `.board.statuses.ready // "Ready"` the way the backlog name is read, in both copies, with a test for a custom name. The plan's brief wrote `Ready`; the code can honour the config without a plan change.
- **F3 — non-blocking, `/codeo:implement`'s.** `claude`'s stderr is redirected to `errf` and deleted unread (`.devcontainer/codeo:~940-946`), so a `claude` that fails before printing JSON (not logged in, locked keychain, a rejected flag) gives only `go: init: claude exited <rc>`. Show the last line of that stderr in the message, as `go_branches` does.
- **F4 — blocking, `/codeo:implement`'s.** Four statements in `.devcontainer/README.md`'s `codeo go` section are untrue: (a) "each failure … is one line" — `go_fail` adds the run's result text as indented lines after it; (b) the flow diagram sends `verify` failures to "go: init: reason" — they are `go: verify:`; (c) `--approved` is said to cover "the lock", but in the home workflow init takes no lock (`.codeo/overlays/init.md`); (d) "a tool outside the allow-list is denied, not asked" leaves out that the engineer's own settings (allow rules, `defaultMode`) also apply to the headless run, so it can reach more than the listed tools.
- **F5 — non-blocking, `/codeo:implement`'s.** `board.sh status` runs with `2>&1` and only the first line is kept, so a stderr warning before the status line becomes the card's "status" (`.devcontainer/codeo:~915`).
- **F6 — non-blocking, `/codeo:implement`'s.** The new progress `echo`s in `cmd_update` run under `set -e` between the `mv`s; with stdout closed or piped to `head`, a SIGPIPE can end the update after some files are installed with no "update failed part-way" line. Before this change the only output was the last line.
- **F7 — non-blocking, `/codeo:implement`'s.** `keychain_check` reports any non-zero exit of `security show-keychain-info` as a locked keychain, including a missing `login.keychain-db`, and then prints an unlock command that cannot help (`.devcontainer/codeo:~832`).
- **F8 — non-blocking, `/codeo:implement`'s.** `go --sandbox` (or a saved sandbox default) prints `container: codeo-<N>` (`.devcontainer/codeo:~972`).
- **F9 — non-blocking, `/codeo:implement`'s.** With no `CODEO_HOME_CLONE`, `go` and `done` take the current directory as the clone and run its `.devcontainer/scripts/role.sh` and `codeo-root.sh` before the role is known: running `codeo go` inside an untrusted checkout runs that checkout's code. Say so in one sentence in the docs.
- **F10 — non-blocking, `/codeo:implement`'s.** `skills/init/SKILL.md` (~line 293) records "approved in advance by the engineer through codeo go" even when `--approved` was typed by hand in an interactive session, so the record would be untrue.
- **F11 — non-blocking, `/codeo:implement`'s.** `t_keychain_skipped_off_macos` only checks that `security` was not called, not that `go` carried on; `prove_ignores_a_removal_record_and_the_overlay` uses an empty overlay, so it does not show the overlay is ignored.
- **F12 — non-blocking, `/codeo:plan`'s.** `tests/inventory.test.sh` changed (the init rule count 11 → 12) and is not in `plan.md`'s footprint; only a plan round can add it. It is not blocking on a first-round plan, and the overlap with #207 is the same *proceed and coordinate* as Q7 and Q8.
- **Parked from `implement.md`, not blocking:** untested board-set-failure, missing-`jq` and custom-Backlog branches of `go` (the custom Ready name is part of F2); no timeout on the headless call (documented); help-column alignment; two near-duplicate argument loops.

No `/codeo:issue` was filed.

**Routing.** F1, F2 and F4 are blocking and are the implementer's: the code or the page does not do what the plan intends, and no plan change is needed. F3 and F5-F11 are non-blocking and cheap to fold into the same round; F12 stays with the plan and does not hold the change.

**Verdict: back to `/codeo:implement`.**

### Round 2 — 2026-11-28

**Commands run** (this pass, from step 0 again):
- `bash .../sync-main.sh --abort-on-conflict` → `sync-main: the branch already contains origin/main`.
- `bash .../overlap.sh 217` → nothing (Q1 of `implement.md` covers #181); `overlap.sh --outside 217` → `tests/inventory.test.sh` (F12 below).
- `bash .../scope.sh origin/main HEAD` → `suite.shell=true`.
- Build: the `shell` suite's `build` is `true` → exit 0.
- Suite: `bash tests/run.sh` → `all cases passed`, exit 0 (1m08s).
- `overlay.sh qc invariants-extra` → exit 3; no environment, invariants file or `wiki` module is configured, so no environment step.

**Criteria** (`init.md`):

| Criterion | Verdict | Settled by |
|---|---|---|
| `codeo go <N>` on a Ready or Backlog issue ends with the container running and its name and branch printed | met | `t_go_runs_the_steps_in_order`, `t_go_none_and_unset_cards_are_set_to_ready`, `t_go_ready_card_is_not_moved`, `t_go_creates_a_missing_home` (a first use with no home directory), `t_go_honours_a_custom_ready_name`, `t_go_custom_backlog_name_is_still_moved`, `t_go_names_a_sandbox_by_kind` |
| A failed step in `go` prints one line naming it and leaves later steps unrun | met | `t_go_stops_on_each_init_failure`, `t_go_odd_claude_output_is_one_init_line`, `t_go_existing_branch_stops_before_the_board`, `t_go_home_that_cannot_be_created_is_one_home_line`, `t_go_shows_the_last_claude_stderr_line` |
| `codeo done <N>` removes the container only when every proof passes, and otherwise prints the failed proof and removes nothing | met | `t_done_removes_when_every_proof_passes`, `t_done_names_the_failed_proof_and_removes_nothing`, `t_done_never_passes_force`; `tests/cleanup.test.sh` `prove_*` |
| `codeo --version` and `-v` print the version; the test fails when it differs from `plugin.json` | met | `t_version_flags_print_the_constant`, `t_version_equals_plugin_json` (both copies) |
| `codeo update` prints old and new version and a line per file; the failure paths still change nothing installed | met | `t_update_prints_versions_and_each_file`, `t_update_same_version_says_so`, `t_update_old_download_says_unknown`, `t_update_finishes_with_stdout_closed`, the existing `t_update_*` failure cases |
| With a stubbed `security` reporting a locked keychain, `go` and `done` stop before any board, git or Docker call and print the unlock command; unlocked or non-macOS, they go on | met | `t_keychain_locked_stops_before_any_call`, `t_go_keychain_locked_makes_no_other_call`, `t_keychain_missing_file_goes_on`, `t_keychain_skipped_off_macos`, `t_go_runs_the_steps_in_order` (unlocked, `go`); the locked-keychain detection itself is unverified on a real Mac, as the issue allows |
| README, the keychain section and the release checklist are updated | met | `README.md`, `.devcontainer/README.md` (*The keychain over SSH on macOS*), `docs/release-checklist.md` step 6, `tests/readme.test.sh` `host-command-go-done` |

**Documentation check.** Every changed page is in present tense with no issue number inside a page and no "now" or "no longer"; `CHANGELOG.md` carries the one `(#217)`. The four untrue statements of round 1 (F4) are corrected, and `--approved` is no longer said to cover "the lock". Five smaller statements are still inexact (F13-F15 below); none misleads about what the headless run may do.

**Independent review** (opus, handed the criteria and the diff only): ready to merge with fixes; its one Important item and its minors are classified below. It confirmed the template matches the command modulo placeholders.

**Round 1's findings.** F1 (blocking in round 1) — fixed by `9f8c487`; F2 (blocking in round 1) — fixed by `9f8c487`; F4 (blocking in round 1) — fixed by `8abaf2f`; F3 and F5-F11 — fixed by `9f8c487`, `8abaf2f` and `0a5f631`. Each has a test that fails without the fix.

**Findings**

- **F12 — non-blocking, `/codeo:plan`'s (carried).** `tests/inventory.test.sh` changed (the init rule count 11 → 12) and is not in `plan.md`'s footprint; only a plan round can add it. The plan is on its first round, so it is not blocking by rule, and the overlap with #207 is the same *proceed and coordinate* as Q7 and Q8.
- **F13 — non-blocking, `/codeo:plan`'s.** `.devcontainer/codeo:~801` (and the template): `codeo update` prints `version: <v> (already the newest)` when the downloaded file's `CODEO_VERSION` equals the installed one, but `update` downloads from `main` and the constant moves only when a release is cut, so right after this change merges a user gets new files and "already the newest". The plan's Task 2 fixed that wording, so the code does what the plan says. A wording such as "same version" would not mislead.
- **F14 — non-blocking, `/codeo:implement`'s.** Inexact statements: `.devcontainer/README.md:~175` says `done` after a manual removal stops with `no container codeo-<N> found; nothing removed`, which holds only with `--container` (without a kind flag `detect_kind` dies with `no container or sandbox codeo-<N> found; start one with: codeo issue <N>`); `.devcontainer/README.md:~171` says `go` downloads none of the scripts into the home directory, but its `container` step runs `codeo issue`, whose first use downloads them; `README.md:~302` and `.devcontainer/README.md:~148` say both commands need `claude`, but `done` never runs it; the flow diagram has no board-not-configured branch.
- **F15 — non-blocking, `/codeo:implement`'s.** `.devcontainer/codeo:~985`: the container-step retry message says "the card is In progress" even when no board is configured or `board.statuses.inProgress` is renamed.
- **F16 — non-blocking, `/codeo:implement`'s.** `go` writes the board (Backlog → Ready) before it checks that `jq` and `claude` are installed, so a host missing one ends at `go: init` with the card already moved (documented). The checks could sit in the `home` step.
- **F17 — non-blocking, `/codeo:implement`'s.** `t_keychain_unlocked_goes_on` never creates the keychain file, so `keychain_check` returns before calling `security` and the test repeats `t_keychain_missing_file_goes_on`; `done`'s unlocked path is not tested.
- **F18 — non-blocking, `/codeo:implement`'s.** The note init records, `approved in advance by the engineer (--approved)`, reads as approval of the draft; the docs say the engineer approved only the issue number. "approved in advance by the command that started this run" is exact.
- **Minor, not separate findings:** a `grep | head -n 1` under `pipefail` can discard the captured board line when stderr is larger than the pipe buffer; the keychain lock detection rests on `security show-keychain-info` exiting non-zero, unverified on a Mac (documented).

No `/codeo:issue` was filed. The role check refuses `/codeo:issue` in this checkout, so the follow-ups are promised under `## Notes`.

**Routing.** No finding blocks the merge. F13 belongs to a plan decision and F14-F18 are small and inexact rather than harmful; a non-blocking finding never sends the change back on its own, so they are recorded and left for `/codeo:triage`.

**Verdict: clear — forward to `/codeo:close`.**

### Round 3 — 2026-11-28

(re-grade after `implement.md` round 3, which merged `origin/main` and resolved `CHANGELOG.md`)

**Commands run** (this pass, from step 0 again):
- `bash ./scripts/../sync-main.sh --abort-on-conflict` → `sync-main: the branch already contains origin/main`.
- `overlap.sh 217` → nothing; `overlap.sh --outside 217` → `tests/inventory.test.sh` (F12).
- `scope.sh origin/main HEAD` → `suite.shell=true`.
- Build: the `shell` suite's `build` is `true` → exit 0.
- Suite: `bash tests/run.sh` → `all cases passed`, exit 0, no FAIL line.
- `overlay.sh qc invariants-extra` and `wiki-rules` → exit 3; no environment, invariants file or `wiki` module, so no environment step.

**Also changed on main** (the merge): `.devcontainer/README.md`, `.devcontainer/scripts/session-title.sh`, `tests/devcontainer.test.sh`, `CHANGELOG.md`, #181's plan and archived dossier. The merged `CHANGELOG.md` `## Unreleased` carries both bullets and one `Shared state:` line covering both; the `.devcontainer/README.md` merge keeps #181's sections and #217's `codeo go` section.

**Criteria** (`init.md`): unchanged from round 2 by the merge; each re-run in the suite above.

| Criterion | Verdict | Settled by |
|---|---|---|
| `codeo go <N>` on a Ready or Backlog issue ends with the container running and its name and branch printed | met | `t_go_runs_the_steps_in_order`, `t_go_none_and_unset_cards_are_set_to_ready`, `t_go_ready_card_is_not_moved` |
| A failed step in `go` prints one line naming it and leaves later steps unrun | met | `t_go_stops_on_each_init_failure`, `t_go_existing_branch_stops_before_the_board`, `t_go_home_that_cannot_be_created_is_one_home_line` |
| `codeo done <N>` removes the container only when every proof passes, and otherwise prints the failed proof and removes nothing | met | `t_done_removes_when_every_proof_passes`, `t_done_names_the_failed_proof_and_removes_nothing`, `t_done_never_passes_force`; `tests/cleanup.test.sh` `prove_*` |
| `codeo --version` and `-v` print the version; the test fails when it differs from `plugin.json` | met | `t_version_flags_print_the_constant`, `t_version_equals_plugin_json` (both copies) |
| `codeo update` prints old and new version and a line per file; the failure paths still change nothing installed | met | `t_update_prints_versions_and_each_file`, `t_update_same_version_says_so`, `t_update_finishes_with_stdout_closed`, the existing `t_update_*` |
| With a stubbed `security` reporting a locked keychain, `go` and `done` stop before any board, git or Docker call and print the unlock command; unlocked or non-macOS, they go on | met | `t_keychain_locked_stops_before_any_call`, `t_go_keychain_locked_makes_no_other_call`, `t_keychain_skipped_off_macos` |
| README, the keychain section and the release checklist are updated | met | `README.md`, `.devcontainer/README.md` (*The keychain over SSH on macOS*), `docs/release-checklist.md` step 6, `tests/readme.test.sh` |

**Documentation check.** The merge touched only `CHANGELOG.md` (coherent, one `(#217)` and one `(#181)`) and brought #181's README sections; no page describes the old behaviour. The template and the command match modulo placeholders.

**Independent review** (opus, handed the criteria and the diff only): ready to merge with fixes. It confirmed the keychain stop-before-any-call ordering, the `prove` read-only behaviour, the `update` failure paths and the merged `CHANGELOG.md`. Its one Important item is F14 again; its minors are F15 and two new wording nits (F19, F20).

**Findings**

- Round 2's F12-F18 are unchanged by the merge and stay as recorded there (F12 and F13 `/codeo:plan`'s, F14-F18 `/codeo:implement`'s, all non-blocking).
- **F14 — non-blocking, `/codeo:implement`'s (re-raised by the reviewer as Important).** `.devcontainer/README.md:175` says `done` after a manual removal stops with `no container codeo-<N> found; nothing removed`; the default `codeo done <N>` dies in `detect_kind` (`.devcontainer/codeo:320`) with `no container or sandbox codeo-<N> found; start one with: codeo issue <N>`, which is true only with `--container`. Checked: confirmed. Classified as in round 2: the proofs passed, nothing is wrongly removed and the message is wrong rather than harmful, and the change under review did not touch it since round 2's clear grade.
- **F19 — non-blocking, `/codeo:implement`'s.** `.devcontainer/README.md:171`: "`go` downloads none of the scripts into it" is limited to the `home` step; the `container` step runs `codeo issue`, which downloads missing scripts into `CODEO_HOME`.
- **F20 — non-blocking, `/codeo:implement`'s.** `.devcontainer/codeo` `cmd_go`: the informational `codeo: go: board: not configured, skipped` shares the `codeo: go: <step>:` prefix the docs give for failure lines.
- F15 (re-raised): unchanged.

No `/codeo:issue` was filed (the role check refuses it in this checkout); F14-F20 are promised under `## Notes` for `/codeo:triage`.

**Routing.** No finding blocks the merge. The merge changed only `CHANGELOG.md`, which is coherent; the remaining items are wording, and a non-blocking finding never sends the change back on its own.

**Verdict: clear — forward to `/codeo:close`.**

## Log

- 2026-11-28 — round 1: build and suite pass, 6 criteria met, 1 not met; 3 blocking and 9 non-blocking findings; back to implement · cost: 7m · opus-5-5 528k in + 5.4M cached / 22k out · sonnet-5-5 403k in + 459k cached / 3k out
- 2026-11-28 — round 2: build and suite pass, 7 of 7 criteria met, no blocking finding; clear, forward to close · cost: 9m · opus-5-5 590k in + 4.6M cached / 28k out
- 2026-11-28 — round 3: build and suite pass, 7 of 7 criteria met, no blocking finding; clear, forward to close · cost: 4m · opus-5-5 189k in + 2.1M cached / 14k out · sonnet-5-5 118k in + 739k cached / 1k out
