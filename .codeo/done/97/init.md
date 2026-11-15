# Issue #97 — init

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/97 |
| Branch | `docs/docs-skill-wording-test-guard` |
| Updated | 2026-11-15 |

## Where this stands

Branch `docs/docs-skill-wording-test-guard` cut off `main` at 90075d4, claimed and pushed. Nothing is open; the next step is `/codeo:plan`, run in this issue's own container.

## Questions

None.

## Outcome

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/97 — Docs, skill wording and test-guard follow-ups from #34, #39 and #69 (consolidates #41, #43, #74) |
| State | open · labels `documentation` |
| Branch | `docs/docs-skill-wording-test-guard` off `main` at `90075d4` |
| Board | Ready → In progress |

**Problem.** Three earlier changes left docs, skill wording and test guards inaccurate or under-guarded; this issue consolidates #41, #43 and #74 into one planning pass, each carried over unchanged as a "Part of" section whose requirements and criteria all apply. Part #41: `docs/skills.md` misdescribes `doctor` and `qc`, and the skills coverage guard miscounts fenced lines, prints in unstable order and leaves a regex unescaped. Part #43: the re-planned footprint rule has no mechanical check and contradicts itself in `skills/plan/SKILL.md`, `board.sh set` has misleading messages, an unsafe 50-item lookup and untested branches, and several pages describe old behaviour. Part #74: `/codeo:close`'s abandon exit has no closing block, guards miss a partial revert, two `docs/handoff.md` exception rows are wrong or missing, and plan-skill and changelog wording have gaps.

**Acceptance criteria** — verbatim from the issue, unchecked, grouped by the part they come from:

Part of #41:
- [ ] `docs/skills.md` `doctor` Reads lists the extension-points file, installed-plugins file, PATH checks and the `ci.requiredChecks` fallback.
- [ ] `docs/skills.md` `qc` mentions the sync merge commit.
- [ ] A test shows fenced lines in an Extension points part are not counted.
- [ ] The guard's output order is identical across runs.
- [ ] A skill name containing regex metacharacters is matched literally.

Part of #43:
- [ ] A test fails when a second-round `### Footprint` omits a path that `overlap.sh --outside <N>` would print, without relying on a grep of the skill text.
- [ ] Reading `skills/plan/SKILL.md` from sub-step 2 through 4, no step requires `## Outcome` to be both written and still pending.
- [ ] With the issue on no board, `board.sh set` does not print "no project #N is on …".
- [ ] A failed title read is not reported as a failed add; a failed removal's message includes the reason.
- [ ] A `tests/board.test.sh` case runs with `board.statuses` absent from the config and passes.
- [ ] The `undo-fails` case fails if `item-delete` is not called.
- [ ] An issue on a project beyond the first 50 items is found; a failed write on it does not delete its card. *(subject to Q1)*
- [ ] Each of the five wording items above reads correctly against the code.

Part of #74:
- [ ] `/codeo:close`'s abandon exit ends with a closing block: after a finished abandon, the next goal and first step name a command that can run with the lock gone; after an abandon that kept the lock, the first step is `/codeo:close`, and neither block names `/codeo:init #<N>` or `/codeo:close --stash`.
- [ ] `docs/handoff.md` lists the abandon among close's exits and has an exceptions-table row for each new abandon exit and for `/codeo:issue`'s "Status unreadable" exit, and its `init — no lock` row no longer names `lock.sh take local` unconditionally.
- [ ] `tests/closing-exits.test.sh` has a case for each new abandon block, and a check that fails when the old unconditional sentences are put back in close step 17 and in the stash prose (the case is shown to bite against a copy with the sentence restored).
- [ ] `skills/plan/SKILL.md`'s host-task paragraph no longer contradicts itself on `host: local` on Windows or on the order of asking and labelling, its "neutral" list names single-quoted arguments, globs, `~` and `./script`, and `tests/plan-skill.test.sh` pins the changes.
- [ ] `CHANGELOG.md` has an `## Unreleased` entry for this change that says both branches of the host-task rule.
- [ ] Every left minor listed above is fixed or dismissed with a reason in `plan.md`, and step 17's unconditional lead and the empty-`step` guard are fixed.
- [ ] `bash tests/run.sh` passes.

**Out of scope.** Redesigning the footprint format or `overlap.sh`/`inflight.sh` semantics; changing `board.sh set`'s resolution order; re-describing other skills (#41); #70 (overlaps `skills/close/SKILL.md` step 17 and `docs/handoff.md`; the footprint check raises it); closing blocks for close's other pre-#69 stops; `/codeo:implement` on `Runs on: the engineer's host` tasks; dev container follow-ups.

**Open at intake.** #43's Key Requirement 4 and its beyond-50-items criterion are marked "subject to Q1" from the original triage, unresolved in the issue. #70 overlaps this issue and no sequence is promised.

## Log

- 2026-11-15 — initialized: branch docs/docs-skill-wording-test-guard off main at 90075d4 · cost: unavailable
