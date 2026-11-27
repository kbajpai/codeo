# Issue #204 — implement

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/204 |
| Branch | `chore/204-fix-codeo-close-opens-pr` |
| Updated | 2026-11-27 |

## Where this stands

Round 2, done, after the send-back from `qc.md` round 1. F1-F7 are fixed. Next step: `/codeo:qc`.

## Questions

None.

## Notes

- Nothing out of scope was found that needed `/codeo:issue`.
- Later, not in this change: `scripts/inflight.sh` labels an archive with no pull request `(PR open)` and its header comment says "a pull request is usually open"; both should name the window between close's archive push and `pr create` (qc round 1, F5).
- Parked, non-blocking, from the whole-branch review (for `/codeo:qc` to weigh): long lines in `skills/close/SKILL.md`'s step 1 table and step 6; three weak pins in `tests/close-skill.test.sh` (the whole-file `close-15` check, the push-before-`pr create` order check); `scripts/inflight.sh` labels an archive with no pull request `review — dossier archived` (cosmetic; `skills/triage/SKILL.md` now names the case); a kill between `git mv` and the commit leaves a staged rename that step 3 stops on (unchanged behaviour).

## Outcome

**Built.** Phase 1 of `skills/close/SKILL.md` is reordered: the checks, then archive and push (`— archived`), then `pr create`, then the record of `#<number> <url>` in `.codeo/done/<N>/close.md` (`— PR #<pr>`). Step 1's table gains the two interrupted-close cases and the older-plugin case; steps 2-3 read the dossier from `.codeo/<N>/` or `.codeo/done/<N>/`; step 3's send-back un-archives when the dossier is archived. Rule `close-15` (archive and push before the pull request) is in the skill and in `docs/skills-inventory.md`. Tests: new pins in `tests/close-skill.test.sh`, a two-commit replay in `tests/qc-verdict.test.sh`, an archived-with-no-pull-request case in `tests/role.test.sh`, `tests/inventory.test.sh`'s close rule count 14 → 15 (unplanned, needed by the new rule), and the log wording of two fixtures.

**Documentation pages changed:** `docs/dossier.md`, `docs/handoff.md`, `docs/skills.md`, `README.md`, and the wording in `skills/triage/SKILL.md` and `skills/init/SKILL.md`; `CHANGELOG.md` has the entry.

**Build result:** the `shell` suite's build is `true`: exit 0. The full suite and the acceptance criteria are `/codeo:qc`'s. Deviation: the task implementers ran `bash tests/run.sh` themselves (it exited 0 after Tasks 3, 5 and 6 and after the last fix); that is evidence, not the grade.

**Deviations from the plan.** Tasks 3 and 4 were done by one implementer and one review (both small). `tests/inventory.test.sh` was edited (above). Task 2 took a fix round (steps 2-3 read the wrong path on the resumed rows; step 3's keep-as-is exception lacked `done/<N>/close.md`) and a final-review fix wave (an older-plugin row in the table, the un-archive gate wording, one weak pin). Task 5 took a fix round (a paragraph had split the triage table). The final whole-branch review ran on the subagent model, `sonnet`, as this skill requires, not a more capable one. Open: whether a conflict found at step 3 on the resumed-after-`pr create` row should go through steps 9/11 instead of step 3's send-back; both end with the same un-archive and round, and nothing pins it.

No shared environment is configured: no lease, no deploy.

### Round 2

2026-11-27
(send-back from qc.md round 1)

Each finding was checked against the code before work started; all held. Fixed in four commits (`9c2c5c1`, `3c43037`, `3396264`, `89d5e43`), by one implementer on the subagent model, with a scoped review of each pair:

- **F1 (blocking).** `skills/close/SKILL.md` step 1 now says "a round records this pull request" is read from `HEAD`, like the dossier's place: a round only in the working tree counts as not recorded, so an interrupted step 6 takes the "resumed after `pr create`" row, step 3 keeps the modified `.codeo/done/<N>/close.md`, and step 7 commits it.
- **F2 (blocking).** Step 3's `close.md` exception names both resumed rows. On the "resumed after `pr create`" row a conflict is not sent back at step 3: the run records the pull request (steps 6-7) and the next run's step 9 sends the conflict back through step 11. The un-archive bullet stays for the row with no pull request yet.
- **F6.** The two resumed rows say which steps run (2, 3 and 5 onward; 2-3 then 6-7).
- **A review of this round's fixes** found the first-open-resumed row would also match a send-back round that has no record of the pull request; the row now applies in that case only when no send-back round exists, and step 3's open-pull-request sentence says what the run does next (`89d5e43`).
- **F3.** `tests/qc-verdict.test.sh`: `qc.md` is created in the base commit so the archive commit is a real rename, and a third commit un-archives the dossier and must exit 1 naming `.codeo/7` (criterion 3).
- **F7.** `tests/close-skill.test.sh`: a negative pin that step 4 has no `pr create`, a pin that `close-15` sits directly above step 4, and pins for the new wording.
- **F4.** `docs/handoff.md` names the no-pull-request window as between close's archive push and `pr create`.
- **F5 (part).** `skills/init/SKILL.md` says a `(PR open)` listing waits on its pull request or on `/codeo:close` to open it. `scripts/inflight.sh`'s header comment and its `(PR open)` label are outside the plan's footprint and are left as they were (see `## Notes`).

**Documentation pages changed:** `docs/handoff.md`, `skills/init/SKILL.md`; the skill's own text (`skills/close/SKILL.md`) carries F1, F2 and F6.

**Build result:** the `shell` suite's build is `true`: exit 0. The subagent ran `close-skill`, `qc-verdict`, `init-skill`, `skills-lint`, `skills-doc` and `readme` tests (all passed); the full suite is `/codeo:qc`'s.

**Deviations from the plan.** None of scope: the files edited are the plan's. No shared environment: no lease, no deploy. Sync with `main` at the start of the round: the branch already contained it.

## Log

- 2026-11-27 — implemented docs/plans/2026-11-27-close-archive-before-pr-204.md: 6 tasks, 9 commits, build true · cost: 37m · sonnet-5-5 607k in + 19.7M cached / 83k out
- 2026-11-27 — round 2: fixed qc round 1's F1-F7 (4 commits), build true · cost: 3m · sonnet-5-5 123k in + 5M cached / 23k out
