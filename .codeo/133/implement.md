# Issue #133 — implement

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/133 |
| Branch | `feat/codeo-command-host-short-bash` |
| Updated | 2026-11-19 |

## Where this stands

Round 3 done: the CI test failure from close.md round 2 is fixed, with QC round 2's F9-F17. Nothing is open. Next step: `/codeo:qc`.

## Questions

### Q1 — How do we coordinate `CHANGELOG.md` with #126?

**Why it matters:** two branches that both add a changelog bullet at the same spot conflict at merge.

**What overlaps.** #126 (branch `feat/put-issue-number-branch-name`, assignee kbajpai, step `plan`, waiting on `/codeo:implement`) lists `glob:CHANGELOG.md` in its footprint. This plan's Task 7 adds one bullet there, under `## Unreleased` (adding the heading only when it is absent). #126 has not changed a file yet (`changed: none`). #126 also edits `docs/dossier.md`, `docs/handoff.md` and `skills/init/SKILL.md`, which this plan never touches.

**Options:**
- **A — proceed and coordinate (my pick).** Same terms as Q6 of the plan dossier for #131: each branch adds its own bullet under `## Unreleased`, and whichever merges second rebases and keeps both.
- **B — sequence after #126.** Task 7 waits until #126 has merged.
- **C — re-scope.** Drop the changelog entry from this plan and file it separately.

**Answer:** A — proceed and coordinate. (Engineer: "A", 2026-11-18.)

## Outcome

**Built** (all seven tasks of `docs/plans/2026-11-18-codeo-host-command-133.md`, each through an implementer and a task review; two tasks needed one fix round, then a whole-branch review and one fix wave):

1. Skeleton, argument checks, `help`, and the test harness: `.devcontainer/codeo`, `tests/codeo-command.test.sh`.
2. First-use download, `home`, container `issue`, `shell`, branch lookup through a blob-less bare clone.
3. Container-or-sandbox choice, `default`, `open`, sandbox `issue` and `shell`.
4. `list`.
5. `rm` with the container safe check (one fix round: tests that a failing `git` exec is never read as a clean check).
6. `update`, all or nothing (one fix round: a failed move reports a partial install, the raw-URL default is shared, mode 755).
7. Documentation and changelog.
Whole-branch review fix wave: `rm --force` of a container that is already gone still removes its volume and image; a relative `CODEO_HOME` works; an unset `HOME` gives one clear line; `mkdir` failure is reported; the `--rebuild`-with-sandbox usage says why; tests for update through a symlink and `shell home --sandbox`.

**Documentation pages changed:** `.devcontainer/README.md`, `.sbx/README.md`, `CHANGELOG.md` (an `## Unreleased` entry). The repository `README.md` is unchanged.

**Build result:** the one configured suite (`shell`) has the build command `true`; it exits 0. `bash tests/run.sh codeo-command` prints `all cases passed`. The full `bash tests/run.sh` was run per task by the implementers: its only failure is `tests/live.test.sh` (3 assertions), caused by a live-signal stamp file `.git/codeo-live-beat` in this container's checkout (the test is not touched by this branch); grading the full suite is `/codeo:qc`'s.

**Deviations from the plan:** none in scope. Where the plan left room, the code does this: `rm` of a container refuses (without `--force`) when the check cannot run, as the plan says; `--container` and `--sandbox` together are a usage error; `usage` can carry a reason line. The plan's Task 1 names `die` and `valid_*` as interfaces; they are all used. No documentation task covered behavior the code gained beyond the plan.

**Deferred minors (for qc and triage):** with `HOME` and `CODEO_HOME` unset and no kind flag, `codeo issue N` prints its one-line error twice (exit status right); a SIGPIPE under `pipefail` in `rm --force`'s name check could in theory read as "not listed" (output is tiny); the lookup lazily fetches one blob per matching branch; `container_check` does not look at git-ignored files (by design); running `bash .devcontainer/codeo update` from a repository checkout overwrites the tracked file; the README lines about hand removal at `:41` and `:107` do not mention `codeo rm`. No `Ruling:` was made.

**Environment:** no shared environment is configured: no lease, no deploy. `sync-main.sh` found the branch already contains `origin/main`; `overlap.sh` printed nothing after the Q1 answer.


### Round 2 — 2026-11-19

(send-back from qc.md round 1)

Each finding was checked against the code before work began; F1 and F3-F8 all held. One fix commit, `bb31110`, then a scoped re-review (sonnet): all findings addressed, no new breakage.

- **F1 (blocking) — fixed.** An installed `docker` or `sbx` whose listing fails is now reported on stderr (`codeo: could not list docker containers` / `sbx sandboxes`, plus the program's first error line). `list` prints `no issue containers or sandboxes` only when every installed program answered, and exits 1 after the warnings when one failed. `shell`, `open` and `rm` die with `could not ask docker or sbx whether codeo-<N> exists; …` when nothing is found and a listing failed; one kind found is still used. `t_list_docker_down` now asserts this; new tests cover sbx down, one program down, `shell`/`open`/`rm` with a failed listing, and docker down with the sandbox found.
- **F3** `-q` on `git clone --bare` and `git fetch`. **F4** `codeo home` takes at most one argument. **F5** `--container|--sandbox` in the usage and help text and in the `shell` and `rm` rows of `.devcontainer/README.md` and the `rm` row of `.sbx/README.md`. **F6** the changelog and the `cmd_update` comment say a failed download changes nothing, not "all or nothing". **F7** `find_branch` reads the ref listing into a variable and dies when it fails. **F8** `cmd_update` reports a failed `mkdir`; `rm` stops a container it started for the check when it then refuses or cannot check.
- **F2** is not work: a stopped container's `-` branch is the engineer's plan Q5 answer; a change of it is a `/codeo:plan` round. No question raised here.

**Documentation pages changed:** `.devcontainer/README.md`, `.sbx/README.md`, `CHANGELOG.md`.

**Build result:** suite `shell`, build command `true`: exit 0. `bash tests/run.sh codeo-command` prints `all cases passed`. The full suite is qc's.

**Deviations from the plan:** none. The implementer made one commit instead of an F1 commit plus a second one; both touch the same hunks.

**Deferred minors (for qc and triage):** two comment lines in `.devcontainer/codeo` are overlong; the `shell` and `open` rows of `.sbx/README.md` do not show the kind flags; `.devcontainer/README.md:17` still says "It is all or nothing" beside the part-way case; `container_check`'s own `docker ps -a` failure reads as "state unknown" and goes on to `docker start`; plus the round 1 carried minors. No whole-branch review was run for this small round. No `Ruling:` was made.

**Environment:** no shared environment is configured. `sync-main.sh` found the branch already contains `origin/main`; `overlap.sh` printed nothing.


### Round 3 — 2026-11-19

(send-back from close.md round 2)

The finding was checked against the code and the CI log before work began; it holds. `sync-main.sh` merged `origin/main` (#126; it changed `CHANGELOG.md`) cleanly into the branch (`9b7ce8c`); no conflict, nothing in the outcome to resolve; `overlap.sh` printed nothing. Two fix commits, then a scoped re-review (sonnet): all findings addressed, no new Critical or Important breakage.

- **CI failure — fixed (`6c77860`).** `t_list_no_programs` removed the `docker` stub but ran `codeo` with `PATH=$cm_dir/bin:/usr/bin:/bin`, so the GitHub runner's real `docker` answered and `codeo list` exited 0. Every test run now uses `PATH="$cm_dir/bin:$cm_dir/sys"`, where `sys` (built by `cm_sys` in `cm_setup`) symlinks only the tools codeo and the stubs need and never `docker`, `sbx`, `git` or `curl`. A new test, `t_run_path_has_no_host_programs`, plants fake programs on the outer `PATH` and proves the run cannot see them. With a fake `docker` and `sbx` first on the outer `PATH` the suite passes; the old tests reproduce the CI error under that setup.
- **QC round 2 findings, `b0999d9`:** F9 the lookup clone is re-pointed at `CODEO_REPO_URL` before the fetch; F10 the branch check uses `git rev-parse -q --verify`, which needs no blob download, so a network failure is no longer read as "branch lacks the file"; F11 `rm` says `no container codeo-<N> found` when the container does not exist; F12 a container is stopped again only when its state was known not to be running; F13 `list` shows `paused` and `restarting`; F14-F16 README wording (failed listings, "all or nothing", the `.sbx/README.md` `shell` and `open` rows); F17 the two overlong comments wrapped.

**Documentation pages changed:** `.devcontainer/README.md`, `.sbx/README.md`.

**Build result:** suite `shell`, build command `true`: exit 0. `bash tests/run.sh codeo-command` prints `all cases passed`. The full suite is qc's.

**Deviations from the plan:** none.

**Deferred minors (for qc and triage):** `cm_sys` skips a tool it cannot find without a message; a few comment lines are still long (`.devcontainer/codeo` about `:357` and `:425`, `tests/codeo-command.test.sh:111`) and the test header comment wraps oddly; `rm --container` does not check that the container exists before `container_check`, so a missing container is found only after a failed start; `docker start` of a paused container is as before. No `Ruling:` was made.

**Environment:** no shared environment is configured.

## Log

- 2026-11-18 — Q1 raised · cost: 0m · sonnet-5-5 11k in + 341k cached / 770 out
- 2026-11-18 — implemented: 7 tasks + 2 task fix rounds + final-review fix wave · build: true (exit 0) · cost: 86m · sonnet-5-5 1.1M in + 31.2M cached / 232k out
- 2026-11-19 — implemented round 2 (send-back from qc round 1): F1 and F3-F8 fixed in bb31110, re-review clean · build: true (exit 0) · cost: 8m · sonnet-5-5 256k in + 3.1M cached / 31k out
- 2026-11-19 — implemented round 3 (send-back from close round 2): CI test isolation fixed in 6c77860, F9-F17 in b0999d9, re-review clean · build: true (exit 0) · cost: 12m · sonnet-5-5 163k in + 4.9M cached / 28k out
