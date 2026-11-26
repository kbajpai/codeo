# Issue #182 — qc

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/182 |
| Branch | `feat/182-release-v1-0-10-once` |
| Updated | 2026-11-26 |

## Where this stands

Round 1 is written and the verdict is clear: no blocking finding. Eight of the nine acceptance criteria are met; criterion 8 (the pin merged through its own pull request) is the pull request `/codeo:close` opens, so it is not yet checkable. Next step: `/codeo:close`.

## Questions

None.

## Notes

No shared environment, invariants document, `wiki` module or overlay rules are configured, so steps 6's overlay rules and 9 did not apply. `/codeo:issue` is refused in this checkout (role `issue:182`), so the three non-blocking findings are recorded here as promised work, with no issue number, for `/codeo:triage` to collect:
- Will file: the README says an unusable config skips only `ruleset` (README.md lines 173 and 466); `codename`, `gh-scopes`, `board` and `suites` also print `fail …: skipped: config is unusable` (`scripts/doctor.sh` lines 48, 83, 101, 171).
- Will file: `tests/install.test.sh` `t_latest_installed_without_version` still uses `v1.0.9` as the latest release (stubs `v1.0.8` and `v1.0.9`), which checklist step 6 says moves each release; `docs/release-checklist.md` and the test should agree on that function.
- Will file: the `v1.0.10` changelog bullet for #182 omits the `/codeo:qc` README changes and the rewritten `/codeo:doctor` summary; the published Release carries the same bullet.

## Outcome

### Round 1 — 2026-11-26

Review range: `git merge-base origin/main HEAD` = `89789dd` to `HEAD` = `98f4f1e`: release PR #189's merge `d60c26a` plus this branch's pin. Step 2's `sync-main.sh --abort-on-conflict` merged `origin/main` (1 commit: #189) cleanly. `overlap.sh 182` and `overlap.sh --outside 182` printed nothing and exited 0.

`scope.sh origin/main HEAD`: `suite.shell=true` (needed for unclassified paths `.codeo/182/*` and `.codeo/config.json`); no `deploy=` line (no environment, one suite).

**Build.** `true` for suite `shell`: exit 0. **Suite.** `bash tests/run.sh`: exit 0, last line `all cases passed`. `bash tests/readme.test.sh`: `all cases passed`.

| # | Criterion | Settled by | Verdict |
|---|---|---|---|
| 1 | #173, #176, #177, #179 closed before the release PR opened | `gh issue view`: #173 `CLOSED 2026-11-25T23:25:17Z`, #176 `2026-11-25T22:55:36Z`, #177 `2026-11-26T00:09:06Z`, #179 `2026-11-26T02:11:27Z`; #189 `createdAt 2026-11-26T03:01:04Z` | met |
| 2 | Every README mismatch fixed in the release PR; `readme.test.sh` passes | The two `/codeo:implement` mismatches and every omission the audit found are in `d60c26a`'s README diff; the independent review found every changed sentence true of the code; `bash tests/readme.test.sh` ends `all cases passed` | met |
| 3 | Changelog entry per gating issue that merged work | `origin/main:CHANGELOG.md` `## v1.0.10` has bullets citing #173 (3), #176, #177, #179, and also #157, #163, #166, #170, #171, #182 | met |
| 4 | `plugin.json` `1.0.10`, `## v1.0.10 — <date>` replaces `## Unreleased`, merged through a PR | `git show origin/main:.claude-plugin/plugin.json` version `1.0.10`; `CHANGELOG.md:3` `## v1.0.10 — 2026-11-26`, no `## Unreleased`; merged as PR #189 (`d60c26a`) | met |
| 5 | `bash tests/run.sh` in a clean clone of the merged commit ends `all cases passed` | Fresh clone checked out at `v1.0.10` = `d60c26af738c9873f3fd8c216c8b0c6eaaf9e62b`: `all cases passed` | met |
| 6 | `git ls-remote --tags origin` lists `v1.0.10` at the merged commit | `d60c26af738c9873f3fd8c216c8b0c6eaaf9e62b	refs/tags/v1.0.10`; `gh pr view 189` merge commit is the same SHA | met |
| 7 | `gh release view v1.0.10` shows a release | `["v1.0.10","v1.0.10",false,false,"https://github.com/kbajpai/codeo/releases/tag/v1.0.10"]`; body starts `Config schema: 1 (unchanged)` | met |
| 8 | `plugin.ref` is `v1.0.10`, merged through its own PR | `.codeo/config.json` on this branch: `v1.0.10`; `origin/main` still `v1.0.9`; the PR is the one `/codeo:close` opens | not yet checkable — the pull request does not exist yet |
| 9 | After a rebuild, the installed codeo reports v1.0.10 | `claude plugin list`: `codeo@codeo` `Version: 1.0.10`, `Status: enabled` at `user` scope and at `project` scope | met |

**Documentation.** The change moves `README.md` and `docs/updating.md`. `docs/updating.md` differs from `89789dd` in version numbers only. The README diff has no "now" or issue number; the only "no longer" hits are the installer's own `no longer installed` output in moved transcripts. The plan names both pages and no other.

**Independent review** (opus, `QC review:`, given the criteria and the range, not the implementer's account). In plain text: ready to merge, yes; no critical and no important issues. It found every README sentence the diff adds or changes true of the code, the version substitution consistent with checklist step 6, and the tag, Release and pin in place. Three minor findings, below. It declined to judge the rebuild (settled above, criterion 9) and the `BEHIND` behaviour that GitHub reports (the README states it as the close skill does).

**Findings.**
- **F1 — non-blocking, `/codeo:implement`'s.** README.md lines 173 and 466 say an unusable config skips `ruleset`; `scripts/doctor.sh` lines 48, 83, 101 and 171 show `codename`, `gh-scopes`, `board` and `suites` also print `skipped: config is unusable`. Incomplete rather than false; shipped in `d60c26a`, so it goes to a later release.
- **F2 — non-blocking, `/codeo:plan`'s.** `tests/install.test.sh` `t_latest_installed_without_version` (lines 518-523) still uses `v1.0.9` as the latest release. The plan told `implement` to skip that function (as v1.0.9's plan did, when its list already held `v1.0.9`); with `v1.0.10` out it now stands for a release that is no longer latest. The test still checks what it meant to.
- **F3 — non-blocking, `/codeo:implement`'s.** The #182 changelog bullet omits the `/codeo:qc` round-start change and the `/codeo:doctor` summary rewrite. Incomplete, not untrue; the Release notes carry the same text.

No issue was filed: the role check refuses `/codeo:issue` here, so the three are promised under `## Notes`.

**Verdict: clear — forward to `/codeo:close`.**

## Log

- 2026-11-26 — qc round 1: build and suite passed, 8 of 9 criteria met and criterion 8 not yet checkable until the pin's PR exists, 3 non-blocking findings, verdict clear · cost: 12m · opus-5-5 371k in + 5M cached / 20k out · sonnet-5-5 247k in + 29k cached / 938 out
