# Issue #213 — qc

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/213 |
| Branch | `feat/213-release-v1-0-11-main` |
| Updated | 2026-11-28 |

## Where this stands

Round 1 is written: the verdict is clear, forward to `/codeo:close`. Nothing is open. The release v1.0.11 is shipped (pull request #214 merged as `00de557`, tag `v1.0.11`, GitHub Release); what this branch still carries to `main` is the pin (`.codeo/config.json` `plugin.ref` → `v1.0.11`), the plan and the dossiers, which `/codeo:close`'s pull request merges. Every finding is non-blocking; the ones against the shipped README and changelog can only be fixed in a later release (a pushed tag is never moved) and are recorded under `## Notes` for `/codeo:triage`.

## Questions

None.

## Notes

Later work, for `/codeo:triage` (no issue numbers: `/codeo:issue` runs in a home checkout, and this is an issue checkout). File each with `/codeo:issue` in a home checkout:
- Later work: the v1.0.11 changelog's `Shared state:` line (`CHANGELOG.md:6`) does not mention that #195 makes `lib/identity.sh`'s `codeo_owner_of_init` and `lock.sh verify` read init.md's `- <date> — resumed: by <login> after …` line as the owner, before the `| Owner |` row, nor #204's close phase detection reading whether a `close.md` round records the pull request. `docs/release-checklist.md` step 6 says the line "must name every dossier convention a script or a skill reads back"; earlier releases' lines name only what changed (`Shared state: none`, `unchanged from v1.0.5`), so whether the line must be cumulative is the checklist's to settle. The next release's notes, or the checklist's wording, should say which.
- Later work: `README.md` (Setting a project up step 1, and the Troubleshooting *config* entry) says a `TODO-set-me` value makes doctor fail `config` and `ruleset`; with an unusable config, `codename`, `gh-scopes`, `board` and `suites` also print `fail … skipped: config is unusable` (`scripts/doctor.sh` lines 49, 84, 102, 172). True but incomplete; fix in the next release's README.
- Later work: four README sentences in v1.0.11 over-generalize what the code does (the reviewer's Minor findings, confirmed against the cited lines): "A stash or an abandon removes you from the issue's assignees" (close removes the *recorded owner*, `lock.sh owner <N>`, not necessarily the caller); the `mismatch` refusal example holds only for plan, implement, qc and close (`role.sh` prints "runs in a home checkout" for the home skills); "git writes through Bash are refused … Writes under `.codeo/` are exempt" (the guard allows `pull`, `fetch`, `branch`, `worktree`, plain `checkout`/`switch`, and refuses `push` and `commit --amend` even for `.codeo/` changes; `docs/home-checkout.md` is exact); `issue` keeps its dossier at `.codeo/intake/new-<slug>/issue.md` until the issue is filed, then `.codeo/intake/<N>/`. Also the cleanup-sentence placement and the edit-guard paragraph's position in the role-guard entry (implement.md's deferred Minor list). One README pass in the next release can take all of them.
- Later work: `Safe to bump mid-workflow: yes` in the v1.0.11 changelog header has caveats its own #195 bullet states (a Bot or unresolved login is refused after the bump; an offline container takes no lock); a later release could carry them in the header, as v1.0.9 did.
- Later work: flaky tests in CI, independent of this change. `main`'s CI on `00de557` (run 46089672906) failed twice: first `tests/live.test.sh` `two_simultaneous_beats_from_one_checkout_leave_a_fresh_signal — round 9 published: want [1] got [0]`, then, on the rerun, `tests/close-skill.test.sh` (`docs/skills.md close section has no web-session exception`) and `tests/role-guard.test.sh`. The last two are the `producer | grep -q` under `set -o pipefail` SIGPIPE race recorded in `implement.md`; the first is a timing race of its own. The release changed none of these tests or the scripts they exercise (`git diff --stat 3857710 00de557 -- tests/live.test.sh scripts/live.sh hooks/` is empty). Until they are fixed, `/codeo:close`'s pull request may need a rerun of `tests`.
- Later work: `tests/sandbox.test.sh` fails in this sandbox because the sandbox's global excludes file (`/home/agent/.gitignore_global`, an `sbx host ignore` block) lists `.sbx` and the test runs `git add .sbx` in a temporary repository (its lines 409 and 417). It passes with `GIT_CONFIG_GLOBAL=/dev/null` and in CI. A test that sets its own `GIT_CONFIG_GLOBAL` would not depend on the machine's ignores.

How this pass reviewed the change: the workflow's work reached `main` through #214 before this pass, so `git merge-base origin/main HEAD` is the release commit and the branch's own diff is only the pin, the plan and the dossiers. The independent review was given the whole range from `3857710` (main before the release) to `HEAD`, so it judged the release as well as the pin.

## Outcome

### Round 1 — 2026-11-28

**Lock and ownership.** `role.sh --check qc` exited 0. `lock.sh verify`: `lock: verified #213 as kbajpai (legacy lock: no recorded user)`.

**Sync and scope.** `sync-main.sh --abort-on-conflict`: `sync-main: merged origin/main (1 commit(s))` (the release commit `00de557`; no `also changed on main:` lines). `overlap.sh 213` printed nothing (exit 0). `git diff origin/main...HEAD --stat`: `.codeo/213/implement.md`, `.codeo/213/init.md`, `.codeo/213/issue.md`, `.codeo/213/plan.md`, `.codeo/config.json` (1 line), `docs/plans/2026-11-27-release-v1-0-11.md`: 6 files, 509 insertions, 1 deletion. `scope.sh origin/main HEAD`:

```
scope: suite shell needed for unclassified paths:
  .codeo/213/implement.md
  .codeo/213/init.md
  .codeo/213/issue.md
  .codeo/213/plan.md
  .codeo/config.json
suite.shell=true
```

**Build.** `shell`'s build is `true`: exit 0.

**Suite.** `shell`'s test, `bash tests/run.sh`, on `HEAD` (`7082ace`), as configured: `failed: sandbox.test.sh` (exit 1). Root cause (systematic-debugging Phase 1): the sandbox's global excludes file `/home/agent/.gitignore_global` lists `.sbx`, and `tests/sandbox.test.sh` lines 409 and 417 run `git add .sbx` in a temporary repository, which git refuses ("The following paths are ignored by one of your .gitignore files: .sbx"). Not this change, and not a defect of the code. With `GIT_CONFIG_GLOBAL=/dev/null bash tests/run.sh`: `all cases passed` (exit 0).

**Criteria.**

| # | Criterion | Verdict | Settled by |
|---|---|---|---|
| 1 | README mismatches fixed in the release PR; `tests/readme.test.sh` passes | met | On `origin/main`, the eight mismatch phrases the plan named count 0 (`bash, \`jq\`, \`git\` and \`gh\``, ``ruleset` is skipped``, ``refuses to overwrite a `config.json` that exists.``, `setup leaves them out`, `nothing else is recorded`, `each owning one dossier file under`, `never refused`, ``(`gh auth login`)``), and the added text is there (`CODEO_HOME_EDITS`, `is a Bot account`, `does not expand`, `mismatch:<N>:<folder>`: 1 each). `tests/readme.test.sh` passed inside the full suite on `HEAD`, which contains `00de557`. The review found no README sentence the code contradicts; the incomplete and over-general ones are non-blocking findings F1 and F3. |
| 2 | `plugin.json` 1.0.11; `## v1.0.11 — <date>` replaces `## Unreleased`, an entry for each of #188, #190, #192, #195, #204, #206; merged through a PR | met | `git show origin/main:.claude-plugin/plugin.json` → `1.0.11`; `## Unreleased` count 0; `3:## v1.0.11 — 2026-11-27`; in that section `#188`…`#206` count 1 each (and `#211` 1); `gh pr view 214` → `["MERGED","00de557a939e7b7b3477c34c23dff81820ff03ae","main"]`. |
| 3 | `bash tests/run.sh` in a clean clone of the merged commit ends `all cases passed` | met | Fresh clone, `git checkout --detach 00de557a939e7b7b3477c34c23dff81820ff03ae`, `git rev-parse HEAD` prints that SHA, `plugin.json` `1.0.11`; `GIT_CONFIG_GLOBAL=/dev/null bash tests/run.sh` → `all cases passed`. As written it ends `failed: sandbox.test.sh`, for the sandbox-only cause in **Suite** above. `main`'s CI on that commit failed twice on unrelated flaky tests (F4). |
| 4 | `git ls-remote --tags origin` lists `v1.0.11` at the merged commit | met | `00de557a939e7b7b3477c34c23dff81820ff03ae	refs/tags/v1.0.11`; no `^{}` line (lightweight). |
| 5 | `gh release view v1.0.11` shows a release for the tag | met | `["v1.0.11","v1.0.11",false,false,"2026-11-28T00:54:37Z"]`; body's first line `Config schema: 1 (unchanged)`. |
| 6 | `.codeo/config.json` `plugin.ref` is `v1.0.11`, merged through its own pull request | not yet checkable — met on the branch (`jq -r .plugin.ref .codeo/config.json` → `v1.0.11`; `origin/main` → `v1.0.10`); it is merged by `/codeo:close`'s pull request | `.codeo/config.json` |
| 7 | After a dev container rebuild or restart, the installed plugin reports v1.0.11 | met | `claude plugin list` in this session (after the engineer's rebuild): `codeo@codeo` `Version: 1.0.11` at `Scope: user` and at `Scope: project`. |

**Rules and footprint.** `overlay.sh qc invariants-extra` exit 3 (no further rules); no invariants file. `overlap.sh --outside 213` printed nothing (exit 0): the branch stays inside its footprint. `plan.md` has no `### Round 2`.

**Documentation.** `overlay.sh qc wiki-rules` exit 3; no wiki module. The branch's own diff moves no page: the pin is this project's configuration, and no page under `docs/` names this project's pin (`docs/updating.md`'s *Moving a project's pin* is generic). The pages the plan named, `README.md` and `docs/updating.md`, changed in the release commit: the version examples follow the checklist (the review confirmed every move), and the README text is judged under criterion 1. No page speaks of "now", "no longer" or an issue number in the lines the release added. The plan file under `docs/plans/` is design reasoning, not documentation.

**Independent review** (`QC review:`, on `opus`, range `3857710..7082ace`, given only the acceptance criteria, the out-of-scope list and the checklist). It said "Ready to merge? With fixes": no Critical; two Important (F1, F2); five Minor (F3, F5). It confirmed the version moves, the heading and its date rule, the tag, the one-line pin and how `.devcontainer/scripts/plugins.sh` reads it.

**Findings.**
- F1 — non-blocking; implement's in kind, but past this workflow: the v1.0.11 README sentence on a `TODO-set-me` config names `config` and `ruleset` as failing, but `codename`, `gh-scopes`, `board` and `suites` also fail with `skipped: config is unusable` (`scripts/doctor.sh` 49, 84, 102, 172). True but incomplete. It is in the shipped release; it can only be fixed in a later release. To `/codeo:triage` (`## Notes`).
- F2 — non-blocking; plan's and the checklist's: the `Shared state:` line (`CHANGELOG.md:6`) does not name #195's owner read of the `resumed: by` line or #204's close phase detection. The checklist asks for every read-back convention; the earlier releases' lines name only what changed, which this line does. Shipped; to `/codeo:triage`.
- F3 — non-blocking: the four over-general README sentences and the two placement notes listed under `## Notes`. Shipped; to `/codeo:triage`.
- F4 — non-blocking; neither skill's: CI flakes on `main` at `00de557` (`live.test.sh`'s simultaneous-beats race; the `pipefail` SIGPIPE race in `close-skill.test.sh` and `role-guard.test.sh`). None of these tests or their scripts changed in the release. They may make `/codeo:close`'s pull request need a rerun of `tests`. To `/codeo:triage`.
- F5 — non-blocking: `Safe to bump mid-workflow: yes` without the caveats the #195 bullet states. Shipped; to `/codeo:triage`.
- F6 — non-blocking; neither skill's: `tests/sandbox.test.sh` depends on the machine's global gitignore. To `/codeo:triage`.

No issue was filed by this pass (`/codeo:issue` runs in a home checkout); each finding is a `## Notes` line.

**Verdict: clear — forward to `/codeo:close`.**

## Log

- 2026-11-28 — round 1: clear, forward to /codeo:close; 6 non-blocking findings recorded for triage · cost: 12m · opus-5-5 524k in + 7.6M cached / 34k out
