# Issue #50 — qc

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/50 |
| Branch | `feat/name-dev-container-after-its` |
| Updated | 2026-11-10 |

## Where this stands

Round 1, paused at a question before the verdict. Build, suite, criteria 4-6 and the independent review are done; criteria 1-3 need the host, and the engineer's results are Q1. Rebuilding the container ends the session, so everything below is saved here first. Re-invoke `/codeo:qc` after the rebuild: it re-reads this file, takes Q1's answer, and writes the round.

## Questions

### Q1 — What do the two host checks show?

**Why it matters:** acceptance criteria 1-3 ("after a rebuild `docker ps` shows `codeo-home-<hash>`", "rebuilding gives the same name", "two same-named clones give different names") can only be observed on the host; this container has no `docker`. They are plan Task 4, and QC cannot pass a criterion it has not seen.

**To do (engineer):**
1. Rebuild the container; on the host run `docker ps --format '{{.Names}}'` and paste this container's line. Expected: `codeo-home-031er97u1o8nfhn55jo8tkvqb43vvn3483bfpgnn92fj540pqokb` (the name from plan Q3).
2. Open a second clone at another path whose folder is also `codeo-home`, start its dev container, and paste `docker ps --format '{{.Names}}'` again. Expected: two names starting `codeo-home-` with different suffixes, both running.

**Options:** paste both outputs · accept criteria 1-3 on plan Q3's observation and the format's documented behaviour alone (the verdict then says they were not re-observed).

**Answer:**

## Notes

Evidence from this pass (2026-11-10):

- `sync-main.sh --abort-on-conflict`: "the branch already contains origin/main". `overlap.sh 50`: nothing. `overlap.sh --outside 50`: nothing (no file outside the footprint).
- `scope.sh origin/main HEAD`: `suite.shell=true` (unclassified paths `.codeo/50/*` and `CHANGELOG.md`; `.devcontainer/**` and `tests/**` are the suite's own).
- Build: the `shell` suite's `build` is `true`; exit 0.
- Test: `bash tests/run.sh` → `all cases passed`, exit 0.
- Overlay `invariants-extra`, `wiki-rules`: none (exit 3). No invariants file, no wiki module, no shared environment: no step 9.
- Documentation: the change moves no page under `docs/`; `CHANGELOG.md` carries the bullet, and its claims (52-character suffix, 63 in all, rebuild once, `docker rm` for a same-named leftover) match plan Q3's observation. No page talks about the issue instead of the system.
- Independent review (opus, given the criteria and the diff only): no Critical, no Important; "Ready to merge: Yes".

Findings:

- **F1 — non-blocking, plan's.** `.devcontainer/devcontainer.json:7`: `${localWorkspaceFolderBasename}` is used unchanged, and Docker accepts only `[a-zA-Z0-9][a-zA-Z0-9_.-]+` as a container name. A clone folder with a space, `+`, `@`, non-ASCII, or a leading `.`/`_` now fails to start where it used to work. The code does what the plan says; the plan did not consider it. The CHANGELOG does not mention the limit.
- **F2 — non-blocking, plan's.** `tests/devcontainer.test.sh:66`: `run_args_cap_memory_and_cpus` was loosened from exact equality to "carries both caps" (as the plan's Task 1 said), so an extra `runArgs` entry such as a second `--memory` is no longer caught. An exact check against the new three-element array would pin both.
- **F3 — non-blocking, implement's.** `tests/devcontainer.test.sh:6-8`: the header comment leaves "It also checks .devcontainer/Dockerfile" alone on a line. Cosmetic.

Neither F1 nor F2 sends the change back on its own. They go to the engineer to decide at `/codeo:close`, or to `/codeo:triage`/`/codeo:issue` if worth keeping.

## Outcome

_Pending — written at the hand-off._

## Log

- 2026-11-10 — Q1 raised (round 1; host checks outstanding) · cost: 3m · opus-5-5 161k in + 857k cached / 7k out · sonnet-5-5 108k in + 29k cached / 598 out
