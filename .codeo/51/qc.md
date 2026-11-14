# Issue #51 — qc

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/51 |
| Branch | `feat/seed-dev-container-git-identity` |
| Updated | 2026-11-14 |

## Where this stands

Round 3 is written: the build and the full `shell` suite pass, all six criteria are met and nothing is
blocking (F5 is fixed; F4 and F6 are non-blocking). The verdict is clear, forward to `/codeo:close`. Q1 and
Q2 (the overlaps with #52 and #75) are answered; nothing is open.

## Questions

### Q1 — #52 also changes `CHANGELOG.md`: proceed, sequence or re-scope?

**Why it matters:** `overlap.sh 51` printed `52	CHANGELOG.md` and `52	glob:CHANGELOG.md`. #52
(branch `feat/run-codeo-latest-claude-models`, assignee kbajpai, step plan) adds its own bullet under
*Unreleased*, and its plan already records `sequenced: after #51 — both add a CHANGELOG.md bullet under
Unreleased (Q5)`. Sequencing #51 after #52 would make the two wait on each other; re-scoping cannot drop
the changelog line, which acceptance criterion 6 requires.
**Options:** proceed and coordinate · sequence after #52 · re-scope.

**Answer:**
Proceed and coordinate (recommendation accepted, answered in the conversation).

### Q2 — #75 also changes `CHANGELOG.md`: proceed, sequence or re-scope?

**Why it matters:** `overlap.sh 51` printed `75	CHANGELOG.md` and `75	glob:CHANGELOG.md`. #75 (branch
`chore/release-v1-0-6-main`, assignee kbajpai, step plan) is the v1.0.6 release; it turns the *Unreleased*
section into the release entry, and its footprint already says `proceed and coordinate` with #51 and #52.
If #51 merges first, its bullet ships in v1.0.6; if the release merges first, the bullet lands under a fresh
*Unreleased*. Sequencing after #75 would hold #51 for a release it does not need; re-scoping cannot drop the
changelog line, which criterion 6 requires.
**Options:** proceed and coordinate · sequence after #75 · re-scope.

**Answer:**
Proceed and coordinate (recommendation accepted, answered in the conversation).

## Notes

Commands this pass ran, from `/workspaces/codeo-51`:

- `bash scripts/sync-main.sh --abort-on-conflict` → `sync-main: the branch already contains origin/main` (exit 0).
- `bash scripts/overlap.sh 51` → the two #52 lines above; `bash scripts/overlap.sh --outside 51` → nothing, so the branch changed nothing outside its footprint.
- `bash scripts/scope.sh origin/main HEAD` → `suite.shell=true` (it needed the suite for unclassified paths: `.codeo/51/*.md`, `CHANGELOG.md`). No `deploy=` line: no shared environment is configured.
- Build: the `shell` suite's `build` is `true` → exit 0.
- Test: `bash tests/run.sh` → `all cases passed` (exit 0).
- `overlay.sh qc invariants-extra` and `qc wiki-rules` → exit 3 (none); no invariants file, no wiki module, no shared environment, so there is no `#### Environment` block.
- Independent review: `QC review:` subagent on opus (the `models.reviewer` default), given the acceptance criteria and the diff range `2a86915..80ef15a`, not the implementer's account. Its verdict, quoted in plain text: "With fixes — the code meets every acceptance criterion and the suite passes, but the CHANGELOG says a restart fills a missing identity, and a restart does not run this script."

**Documentation check.** `.devcontainer/README.md` (*What the start script does*) says what the script does in the present tense and matches the code (the two sources and their order, fill-only-if-missing, nothing else copied, the 10-second wait, the TODO naming the sources). No page under `docs/` describes the identity step (`grep` for `git identity`, `user.name` and `GIT_AUTHOR` over `docs/*.md` and `README.md` finds nothing). `CHANGELOG.md` has the one inaccuracy in F1.

**Round 2 commands**, from `/workspaces/codeo-51` at `c0bebc6`:

- `bash scripts/sync-main.sh --abort-on-conflict` → `sync-main: the branch already contains origin/main` (exit 0).
- `bash scripts/overlap.sh 51` → the two #75 lines of Q2 (#52's pair from round 1 is already raised); `bash scripts/overlap.sh --outside 51` → nothing.
- `bash scripts/scope.sh origin/main HEAD` → `suite.shell=true` (unclassified paths `.codeo/51/*.md` and `CHANGELOG.md`); no `deploy=` line, no shared environment.
- Build: the `shell` suite's `build` is `true` → exit 0. Test: `bash tests/run.sh` → `all cases passed` (exit 0).
- `overlay.sh qc invariants-extra` and `qc wiki-rules` → exit 3 (none) in round 1, unchanged.
- Independent review: a `QC review:` subagent on opus, given the criteria and the range `2a86915..c0bebc6`. Its verdict, in plain text: "With fixes — all acceptance criteria are met and tested, and the suite passes; the one real defect is that a non-numeric `CODEO_GITCONFIG_WAIT` makes the script exit 1, which breaks the always-exit-0 requirement."
- Reproduced here in a scratch shell under `set -euo pipefail` with the script's own loop condition `((waited < ${CODEO_GITCONFIG_WAIT:-10}))`: `abc` → `abc: unbound variable`, exit 1; `5s` → an arithmetic error on stderr, then it carries on, exit 0; `1.5` → the same; an empty value → exit 0.

**Documentation check, round 2.** `CHANGELOG.md:11` now says an existing container runs the script by hand and that a restart does not run it, which matches `devcontainer.json` (the script is `postCreateCommand`, `postStartCommand` is `window-title.sh`). `.devcontainer/README.md` is unchanged and still true. The changelog and the README both present `CODEO_GITCONFIG_WAIT` as a setting an engineer can change, which F5 turns on.

**Round 3 commands**, from `/workspaces/codeo-51` at `6d9a41f`:

- `bash scripts/sync-main.sh --abort-on-conflict` → `sync-main: the branch already contains origin/main` (exit 0; `main` is at `0414469`, the v1.0.6 release, already merged by implement round 3).
- `bash scripts/overlap.sh 51` → nothing (Q1 and Q2 stay answered); `bash scripts/overlap.sh --outside 51` → nothing.
- `bash scripts/scope.sh origin/main HEAD` → `suite.shell=true` (unclassified paths `.codeo/51/*.md` and `CHANGELOG.md`); no `deploy=` line, no shared environment.
- Build: the `shell` suite's `build` is `true` → exit 0. Test: `bash tests/run.sh` → `all cases passed` (exit 0).
- `git diff origin/main...HEAD --stat` → the start script, `tests/devcontainer.test.sh`, `.devcontainer/README.md` and `CHANGELOG.md` (plus the plan file and the dossiers).
- Independent review: a `QC review:` subagent on opus, given the criteria, the base `0414469` and head `6d9a41f`, and asked to check the changelog section. Its verdict, in plain text: "Ready to merge: Yes — every acceptance criterion is implemented, tested and passing; the script still always exits 0 and is safe to re-run, the docs describe what the code does, and the changelog entry is under Unreleased above v1.0.6." It also ran `bash tests/devcontainer.test.sh` itself (all cases passed).

**Documentation check, round 3.** `CHANGELOG.md` has a `## Unreleased` section (Config schema 1, Shared state unchanged from v1.0.6, Safe to bump mid-workflow yes) above the untouched `## v1.0.6` section, and the identity bullet sits only under `Unreleased`. Its sentences match `.devcontainer/devcontainer.json` (the script is `postCreateCommand`, so a restart does not run it) and the script (the two sources and their order, fill-only-if-missing, the 10-second wait, a non-whole-number limit counting as 10, the TODO naming the sources). `.devcontainer/README.md` says the same. No page under `docs/` describes the identity step.

## Outcome

### Round 1 — 2026-11-14

Merge of `origin/main` at the start of the round: none needed (already contained). Files #72 changed on `main` were re-checked at implement time; nothing new here.

| Criterion | Verdict | Settled by |
|---|---|---|
| With an empty volume config and an identity in the host `~/.gitconfig`, `git config --global user.name` and `user.email` return the host's values after the start script runs | met | `start_seeds_the_identity_from_the_host_gitconfig` in `tests/devcontainer.test.sh`; the engineer's real-container run (implement Q1 part 1) |
| With an empty volume config, no host identity, and `GIT_AUTHOR_NAME` / `GIT_AUTHOR_EMAIL` set, those values land in the volume config | met | `start_seeds_the_identity_from_the_environment` |
| With the host file and the environment both set, the host file's values win | met | `start_host_gitconfig_wins_over_the_environment` |
| A `user.name` or `user.email` already in the volume config is unchanged after a run, and a missing one beside it is still filled | met | `start_keeps_an_identity_already_in_the_volume` |
| With no source holding an identity, the TODO still appears and lists the sources that were tried | met | `start_todo_names_the_sources_tried`; `devcontainer-start.sh` step 5 |
| `tests/devcontainer.test.sh` covers each case above and the suite passes; `CHANGELOG.md` records the change | met | the five cases above are in `cases=( ... )`; `bash tests/run.sh` → `all cases passed`; `CHANGELOG.md:11` (but see F1) |

**Findings.**

- **F1 (blocking) — `CHANGELOG.md:11` says "No rebuild is needed: the next container start, or `bash .devcontainer/scripts/devcontainer-start.sh`, fills a missing identity."** The start script is `postCreateCommand` (`.devcontainer/devcontainer.json:15`); a restart of an existing container runs only `postStartCommand` (`window-title.sh`, line 16), so a restart never reaches step 5. Someone with an existing container who trusts the sentence restarts it, still has no identity, and has no way to know why. The README does not repeat the error ("runs when the container is created"). Whose it is: the code does what the plan says, and the plan's Task 4 wording is the source of the sentence (`docs/plans/2026-11-14-seed-dev-container-git-identity.md:161`, and the same phrase in `.codeo/51/plan.md`'s notes) — so the cause is the plan's, but the repair is a one-sentence documentation edit that changes no design, so it routes to `/codeo:implement` to be made and recorded as a deviation from the plan's wording, not to a re-plan. The sentence must say that an existing container gets the identity by re-running `bash .devcontainer/scripts/devcontainer-start.sh`, or on a rebuild or a new container, and not on a restart.
- **F2 (non-blocking) — `tests/devcontainer.test.sh`, `start_waits_for_the_host_gitconfig_to_arrive`.** The background writer makes two separate `git config --file` calls, so the host file exists after the first (name only); if the script's one-second poll lands between the two, `user.email` stays empty and the assertion fails, a window of a few milliseconds. Write the file to a temporary path and `mv` it into place. Implement's.
- **F3 (non-blocking) — the wait costs 10 seconds on every container creation for an engineer with no host `~/.gitconfig`, or with VS Code's git-config copy turned off,** until they set an identity. Documented in the README and the changelog, and Q1 of the plan chose it; recorded for the engineer, no change asked.
- **F4 (non-blocking) — the wait checks that `~/.gitconfig` exists, not that it is complete,** so a copy caught half-written reads as an empty key and falls through to `GIT_AUTHOR_*` or the TODO. The real impact is probably small; recorded, no change asked.

Not a finding: the real-container rebuild check (implement Q1 part 2) was skipped by the engineer, so whether VS Code's copy arrives within the 10 seconds on a first start rests on the stubbed tests and one observed timing; the reviewer set the same question aside as provable only in a real container.

No issue was filed by this pass. #52's CHANGELOG overlap was answered at Q1.

**Verdict: back to `/codeo:implement`.**

### Round 2 — 2026-11-14

Merge of `origin/main` at the start of the round: none needed (already contained).

| Criterion | Verdict | Settled by |
|---|---|---|
| With an empty volume config and an identity in the host `~/.gitconfig`, `git config --global user.name` and `user.email` return the host's values after the start script runs | met | `start_seeds_the_identity_from_the_host_gitconfig`; the engineer's real-container run (implement Q1 part 1) |
| With an empty volume config, no host identity, and `GIT_AUTHOR_NAME` / `GIT_AUTHOR_EMAIL` set, those values land in the volume config | met | `start_seeds_the_identity_from_the_environment` |
| With the host file and the environment both set, the host file's values win | met | `start_host_gitconfig_wins_over_the_environment` |
| A `user.name` or `user.email` already in the volume config is unchanged after a run, and a missing one beside it is still filled | met | `start_keeps_an_identity_already_in_the_volume` |
| With no source holding an identity, the TODO still appears and lists the sources that were tried | met | `start_todo_names_the_sources_tried` |
| `tests/devcontainer.test.sh` covers each case above and the suite passes; `CHANGELOG.md` records the change | met | the five cases above are in `cases=( ... )`; `bash tests/run.sh` → `all cases passed`; `CHANGELOG.md:11`, now accurate |

**Findings.**

- F1 (blocking in round 1) — fixed by `8f1e166`: the changelog now says a restart does not run the script. F2 (non-blocking in round 1) — fixed by `8f1e166`: the wait test places the host file whole.
- **F5 (blocking) — `.devcontainer/scripts/devcontainer-start.sh:251`, a non-numeric `CODEO_GITCONFIG_WAIT` makes the script exit 1.** The loop condition `((waited < ${CODEO_GITCONFIG_WAIT:-10}))` evaluates the value as arithmetic, and under `set -u` a word such as `abc` is read as an unset variable, so the script stops with `unbound variable` and exit 1 (reproduced above). The script's header and the plan's Global Constraints say it always exits 0 so it never fails the container's creation; the README and the changelog both offer the variable as a setting, so a typo is a realistic way to hit it, and the cost is a container that fails to create. Whose it is: `/codeo:implement`'s, because the plan's constraint "the start script still always exits 0" was not kept; the cause is the unvalidated expansion, found by reading the diff and reproducing it, with no debugging needed. The wait's limit must be checked as a whole number before the loop and fall back to the default 10 when it is not, with a case in `tests/devcontainer.test.sh` that passes a non-numeric value and expects exit 0 and the identity still seeded.
- **F4 (non-blocking, unchanged from round 1; the reviewer's Minor) — the wait stops when `~/.gitconfig` exists, not when it has content.** A copy created and then written leaves a window where the key reads empty and falls through to `GIT_AUTHOR_*` or the TODO; the script only runs on create, so it stays missing until a re-run. Waiting while the file is empty (`! -s`) would close most of it. Recorded; no change asked, as in round 1.
- **F3 (non-blocking, unchanged)** — an engineer with no host `~/.gitconfig` and no `GIT_AUTHOR_*` waits the full 10 seconds at every container creation; documented.

Not a finding: the rebuild check (implement Q1 part 2) is still the engineer's skipped proof, as in round 1.

No issue was filed by this pass. #75's overlap was answered at Q2.

**Verdict: back to `/codeo:implement`.**

### Round 3 — 2026-11-14

Merge of `origin/main` at the start of the round: none needed (the v1.0.6 release was merged in implement round 3).

| Criterion | Verdict | Settled by |
|---|---|---|
| With an empty volume config and an identity in the host `~/.gitconfig`, `git config --global user.name` and `user.email` return the host's values after the start script runs | met | `start_seeds_the_identity_from_the_host_gitconfig`; the engineer's real-container run (implement Q1 part 1) |
| With an empty volume config, no host identity, and `GIT_AUTHOR_NAME` / `GIT_AUTHOR_EMAIL` set, those values land in the volume config | met | `start_seeds_the_identity_from_the_environment` |
| With the host file and the environment both set, the host file's values win | met | `start_host_gitconfig_wins_over_the_environment` |
| A `user.name` or `user.email` already in the volume config is unchanged after a run, and a missing one beside it is still filled | met | `start_keeps_an_identity_already_in_the_volume` |
| With no source holding an identity, the TODO still appears and lists the sources that were tried | met | `start_todo_names_the_sources_tried` |
| `tests/devcontainer.test.sh` covers each case above and the suite passes; `CHANGELOG.md` records the change | met | the five cases above are in `cases=( ... )`; `bash tests/run.sh` → `all cases passed`; the `CHANGELOG.md` bullet under `## Unreleased` |

**Findings.**

- F5 (blocking in round 2) — fixed by `537ee3c`: the wait limit is checked as a whole number (anything else counts as 10) and compared as `10#$wait_max`; `start_a_non_numeric_wait_limit_falls_back_and_still_exits_zero` covers `abc`, `5s`, `1.5` and `08`. The bullet's placement under `## Unreleased` was checked in the documentation check above.
- **F4 (non-blocking, unchanged from rounds 1 and 2; the reviewer's Minor 1) — the wait stops when `~/.gitconfig` exists, not when it has content,** so a copy that is created and then written could be read half-done; with `GIT_AUTHOR_*` set, the environment's value would then fill the volume and, never being overwritten, would keep the host's value out. Whether VS Code writes the copy in one step is unverified (the wait test places the file whole). Non-blocking by effect: it needs a timing window of a few milliseconds and affects a first start only. Implement's, if the engineer wants it closed (wait while the file is empty, or re-read once after a second).
- **F6 (non-blocking, new; the reviewer's Minor 2) — `[include]` / `[includeIf]` in the host file are not followed,** because `git config --file` ignores includes by default (confirmed by the reviewer with a scratch file). A host that keeps its identity in an included file gets the environment's value or the TODO. The effect is small: an included file is usually a host path VS Code does not copy in. The README could say that only values written directly in `~/.gitconfig` count. Plan's, if at all: the plan chose to read the two keys from the host file alone.
- **F3 (non-blocking, unchanged)** — an engineer with no host `~/.gitconfig` and no `GIT_AUTHOR_*` waits the full 10 seconds at every container creation; documented.

Not a finding: the rebuild check (implement Q1 part 2) is still the engineer's skipped proof, as in rounds 1 and 2.

No issue was filed by this pass; F4 and F6 may be worth `/codeo:triage`.

**Verdict: clear — forward to `/codeo:close`.**

## Log

- 2026-11-14 — Round 1: build and suite pass, six criteria met, F1 blocking; back to implement · cost: 4m · opus-5-5 256k in + 1.7M cached / 10k out · sonnet-5-5 204k in + 724k cached / 2k out
- 2026-11-14 — Round 2: build and suite pass, six criteria met, F5 blocking (a non-numeric wait exits 1); back to implement · cost: 3m · opus-5-5 304k in + 1.3M cached / 9k out · sonnet-5-5 23k in + 1.1M cached / 2k out
- 2026-11-14 — Round 3: build and suite pass, six criteria met, no blocking finding; clear · cost: 4m · opus-5-5 90k in + 1.2M cached / 8k out · sonnet-5-5 22k in + 1.1M cached / 648 out
