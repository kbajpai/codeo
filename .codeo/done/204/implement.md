# Issue #204 — implement

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/204 |
| Branch | `chore/204-fix-codeo-close-opens-pr` |
| Updated | 2026-11-27 |

## Where this stands

Round 4, done, after the send-back from `qc.md` round 3 (a conflict with `main`). Next step: `/codeo:qc`.

## Questions

### Q1 — #206 now changes `tests/intake.test.sh`, inside this plan's `tests/**`. Proceed, sequence, or re-scope?

**Why it matters:** `overlap.sh 204` printed `206	glob:tests/intake.test.sh`. `#206` (branch `fix/206-codeo-cleanup-prints-codeo-rm`, assignee kbajpai) has added that file to its changed paths since `plan.md` Q3 was answered. This branch does not change `tests/intake.test.sh`: the overlap is this plan's coarse `tests/**` footprint glob, not a shared edit, so it cannot conflict. No exclusive resource is shared.

- Proceed and coordinate: as `plan.md` Q3 decided for #206.
- Sequence after #206.
- Re-scope.

I recommend proceed and coordinate.

**Options:** proceed and coordinate (recommended) · sequence after #206 · re-scope.

**Answer:**
Proceed and coordinate, as recommended. Given in the conversation: "go with your picks".

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

### Round 3

2026-11-27
(send-back from qc.md round 2)

Sync with `main` at the start of the round: the branch already contained it. `overlap.sh` raised one overlap, #206's `tests/intake.test.sh` (Q1, answered: proceed and coordinate). Each finding was checked against the code before work started; all held. Fixed in three commits (`465e63c`, `e476333`, `3d805df`) by one implementer on the subagent model, with a scoped review:

- **G1 (blocking).** `skills/close/SKILL.md` step 1: when no round in `close.md` records the pull request, the row is a first open resumed, whatever other rounds exist — a conflict round without a record predates the pull request, as step 6 already says. Only a round recording the pull request followed by a `— review feedback` or `— conflicts with <base>` round is a return from review. The wrong parenthetical added in round 2 is gone. On a pull request opened by hand or by an older plugin after a step-3 conflict, step 6 now writes the `— pull request opened` round with `#<number> <url>`, so criterion 2 holds on that path, and no review-return comment is posted. Pins: the old-wording pin became a check that the text is gone, plus fixed-string pins for the new rule.
- **G2.** The resumed-after-`pr create` row runs steps 2-3 then 6-8; the first-open-resumed row runs steps 2 and 3, then 6, 4, 7 and 8, step 5 skipped.
- **G3.** Step 1's prose says the un-archiving send-back at step 3 is for the dossier archived with no pull request yet; with a pull request open, step 3 sends nothing back and the next run's step 9 sends the conflict back through step 11.
- **G5.** `docs/dossier.md`: the record is written in the commit after the archive, or in the archive's own commit when the pull request was opened before the archive.
- **G6.** `docs/handoff.md`: the `review — dossier archived` line does not look for a pull request; between close's archive push and `pr create` the workflow waits for `/codeo:close`, not for review.

**Documentation pages changed:** `docs/dossier.md`, `docs/handoff.md`; the skill's own text carries G1-G3.

**Build result:** the `shell` suite's `build` is `true`: exit 0. The implementer ran `close-skill`, `skills-lint`, `skills-doc`, `readme`, `init-skill`, `triage-skill` and `closing-block` tests (all passed, new pins red before the edit); the full suite is `/codeo:qc`'s.

**Deviations from the plan.** None of scope. Open and left as deferred minors: step 3's sentence for the resumed-after-`pr create` row still says "the run goes on to steps 6-7" where step 1 says 6-8 (an existing pin fixes the string; no run is misdirected); whether a `— pull request updated` round counts as recording the pull request in the first-open-resumed row is not stated. G4, G7 and G8 from `qc.md` round 2 are recorded there as non-blocking and untouched. No shared environment: no lease, no deploy.

### Round 4

2026-11-27
(send-back from qc.md round 3)

`sync-main.sh` merged `origin/main` (`c7505a9`, the acting-user change that merged first) and stopped on four conflicts, resolved in the merge commit `1e5afbc`. Everything else on `main` merged cleanly, including `skills/close/SKILL.md`, `docs/dossier.md`, `docs/handoff.md` and `README.md`. `overlap.sh 204` and `overlap.sh --outside 204` print nothing.

- **Rule id collision.** `main` took `close-15` (step 0's `lock.sh verify`) and `close-16` (the owner on a stash or abandon) for its own rules, the id this branch had used for "archive and push before the pull request opens". This branch's rule is now **`close-17`**: the marker above step 4 in `skills/close/SKILL.md`, the two pins in `tests/close-skill.test.sh` (the marker's placement and its adjacency to step 4), the inventory bullet and the changelog bullet. `main`'s `close-15` and `close-16` are untouched.
- `CHANGELOG.md`: both `## Unreleased` bullets kept, this branch's before `main`'s.
- `docs/skills-inventory.md`: `main`'s `close-15` and `close-16` kept, `close-17` added after them.
- `tests/inventory.test.sh`: `main`'s rule counts, with `[close]=17`.
- `tests/fixtures/skills-inventory.rules.sha256`: regenerated with `bash tests/inventory.test.sh --update`, not hand-merged.

**Documentation pages changed:** none beyond the merge. **Build result:** the `shell` suite's `build` is `true`: exit 0. After the merge `inventory`, `skills`, `close-skill`, `skills-lint` and `skills-doc` tests each print `all cases passed`; the full suite is `/codeo:qc`'s.

**Deviations from the plan.** The plan's text and its Task 3 name the rule `close-15`; the id is `close-17` because `main` took 15 and 16 first. The plan is not edited here (`/codeo:plan`'s file); `/codeo:qc` should read "close-15" in it as `close-17`. No shared environment: no lease, no deploy.

## Log

- 2026-11-27 — implemented docs/plans/2026-11-27-close-archive-before-pr-204.md: 6 tasks, 9 commits, build true · cost: 37m · sonnet-5-5 607k in + 19.7M cached / 83k out
- 2026-11-27 — round 2: fixed qc round 1's F1-F7 (4 commits), build true · cost: 3m · sonnet-5-5 123k in + 5M cached / 23k out
- 2026-11-27 — round 3: Q1 raised (overlap with #206, tests/intake.test.sh) · cost: 0m · sonnet-5-5 10k in + 377k cached / 405 out
- 2026-11-27 — round 3: fixed qc round 2's G1, G2, G3, G5, G6 (3 commits), build true · cost: 2m · sonnet-5-5 89k in + 3.6M cached / 16k out
- 2026-11-27 — round 4: merged main (#195, 4 conflicts resolved, rule id close-15 renumbered to close-17), build true · cost: 1m · sonnet-5-5 38k in + 3M cached / 4k out
