# Issue #161 — qc

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/161 |
| Branch | `docs/documentation-leftovers-154-146-removal` |
| Updated | 2026-11-24 |

## Where this stands

Round 2 is written and routed back to `/codeo:implement` once more: F1 and F2 from round 1 are fixed, but the `G` edge label (round 1's F3) reads false on the `--force` path, so it is now blocking (F3). It is one label. Next step: `/codeo:implement` rewrites the `G` label, then `/codeo:qc` runs round 3 from step 0.

## Questions

None.

## Notes

- The unchanged sentence "A container that `codeo` started itself is read once" in the same README is also untrue when `docker ps -a` fails (such a container is then restarted). It is pre-existing and outside #154 F1-F5, so it is not a finding (qc-02); say it once if F2's fix touches that paragraph.
- `implement.md` and `plan.md` were written after the work was done, in a hosted web session; this round judged the diff against `init.md`'s criteria, not against those records.

## Outcome

### Round 1 — 2026-11-24

**Scope.** `bash scripts/sync-main.sh --abort-on-conflict` merged `origin/main` (1 commit, `a389a65`, #164) and printed `also changed on main: CHANGELOG.md` and `also changed on main: tests/live-signal.test.sh`; both files were re-read on the merged tree and this branch's edits are intact (the v1.0.8 `Shared state:` line, the `SessionStart groups` assertion at `tests/live-signal.test.sh:265`). `overlap.sh 161` printed nothing; `overlap.sh --outside 161` printed nothing and exited 0. `git diff origin/main...HEAD --stat`: 11 files, 211 insertions, 9 deletions — `.devcontainer/README.md`, `CHANGELOG.md`, `docs/release-checklist.md`, `.claude/hooks/session-start.sh`, `.claude/settings.json`, `tests/live-signal.test.sh`, the plan, and `.codeo/161/*`. No overlay rules apply (`overlay.sh qc invariants-extra` and `wiki-rules` both exit 3); no invariants file, no wiki module, no shared environment.

`scope.sh origin/main HEAD` printed `scope: suite shell needed for unclassified paths:` (`.claude/hooks/session-start.sh`, `.claude/settings.json`, `.codeo/161/*`, `CHANGELOG.md`) and `suite.shell=true`.

**Build.** The `shell` suite's build is `true`: exit 0.

**Suites.** `bash tests/run.sh` ran whole, `shell` suite, exit 1, ending `failed: install.test.sh`. Only `install.test.sh` failed; `live.test.sh` and every other file passed this run. `install.test.sh`: 200 `FAIL` lines, 57 distinct cases, the first being `t_list_notice_does_not_hide_dropped_installs: exit 127 (stderr: rm: command not found)`. The same test run on a pristine `git archive origin/main` copy gave 200 `FAIL` lines and the same 57 cases, identical after normalising temp paths and numbers, so the failure is this sandbox's (a guard `rm` earlier in `PATH`) and not this change's. The CI `tests` job on head `e2a0d1e` was still in progress when this round was written.

**Criteria.**

| Criterion | Verdict | Settled by |
|---|---|---|
| The flowchart edge from `G` names the failed follow-up `docker ps -a` listing under `--force`, and the `H` edge no longer carries a `--force` parenthesis | not met — `G` names the listing, but `H` still reads `docker rm -f failed (only while the container is still listed)`, the `--force`-only clause | `.devcontainer/README.md:220-221`; `.devcontainer/codeo:695-702` |
| The sandbox paragraph no longer says the script stops "before it reads `--force`" and still names `sbx rm --force codeo-<N>` as the way out | met | `.devcontainer/README.md:228`; `.sbx/codeo-sandbox.sh:416-425` (`--force` parsed, then `die "no clone …"` either way) |
| The inspect paragraph no longer says a container `codeo` "had to start" is always stopped again | met | `.devcontainer/README.md:191`; `.devcontainer/codeo:523-537` (`started=1` only when `listed=1`) |
| Node `Q`'s label is true for every edge that reaches it | not met — `Q` reads "a container codeo started for the read is stopped again"; when `docker ps -a` fails, `started` stays 0, so the `R`/`X` no-`--force` edges to `Q` leave a container `codeo` started running | `.devcontainer/README.md:199`; `.devcontainer/codeo:530-537, 550` |
| `CHANGELOG.md`'s v1.0.8 `Shared state:` line names the exact `## Outcome` match in `dossier-check.sh`, `inflight.sh` and `qc-verdict.sh` and the `### Round <n> — stashed\|abandoned` reader in `lock.sh` | met | `CHANGELOG.md:20`; `git show v1.0.8:scripts/<f>.sh` has `^## Outcome[[:space:]]*$` (1, 4, 2 matches), `v1.0.7` has none; `scripts/lock.sh:33, 79, 165` (`is_parked`, `CODEO_LOCK_SKIP_PARKED`) is in `v1.0.8` (3 matches), not `v1.0.7` (0) |
| `docs/release-checklist.md` step 6 names the README installer examples and `tests/install.test.sh` stubs as files a release also moves | met | `docs/release-checklist.md:74-76`; `git diff --stat v1.0.7 v1.0.8` over `.claude-plugin README.md tests/install.test.sh CHANGELOG.md` shows exactly those four files |

**Documentation.** The diff changes README prose, a flowchart, the changelog and the release checklist; each was read against `.devcontainer/codeo` (`container_check`, `cmd_rm`) and `.sbx/codeo-sandbox.sh` (`cmd_end`) path by path. The flowchart could not be rendered here (`mmdc` is not installed): the edits are label text only and every quote on lines 196-222 is balanced. The `SessionStart` hook changes behaviour (a cloud session now installs the codeo plugins) and no page or `CHANGELOG.md` `## Unreleased` bullet covers it; the plan named no page for it (F6).

**Independent review** (`opus`, given the criteria and the git range only). Quoted in plain text: "Ready to merge? With fixes. The H edge label now states a false condition for the only path that reaches H, and the Q label still fails criterion 4 in the `docker ps -a` failure case that the issue itself identified. Both are one-line label fixes." Its findings are F1-F5 below; F6 is this pass's.

**Findings.**

- **F1 — blocking — `/codeo:implement`'s.** `.devcontainer/README.md:221`: the `H` edge reads `docker rm -f failed (only while the container is still listed)`. `H` is reached only from "anything else, no --force", and without `--force` `cmd_rm` dies on any `docker rm -f` failure with no listing (`.devcontainer/codeo:697`); "only while the container is still listed" is the `--force`-only behaviour at `:701`. #154 F2 asked for this parenthesis to go; the change removed the words `with --force,` and kept the clause. Fix: the label is just `docker rm -f failed`.
- **F2 — blocking — `/codeo:implement`'s.** `.devcontainer/README.md:199`: node `Q` still says "a container codeo started for the read is stopped again", but `stop_started` only stops a container `codeo` knows it started (`.devcontainer/codeo:477-478, 537`). With a failing `docker ps -a`, the `R`/`X` no-`--force` refusals reach `Q` with the container left running, the case #154 F4 names and `.devcontainer/README.md:191` now describes. Fix: "a container codeo knows it started for the read is stopped again", or the same `docker ps -a` caveat as the paragraph.
- **F3 — non-blocking — `/codeo:implement`'s.** `.devcontainer/README.md:220`: the `G` edge opens with an unqualified "docker rm -f failed" and then "(otherwise only while the container is still listed)", which reads as "without `--force`" when the code does the opposite (without `--force` any failure dies; with `--force` only a failed listing or a container still listed does). Criterion 1's `G` half is met; suggested wording: `docker rm -f failed (with --force: only when the follow-up docker ps -a listing failed or still lists the container), or volume rm failed and the volume still exists`.
- **F4 — non-blocking — `/codeo:implement`'s.** `docs/release-checklist.md:74-76`: "which move to the latest release" is not exact. The README's `--version v1.0.7` example (`README.md:75`) and the older-tag stubs in `tests/install.test.sh` move to the release before the new one, and the sort-order stubs (`v1.0.9`, `v1.0.10`, `v2.0.0-rc1`) do not move. The wording follows the issue's own, so it does not fail criterion 6.
- **F5 — non-blocking — `/codeo:implement`'s.** `.claude/hooks/session-start.sh:13`: the skip test greps `claude plugin list` for `superpowers@superpowers-marketplace` while `install.sh` accepts `superpowers@*` (`install.sh:246`), so a session with another superpowers marketplace re-runs the installer each start (idempotent, slow); a disabled codeo counts as installed; the group has no matcher, so it also runs on `clear` and `compact`. The reviewer also says the installer's stdout lands in session context; this pass did not verify that.
- **F6 — non-blocking — `/codeo:plan`'s.** The `SessionStart` hook, `.claude/settings.json` and the `tests/live-signal.test.sh` assertion widen a documentation fix to a behaviour change that no `CHANGELOG.md` bullet or page covers, and the plan listed no task for them. It was added at the engineer's request and recorded as a deviation in `implement.md`; whether it ships here or on its own pull request is the engineer's call.

Not findings: both hook tests pass (`tests/devcontainer.test.sh`'s gating check and `tests/live-signal.test.sh`'s group count were exercised by the full run); the stale `:658` line number lives in the issue only, not in the README.

**Verdict: back to `/codeo:implement`.**

### Round 2 — 2026-11-24

**Scope.** `sync-main.sh --abort-on-conflict`: `the branch already contains origin/main`. `overlap.sh 161` and `overlap.sh --outside 161` printed nothing and exited 0. `git diff origin/main...HEAD --stat`: 12 files, 295 insertions, 9 deletions (round 1's 11 plus `.codeo/161/qc.md`). `scope.sh origin/main HEAD` printed `suite.shell=true`, the unclassified paths being `.claude/hooks/session-start.sh`, `.claude/settings.json`, `.codeo/161/*` and `CHANGELOG.md`. Head `dc0101a`, base `a389a65`. No overlay rules, invariants file, wiki module or shared environment.

**Build.** The `shell` suite's build is `true`: exit 0.

**Suites.** `bash tests/run.sh`, whole, exit 1, ending `failed: install.test.sh`; every other file passed, `live.test.sh` included. `install.test.sh`: 200 `FAIL` lines, 57 distinct cases (the first `t_list_notice_does_not_hide_dropped_installs: exit 127 (stderr: rm: command not found)`), identical after normalising temp paths and numbers to the same file run on a pristine copy of `origin/main` in round 1, so they are this sandbox's, not this change's.

**Criteria.**

| Criterion | Verdict | Settled by |
|---|---|---|
| The flowchart edge from `G` names the failed follow-up `docker ps -a` listing under `--force`, and the `H` edge no longer carries a `--force` parenthesis | not met — `H` is now `docker rm -f failed`, but the `G` label names the listing and reads false (F3) | `.devcontainer/README.md:220-221`; `.devcontainer/codeo:695-702` |
| The sandbox paragraph no longer says the script stops "before it reads `--force`" and still names `sbx rm --force codeo-<N>` as the way out | met | `.devcontainer/README.md:228` ("refuses at the missing clone with or without `--force`"); `grep -c "stops before it reads"` prints 0; `.sbx/codeo-sandbox.sh:416-425` |
| The inspect paragraph no longer says a container `codeo` "had to start" is always stopped again | met | `.devcontainer/README.md:191`; `.devcontainer/codeo:523-537` |
| Node `Q`'s label is true for every edge that reaches it | met | `.devcontainer/README.md:199`; the reviewer traced B, C, R, X and F into `Q` through `container_check` and `stop_started` (`.devcontainer/codeo:477-478, 530-550`) and found the label true on each |
| `CHANGELOG.md`'s v1.0.8 `Shared state:` line names the exact `## Outcome` match in `dossier-check.sh`, `inflight.sh` and `qc-verdict.sh` and the `### Round <n> — stashed\|abandoned` reader in `lock.sh` | met | `CHANGELOG.md:23`; `git show v1.0.8:scripts/lock.sh` has `is_parked` (3 matches), `v1.0.7` has none; the exact match is in all three scripts at v1.0.8 (`dossier-check.sh:133`, `inflight.sh`, `qc-verdict.sh`); see F7 for one overstatement in the wording |
| `docs/release-checklist.md` step 6 names the README installer examples and `tests/install.test.sh` stubs as files a release also moves | met | `docs/release-checklist.md:74-76` |

**Documentation.** Every flowchart edge into `Q`, `G`, `H` and `Y` was re-read against `cmd_rm` and `container_check`. The flowchart was not rendered (`mmdc` is not installed); the edits are label text only and every quote in the block is balanced. The `SessionStart` hook still has no `CHANGELOG.md` bullet or page (F6). Round 1 cited `CHANGELOG.md:20`; that is the `## v1.0.8` heading, and the `Shared state:` line is line 23.

**Independent review** (`opus`, criteria and git range only). Quoted in plain text: "Ready to merge? With fixes. Five of the six criteria are met cleanly, including Q, H and the sandbox and inspect paragraphs. The G to Y edge names the listing failure but now reads as false for `--force`, which this issue was meant to fix, so it should be reworded before merge."

**Findings.**

- F1 (blocking in round 1) — fixed by `0bffad7`: the `H` edge reads `docker rm -f failed`.
- F2 (blocking in round 1) — fixed by `0bffad7`: node `Q` says a container `codeo` knows it started is stopped again.
- **F3 — blocking — `/codeo:implement`'s** (non-blocking in round 1, raised here after the reviewer's trace and a re-read of `cmd_rm`). `.devcontainer/README.md:220`: the `G` label opens with an unqualified "docker rm -f failed", but with `--force` a failed `docker rm -f` ends in `Y` only when the follow-up listing fails or still lists the container (`.devcontainer/codeo:699-701`); and "the follow-up docker ps -a listing failed" reads as a cause on its own, though that listing runs only inside the `else` after `docker rm -f` has failed. The label misdescribes #154 F1's own case. Fix: `docker rm -f failed (with --force, only when the follow-up docker ps -a listing fails or still lists the container), or volume rm failed and the volume still exists`.
- F4 — non-blocking — `/codeo:implement`'s. Unchanged from round 1: `docs/release-checklist.md:74-76` says the examples "move to the latest release", but the README's `--version v1.0.7` example and older-tag stubs move to the release before it and the `v1.0.9`/`v1.0.10`/`v2.0.0-rc1` ordering stubs do not move.
- F5 — non-blocking — `/codeo:implement`'s. Unchanged from round 1: the hook's skip check greps for `superpowers@superpowers-marketplace` while `install.sh` accepts `superpowers@*` (`install.sh:246`), treats a disabled codeo as installed, and has no matcher, so it also runs on `clear` and `compact`.
- F6 — non-blocking — `/codeo:plan`'s. Unchanged from round 1: the `SessionStart` hook, `.claude/settings.json` and the `tests/live-signal.test.sh` assertion are outside the issue and no `CHANGELOG.md` bullet or page covers them.
- F7 — non-blocking — `/codeo:implement`'s. `CHANGELOG.md:23` says the three scripts match `## Outcome` exactly "so `## Outcomes` and `## Outcome notes` no longer count". For `dossier-check.sh` only `## Outcome notes` stopped counting: at v1.0.7 (`scripts/dossier-check.sh:131`, `index($3, name " ") == 1`) `## Outcomes` was already ignored, and v1.0.8 adds `name != "Outcome" &&` (`:133`). `inflight.sh` and `qc-verdict.sh` had a bare `/^## Outcome/` at v1.0.7, so both forms stopped counting there. The sentence is the issue's own wording; the fix is to say which script stopped counting which heading.
- F8 — non-blocking — `/codeo:implement`'s. `.claude/hooks/session-start.sh:2` says the hook installs the plugins "so /codeo:* commands load"; the repository `README.md` says sessions already open need a restart to load newly installed plugins, so the commands may load only in the next session. Plausible, not verified at runtime.

Not findings: `tests/live-signal.test.sh:265` pins only the group count, not that the new group is the installer (low impact); both hook tests pass in the full run.

**Verdict: back to `/codeo:implement`.**

## Log

- 2026-11-24 — round 1: sync merged origin/main, build true, suite shell failed only install.test.sh (same 57 cases as origin/main), opus review, 2 blocking findings → back to implement · cost: 7m · opus-5-5 120k in + 1.4M cached / 12k out · sonnet-5-5 52k in + 5.9M cached / 18k out
- 2026-11-24 — round 2: build true, suite shell failed only install.test.sh (same 57 cases as origin/main), opus review, F1 and F2 fixed, 1 blocking finding (F3, the G edge label) → back to implement · cost: 7m · opus-5-5 117k in + 1.1M cached / 12k out · sonnet-5-5 15k in + 4M cached / 15k out
