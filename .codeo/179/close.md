# Issue #179 — close

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/179 |
| Branch | `docs/179-close-171-leftovers-readme-wording` |
| Updated | 2026-11-26 |

## Where this stands

Pull request #187 is open but its `tests` check fails in CI (`readme.test.sh`, the `adopting-guard` check). The workflow goes back to `/codeo:implement`, then `/codeo:qc`, then `/codeo:close`.

## Questions

None.

## Notes

- The lookup sees only the newest pull request for the branch; none exists.

## Outcome

### Round 1 — conflicts with main

2026-11-26

`git merge-tree --write-tree --name-only origin/main HEAD` exits 1:

- `tests/readme.test.sh` — content conflict. The change on `main` that touched it: `3a36e47 docs: close the #163, #166 and #168 leftovers: home-checkout jq and sandbox wording, overlay order, cleanup closing block, close step 17, changelog and checklist (#177) (#186)`. It also changed `docs/home-checkout.md`, which merged without a conflict. This is the overlap raised and answered at plan (`plan.md` Q7, proceed and coordinate).

qc round at review: 3

### Round 2 — pull request opened

2026-11-26

#187 https://github.com/kbajpai/codeo/pull/187

Went out on `qc.md` round 4: **Verdict: clear — forward to `/codeo:close`.** The `qc round at review` of round 1 was 3, so round 4 is newer. No override.

### Round 3 — review feedback

2026-11-26

The `tests` check of pull request #187 fails, so the pull request is blocked from merging (`mergeStateStatus` `BLOCKED`, `mergeable` true; `qc-verdict` passes). It failed on the first run and again on a re-run of the failed job, so it is not a flake:

- https://github.com/kbajpai/codeo/actions/runs/45734195351 — job `tests`, step "Run the test suite", `bash tests/run.sh`:

```
=== FAIL: readme.test.sh
FAIL adopting-guard: docs/home-checkout.md has no line "## Adopting the guard in your project"
failed: readme.test.sh
```

The heading is in the file the check ran on (`refs/pull/187/merge` has `## Adopting the guard in your project` at `docs/home-checkout.md:39`), and the same check's next lines, which read the section through `section()`, did not fail. `bash tests/run.sh` and `bash tests/readme.test.sh` pass locally and in a clean worktree (40 of 40 runs here).

Likely cause, for `/codeo:implement` to confirm, not proven here: `tests/readme.test.sh:273` is `prose docs/home-checkout.md | grep -qxF '## Adopting the guard in your project' || fail …` under `set -euo pipefail`. `grep -q` exits at the first match, line 39 of a page that is now about 9.7 KB, while `awk` is still writing; the writer can die of SIGPIPE, `pipefail` then makes the pipeline fail although the line was found, and `|| fail` fires. That is the hazard `qc.md` rounds 1 and 4 recorded as non-blocking and theoretical (I3); CI shows it is not. The file has 22 such `… | grep -q…` pipelines. Fix: read the output into a variable (or use `grep … <(…)`, as other checks in the file already do) wherever the producer's output can be longer than the match, then check that the failure is gone with the pull request's CI.

qc round at review: 4

## Log

- 2026-11-26 — conflicts with main: `tests/readme.test.sh` after #177; sent back to implement · cost: 0m · sonnet-5-5 25k in + 1.1M cached / 1k out
- 2026-11-26 — opened PR #187 on qc round 4 (clear), archived the dossier · board.sh: #179 In review → In review on #3 Codeo · cost: 0m · sonnet-5-5 23k in + 877k cached / 3k out
- 2026-11-26 — CI failure on PR #187 sent back to implement: tests/readme.test.sh adopting-guard, likely SIGPIPE under pipefail · board.sh: #179 In review → In progress on #3 Codeo · cost: 19m · sonnet-5-5 36k in + 6.8M cached / 10k out
