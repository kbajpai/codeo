# Issue #171 — qc

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/171 |
| Branch | `docs/make-readme-complete-easy-follow` |
| Updated | 2026-11-25 |

## Where this stands

Round 1 is written. The build and the full suite pass, but two README statements are untrue and the change goes back to `/codeo:implement`. Next step: `/codeo:implement`.

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

## Log

- 2026-11-25 — qc round 1: build and suite pass; two blocking documentation findings (F1, F2), eight non-blocking; back to implement · cost: 5m · opus-5-5 263k in + 6.7M cached / 25k out · sonnet-5-5 98k in + 265k cached / 609 out
