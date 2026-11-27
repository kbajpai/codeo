# Issue #188 — implement

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/188 |
| Branch | `docs/188-close-177-qc-leftovers-utc` |
| Updated | 2026-11-27 |

## Where this stands

All six tasks of `docs/plans/2026-11-27-close-177-qc-leftovers-188.md` are built, reviewed and committed. The build passes. Next: `/codeo:qc`.

## Questions

None.

## Notes

- Step 2a: `sync-main.sh` reported the branch already contains `origin/main`; no `also changed on` lines. `overlap.sh 188` printed nothing.
- Two minor review findings, deferred and not fixed here:
  - `tests/cleanup-skill.test.sh`: the new `while origin still holds` pin greps the whole skill file, so it would still pass if the phrase moved out of step 4.
  - `CHANGELOG.md`: the new `## Unreleased` bullet has no `(#188)` suffix, where the neighbouring bullets end with their issue number.

## Outcome

2026-11-27

**Built** — six tasks, one commit each, on top of `764f4f9`:

| Task | Commit | What changed |
|---|---|---|
| 1 | `bae6603` | `docs/release-checklist.md`: the UTC date "can differ by a day from the engineer's local date"; the stray comma in `CHANGELOG.md`'s v1.0.9 section is gone |
| 2 | `4d6eda6` | `skills/close/SKILL.md` step 17 drops the `refs/heads/` prefix before the allowlist and prints one delete "per branch that passes"; `tests/close-skill.test.sh` pins both |
| 3 | `66e4800` | `.codeo/overlays/{cleanup,close}.md` and their `templates/containers/` copies say the row is marked only when the script finds the tracker (`CODEO_TRACK` names it, else `codeo-track.sh` sits beside it); `tests/cleanup-skill.test.sh` and `tests/close-removal.test.sh` pin it |
| 4 | `c078ff5` | `docs/home-checkout.md`: the assignee lookup is described as running `gh` and getting nothing without `jq`; the tracking-comment section says with no tracker nothing is recorded and nothing is asked |
| 5 | `533354f` | `skills/cleanup/SKILL.md` step 4: a `name`-only failure gets a `leftover` line while origin still holds its `codeo-live/<N>/*` branches; pinned in `tests/cleanup-skill.test.sh` |
| 6 | `e667163` | `CHANGELOG.md`: one bullet under `## Unreleased` |

**Documentation pages changed:** `docs/release-checklist.md`, `docs/home-checkout.md`, `skills/close/SKILL.md`, `skills/cleanup/SKILL.md`, the two overlays and their templates, `CHANGELOG.md`. No documentation gap: nothing the code gained is left undocumented, and no script changed (`git diff --stat origin/main -- scripts lib hooks .sbx .devcontainer` prints nothing).

**Build result:** the `shell` suite's `build` is `true` and exits 0. The implementer also ran the whole `bash tests/run.sh` before each commit, ending `all cases passed`; grading the suite is `/codeo:qc`'s.

**Deviations from the plan, and why**
- Task 3's new test needle is plain `CODEO_TRACK names it`, not backticked: the sentence has the backticks around `CODEO_TRACK` in the plan's prose, but a needle with them cannot match across the words. The four overlay files carry plain `CODEO_TRACK`, byte-identical.
- Task 5's pin uses the file's `grep -qF … || check_fail` style rather than the `[[ ]]` form the plan wrote.
- Task 1's check greps `differ by a day from the` (the phrase wraps); Task 6's check diffs against `origin/main`, since local `main` can lag.
- The six tasks were sent to one implementer in order, with one commit per task (small same-shape edits), and reviewed as one unit over `764f4f9..e667163`: spec compliant on all six, no Critical or Important finding. No separate whole-branch review was run; `/codeo:qc`'s independent review follows. No `Deployed revision:`: no shared environment.

## Log

- 2026-11-27 — implemented docs/plans/2026-11-27-close-177-qc-leftovers-188.md: 6/6 tasks, build passes, review clean (2 minors deferred) · cost: 30m · sonnet-5-5 139k in + 3.9M cached / 22k out
