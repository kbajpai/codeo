# Issue #126 — qc

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/126 |
| Branch | `feat/put-issue-number-branch-name` |
| Updated | 2026-11-19 |

## Where this stands

Round 1 is graded: clear, with five non-blocking findings. Ready for `/codeo:close`.

## Questions

None.

## Outcome

### Round 1 — 2026-11-19

**Commands run, and what they printed.**

- `sync-main.sh --abort-on-conflict`: exit 0, `sync-main: the branch already contains origin/main`. No `also changed on` lines.
- `overlap.sh 126`: no output, exit 0. `overlap.sh --outside 126`: no output, exit 0, so the branch changed no file outside its plan's footprint.
- `scope.sh origin/main HEAD`: exit 0, `suite.shell=true` (needed for unclassified paths `.codeo/126/*`, `CHANGELOG.md`). No `deploy=` line: no environment is configured.
- Build (`true`, suite `shell`): exit 0.
- Test (`bash tests/run.sh`, suite `shell`, whole suite): in this checkout it exited 1 with only `live.test.sh` failing, 3 assertions: `beat_without_a_lock_or_on_the_base_branch_does_nothing — no lock: stamp: want [no] got [yes]`, `… — base: stamp: want [no] got [yes]`, `clear_deletes_the_ref_and_the_stamp — stamp gone: want [no] got [yes]`. From a clean `git worktree` of `HEAD` the same command printed `all cases passed`, exit 0. `implement.md` records the same split. The failing assertions concern the live-session heartbeat's throttle stamp kept in this checkout's git directory; no file the diff touches is involved. It is this container, not the change.
- Reviewer (opus, `QC review:`), given the acceptance criteria and the diff range `9f14461..f752dcb` only. It ran `tests/branch-name.test.sh` and `tests/init-skill.test.sh`, both passing.

**Documentation check.** `docs/dossier.md:158` and `docs/handoff.md:39` show `feat/12-order-export`, the shape `init` now cuts. A grep outside `.codeo/` and `docs/plans/` finds no remaining "number is never part of it", "There is no issue number in it." or "restore the title". `CHANGELOG.md` has a `## Unreleased` entry with the shape, config and safety lines. The plan says no wiki module and no other page moves; nothing else under `docs/` describes the branch name's derivation. The `claim.sh` header comments are covered at F1 and F2.

**Criteria.**

| Criterion | Verdict | Settled by |
|---|---|---|
| `branch-name.sh <N>` prints `<type>/<N>-<slug>` for a mapped label and for none (`chore`) | met | `scripts/branch-name.sh:52`; `tests/branch-name.test.sh` `feat/120-…`, `fix/5-fix-thing`, `chore/7-three-words-only`; passes in the clean worktree |
| Two issues with one title derive two different names | met | `tests/branch-name.test.sh`: `feat/20-same-title` and `feat/21-same-title` |
| `/codeo:init #<N>` cuts and pushes the numbered branch for a new issue | met | `skills/init/SKILL.md` step 6 (no row: derive `<type>/<N>-<slug>`, `ls-remote` absent, fresh claim) and `tests/init-skill.test.sh` wording checks; the skill is prose, so this is read and pinned by wording, not run |
| A workflow already on an old-style branch is resumed, not started a second time | met | `skills/init/SKILL.md` step 6 finds the branch by its dossier through `inflight.sh --branches` and runs `--carries` / `--stash-live` on it; reviewer checked `inflight.sh` `--branches` against that wording. Same caveat as above. Gap at F4 |
| `claim.sh` behaves as the plan decides for same-title issues, with matching tests and message | met | `scripts/claim.sh:211` new message; `tests/claim.test.sh:328-329` assert it and that "derives the same branch name" is gone |
| `tests/branch-name.test.sh`, `tests/run.sh` and the docs agree with the new shape; the old statement is gone | met | the test file expects the new shape; `tests/run.sh` has nothing shape-specific; docs and grep as above |

**Findings.** None blocking. Reviewer's verdict, quoted in plain text: no Critical or Important defects, "With fixes" for the minors below.

- F1 non-blocking, `/codeo:implement`'s: `scripts/claim.sh` header's "Known limit" sentence (about lines 42-46) describes another issue's merged-and-left branch whose *title derives N's name*. With the number in the name that cannot arise for branches `init` cuts, so the sentence is stale.
- F2 non-blocking, `/codeo:implement`'s: the `claim.sh` header (about line 29) says the exit-2 remedy is "rename or delete the branch on origin, as for a branch that is not a pipeline one", while line 221's message for that case still ends "or retitle #$n". Small imprecision.
- F3 non-blocking, `/codeo:implement`'s: `scripts/claim.sh:211` says a branch carrying another issue's dossier "under that name was pushed by hand", assuming `--carries` got the derived name. `init` also runs it on a branch found by its dossier, which may be old-style, so the stated cause can be false there (a branch with `.codeo/<N>/` but no `init.md`, plus another issue's dossier by path). Fringe.
- F4 non-blocking, `/codeo:plan`'s (a transition gap the plan did not cover): an old-style branch left on origin after a squash or rebase merge. Before, the derived name matched it and `--carries` reported the own archived dossier; now `inflight.sh` filters its row because the base holds `done/<N>`, the numbered name is not on origin, and `init` makes a fresh claim beside the leftover. Needs the issue to still be open after its merge. Reviewer's reading of `inflight.sh`, not reproduced here.
- F5 non-blocking, cosmetic: step 6 hard-codes `.codeo/<N>` and `.codeo/done/<N>`, as the rest of the skill and `claim.sh` do.
- N1 non-blocking, not the change's: `live.test.sh` fails in this container only (above). No issue filed.

No issue was filed by this pass. F1-F4 are polish or a narrow transition case, recorded here and not worth another round on their own.

**Verdict: clear — forward to `/codeo:close`.**

## Log

- 2026-11-19 — qc round 1: clear, 5 non-blocking findings · cost: 10m · opus-5-5 189k in + 2.7M cached / 16k out · sonnet-5-5 108k in + 299k cached / 898 out
