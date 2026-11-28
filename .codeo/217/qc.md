# Issue #217 — qc

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/217 |
| Branch | `feat/217-add-codeo-go-codeo-done` |
| Updated | 2026-11-28 |

## Where this stands

Round 1, done: back to `/codeo:implement`. The build and the full `shell` suite pass on the merged tree, and six of the seven criteria are met, but the first is not met on a machine where `~/codeo` does not exist yet (F1), `go` refuses a Ready card on a board that names its Ready column otherwise (F2), and four statements in the new documentation are untrue (F4). Nothing is open as a question.

## Questions

None.

## Notes

- `scope.sh origin/main HEAD` printed `suite.shell=true`; its unclassified paths were `.codeo/217/*.md`, `CHANGELOG.md`, `README.md` and `templates/containers/.devcontainer/codeo`.
- No environment, invariants file or `wiki` module is configured, so there is no environment step. `models.reviewer` is unset: the reviewer ran on opus.
- `overlap.sh 217` printed nothing after Q7 and Q8 of `plan.md`; `overlap.sh --outside 217` printed `tests/inventory.test.sh` (F12).
- The macOS keychain path and the real `claude -p /codeo:init … --approved` run are not exercised here; the engineer ran the listing and flag checks by hand on a Mac (`implement.md`).

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

## Log

- 2026-11-28 — round 1: build and suite pass, 6 criteria met, 1 not met; 3 blocking and 9 non-blocking findings; back to implement · cost: 7m · opus-5-5 528k in + 5.4M cached / 22k out · sonnet-5-5 403k in + 459k cached / 3k out
