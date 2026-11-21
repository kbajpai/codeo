# Issue #144 — qc

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/144 |
| Branch | `fix/close-108-leftovers-overlap-sh` |
| Updated | 2026-11-21 |

## Where this stands

Round 2 is written: the build and the whole `shell` suite pass, all five criteria are met, and the one blocking finding from round 1 (F1) is fixed. The verdict is clear. Nothing is open.

## Questions

None.

## Notes

- Finding F1 was found by the independent reviewer and confirmed here by reverting `scripts/inflight.sh` lines 180, 209 and 224 one at a time in a scratch copy: `outcome-heading` and `inflight` still print `all cases passed` each time.

## Outcome

### Round 1 — 2026-11-21

**Commands run.**
- `sync-main.sh --abort-on-conflict`: `the branch already contains origin/main`, exit 0.
- `overlap.sh 144`: nothing printed, exit 0. `overlap.sh --outside 144`: `docs/skills.md`.
- `scope.sh origin/main HEAD`: `suite.shell=true` (unclassified paths `.codeo/144/*.md`, `CHANGELOG.md`); no `deploy=` line, since no environment is configured.
- Build (`true`): exit 0. Suite `shell` (`bash tests/run.sh`): exit 0, `all cases passed`.
- Mutations in a scratch copy: `inflight.sh` line 84 back to the prefix match fails `outcome-heading` (`heading ## Outcome: — the three readers agree: want [no no no ] got [no no yes ]`, `6 case(s) failed`); the `skills/close` stop sentence removed fails `overlap-stop` (`skills/close/SKILL.md: STOP wanted 1, found 0`); lines 180, 209 and 224 each back to the prefix match: both `outcome-heading` and `inflight` pass.

**Criteria.**

| Criterion | Verdict | Settled by |
|---|---|---|
| Each of `skills/plan`, `skills/implement`, `skills/qc`, `skills/close` and `docs/handoff.md` says that `overlap: cannot diff …` with a non-zero exit is a stop to report, not "no overlap", and a test pins the sentence in each | met | `tests/overlap-stop.test.sh` (counts per file; fails when the `skills/close` sentence is removed) |
| A dossier with a `## Outcomes` heading is judged the same by `dossier-check.sh`, `inflight.sh` and `qc-verdict.sh`, and a test fails if one of them differs | not met — the three scripts agree, but `tests/outcome-heading.test.sh` does not fail when `inflight.sh` lines 180, 209 or 224 regress, or when `dossier-check.sh`'s `section_range` or `last_round_clear` regresses alone (F1) | `scripts/inflight.sh`, `scripts/dossier-check.sh`, `tests/outcome-heading.test.sh` |
| The comment at `scripts/inflight.sh:205` matches whichever rule is chosen | met | `scripts/inflight.sh:205-206` says the match is exact, as `qc-verdict.sh` matches it |
| After a lock was taken and a volume or sandbox TODO printed, `/codeo:init`'s closing block names a next command, `docs/handoff.md` says the same, and the test that forbids `/codeo:plan` there is changed to match | met | `skills/init/SKILL.md` step 11, `docs/handoff.md` row `init — lock taken, TODO`, `tests/closing-exits.test.sh` case `init-lock-taken-todo` |
| The documentation pages the changes touch describe the behaviour in the present tense | met | `docs/handoff.md`, `docs/dossier.md`, `docs/skills.md:71`, `skills/*/SKILL.md` read; no "now", "no longer" or issue number in the added text |

**Documentation check.** The pages the plan named (`skills/plan`, `implement`, `qc`, `close`, `init`, `docs/handoff.md`, `docs/dossier.md`, `CHANGELOG.md`) were all changed and say what the code does. `docs/skills.md:71` also needed the change and the plan left it out (F2). The project has no wiki module and no documentation rules of its own.

**Independent review** (opus, given the criteria only): no Critical issues; one Important, four Minor. Its assessment, quoted in plain text: ready to merge with fixes, because the second criterion is only partly pinned by its test.

**Findings.**
- **F1 — blocking, `/codeo:implement`'s.** `tests/outcome-heading.test.sh` does not fail when a single reader regresses to the prefix match, for five of the eight changed readers: `inflight.sh:180` (`verdict_of`), `:209` (`close_send_back`) and `:224` (`last_qc_round`), because `recognised_by_inflight` checks only the step column, which `last_step` alone feeds; and `dossier-check.sh`'s `section_range` (`:132`) and `last_round_clear` (`:480`) each alone, because the fixture's `close.md` has a "pull request opened" round, so the other reader's check masks the regressed one. Reverting only `section_range` lets a mid-workflow `qc.md` titled `## Outcome notes` pass `[sections]` while the other readers see no outcome. The plan's task described the test, and the code does what it says, but the code is what is wrong: the criterion requires a failure when any reader differs. Root cause is the fixture and assertion coverage, not the scripts. Fix: assert the columns fed by `verdict_of`, `last_qc_round` and `close_send_back` in `recognised_by_inflight` (or one fixture per reader), and run `dossier-check`'s `[sections]` check on a dossier with no "pull request opened" round.
- **F2 — non-blocking, `/codeo:plan`'s.** `overlap.sh --outside 144` prints `docs/skills.md`: the branch changed line 71, which `plan.md`'s footprint omits. The change is right (that page said a TODO never names `/codeo:plan`, which is false after this change), so only a plan round can add the file to the footprint. On a first plan round this is not blocking by rule. Already recorded by `implement.md` Q2, answered *proceed and coordinate* (#145 lists `docs/skills.md`; #143 lists `CHANGELOG.md`).
- **F3 — non-blocking, `/codeo:implement`'s.** `skills/init/SKILL.md:341` dropped the explicit "do not hand off to `/codeo:plan`" after a `lock: TODO`; the no-lock case is now told only by the closing-block paragraphs. Restore a clause such as "after a TODO, end the turn with the closing block below rather than invoking `/codeo:plan`" for the no-lock case.
- **F4 — non-blocking, `/codeo:implement`'s.** Nits: `scripts/dossier-check.sh:75`'s comment line is far longer than its neighbours and hard to read; `skills/init/SKILL.md:355` repeats "when no lock was taken" inside the block titled "no lock".
- The reviewer's note that the stop sentence names only `cannot diff` and `cannot resolve`, though `overlap.sh` exits 1 on other errors, is recorded and not raised: it matches the criterion, and the sentence is true as far as it goes.

No issue was filed for this pass.

**Verdict: back to `/codeo:implement`.**

### Round 2 — 2026-11-21

**Commands run.**
- `sync-main.sh --abort-on-conflict`: `the branch already contains origin/main`, exit 0. `overlap.sh 144`: nothing printed, exit 0. `overlap.sh --outside 144`: `docs/skills.md`.
- `scope.sh origin/main HEAD`: `suite.shell=true` (unclassified paths `.codeo/144/*.md`, `CHANGELOG.md`); no `deploy=` line, since no environment is configured.
- Build (`true`): exit 0. Suite `shell` (`bash tests/run.sh`, whole): exit 0, `all cases passed`.
- Reviewer mutation runs (each reader alone reverted to `/^## Outcome/`, `bash tests/run.sh outcome-heading`): fails for `inflight.sh` lines 84, 180, 209 and 224, `dossier-check.sh` `section_range` and `last_round_clear`, and `qc-verdict.sh:72`; tightening each to `/^## Outcome$/` also fails, so the trailing-space and CRLF cases are real checks.
- My mutation run: `qc-verdict.sh:134` (the `plan.md` round count) reverted alone leaves `outcome-heading` passing, while `qc-verdict` fails (4 failed cases in a scratch copy, against 2 unrelated baseline ones from the copy not being a git repository, including `round 2 footprint omits: c.txt`), so `tests/qc-verdict.test.sh` guards that line.

**Criteria.**

| Criterion | Verdict | Settled by |
|---|---|---|
| Each of `skills/plan`, `skills/implement`, `skills/qc`, `skills/close` and `docs/handoff.md` says that `overlap: cannot diff …` with a non-zero exit is a stop to report, not "no overlap", and a test pins the sentence in each | met | `tests/overlap-stop.test.sh`; the sentence matches `scripts/overlap.sh` (exit 1 with `cannot diff`, line 159) |
| A dossier with a `## Outcomes` heading is judged the same by `dossier-check.sh`, `inflight.sh` and `qc-verdict.sh`, and a test fails if one of them differs | met — seven readers are pinned by `tests/outcome-heading.test.sh`, and the eighth (`qc-verdict.sh:134`) by `tests/qc-verdict.test.sh` (F3) | `tests/outcome-heading.test.sh`, `tests/qc-verdict.test.sh` |
| The comment at `scripts/inflight.sh:205` matches whichever rule is chosen | met | `scripts/inflight.sh:205-206` says the match is exact, as `qc-verdict.sh` matches it |
| After a lock was taken and a volume or sandbox TODO printed, `/codeo:init`'s closing block names a next command, `docs/handoff.md` says the same, and the test that forbids `/codeo:plan` there is changed to match | met | `skills/init/SKILL.md` step 11, `docs/handoff.md` row `init — lock taken, TODO`, `docs/skills.md:71`, `tests/closing-exits.test.sh` case `init-lock-taken-todo` |
| The documentation pages the changes touch describe the behaviour in the present tense | met | `docs/handoff.md`, `docs/dossier.md`, `docs/skills.md:71` and `skills/*/SKILL.md` read; no "now", "no longer" or issue number in the added page text (the `CHANGELOG.md` bullet carries its issue number by that file's convention) |

**Documentation check.** Every page the plan named was changed and says what the code does; `docs/skills.md:71` also needed the change (F2). The project has no wiki module and no documentation rules of its own.

**Independent review** (opus, given the criteria only; round 2 on `5e09b71`): no Critical issues; one Important and five Minor. Its assessment, quoted in plain text: ready to merge with fixes, because `qc-verdict.sh:134` is not pinned by the dedicated test.

**Findings.**
- **F1 (blocking in round 1) — fixed by `00334e5`:** `tests/outcome-heading.test.sh` now pins seven readers, each alone (confirmed by the reviewer's mutation runs above).
- **F2 — non-blocking, `/codeo:plan`'s.** `overlap.sh --outside 144` prints `docs/skills.md`: the branch changed line 71, which `plan.md`'s footprint omits, and only a plan round can add it. Not blocking on a first plan round; already answered by `implement.md` Q2 (proceed and coordinate).
- **F3 — non-blocking, `/codeo:implement`'s.** `tests/outcome-heading.test.sh` does not itself pin `qc-verdict.sh:134`, and its commit subject says it pins every reader. The line is guarded by `tests/qc-verdict.test.sh`, so criterion 2 holds; a case that commits `plan.md` with the heading varied and a `### Round 2` would make the claim literal.
- **F4 — non-blocking, `/codeo:implement`'s.** In `skills/implement/SKILL.md:89-92` and `skills/close/SKILL.md:220-224` the new sentences sit before "The step stops until it is answered", so "it" reads as the skip warning and not the numbered question; moving them after that sentence, as `skills/qc/SKILL.md` does, fixes it.
- **F5 — non-blocking nits, `/codeo:implement`'s.** `skills/init/SKILL.md` says "end the turn … do not hand off" only for the no-lock case (the lock-taken TODO case is implied); the stop rule names the `cannot diff` and `cannot resolve` lines, so a non-zero exit with neither line is not named (it matches the criterion as written); `inflight_send_back` does not separate `inflight.sh:209`'s trailing-space direction; `CHANGELOG.md` says the no-lock closing block is "unchanged" though its wording was re-flowed.

Per the skill, no further round is opened for non-blocking polish: F3-F5 are recorded here for the engineer and `/codeo:triage`. No issue was filed for this pass.

**Verdict: clear — forward to `/codeo:close`.**

## Log

- 2026-11-21 — round 1: build and suite clear, F1 blocking, sent back · cost: 17m · opus-5-5 166k in + 2.6M cached / 16k out · sonnet-5-5 104k in + 281k cached / 1k out
- 2026-11-21 — round 2: build and suite clear, F1 fixed, no blocking finding, clear · cost: 7m · opus-5-5 253k in + 2M cached / 17k out · sonnet-5-5 171k in + 785k cached / 2k out
