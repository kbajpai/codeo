# Issue #171 — qc

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/171 |
| Branch | `docs/make-readme-complete-easy-follow` |
| Updated | 2026-11-25 |

## Where this stands

Round 3 is written: build and suite pass here and in a clean worktree, no blocking finding, six non-blocking notes. The verdict is clear. Next step: `/codeo:close`.

## Questions

None.

## Notes

- Out-of-scope observation, not a finding: `docs/handoff.md:3` says "Seven pipeline skills" and `docs/skills.md` says six; and how another project adopts the role guard. Both are already recorded in `plan.md` `## Notes`.

## Outcome

### Round 1 — 2026-11-25

**Sync and scope.** `sync-main.sh --abort-on-conflict`: `the branch already contains origin/main`. `overlap.sh 171`: nothing printed, exit 0. `overlap.sh --outside 171`: nothing, exit 0. `scope.sh origin/main HEAD`: `suite.shell=true` (needed for unclassified paths `.codeo/171/*`, `CHANGELOG.md`, `README.md`). Diff: 11 files, +1224/−231.

**Build.** `true` (suite `shell`): exit 0.

**Tests.** `bash tests/run.sh` (whole suite): exit 0, `all cases passed`.

**Criteria.**

| # | Criterion | Verdict | Settled by |
|---|---|---|---|
| 1 | Summary, table of contents, "start here" path | met — README.md:3, :5-18, :20-28 | `tests/readme.test.sh` start-here and sections checks; reading |
| 2 | Install, update/replace/restore, uninstall separate; common install first | met — `## Installing` :40, `## Updating` :518, `## Uninstalling` :541; replace and restore in `docs/updating.md` | `t_readme_sections` in `tests/install.test.sh` |
| 3 | First workflow: all six steps with command, asks, writes, next | met — README.md:244-302, each with Run / It asks / It writes / It commits / Next | `tests/readme.test.sh` walkthrough check; reviewer checked each claim against skills/*/SKILL.md |
| 4 | Every key the plugin reads, optionality, an example | met — 46-row table :325-370 and two JSON examples :374-405 | `tests/readme.test.sh` config-keys check; reviewer cross-checked keys and defaults against the code (see F6 on the test's strength) |
| 5 | Troubleshooting: role guard, lock, interruption, card not Ready, plus doctor entries | not met as written — all four entries exist (:413, :423, :433, :439) but the lock entry contradicts itself and its `lock: TODO` example gets the wrong fix (F2) | README.md:423-431, `scripts/lock.sh:154,172-181` |
| 6 | Every command, path and link exists and is spelled as in the repo | not met — README.md:38 says doctor checks `claude`, which it does not (F1); the commands, paths and anchors otherwise resolve | `tests/readme.test.sh` commands/paths/links checks (pass); `scripts/doctor.sh:197,260` |
| 7 | `bash tests/run.sh` passes, wording pins updated | met | full-suite output above |

**Documentation check.** The change is documentation; no behaviour changes, so no other page is moved. The pages that talk about the issue instead of the system: none new (`no longer` hits in `docs/updating.md` are quoted installer output). F8 is one moved sentence.

**Independent review (opus).** Quoted, not bold: no Critical; three Important; seven Minor; assessment "With fixes". Strengths: config table and defaults match the code; walkthrough claims match the skills; links and anchors resolve; moved text is intact.

**Findings.**

- **F1 — blocking, `/codeo:implement`'s.** README.md:38 says "`install.sh` and `/codeo:doctor` both check all five tools." Doctor checks `jq`, `git` and bash (`scripts/doctor.sh:197`) and `gh` (the `gh-auth` check); it never runs or checks `claude` (`scripts/doctor.sh:260`, "claude itself is never run"). The plan said the statement was the old one; the code does not do this. Fix: say the installer checks all five and doctor checks bash, `jq`, `git` and `gh`.
- **F2 — blocking, `/codeo:implement`'s.** README.md:423-431. (a) The branch-mismatch fix says to "switch back to the lock's branch yourself" and also "do not switch branches to make it agree". (b) It says the lock file is only written by the plugin's script, so do not edit it, yet the example `lock: TODO` line (`scripts/lock.sh:181`) says "fill the lock's volume line in by hand", and its fix "take the lock again" is wrong for it: the lock was already written with `volume: unknown`, so a second take only prints `lock already taken` (`scripts/lock.sh:154`). Fix: separate what the engineer may do (switch back themselves) from what is forbidden (editing `.codeo/active` except the volume line the TODO names), and either pick a TODO whose fix is a re-take (`no single init.md names branch …`, `scripts/lock.sh:163`) or say the volume line is the one by-hand edit.
- **F3 — non-blocking, `/codeo:implement`'s.** Lost content. README.md:133 still says the settings file can be written by hand, but the old README's line on how to find the tag (`git ls-remote --tags --refs https://github.com/kbajpai/codeo 'v*'`, base `README.md:145`) is gone from every page except `docs/release-checklist.md`; so are the sentences that a teammate who trusts the folder is offered both plugins and that a later replace drops the project's install. Restore them near the hand-written example.
- **F4 — non-blocking, `/codeo:implement`'s.** `docs/updating.md:126`: "Restart every open Claude Code session afterwards." opens "Moving a project's pin" but belonged to the superpowers section above it.
- **F5 — non-blocking, `/codeo:implement`'s.** `docs/updating.md:112`: "Before you run it, read CHANGELOG.md …" ends "When an update fails", where "it" no longer points at the update command. README.md:535 has a milder version.
- **F6 — non-blocking, `/codeo:implement`'s.** `tests/readme.test.sh:116-128` greps each key's last segment (`name`, `owner`, `test`, `done` …) anywhere in the code, so for most keys the check cannot fail; and the "exactly the keys the plugin reads" claim in the header (line 6) holds only as far as the hand-kept `known_keys` list does. The header should say what the check proves. (Already parked as a minor in `implement.md`.)
- **F7 — non-blocking, `/codeo:implement`'s.** `tests/readme.test.sh:2,61-62`: "once they exist" and `[[ -f … ]] &&` skip the checks for `docs/updating.md` and `docs/home-checkout.md` silently if either is renamed. Both exist now, so the check should fail when one is missing.
- **F8 — non-blocking.** `docs/home-checkout.md:5` "which is still supported" is history wording, moved verbatim from the old README.
- **F9 — non-blocking.** README.md:423 "only `/codeo:close` removes it": `.devcontainer/scripts/devcontainer-start.sh:212` also removes an empty `.codeo/active`.
- **F10 — non-blocking.** README.md:321 lists what doctor checks and does not check; `hooks.onLeaseChange` is in neither list.

Issues filed by this pass: none.

**Verdict: back to `/codeo:implement`.**

### Round 2 — 2026-11-25

**Sync and scope.** `sync-main.sh --abort-on-conflict`: `the branch already contains origin/main`. `overlap.sh 171` and `overlap.sh --outside 171`: nothing printed, exit 0. `scope.sh origin/main HEAD`: `suite.shell=true`. Diff: 12 files, +1313/−231; head `5b269d4`.

**Build.** `true` (suite `shell`): exit 0.

**Tests.** `bash tests/run.sh` in this checkout: exit 0, `all cases passed`. In a clean worktree of `HEAD` (no gitignored files), `bash tests/readme.test.sh`: `FAIL paths: README.md: \`.codeo/active\` does not exist`, exit 1. The first run passes only because this checkout holds the lock, and `.codeo/active` exists here.

**Round 1 recap.** F1 (blocking in round 1) — fixed by `ca7f2f3`: README.md:38 now says the installer checks all five tools and doctor checks bash, `jq`, `git` and `gh`. F2 (blocking in round 1) — fixed by `ca7f2f3`: the lock entry no longer contradicts itself and the `lock: TODO` example has the right fix. F3-F10 are fixed by `ca7f2f3`; the reviewer re-read each against the code and found them correct.

**Criteria.**

| # | Criterion | Verdict | Settled by |
|---|---|---|---|
| 1 | Summary, contents, "start here" | met | README.md:3, :5-18, :20-28; `tests/readme.test.sh` start-here and sections checks |
| 2 | Install, update/replace/restore, uninstall separate; common install first | met | `## Installing` :40, `## Updating`, `## Uninstalling`; `t_readme_sections` |
| 3 | First workflow, six steps with command, asks, writes, next | met | README.md:244-302; reviewer checked each commit subject and file against skills/*/SKILL.md |
| 4 | Every key read, optionality, example | met | the 46-row table and two JSON examples; reviewer checked keys and defaults against `lib/env.sh`, `board.sh`, `branch-name.sh`, `scope.sh`, `intake.sh` |
| 5 | Troubleshooting: role guard, lock, interruption, card not Ready, plus doctor entries | met | README.md:413-445; the lock entry is now consistent (`scripts/lock.sh:154,172-181`) |
| 6 | Every command, path and link exists and is spelled as in the repo | met | commands, paths and anchors resolve in a clean worktree except `.codeo/active`, which is a runtime file the README names correctly; see G1 for the test |
| 7 | `bash tests/run.sh` passes | not met | passes here, but `tests/readme.test.sh` fails on a clean checkout (G1), so CI (`.github/workflows/ci.yml:18` runs `bash tests/run.sh`) fails |

**Documentation check.** No behaviour changed, so no other page moves. No page talks about the issue instead of the system; the "no longer" hits are quoted installer output.

**Independent review (opus).** Quoted, not bold: one Critical, one Important, four Minor; assessment "With fixes". It confirmed the config table, doctor coverage, walkthrough commit subjects, role-guard and lock lines against the code, and that no old README content was lost; it mutated a copy to show the test catches a misspelt command, a broken anchor, a missing path and a missing key.

**Findings.**

- **G1 — blocking, `/codeo:implement`'s.** `tests/readme.test.sh` (the `paths` loop) requires every backticked `.codeo/…` token to exist in the repository. The round-2 wording at README.md:429 backticks `.codeo/active`, which is gitignored (`.codeo/.gitignore`) and exists only in a checkout that holds the lock. Reproduced above: clean worktree, exit 1. Cause: the check tests the README's user-project paths against codeo's own repository, and the other such paths (`.codeo/config.json`, `docs/plans/`) pass only because codeo dogfoods them. The code did what the plan said; the new README sentence tripped the test, so it is the implementer's. The fix is the implementer's to choose: an allow-list of runtime paths, or limit the check to plugin-repo paths.
- **G2 — non-blocking, `/codeo:implement`'s.** The `paths` check skips any backticked token with a space, so `bash scripts/dossier-check.sh .codeo/<N>` (README.md:439), `bash .devcontainer/scripts/devcontainer-start.sh` (README.md:419) and `.devcontainer/scripts/role.sh --check <skill>` (`docs/home-checkout.md:26`) are not checked; renaming them in a copy left the test green. All exist today. Already parked as a minor in `implement.md`; the header's "every backticked repo path … resolves" overstates it.
- **G3 — non-blocking.** README.md:360: the `resources[].paths` row describes only the environment resource; `/codeo:plan` also uses every resource's `paths` to decide a footprint's `exclusive:` entries (`skills/plan/SKILL.md:243-246`).
- **G4 — non-blocking.** README.md:38: "It installs none of them" now reads as if doctor installs, where the installer is meant.
- **G5 — non-blocking.** README.md:198 says setup leaves out everything else, but `/codeo:setup --stack` writes `stacks` (`scripts/setup.sh:62`); README.md:323 says so correctly.

Issues filed by this pass: none.

**Verdict: back to `/codeo:implement`.**
### Round 3 — 2026-11-25

**Sync and scope.** `sync-main.sh --abort-on-conflict`: `the branch already contains origin/main`. `overlap.sh 171` and `overlap.sh --outside 171`: nothing printed, exit 0. `scope.sh origin/main HEAD`: `suite.shell=true`. Diff: 12 files, +1374/−231; head `349443c`. No shared environment is configured, so there is no environment block.

**Build.** `true` (suite `shell`): exit 0.

**Tests.** `bash tests/run.sh` in this checkout: `all cases passed`, exit 0. The same command in a clean `git worktree` at `349443c`, with no gitignored files and so no `.codeo/active`: `all cases passed`, exit 0. The round 2 failure does not recur.

**Round 2 recap.** G1 (blocking in round 2) — fixed by `078331a`: `tests/readme.test.sh` allows `.codeo/active` and `.codeo/intake` by name; the clean-worktree run above passes. G2-G5 (non-blocking in round 2) — fixed by `078331a`; the reviewer renamed a script path used as a command argument in a copy and the test failed.

**Criteria.**

| # | Criterion | Verdict | Settled by |
|---|---|---|---|
| 1 | Summary, contents, "start here" | met | README.md:3, :5-18, :20-28; `tests/readme.test.sh` start-here and sections checks |
| 2 | Install, update/replace/restore, uninstall separate; common install first | met | `## Installing`, `## Updating`, `## Uninstalling`; `t_readme_sections` in `tests/install.test.sh` |
| 3 | First workflow, six steps with command, asks, writes, next | met | README.md:244-302; reviewer checked each commit subject and file against skills/*/SKILL.md |
| 4 | Every key read, optionality, an example | met | the Configuration table and two JSON examples; reviewer matched the table to every `config.sh get` and `codeo_cfg` read in the code |
| 5 | Troubleshooting: role guard, lock, interruption, card not Ready, plus doctor entries | met | README.md:413-445; each cause and fix matches `scripts/lock.sh`, `.devcontainer/scripts/role.sh`, `scripts/board.sh` and skills/init/SKILL.md |
| 6 | Every command, path and link exists and is spelled as in the repo | met | `tests/readme.test.sh` commands, paths (now including paths inside commands) and links checks, passing in a clean worktree; reviewer mutated a copy for each and every mutation failed |
| 7 | `bash tests/run.sh` passes | met | both runs above |

**Documentation check.** No behaviour changed, so no other page moves. The pages talk about the system: the only "no longer" lines are quoted installer output.

**Independent review (opus).** Quoted, not bold: no Critical, no Important, six Minor; assessment "With fixes (all minor)". It ran the suite in a clean worktree, mutated `tests/readme.test.sh` thirteen ways, and found no content lost from the old README.

**Findings (all non-blocking, all `/codeo:implement`'s if picked up).**

- **H1 — non-blocking.** README.md:447: the "Checks from /codeo:doctor" intro says each entry is one doctor check, but the last two entries (`its source doesn't match its extraKnownMarketplaces entry`, and a hand-edited `ref`) are `claude plugin` and `install.sh` problems that `scripts/doctor.sh` does not check. They need their own heading or a reworded intro.
- **H2 — non-blocking.** README.md:27: Start here step 6 says to merge the pull request and "see the workflow finish". The workflow finishes only when `/codeo:close` is run again after the merge (`skills/close/SKILL.md` step 8); README.md:302 says so, the start path does not.
- **H3 — non-blocking.** README.md:429: the advice to run `/codeo:init #<N>` for a `lock: TODO` that says no lock was taken also catches the diverged and stale-local TODOs of `scripts/lock.sh:94,103,115`, which say to reconcile by hand and re-run the script.
- **H4 — non-blocking.** `tests/readme.test.sh:52-56`: the heading-slug function does not produce GitHub's `-1` suffix for a repeated heading, so a link to one would fail falsely. No page repeats a heading today.
- **H5 — non-blocking.** `tests/readme.test.sh:72-81`: paths the README names for a user's project (`docs/plans/`, `.codeo/config.json`) pass because codeo uses itself; the header does not say so.
- **H6 — non-blocking.** `docs/updating.md`, "Updating superpowers": no advice to restart Claude Code sessions after `claude plugin update superpowers@…`.

Issues filed by this pass: none. H1-H6 are small enough to carry as notes for `/codeo:triage`.

**Verdict: clear — forward to `/codeo:close`.**
## Log

- 2026-11-25 — qc round 1: build and suite pass; two blocking documentation findings (F1, F2), eight non-blocking; back to implement · cost: 5m · opus-5-5 263k in + 6.7M cached / 25k out · sonnet-5-5 98k in + 265k cached / 609 out
- 2026-11-25 — qc round 2: build and suite pass here; one blocking finding (G1, the readme test fails on a clean checkout), four non-blocking; back to implement · cost: 4m · opus-5-5 329k in + 5.3M cached / 24k out · sonnet-5-5 27k in + 343k cached / 1k out
- 2026-11-25 — qc round 3: build and suite pass here and in a clean worktree; no blocking finding, six non-blocking (H1-H6); clear · cost: 8m · opus-5-5 360k in + 7.4M cached / 26k out · sonnet-5-5 25k in + 441k cached / 805 out
