# Issue #100 — qc

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/100 |
| Branch | `chore/release-v1-0-7-once` |
| Updated | 2026-11-18 |

## Where this stands

Round 1 is written and the verdict is clear. Nothing is open.

## Questions

None.

## Notes

- Later work, not filed from this checkout: `tests/live.test.sh` lines 227, 234 and 373 test `[[ -e $(git -C "$clone" rev-parse --git-path codeo-live-beat) ]]`, a path relative to the current directory rather than to the clone, so the suite fails in any checkout whose own `.git/codeo-live-beat` exists, which is every checkout with a running workflow. File it with `/codeo:issue` in the checkout the project's role check allows.

## Outcome

### Round 1 — 2026-11-18

**Sync and scope.** `sync-main.sh` merged `origin/main` (1 commit, the release merge `7b25bc2`); `overlap.sh 100` printed nothing; `overlap.sh --outside 100` printed nothing. `git diff origin/main...HEAD --stat`: six files — `.codeo/100/{implement,init,issue,plan}.md`, `.codeo/config.json` (one line), `docs/plans/2026-11-18-release-v1-0-7.md`. `scope.sh origin/main HEAD` printed `suite.shell=true` (`suite shell needed for unclassified paths: .codeo/100/*, .codeo/config.json`). No `deploy=` line: no environment is configured.

**Build.** Suite `shell`, build `true`: exit 0.

**Suites.** `bash tests/run.sh` on this branch: `FAIL: beat_without_a_lock_or_on_the_base_branch_does_nothing — base: stamp: want [no] got [yes]`, `FAIL: clear_deletes_the_ref_and_the_stamp — stamp gone: want [no] got [yes]`, `3 assertion(s) failed`, `failed: live.test.sh`. Root cause (Phase 1): the assertions at `tests/live.test.sh:227,234,373` read `git -C "$clone" rev-parse --git-path codeo-live-beat`, which prints the relative `.git/codeo-live-beat`, and test it from the working directory, not the clone; this checkout has its own `.git/codeo-live-beat` (written 20:42 by this workflow's live heartbeat), so the test sees `yes`. The diff changes no test and no script (`git diff 7b25bc2 HEAD --stat -- tests` is empty). The same suite in a clean clone at `7b25bc2475ad1b9e66f8a85b364355425dbde2e2` (cloned from origin, version `1.0.7`): `all cases passed`, `test=0`.

**Acceptance criteria**

| # | Criterion | Verdict | Settled by |
|---|---|---|---|
| 1 | #70, #71, #96, #97, #98 closed before the release PR opened | met | `gh issue view`: all `CLOSED`, 2026-11-15 to 2026-11-16; PR #127 created 2026-11-18T20:06:12Z |
| 2 | Changelog entry for each of the five, plus existing | met | `origin/main:CHANGELOG.md` v1.0.7 section holds `#70`:1, `#71`:1, `#96`:2, `#97`:1, `#98`:1, `#99`:1 |
| 3 | `plugin.json` 1.0.7, `## v1.0.7 — <date>` replaces `## Unreleased`, merged by PR | met | `origin/main:.claude-plugin/plugin.json` `.version` is `1.0.7`; `CHANGELOG.md:3` `## v1.0.7 — 2026-11-18`; PR #127 `MERGED` 2026-11-18T20:12:39Z as `7b25bc2` |
| 4 | `bash tests/run.sh` in a clean clone of the merged commit ends `all cases passed` | met | clean clone at `7b25bc2`: `all cases passed`, `test=0` |
| 5 | `git ls-remote --tags origin` lists `v1.0.7` at the merged commit | met | `7b25bc2475ad1b9e66f8a85b364355425dbde2e2 refs/tags/v1.0.7`; `git cat-file -t v1.0.7` is `commit` (lightweight) |
| 6 | `gh release view v1.0.7` shows a release | met | `v1.0.7 v1.0.7 false false 2026-11-18T20:25:21Z` (tag, name, draft, prerelease, published) |
| 7 | `plugin.ref` is `v1.0.7`, merged through its own PR | not yet checkable — the PR is `/codeo:close`'s to open, as the plan says | `.codeo/config.json` reads `v1.0.7` on this branch (`jq -r .plugin.ref`) |
| 8 | Installed plugin reports v1.0.7 after rebuild | met | `claude plugin list`: `codeo@codeo` `Version: 1.0.7` for scope user and scope project |

**Documentation.** The plan names no page and the diff changes no behaviour. `grep` for `1.0.6`/`1.0.7` under `docs/` outside `docs/plans/` finds only `docs/dev-environment-sbx-evaluation.md` lines 83, 104, 277, 288, 289, which are recorded observations of an installation made on 2026-11-14/15 and stay as observed. No wiki module, and no documentation-rules overlay (exit 3).

**Independent review** (Opus, given the criteria only). No critical or important findings; assessment "Ready to merge: Yes". It re-checked criteria 1-6 and 8 against GitHub, the tag, a fresh clean clone and the installed plugin. It reported four stale sentences in dossier files (below).

**Findings**

- F1 — non-blocking, belongs to neither skill: `tests/live.test.sh:227,234,373` test a relative `--git-path` from the wrong directory, so `live.test.sh` fails in a checkout that has a live heartbeat. Pre-existing and outside this diff (qc-02); recorded under `## Notes` as later work.
- F2 — non-blocking, plan's: the reviewer reports `.codeo/100/plan.md` "Where this stands" still names `plan-draft.md` as awaiting approval, its Outcome table calls the committed plan "unstaged", and two changelog line numbers in it are off by one (#71 at line 11, the #99 bullet at line 9); `.codeo/100/issue.md` "Where this stands" still reads as a draft. These are other skills' dossier files, which are not edited here, and no criterion depends on them. I did not re-verify the line numbers.

No issue was filed from this pass.

**Verdict: clear — forward to `/codeo:close`.**

## Log

- 2026-11-18 — Round 1: build ok; shell suite failed on this branch for a checkout-local reason (live.test.sh, F1) and passed in a clean clone of the merge commit; criteria 1-6 and 8 met, 7 left to close's PR; review clear; verdict clear · cost: 8m · opus-5-5 156k in + 1.9M cached / 12k out · sonnet-5-5 77k in + 965k cached / 2k out
