# Issue #168 — qc

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/168 |
| Branch | `feat/release-v1-0-9-once` |
| Updated | 2026-11-25 |

## Where this stands

Round 1 is written and the verdict is clear. Nothing is open. The next step is `/codeo:close`.

## Questions

None.

## Notes

- The reviewer's four minor observations are recorded as non-blocking findings F1-F4 below; none sends the change back.
- No invariants file, no shared environment and no `wiki` module are configured; the overlays `qc/invariants-extra` and `qc/wiki-rules` are not set (exit 3).

## Outcome

### Round 1 — 2026-11-25

**Sync and overlap.** `sync-main.sh --abort-on-conflict` printed `sync-main: the branch already contains origin/main` (exit 0), so there are no `also changed on main` lines. `overlap.sh 168` printed nothing (exit 0). `overlap.sh --outside 168` printed nothing (exit 0): no file outside the plan's footprint.

**Diff.** `git diff origin/main...HEAD --stat`: `.codeo/168/{implement,init,issue,plan}.md`, `.codeo/config.json` (one line, `plugin.ref` `v1.0.8` to `v1.0.9`) and `docs/plans/2026-11-25-release-v1-0-9.md`; 6 files, 414 insertions, 1 deletion. The release PR's four files are already on `main` as `6e66283`.

**Scope.** `scope.sh origin/main HEAD` printed `scope: suite shell needed for unclassified paths:` (the `.codeo/168/*` files and `.codeo/config.json`) and `suite.shell=true`. No `deploy=` line: no environment is configured.

**Build.** Suite `shell`, build command `true`: exit 0.

**Tests.** Suite `shell`, `bash tests/run.sh` in this checkout: exit 0, last line `all cases passed`. In a fresh clone checked out at `6e6628336c9bd40037c1cd7c80c8694f0ecddc21`: `HEAD` equals that SHA, `"version": "1.0.9"`, `bash tests/run.sh` exit 0, last line `all cases passed`.

**Criteria.**

| # | Criterion | Settled by | Verdict |
|---|---|---|---|
| 1 | #163 and #166 closed before the release PR opened | `gh issue view`: #163 `CLOSED 2026-11-25T03:20:58Z`, #166 `CLOSED 2026-11-25T02:32:19Z`; PR #174 `createdAt 2026-11-25T03:57:08Z` | met |
| 2 | Changelog entry for each gating issue, beside the existing entries | `git show origin/main:CHANGELOG.md`: the `## v1.0.9 — 2026-11-25` section has a `(#166)` bullet and a `(#163)` bullet, plus the #154 and #157 bullets | met |
| 3 | `plugin.json` says `1.0.9`; `## v1.0.9 — <date>` replaces `## Unreleased`; merged through a PR | `git show origin/main:.claude-plugin/plugin.json` prints `"version": "1.0.9"`; `grep -c '^## Unreleased'` on `origin/main:CHANGELOG.md` prints `0`; PR #174 `MERGED` at `2026-11-25T04:05:35Z`, files `plugin.json`, `CHANGELOG.md`, `README.md`, `tests/install.test.sh` | met |
| 4 | `bash tests/run.sh` in a clean clone of the merged commit ends `all cases passed` | the clean-clone run above | met |
| 5 | `v1.0.9` in `git ls-remote --tags origin` at the merged commit | `6e6628336c9bd40037c1cd7c80c8694f0ecddc21	refs/tags/v1.0.9`, equal to `origin/main`'s tip `6e66283` | met |
| 6 | `gh release view v1.0.9` shows a release | `tagName v1.0.9`, `isDraft false`, `isPrerelease false`, `publishedAt 2026-11-25T04:16:07Z`; `gh release list` marks it `Latest` | met |
| 7 | `plugin.ref` is `v1.0.9`, merged through its own pull request | `.codeo/config.json` on this branch: `"ref": "v1.0.9"` (diff above); the pull request is the one `/codeo:close` opens | not yet checkable — the branch carries the pin, and the merge is `/codeo:close`'s step, as the plan says |
| 8 | After a rebuild, the installed codeo reports v1.0.9 | `claude plugin list` in this container: `codeo@codeo` `Version: 1.0.9` at user scope and at project scope | met |

**Documentation.** The plan moves `README.md` only, in the release PR. On `origin/main` its version numbers read v1.0.9 as the latest and v1.0.8 as the older example, and no `1.0.7` is left. A search of `README.md`, `docs/` and `.devcontainer/` for `v1.0.8` found only the README's older-version examples and the CHANGELOG's own history. No page under `docs/` describes a behaviour this change moves.

**Independent review** (opus, `QC review:`; given the criteria and the range, not the implementer's account). Its assessment, in plain text: Ready to merge, yes; no critical and no important issues. It checked the four release files, the install test's two ordering stubs, the changelog bullets and the #163 bullet's claim against `scripts/cleanup.sh:29-30`, the tag, the Release body against the changelog section, the pin as a one-line change, and found no other live pin in the repository. It also ran the suite in a fresh clone of `HEAD`: `all cases passed`.

**Findings.**

- F1 — non-blocking — `/codeo:implement`'s: `.codeo/168/plan.md:11` and `:62` still say the plan file is `(unstaged)`; it was committed in `d71d60f`. A stale status line in a workflow record.
- F2 — non-blocking — `/codeo:plan`'s: `.codeo/168/init.md:26` says #161 sits under `## Unreleased`; it had no bullet. `plan.md` records the correction (Q2 and the Intake note).
- F3 — non-blocking — `/codeo:plan`'s: the plan's Task 1 Step 6 expects `grep -c 'refs/tags/v1.0.8' tests/install.test.sh` to print `2`; it prints `9`. `implement.md` records this deviation and its cause.
- F4 — non-blocking — nobody's: the changelog date `2026-11-25` is the UTC date of the PR, which was opened on 2026-11-24 in local time (-0500). The plan says "the day the release PR opens" without a timezone.

No issue was filed for this pass.

**Verdict: clear — forward to `/codeo:close`.**

## Log

- 2026-11-25 — round 1: build and suite passed, 7 of 8 criteria met and 1 for `/codeo:close`, review clean; verdict clear · cost: 11m · opus-5-5 134k in + 2M cached / 11k out · sonnet-5-5 93k in + 268k cached / 350 out
