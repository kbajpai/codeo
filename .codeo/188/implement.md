# Issue #188 — implement

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/188 |
| Branch | `docs/188-close-177-qc-leftovers-utc` |
| Updated | 2026-11-27 |

## Where this stands

Round 4 is built: Tasks 10-11 of `docs/plans/2026-11-27-close-177-qc-leftovers-188.md` (after plan round 3), reviewed and committed; the branch also carries round 3's merge of `origin/main`. The build passes. Next: `/codeo:qc`.

## Questions

None.

## Notes

- Step 2a: `sync-main.sh` reported the branch already contains `origin/main`; no `also changed on` lines. `overlap.sh 188` printed nothing.
- Round 1 deferred two minor review findings; Round 2 fixes both (the pin now reads step 4, the changelog bullet names its issue):
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


### Round 2

2026-11-27
(send-back from qc.md round 1)

Round 2 starts from the base branch: `sync-main.sh` reported the branch already contains `origin/main`; `overlap.sh 188` printed nothing. QC's findings were checked against the code before any work: F1 reproduced (with `jq` off `PATH`, `github.sh issue view` exits 1 on `config.json: invalid JSON` and never calls `gh`), F2 holds (`.sbx/codeo-sandbox.sh:22` has no fallback when `CODEO_TRACK` names a missing file), F3 holds (`scripts/cleanup.sh:119` accepts only `[A-Za-z0-9._-]` names), F5 holds. F4 (pins for the docs sentences) is out of scope by the engineer's answer (`plan.md` Q8).

**Built** — three tasks, one commit each, on top of `7d1c573`:

| Task | Commit | What changed |
|---|---|---|
| 7 | `44f7c5b` | `docs/home-checkout.md`: the assignee lookup is described as stopping at `github.sh`'s `jq` read of `.codeo/config.json`, before `gh` (QC F1); the tracker sentence says "when that file is missing" (QC F2) |
| 8 | `19e36d8` | `skills/cleanup/SKILL.md` step 4: "while origin still holds a validly named `codeo-live/<N>/*` branch" (QC F3); in `tests/cleanup-skill.test.sh` the whole-file `while origin still holds` check is gone and a pin on the `step4` variable replaces it (QC F5) |
| 9 | `92e7d92` | `CHANGELOG.md`: the Unreleased bullet ends "No script changed (#188)." (QC F5) |

**Documentation pages changed:** `docs/home-checkout.md`, `skills/cleanup/SKILL.md`, `CHANGELOG.md`. No documentation gap; no script changed (`git diff --stat origin/main -- scripts lib hooks .sbx .devcontainer` prints nothing).

**Build result:** the `shell` suite's `build` is `true` and exits 0. The implementer ran the whole `bash tests/run.sh` before the Task 8 and 9 commits, ending `all cases passed`, and Task 8's pin failed before its wording change and passed after; grading the suite is `/codeo:qc`'s.

**Deviations from the plan:** none. The three tasks went to one implementer, one commit per task, and were reviewed as one unit over `7d1c573..92e7d92`: spec compliant on all three, no Critical or Important finding, one Minor that needs no change. No separate whole-branch review was run; `/codeo:qc` round 2 reviews the whole diff independently. No `Deployed revision:`: no shared environment.


### Round 3

2026-11-27
(send-back from close.md round 2)

Pull request #209 failed to merge: `CHANGELOG.md` conflicted with `main` after #195 (PR #208, `c7505a9`) merged first. No plan task: this round is step 2a's work.

**Merge.** `sync-main.sh` merged `origin/main` and stopped on one conflict, `CHANGELOG.md`, under `## Unreleased`: #195 rewrote the `Shared state:` line and added its `/codeo:init` bullet; this branch added its documentation-leftovers bullet. The two bullets are independent entries, so both are kept (this branch's first, then #195's), and #195's `Shared state:` line stands. Merge commit `887beb2`; `git merge-tree --write-tree --name-only origin/main HEAD` now exits 0 and `overlap.sh 188` prints nothing.

**Also changed on `main`** (merged cleanly, re-checked against this branch's work):
- `scripts/live.sh`, `scripts/github.sh`, `lib/env.sh` — the F1 sentence in `docs/home-checkout.md:9` still holds: `assignee_label` still calls `github.sh`, which still reads `.repo.owner` through `codeo_cfg_required` and `jq empty` (`scripts/github.sh:28`, `lib/env.sh:86`) before any `gh` call. #195 dropped `CODEO_GITHUB_LOGIN` from `live.sh`'s `user_label`; the sentence names neither.
- `skills/close/SKILL.md` and `tests/close-skill.test.sh` — the F3 wording ("drop the `refs/heads/` prefix first", "per branch that passes") and its two pins (`tests/close-skill.test.sh:232-233`) are intact.
- `docs/handoff.md`, `docs/skills.md`, `docs/dossier.md`, `README.md`, `skills/{init,plan,implement,qc}/SKILL.md`, `tests/` — no sentence this branch changed is among them.

Spot checks on the merged tree: `home-checkout.md` still carries "stops before it reaches `gh`" and "when that file is missing, the scripts"; `skills/cleanup/SKILL.md` still says "validly named"; `CHANGELOG.md` carries one `(#188)`; `overlap.sh --outside 188` prints nothing.

**Built:** nothing beyond the merge and the conflict resolution; no documentation page changed in this round. **Build result:** the `shell` suite's `build` is `true` and exits 0; the suite itself is `/codeo:qc`'s. **Deviations from the plan:** none; no `Deployed revision:`, no shared environment.


### Round 4

2026-11-27
(after plan.md round 3)

Round 4 starts from the base branch: `sync-main.sh` reported the branch already contains `origin/main`; `overlap.sh 188` printed nothing. It builds the two tasks `plan.md` round 3 added after QC round 3's send-back (its F8, blocking, and F9, non-blocking). The finding was weighed in the plan, which observed `live.sh`'s `user_label` without `jq` (`host=container` gave the `git config user.name` value, `host=web` gave `unknown`, `gh` was called 0 times) before writing the tasks; nothing was left to ask.

**Built** — two tasks, one commit each, on top of `c5633fc`:

| Task | Commit | What changed |
|---|---|---|
| 10 | `55eb82e` | `docs/home-checkout.md:9`: without `jq`, `live.sh` takes the signal's user from `git config user.name`; its `github.sh` calls stop at the `jq` read of `.codeo/config.json` before `gh`; only a hosted web session asks for the issue's assignee, and there, without `jq`, that lookup yields nothing and the user reads `unknown` (QC F8) |
| 11 | `17fef72` | `.codeo/overlays/cleanup.md` and `templates/containers/.codeo/overlays/cleanup.md`: the tracker clause is one parenthesis, "sits beside it; otherwise it prints a note: …" (QC F9) |

**Documentation pages changed:** `docs/home-checkout.md`, `.codeo/overlays/cleanup.md` and its template. No documentation gap; no script changed (`git diff --stat origin/main -- scripts lib hooks .sbx .devcontainer` prints nothing), and `overlap.sh --outside 188` prints nothing.

**Build result:** the `shell` suite's `build` is `true` and exits 0. The implementer ran the whole `bash tests/run.sh` once with both edits in the tree, ending `all cases passed`, then committed the two tasks separately; grading the suite is `/codeo:qc`'s.

**Deviations from the plan:** none beyond process: Task 10's proof greps were run with `grep -c -F` and double-quoted patterns because the apostrophes in "signal's" and "issue's" break the plan's single-quoted form. The two tasks went to one implementer, one commit per task, and were reviewed as one unit over `c5633fc..17fef72`: spec compliant on both, no Critical or Important finding, one Minor deferred (the phrase "from `git config user.name`" is unqualified in its own clause, and the next sentence covers the hosted case). No separate whole-branch review was run; `/codeo:qc` round 4 reviews the whole diff independently. No `Deployed revision:`: no shared environment.

## Log

- 2026-11-27 — implemented docs/plans/2026-11-27-close-177-qc-leftovers-188.md: 6/6 tasks, build passes, review clean (2 minors deferred) · cost: 30m · sonnet-5-5 139k in + 3.9M cached / 22k out
- 2026-11-27 — round 2 (send-back from qc.md round 1): implemented Tasks 7-9 of docs/plans/2026-11-27-close-177-qc-leftovers-188.md, 3/3, build passes, review clean · cost: 15m · sonnet-5-5 90k in + 4.1M cached / 16k out
- 2026-11-27 — round 3 (send-back from close.md round 2): merged origin/main, resolved CHANGELOG.md (kept both bullets), re-checked the F1 and F3 sentences against #195's changes, build passes · cost: 1m · sonnet-5-5 15k in + 1.8M cached / 3k out
- 2026-11-27 — round 4 (after plan.md round 3): implemented Tasks 10-11, 2/2, build passes, review clean (1 minor deferred) · cost: 8m · sonnet-5-5 112k in + 3.8M cached / 14k out
