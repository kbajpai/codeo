# Issue #177 — qc

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/177 |
| Branch | `docs/177-close-163-166-168-leftovers` |
| Updated | 2026-11-25 |

## Where this stands

Round 1 stopped at step 2: `origin/main` gained #173 (`7d753fc`), and merging it conflicts in `CHANGELOG.md` and `docs/release-checklist.md`. The merge was aborted and the tree is as before. Nothing was built, run or reviewed. Verdict: back to `/codeo:implement` to resolve the merge. Nothing is open.

## Questions

None.

## Notes

None.

## Outcome

### Round 1 — 2026-11-25

**Base.** `sync-main.sh --abort-on-conflict` printed, exit 2:

```
sync-main: conflict: CHANGELOG.md
sync-main: conflict: docs/release-checklist.md
```

`origin/main` moved by one commit, `7d753fc` (#173, "close the #161 leftovers … release-checklist, changelog and README wording"), which changes `CHANGELOG.md` (7 lines) and `docs/release-checklist.md` (21 lines). Both are files this branch also changes: plan.md Q5 and Q7 answered *proceed and coordinate* with #173, so whoever merges second rebases them and keeps both sides. This branch merges second.

`overlap.sh 177` printed nothing (exit 0).

**Not run.** Steps 3-9 did not run: a conflict stops the pass at step 2 (`qc` resolves nothing).

**Criteria**

| # | Criterion | Verdict | Settled by |
|---|---|---|---|
| 1 | `README.md:256` and `:199` hold for a sandbox, and for `/codeo:doctor` and `live-signal.sh` without `jq` | not yet checkable — pass stopped at step 2 | — |
| 2 | `.codeo/overlays/cleanup.md` and `close.md` put the `git status` precondition before the removal commands and state when the row is marked | not yet checkable — pass stopped at step 2 | — |
| 3 | `CHANGELOG.md:20` no longer calls the README example invented; the `(#157)` clause is not repeated under `(#166)` | not yet checkable — pass stopped at step 2 | — |
| 4 | The close overlay's sandbox clause is complete, and `tests/track.test.sh` restores `TMPDIR` | not yet checkable — pass stopped at step 2 | — |
| 5 | `skills/cleanup/SKILL.md` step 4 names the leftover command for a run whose only output is a `failed name` issue | not yet checkable — pass stopped at step 2 | — |
| 6 | `skills/close/SKILL.md` makes the `<machine>` command usable at once, and says the branch stays on `origin` only when a beat pushed | not yet checkable — pass stopped at step 2 | — |
| 7 | The stale `(unstaged)` and `## Unreleased` lines in #168's workflow record are corrected or marked historical | not yet checkable — pass stopped at step 2 | — |
| 8 | The release checklist names the timezone for the changelog date | not yet checkable — pass stopped at step 2 | — |

**Findings**

- F1 — blocking, `/codeo:implement`'s: the branch conflicts with `origin/main` in `CHANGELOG.md` and `docs/release-checklist.md` after #173 merged (`7d753fc`). Resolve by merging `origin/main` (no rebase), keeping both sides: in `CHANGELOG.md`, #173's lines and this branch's `(#177)` bullet and three v1.0.9 corrections; in `docs/release-checklist.md` step 6, #173's wording and this branch's UTC-date sentence, then re-check that the UTC sentence still agrees with whatever #173 says about the date.

No issue was filed by this pass.

**Verdict: back to `/codeo:implement`.**

## Log

- 2026-11-25 — round 1: stopped at step 2, conflict with origin/main (#173) in CHANGELOG.md and docs/release-checklist.md; back to /codeo:implement · cost: 0m · opus-5-5 267k in + 26k cached / 601 out
