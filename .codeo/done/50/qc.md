# Issue #50 — qc

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/50 |
| Branch | `feat/name-dev-container-after-its` |
| Updated | 2026-11-10 |

## Where this stands

Round 1 is written: verdict clear, forward to `/codeo:close`. Q1 is answered and criteria 1-3 are observed on the host. The build, the suite and the sync were re-run in this invocation on the unchanged diff; the independent review from the paused pass stands, since no code has changed since it ran.

## Questions

### Q1 — What do the two host checks show?

**Why it matters:** acceptance criteria 1-3 ("after a rebuild `docker ps` shows `codeo-home-<hash>`", "rebuilding gives the same name", "two same-named clones give different names") can only be observed on the host; this container has no `docker`. They are plan Task 4, and QC cannot pass a criterion it has not seen.

**To do (engineer):**
1. Rebuild the container; on the host run `docker ps --format '{{.Names}}'` and paste this container's line. Expected: `codeo-home-031er97u1o8nfhn55jo8tkvqb43vvn3483bfpgnn92fj540pqokb` (the name from plan Q3).
2. Open a second clone at another path whose folder is also `codeo-home`, start its dev container, and paste `docker ps --format '{{.Names}}'` again. Expected: two names starting `codeo-home-` with different suffixes, both running.

**Options:** paste both outputs · accept criteria 1-3 on plan Q3's observation and the format's documented behaviour alone (the verdict then says they were not re-observed).

**Answer:** (engineer, 2026-11-10) After the rebuild, `docker ps --format '{{.Names}}'` on the host shows `codeo-home-031er97u1o8nfhn55jo8tkvqb43vvn3483bfpgnn92fj540pqokb`, the name plan Q3 predicted. With a second clone, also in a folder named `codeo-home`, running at the same time, it shows `codeo-home-1593q4vnppthep8tg3tnt5054t223ef4hg3ogphjefc661u4id85` as well: two running, different suffixes. An earlier paste, `codeo-50-14hbd96af3pn55cg51s0s5pdpk4amm3n8j37i46umvoi1g4bdd29`, came from a differently named folder and is not used as evidence for criterion 3.

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

### Round 1 — 2026-11-10

Re-run in this invocation: `sync-main.sh --abort-on-conflict` ("the branch already contains origin/main"), `overlap.sh 50` and `overlap.sh --outside 50` (nothing), `scope.sh origin/main HEAD` (`suite.shell=true`; unclassified paths are `.codeo/50/*` and `CHANGELOG.md`), the `shell` suite's build (`true`, exit 0) and `bash tests/run.sh` (`all cases passed`, exit 0). The diff is unchanged since the paused pass. No shared environment is configured, so there is no `#### Environment` block.

| # | Acceptance criterion | Verdict | Settled by |
|---|---|---|---|
| 1 | After a rebuild `docker ps` shows `codeo-home-<hash>` | met | host `docker ps`, Q1: `codeo-home-031er97u1o8nfhn55jo8tkvqb43vvn3483bfpgnn92fj540pqokb` |
| 2 | Rebuilding the same clone gives the same name | met | the rebuilt container shows the name plan Q3 predicted from `${devcontainerId}`, which is derived from the workspace path; Q1 |
| 3 | Two same-named clones at different paths give different names | met | host `docker ps`, Q1: two running `codeo-home-…` names, `…031er9…` and `…1593q4…` |
| 4 | `tests/devcontainer.test.sh` pins the naming and the suite passes | met | `run_args_name_the_container_after_its_clone` (`tests/devcontainer.test.sh:71`); `bash tests/run.sh` → `all cases passed` |
| 5 | `runArgs` still carries `--memory=4g` and `--cpus=2` | met | `.devcontainer/devcontainer.json:7`; `run_args_cap_memory_and_cpus` |
| 6 | `CHANGELOG.md` records the change and the rebuild it needs | met | the `(#50)` bullet in `CHANGELOG.md` names the rebuild and the `docker rm` for a same-named leftover |

Criterion 2 is observed once, not twice: the engineer saw the expected name after one rebuild, and the name comes from `${devcontainerId}`, which depends on the workspace path alone.

Documentation: `CHANGELOG.md` only; no page under `docs/` describes the container name. The CHANGELOG says the suffix is `${devcontainerId}` and not a short hash, which departs from the issue's wording and matches plan Q3.

Independent review (opus, criteria and diff only): no Critical, no Important; ready to merge.

Findings, all non-blocking, none sending the change back:
- **F1** (non-blocking, plan's) — a clone folder name Docker rejects (a space, `+`, `@`, non-ASCII, or a leading `.` or `_`) now fails to start. Not mentioned in the CHANGELOG.
- **F2** (non-blocking, plan's) — `run_args_cap_memory_and_cpus` no longer catches an extra or duplicate `runArgs` entry.
- **F3** (non-blocking, implement's) — a cosmetic stray line in the test header comment.

No issue was filed in this pass. F1 and F2 go to the engineer at `/codeo:close`, or to `/codeo:issue` or `/codeo:triage` if worth keeping.

**Verdict: clear — forward to `/codeo:close`.**

## Log

- 2026-11-10 — Q1 raised (round 1; host checks outstanding) · cost: 3m · opus-5-5 161k in + 857k cached / 7k out · sonnet-5-5 108k in + 29k cached / 598 out
- 2026-11-10 — round 1 written: verdict clear · cost: 1m · sonnet-5-5 16k in + 112k cached / 1k out
