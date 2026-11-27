# Issue #204 — implement

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/204 |
| Branch | `chore/204-fix-codeo-close-opens-pr` |
| Updated | 2026-11-27 |

## Where this stands

Round 1, done. All six tasks of `docs/plans/2026-11-27-close-archive-before-pr-204.md` are built and the build step passes. Next step: `/codeo:qc`.

## Questions

None.

## Notes

- Nothing out of scope was found that needed `/codeo:issue`.
- Parked, non-blocking, from the whole-branch review (for `/codeo:qc` to weigh): long lines in `skills/close/SKILL.md`'s step 1 table and step 6; three weak pins in `tests/close-skill.test.sh` (the whole-file `close-15` check, the push-before-`pr create` order check); `scripts/inflight.sh` labels an archive with no pull request `review — dossier archived` (cosmetic; `skills/triage/SKILL.md` now names the case); a kill between `git mv` and the commit leaves a staged rename that step 3 stops on (unchanged behaviour).

## Outcome

**Built.** Phase 1 of `skills/close/SKILL.md` is reordered: the checks, then archive and push (`— archived`), then `pr create`, then the record of `#<number> <url>` in `.codeo/done/<N>/close.md` (`— PR #<pr>`). Step 1's table gains the two interrupted-close cases and the older-plugin case; steps 2-3 read the dossier from `.codeo/<N>/` or `.codeo/done/<N>/`; step 3's send-back un-archives when the dossier is archived. Rule `close-15` (archive and push before the pull request) is in the skill and in `docs/skills-inventory.md`. Tests: new pins in `tests/close-skill.test.sh`, a two-commit replay in `tests/qc-verdict.test.sh`, an archived-with-no-pull-request case in `tests/role.test.sh`, `tests/inventory.test.sh`'s close rule count 14 → 15 (unplanned, needed by the new rule), and the log wording of two fixtures.

**Documentation pages changed:** `docs/dossier.md`, `docs/handoff.md`, `docs/skills.md`, `README.md`, and the wording in `skills/triage/SKILL.md` and `skills/init/SKILL.md`; `CHANGELOG.md` has the entry.

**Build result:** the `shell` suite's build is `true`: exit 0. The full suite and the acceptance criteria are `/codeo:qc`'s. Deviation: the task implementers ran `bash tests/run.sh` themselves (it exited 0 after Tasks 3, 5 and 6 and after the last fix); that is evidence, not the grade.

**Deviations from the plan.** Tasks 3 and 4 were done by one implementer and one review (both small). `tests/inventory.test.sh` was edited (above). Task 2 took a fix round (steps 2-3 read the wrong path on the resumed rows; step 3's keep-as-is exception lacked `done/<N>/close.md`) and a final-review fix wave (an older-plugin row in the table, the un-archive gate wording, one weak pin). Task 5 took a fix round (a paragraph had split the triage table). The final whole-branch review ran on the subagent model, `sonnet`, as this skill requires, not a more capable one. Open: whether a conflict found at step 3 on the resumed-after-`pr create` row should go through steps 9/11 instead of step 3's send-back; both end with the same un-archive and round, and nothing pins it.

No shared environment is configured: no lease, no deploy.

## Log

- 2026-11-27 — implemented docs/plans/2026-11-27-close-archive-before-pr-204.md: 6 tasks, 9 commits, build true · cost: 37m · sonnet-5-5 607k in + 19.7M cached / 83k out
