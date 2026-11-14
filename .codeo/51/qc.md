# Issue #51 — qc

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/51 |
| Branch | `feat/seed-dev-container-git-identity` |
| Updated | 2026-11-14 |

## Where this stands

Round 1 is written: the build and the full `shell` suite pass and all six criteria are met, but one
documentation sentence is untrue (F1, blocking), so the change goes back to `/codeo:implement`.
Q1 (the overlap with #52) is answered; nothing is open.

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

## Log

- 2026-11-14 — Round 1: build and suite pass, six criteria met, F1 blocking; back to implement · cost: 4m · opus-5-5 256k in + 1.7M cached / 10k out · sonnet-5-5 204k in + 724k cached / 2k out
