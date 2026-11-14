# Issue #61 — qc

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/61 |
| Branch | `chore/release-v1-0-4-main` |
| Plan | `docs/plans/2026-11-14-release-v1-0-4.md` |
| Updated | 2026-11-14 |

## Where this stands

Round 1 done: clear, forward to `/codeo:close`. No question is open.

## Questions

None.

## Notes

- `sync-main.sh`: `the branch already contains origin/main`. `overlap.sh 61` and `overlap.sh --outside 61` printed nothing.
- `scope.sh origin/main HEAD` printed `suite.shell=true` (unclassified paths `.codeo/61/*` and `.codeo/config.json`). No environment is configured, so there is no `deploy=` line and no step 9.
- Overlays `invariants-extra`, `wiki-rules`, `environment-evidence`: exit 3, none set. No invariants file, no `wiki` module.

## Outcome

### Round 1 — 2026-11-14

**Build.** Suite `shell`, build command `true`: exit 0.

**Tests.** `bash tests/run.sh` at head `b528f44`: exit 0, last line `all cases passed`. Clean clone of `cf4618e` (fresh `git clone`, `git checkout --detach`; `git rev-parse HEAD` printed `cf4618eed5d3c5f083db6b8f723ec4f02f5a7f38`, version `1.0.4`): `bash tests/run.sh` last line `all cases passed`.

**Acceptance criteria.**

| # | Criterion | Verdict | Settled by |
|---|---|---|---|
| 1 | `plugin.json` says `1.0.4`, changelog has `## v1.0.4 — <date>`, merged by PR | met | `gh pr view 62` → `MERGED`, base `main`, merge `cf4618e`, files `.claude-plugin/plugin.json` and `CHANGELOG.md` only; `origin/main` `plugin.json` version `1.0.4`, `CHANGELOG.md:3` is `## v1.0.4 — 2026-11-14`, no `## Unreleased` heading in the first three headings |
| 2 | `tests/run.sh` in a clean clone of the merged commit ends `all cases passed` | met | clean-clone run above, at `cf4618e` |
| 3 | `git ls-remote --tags origin` lists `v1.0.4` at the merged commit | met | `032b435… refs/tags/v1.0.4` and `cf4618eed5d3c5f083db6b8f723ec4f02f5a7f38 refs/tags/v1.0.4^{}` (annotated tag, names the merge commit) |
| 4 | `gh release view v1.0.4` shows a release | met | `["v1.0.4","release: v1.0.4",false,false,"2026-11-14T01:28:38Z"]` (not draft, not prerelease) |
| 5 | `.codeo/config.json` `plugin.ref` is `v1.0.4`, merged through its own PR | met | `git diff origin/main...HEAD -- .codeo/config.json` changes the one line `"ref": "v1.0.3"` → `"v1.0.4"`; the PR is `/codeo:close`'s to open from this branch, which is the plan's design |
| 6 | After rebuild the plugin reports v1.0.4 and lowercase `board.sh set <N> ready` is accepted | met | `claude plugin list`: `codeo@codeo` `Version: 1.0.4` for user and project scope; `board.sh set 61 ready` printed `#61 In progress → Ready on #3 Codeo`, exit 0; `set 61 inProgress` printed `#61 Ready → In progress on #3 Codeo`, exit 0; `status 61` printed `In progress` |

**Documentation.** The plan moves no page and none names a version or the pin: `grep` for `v1.0.N`, `plugin.ref` and `"ref"` in `docs/` (outside `docs/plans/`) and `README.md` found nothing. The claim holds.

**Code review.** Independent reviewer on `opus`, given the criteria only. It found no critical or important defect and confirmed criteria 1-4 and 6 itself (including its own clean-clone run), and criterion 5's one-line diff. Its three minor findings are F1-F3 below.

**Findings.**

- F1 — non-blocking, `/codeo:plan`'s file. `.codeo/61/plan.md` `## Where this stands` still reads `Q1-Q3 raised, waiting for answers. Nothing is drafted yet.`, which is untrue at head (all three answered, plan committed in `544ad4b`). Recorded; `qc` does not edit another skill's dossier.
- F2 — non-blocking, same file. `.codeo/61/plan.md` `## Outcome` says the plan file is `(unstaged, approved 2026-11-14)`; it is committed. Stale record only.
- F3 — non-blocking, this checkout. The local tag `v1.0.4` is a different tag object (`b76a237`) from the remote's (`032b435`), though it names the same commit `cf4618e`. It does not affect any criterion, and the remote tag is the one criterion 3 reads. Deleting the local tag (`git tag -d v1.0.4`) before a later `git fetch --tags` avoids a clobber warning; that is the engineer's call.

No issue was filed by this pass. No blocking finding.

**Verdict: clear — forward to `/codeo:close`.**

## Log

- 2026-11-14 — round 1: clear, forward to /codeo:close · cost: 7m · opus-5-5 142k in + 1.5M cached / 11k out · sonnet-5-5 75k in + 632k cached / 1k out
