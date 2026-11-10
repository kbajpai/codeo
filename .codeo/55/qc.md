# Issue #55 — qc

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/55 |
| Branch | `feat/dev-container-home-container-starting` at `29ff750` |
| Updated | 2026-11-10 |

## Where this stands

Round 1 is in progress and stopped at step 10 with Q1-Q3 open; no verdict is written. The build and the suite ran, the independent review is back, and the findings are classified under `## Notes`.

## Questions

### Q1 — F1: `bash tests/run.sh` fails on the private project name in four tracked files. How is it fixed?

**Why it matters:** acceptance criterion 9 says `bash tests/run.sh` passes; it exits 1 on `tests/agnostic.test.sh` (see Notes). The four files are `.codeo/55/init.md`, `.codeo/55/issue.md`, `.codeo/55/plan.md` and `docs/plans/2026-11-10-home-and-issue-containers.md`. `qc` edits nothing, `implement` may not edit other skills' dossiers or the approved plan, and `plan` approved the plan text, so only you can say who touches them. Left alone, `main` goes red after the merge (`close` archives the dossier under `.codeo/done/`, the plan stays in `docs/plans/`).

**Options:**
- *Reword the four files* — you authorise `/codeo:implement` (a send-back round) to replace the name with "the reference project" in them, and you decide separately about the GitHub body of #55, which also names it.
- *You reword them yourself* before the next `qc` round.
- *Exempt `.codeo/` dossiers and `docs/plans/` in `tests/agnostic.test.sh`* — a change to a test that guards the public repo; a different issue's decision.

**Answer:**

### Q2 — The criteria that need Docker (1-5, 7, 8): how do you want them recorded?

**Why it matters:** this container has no `docker` and `/codeo:init` is not runnable under the suite, so criteria 1, 2, 3, 4, 5, 7 and 8 cannot be proved here (the repo tests cover their scripts, overlay text and docs; see the table in Notes). Marking them `untestable here` and clearing on that, or holding the verdict until you have run the host checks, are different verdicts.

**Options:**
- *I ran the host checks* — paste what you saw (rebuild; `/codeo:init` from `codeo-home`; the clone into `codeo-<N>`; `docker ps`; both windows open) and the criteria are settled from that.
- *Record them `untestable here — host check`* and let the verdict rest on the rest; the host checks happen before or after the merge, your call.
- *Hold the verdict* until the host checks are done.

**Answer:**

### Q3 — Do the non-blocking findings F2-F6 ride along if this goes back to `/codeo:implement` for Q1?

**Why it matters:** each further round costs a whole pass, so the cheap findings are worth fixing in the same send-back; but non-blocking polish never sends a change back on its own, and F3 and F4 touch what the plan specified.

**Options:** *blocking only* · *blocking and F2, F5, F6, F7* (implement's, small) · *all of F2-F7, F3 and F4 meaning a plan amendment you approve* · *no send-back: Q1 is settled another way*.

**Answer:**

## Notes

**Commands and output (this pass, branch `29ff750`):**
- `sync-main.sh --abort-on-conflict`: "sync-main: the branch already contains origin/main". `overlap.sh 55`: nothing. `overlap.sh --outside 55`: nothing.
- `scope.sh origin/main HEAD`: "scope: suite shell needed for unclassified paths: .codeo/55/implement.md, .codeo/55/init.md, .codeo/55/issue.md, .codeo/55/plan.md, .codeo/config.json, CHANGELOG.md, README.md" then `suite.shell=true`. No `deploy=` line: no shared environment is configured.
- Build (`true`): exit 0.
- Test (`bash tests/run.sh`): exit 1; 37 of 38 files pass; "=== FAIL: agnostic.test.sh / FAIL: tracked files mention a project-specific word (/roadmaster/):" with hits in `.codeo/55/init.md` (2), `.codeo/55/issue.md` (16), `.codeo/55/plan.md` (9) and `docs/plans/2026-11-10-home-and-issue-containers.md` (5); "failed: agnostic.test.sh".
- `overlay.sh qc invariants-extra` and `qc wiki-rules`: exit 3 (none). No invariants file, no wiki module, no environment.

**Criteria, preliminary (the table is written into the round once Q1-Q3 are answered):**

| # | Criterion | Preliminary | Settled by |
|---|---|---|---|
| 1 | home `init` pushes, assigns, moves card, no `.codeo/active`, stays on `main` | not yet checkable — needs a live `/codeo:init` | overlay text (`tests/init-overlay.test.sh`); reviewer: AC1 holds as written |
| 2 | prints clone instructions, no `claude --cloud` | met (text) / not yet checkable (live) | `tests/init-overlay.test.sh` |
| 3 | `init` with `.codeo/active` stops | met (text) / not yet checkable (live) | `.codeo/overlays/init.md` first paragraph; `tests/init-overlay.test.sh` |
| 4 | issue container prints `lock: took the lock for #<N>`; `.codeo/active` names issue and branch | met in the start script (stub `lock.sh`); real lock not yet checkable | `start_takes_the_lock_on_an_issue_branch` in `tests/devcontainer.test.sh` |
| 5 | home takes no lock; names | met in scripts; `docker ps` not yet checkable | `start_takes_no_lock_on_the_base_branch`; `tests/container-name.test.sh` |
| 6 | wrong folder gets a `todo:` naming the right one | met | `tests/folder-check.test.sh`; `start_reports_a_wrong_folder` |
| 7 | folder Docker rejects: valid name or stated reason | met by Q1=A of the plan (reason in README and CHANGELOG) | `.devcontainer/README.md` "The folder rule"; CHANGELOG |
| 8 | two containers at once | not yet checkable — Docker | — |
| 9 | each script has a test; `bash tests/run.sh` passes; CHANGELOG records it | **not met** — suite exits 1 | tests exist for all four; CHANGELOG bullet present; F1 |

**Findings** (reviewer `QC review: issue #55` on Opus plus this pass; all against lines this change touched):
- **F1 — blocking, owner: the engineer (see Q1).** The suite is red on `agnostic.test.sh`: four tracked files name the private reference project. `implement.md` flagged it; it is not the implementer's defect and not a plan flaw in the code, but the plan text and dossiers carry it.
- **F2 — non-blocking, `/codeo:implement`'s.** `.devcontainer/scripts/folder-check.sh:42` hard-codes `main` where the start script honours `.baseBranch`; a project with another base gets a wrong-folder TODO on its home clone. Codeo's base is `main`.
- **F3 — non-blocking, `/codeo:plan`'s.** `.devcontainer/scripts/codeo-root.sh:24` takes registry entry `[0]` of `codeo@codeo`; with project-scope entries for other projects first it can pick another plugin's `lock.sh`. The plan specified `[0]`.
- **F4 — non-blocking, `/codeo:plan`'s.** With the name now the folder alone, two open-folder checkouts that share a basename (`~/a/codeo`, `~/b/codeo`) cannot run at once ("name already in use"); #50's `-${devcontainerId}` allowed it. `.devcontainer/README.md` and the CHANGELOG explain "name already in use" only as a leftover container.
- **F5 — non-blocking, `/codeo:implement`'s.** `.devcontainer/scripts/container-name.sh:3-5` and the CHANGELOG say all three names come from this one script; the Docker name actually comes from the folder via `runArgs`, and `--docker` only computes what it should be.
- **F6 — non-blocking, `/codeo:implement`'s.** An empty `.codeo/active` is "absent" to the start script's `-s` test, but `lock.sh` sees the file and prints "lock already taken:" with nothing after it: no lock and no TODO.
- **F7 — non-blocking, `/codeo:implement`'s (this pass).** `.devcontainer/README.md` names `scripts/devcontainer-start.sh`; the file is `.devcontainer/scripts/devcontainer-start.sh`.
- Declined by the reviewer, recorded: AC4's "ends its start script with" is read as "the run reports" (the line prints mid-run); the `/tree/<branch>` URL with a `/` in the branch name and the `${containerWorkspaceFolderBasename}` substitution are host checks.

**Documentation check:** `.devcontainer/README.md` (new), `README.md` and `CHANGELOG.md` describe the behaviour in the present tense and match the code except F5 and F7 above; no page under `docs/` described the dev container, and the plan said `docs/` does not move (checked: `docs/` mentions only "a dev container" in passing).

## Outcome

_Pending — written at the hand-off._

## Log

- 2026-11-10 — qc round 1 stopped with Q1-Q3 open · cost: unavailable
