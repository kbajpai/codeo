# Issue #new — issue

| | |
|---|---|
| Issue | not filed yet |
| Source | `/codeo:triage` run 2026-11-08-2, Q1-Q3 (`qc:39:F1-F3`, `qc:39:F4-F5-F7`, `qc:39:F2-F6-F8`) |
| Updated | 2026-11-08 |

## Where this stands

Engineer asked for the three triage items to go into one issue. Draft below awaits answers to Q1-Q2 and approval.

## Questions

### Q1 — Is the 50-item lookup limit in scope?

**What.** implement.md for #39: "if the issue is on a project but beyond the first 50 items the lookup reads, a failed write would delete a card that already existed. Pre-existing lookup limit; the delete is best effort." Fixing it means paging the lookup in `scripts/board.sh`.

**Why it matters.** It is the only item here that can destroy something (an existing card), but it needs a failed write on a board of more than 50 items. It is a larger change than the message and test nits beside it.

**Options.** include it as a requirement · list it under Out of Scope as a follow-up · drop it

**Recommended:** include it. **Answer:**

### Q2 — Shape of the mechanical footprint check

**What.** F1 suggests "a mechanical check, for instance in `dossier-check.sh`". The issue will state the requirement (a re-planned footprint missing a path the branch still changes is caught without relying on the planner following a sentence) and leave where it lives to `/codeo:plan`.

**Why it matters.** Naming a script now would be design; leaving it open keeps the issue to what and why.

**Options.** requirement only, location left to plan · name `dossier-check.sh` as the preferred home

**Recommended:** requirement only. **Answer:**

## Notes

### Draft

**Title:** Close the gaps #39 left: enforce the re-planned footprint rule, tidy `board.sh set` messages and tests, correct the wording it changed

**Issue Type:** none (user-owned repository, `issue-types` prints nothing). **Labels:** `enhancement`, `documentation`.

```markdown
### Description

`/codeo:qc` cleared #39 (PR #42) with eight non-blocking findings and the implementer deferred six more. They fall in three groups: the "footprint is the union of all rounds" rule has no mechanical check and its placement in `skills/plan/SKILL.md` contradicts itself; `scripts/board.sh set` has misleading failure messages and untested branches; and several pages still describe the old behaviour.

### Motivation / Context

- Round 2 of #36 replaced round 1's footprint with only its own files, so `overlap.sh --outside 36` printed `.devcontainer/devcontainer.json` and `CHANGELOG.md` and other workflows were told too little. #39 fixed this with a sentence in `skills/plan/SKILL.md:305-308`; `overlap.sh`, `inflight.sh` and `dossier-check.sh` are unchanged, and the new tests only grep the sentence. A planning pass that skips it reproduces the #36 result.
- The same lines sit inside sub-step 4, which runs after the outcome is written and the footprint has left `## Notes`, then say to "raise what it prints as at sub-step 2", which stops with `## Outcome` still pending and amends the footprint in `## Notes`. If the check prints anything, the instructions contradict each other.
- `board.sh set` failure paths misreport what happened, and some branches have no test.
- User-facing text still says things the code no longer does.

### Key Requirements

1. **Footprint rule.** A re-planned `### Footprint` that omits a path the branch still changes is detected mechanically, not only by a planner following an instruction. Where the check lives is left to `/codeo:plan`.
2. **Plan skill.** The re-run of `overlap.sh --outside <N>` and the "raise what it prints" step are ordered so they do not contradict sub-step 2 and 4 (`## Outcome` pending vs written).
3. **`board.sh set` messages** (`scripts/board.sh`):
   - `:282` says `no project #N is on has the option …` when the issue is on no project.
   - `:214-216` reports a failed title read as `could not add #N to project #P` though nothing was being added.
   - `:270` discards the delete's stderr, so the hand-removal line gives no reason; the comment at `:268-269` ("so the board is as it was") overstates a best-effort removal.
4. **`board.sh set` lookup.** An issue on a project but beyond the first 50 items the lookup reads is not treated as absent, so a failed write cannot delete a card that already existed. *(subject to Q1)*
5. **Tests** (`tests/board.test.sh`): a case with `board.statuses` absent altogether (every case now carries `statuses`); the `undo-fails` case asserts `item-delete 1` is in the gh log; the bash 4.3 guard is proven by the suite or the guard is dropped.
6. **Wording.**
   - `CHANGELOG.md:11` says `set` "removes a card whose write failed" (it removes only a card it added) and that `overlap.sh --outside` "finds nothing the new block omits" (true only if the plan step is followed).
   - `lib/env.sh:29-31` says "a name that is not a key passes through" with no mention of the defaults.
   - `skills/triage/SKILL.md:220` says the script "adds the issue to the board if it is not on it".
   - `docs/handoff.md` says the replacing footprint block "carries the earlier round's files too", broader than the skill's "still changes".
   - `docs/dossier.md` does not say the check runs after the earlier block is replaced.

### Acceptance Criteria

- [ ] A test fails when a second-round `### Footprint` omits a path that `overlap.sh --outside <N>` would print, without relying on a grep of the skill text.
- [ ] Reading `skills/plan/SKILL.md` from sub-step 2 through 4, no step requires `## Outcome` to be both written and still pending.
- [ ] With the issue on no board, `board.sh set` does not print "no project #N is on …".
- [ ] A failed title read is not reported as a failed add; a failed removal's message includes the reason.
- [ ] A `tests/board.test.sh` case runs with `board.statuses` absent from the config and passes.
- [ ] The `undo-fails` case fails if `item-delete` is not called.
- [ ] An issue on a project beyond the first 50 items is found; a failed write on it does not delete its card. *(subject to Q1)*
- [ ] Each of the five wording items above reads correctly against the code.

### Out of Scope

- Redesigning the footprint format or `overlap.sh`/`inflight.sh` semantics.
- Changes to `board.sh set`'s resolution order (configured → default → pass-through), which #39 settled.

### Reference

- #39 (closed, PR #42) and #36 (closed, PR #38).
- `.codeo/done/39/qc.md` findings F1-F8; `.codeo/done/39/implement.md`, "Deferred findings".
- `/codeo:triage` run 2026-11-08-2, Q1-Q3.
```

## Outcome

(pending)

## Log

- 2026-11-08 — drafted from triage run 2026-11-08-2 Q1-Q3 · cost: unavailable
