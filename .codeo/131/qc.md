# Issue #131 — qc

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/131 |
| Branch | `feat/make-sbx-sandbox-lock-follow` |
| Updated | 2026-11-19 |

## Where this stands

Round 1 is written: clear, forward to `/codeo:close`. No question is open.

## Questions

None.

## Notes

- Non-blocking, from this pass (routed to `/codeo:triage` once archived; none filed as an issue):
  - A sandbox lock still carrying `volume: unknown` (a sandbox made before the marker held the name, and every real sandbox until a plugin release and pin bump) goes through the close overlay's volume section, which says to find the container with `docker ps`. That advice does not fit a sandbox; `.sbx/README.md:66` says `end <N>` applies to it all the same.
  - `skills/close/SKILL.md:533-535` (the default text when there is no close overlay) says to run `git status` first because unpushed work "is lost with the volume"; a sandbox has no volume and `end` does its own unpushed check.
  - `tests/devcontainer.test.sh`: `ds_run` (line 501) does not unset `CODEO_SANDBOX_MARK`, and the marker now changes the lock arguments, so a runner environment that sets it to an existing file would fail the exact `take container` checks. The case `start_without_the_marker_ignores_the_callers_home_marker` also passes on the base revision, so it shows the property without catching the original failure.
  - `CHANGELOG.md:9` cites the internal finding labels F19, F20 and F21, which mean nothing to a reader of the changelog.

## Outcome

### Round 1 — 2026-11-19

**Scope.** `sync-main.sh`: the branch already contains `origin/main`. `overlap.sh 131`: no output. `overlap.sh --outside 131`: no output (nothing outside the footprint). `git diff origin/main...HEAD --stat`: 21 files, 840 insertions, 47 deletions. `scope.sh origin/main HEAD`:

```
scope: suite shell needed for unclassified paths:
  .codeo/131/implement.md
  .codeo/131/init.md
  .codeo/131/issue.md
  .codeo/131/plan.md
  CHANGELOG.md
suite.shell=true
```

No `deploy=` line: no shared environment is configured, so step 9 does not apply and nothing here is about one.

**Build.** Suite `shell`, build `true`: nothing to build, exit 0.

**Tests.** `bash tests/run.sh` (the suite's whole `test` command): `all cases passed`, exit 0, no `=== FAIL` or `failed:` line.

**Acceptance criteria.**

| # | Criterion | Settled by | Verdict |
|---|---|---|---|
| 1 | Sandbox lock has `sandbox: codeo-<N>`, no `volume:` line | `tests/lock.test.sh` "container, sandbox lock"; `tests/devcontainer.test.sh` `start_in_a_sandbox_passes_the_sandbox_to_the_lock` | met (in this tree; a real sandbox shows it once a plugin release and pin bump carry `lock.sh`) |
| 2 | No "could not read the workspace volume's name" TODO in a sandbox | same cases; `scripts/lock.sh` writes the sandbox line with no TODO | met (same caveat) |
| 3 | Close names `codeo-sandbox.sh end <N>`, no `docker rm` / `docker volume rm` for a `sandbox:` lock | `.codeo/overlays/close.md` sandbox section; `tests/close-removal.test.sh` checks e and f with mutants | met |
| 4 | Dev container lock's `volume:` line and TODO unchanged | `tests/lock.test.sh` "container, volume read" and "container, volume unreadable"; `start_without_a_marker_takes_the_lock_as_before` | met |
| 5 | Tests cover sandbox lock, dev container lock, and close's report for both | the cases above plus `tests/close-removal.test.sh` for volume and sandbox | met |
| 6 | Failing `exec` makes `issue` print a `codeo-sandbox:` line naming the next step; a test covers it | `tests/sandbox.test.sh` `issue_names_the_next_step_when_the_start_script_fails` | met |
| 7 | `issue` on an existing sandbox succeeds with the pin unreadable; a test covers it | `issue_rerun_needs_no_pin` | met |
| 8 | `end`'s failed state fetch names a way to remove the sandbox, with and without `--force`; a test covers it | `end_names_a_way_out_when_a_stopped_sandbox_cannot_start` | met |
| 9 | Dev container test without the marker passes when `$HOME/.codeo-sandbox` exists, and a test shows it | `start_without_the_marker_ignores_the_callers_home_marker` | met |
| 10 | A failed `run -d` in `issue` has a test | `issue_with_a_failed_run_d_is_one_line` | met |
| 11 | No test reads `CHANGELOG.md` by line number | `docs_changelog_names_the_sandbox_lock` finds its bullet by content; `grep -n` over `tests/*.sh` shows no line-number read of the CHANGELOG | met |
| 12 | `tests/run.sh` passes | the run above, exit 0 | met |

**Documentation.** The change moves the lock's `sandbox:` line, the marker, the `issue` step and `end`'s way out. Pages changed: `docs/handoff.md`, `docs/extension-points.md`, `.sbx/README.md` (marker, `issue` diagram, unreadable-sandbox paragraphs), `.devcontainer/README.md`, `CHANGELOG.md` (`## Unreleased`). The lines added to the pages under `docs/`, `.sbx/` and `.devcontainer/` contain no "now", "no longer" or issue number. No overlay or invariants file applies (`invariants-extra`: exit 3; `wiki-rules`: exit 3; no `$INVARIANTS`, no `wiki` module).

**Independent review.** Dispatched on `opus` with the acceptance criteria and the range `9f14461..ccbc5ac`, with no implementer account. It ran `lock`, `sandbox`, `close-removal` and `live` tests, all passing. Reviewer's verdict, quoted in plain text: no Critical and no Important finding; ready to merge, with four minor findings.

**Findings.** All four are `non-blocking` and `/codeo:implement`'s in kind (code and wording, none of it the plan's):
- F1 (non-blocking) — close overlay, `volume: unknown` on a sandbox: sends the engineer to `docker ps` (`.codeo/overlays/close.md:9,25`). Confirmed in the overlay: it routes by the `volume:` / `sandbox:` line only. The plan ruled old `volume: unknown` locks not recognised (Q4), so this is a known limit, recorded here.
- F2 (non-blocking) — `skills/close/SKILL.md:533-535`: default text says "unpushed work is lost with the volume" for a `sandbox:` lock too. Confirmed. Shows only with no close overlay.
- F3 (non-blocking) — `tests/devcontainer.test.sh:501`: `ds_run` does not unset `CODEO_SANDBOX_MARK`. Confirmed in the `env -u` list. Latent; the suite passes.
- F4 (non-blocking) — `CHANGELOG.md:9` cites F19/F20/F21. Confirmed (one match).

Findings set aside by the reviewer (the `end` path when `sbx ls` itself fails, a directory as the marker, wording of "the only copy") are not about lines this change makes wrong; none is a finding.

No issue was filed by this pass.

**Verdict: clear — forward to `/codeo:close`.**

## Log
- 2026-11-19 — qc round 1 · clear, 4 non-blocking findings · cost: 5m · opus-5-5 181k in + 2.1M cached / 19k out · sonnet-5-5 91k in + 29k cached / 458 out
