# Issue #144 — plan

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/144 |
| Branch | `fix/close-108-leftovers-overlap-sh` |
| Updated | 2026-11-21 |

## Where this stands

Explored and brainstormed; nothing drafted yet. The two questions intake left open are raised as Q1 (which `## Outcome` heading rule every reader follows) and Q2 (the shape of `/codeo:init`'s closing block once a lock was taken and a TODO printed). F6 (the `overlap: cannot diff` stop sentence) needs no answer and is settled in `## Notes`. The plan is drafted once Q1 and Q2 are answered.

## Questions

### Q1 — Which `## Outcome` heading rule should every reader follow?

**Why it matters:** there are three rules today, not two, and the answer decides which scripts change and which existing tests move.

| Reader | Rule today | `## Outcomes` | `## Outcome notes` |
|---|---|---|---|
| `qc-verdict.sh:72,134` | exact, trailing whitespace allowed | not Outcome | not Outcome |
| `dossier-check.sh` `section_range` (`:131`, behind `outcome_written`, `rounds_of`, the footprint and gate checks) | the name, or the name then a space | not Outcome | Outcome |
| `dossier-check.sh:479` `last_round_clear` | prefix | Outcome | Outcome |
| `inflight.sh:84,180,209,224` | prefix | Outcome | Outcome |

`dossier-check.sh:474` already claims `last_round_clear` is "`qc-verdict.sh`'s reading transcribed step for step, so the two cannot disagree", which the prefix makes untrue. `tests/qc-verdict.test.sh:760,827` already pin that `## Outcomes` is not an Outcome section for `qc-verdict.sh`, and the issue puts changing `qc-verdict.sh`'s exit behaviour out of scope.

**Options:**
- **A — exact everywhere (my pick).** `## Outcome`, trailing whitespace allowed, is the only Outcome heading; `## Outcomes` and `## Outcome notes` are ordinary sections to all three scripts. `inflight.sh`'s four matches and `dossier-check.sh:479` are anchored as `qc-verdict.sh` is; `dossier-check.sh`'s Outcome lookups stop accepting `## Outcome <text>` (`section_range` keeps its name-then-space rule for the other sections, such as `## Draft (approved)`). The comment at `inflight.sh:205` is rewritten to say the match is exact. `qc-verdict.sh` is untouched. One shared-fixture test feeds the same `## Outcomes` and `## Outcome notes` dossiers to all three scripts. No dossier under `.codeo/` or `docs/` uses either heading today, so nothing already written is read differently.
- **B — the name, or the name then a space, everywhere.** `## Outcomes` is Outcome nowhere and `## Outcome notes` is Outcome everywhere. `inflight.sh` and `dossier-check.sh:479` are tightened to that, and `qc-verdict.sh` is loosened to accept `## Outcome notes`, which changes what the merge gate judges and sits against the issue's out-of-scope line.
- **C — prefix everywhere.** `qc-verdict.sh` and `section_range` are loosened so `## Outcomes` is Outcome everywhere; the two cases at `tests/qc-verdict.test.sh:760,827` are reversed and the `## Unreleased` CHANGELOG clause "`qc-verdict` no longer reads `## Outcomes` as `## Outcome`" is withdrawn. It undoes what #108 shipped.

**Answer:**

### Q2 — How should `/codeo:init`'s closing block name the next command once a lock was taken and a TODO printed?

**Why it matters:** #108's Q4 already settled what the engineer does in that case: the fix the `lock: TODO` line names, then `/codeo:plan`, with init still withholding its own hand-off (wording only, no behaviour change). What is open is where that is written, which decides whether the `lacks '/codeo:plan'` assertions in `tests/closing-exits.test.sh:94,137,156` are kept for a narrower paragraph or dropped.

**Options:**
- **A — a second paragraph and a second handoff row (my pick).** `skills/init/SKILL.md` step 11 gains `**Closing block — lock taken, TODO printed:**`: goal, a reviewed plan; first step, the fix the `lock: TODO` line names (for example filling in the lock's `volume:` line); second step, `/codeo:plan` (with a host workflow, in the checkout its text names). The `**Closing block — no lock:**` paragraph keeps its goal and steps, loses nothing, and still never names `/codeo:plan`, so its three assertions stay. `docs/handoff.md`'s exits table gains an `init — lock taken, TODO` row, and the trailing "needs the fix alone" clause leaves the `init — no lock` row. The test gains a case for the new paragraph and row (`/codeo:plan` named, and named after the fix), and the two paragraphs are told apart by `lock.sh`'s own `took the lock` / `lock already taken` line, as step 11 already says.
- **B — one paragraph, extended.** The `no lock` paragraph gains a third step ("when the lock was taken, `/codeo:plan`"), its heading and goal are reworded to cover both cases, the handoff row gains the same clause, and the three `lacks '/codeo:plan'` assertions are replaced by an ordering check (`/codeo:plan` only after "when the lock was taken"). Fewer lines, and one paragraph then carries two goals.

**Answer:**

## Notes

- **F6 needs no question.** Every place a skill runs `overlap.sh` gets the same sentence: a non-zero exit with an `overlap: cannot diff …` (or `overlap: cannot resolve …`) line is a stop to report, not "no overlap". That is `skills/plan/SKILL.md` step 10 (both the `--outside` run and the pair run), `skills/implement/SKILL.md:84`, `skills/qc/SKILL.md:92` and `:166`, `skills/close/SKILL.md:216`, and `docs/handoff.md:214`, each pinned by a `must_contain` case in that skill's test. My call, stated here so it can be corrected: the sentence also says that a `overlap: cannot diff #<M> (<branch>)` warning with exit 0 (another workflow's diff could not be made, #108 Q1 option A) is quoted to the engineer and the step carries on with that workflow's footprint alone.
- **Shape (step 5).** A scoped, executable plan under `docs/plans/2026-11-21-close-108-leftovers-144.md`; no standing reference doc, since `docs/handoff.md` and `docs/dossier.md` already are the references and the plan gives them documentation tasks. No technology or architecture choice is being made, so `engineering:system-design` and `engineering:architecture` do not apply.
- **Other workflows in flight (2026-11-21).** #143 (`fix/codeo-host-command-close-leftovers`, at `plan`, waiting on its Q1-Q6) and #145 (`fix/close-102-126-122-leftovers`, at `init`) have no footprint and no changed files yet, so there is nothing to compare; intake noted that #145 will edit `docs/handoff.md` and `skills/triage/SKILL.md`. The footprint is checked again with `overlap.sh` before the outcome is written.

## Outcome

_Pending — written at the hand-off._

## Log

- 2026-11-21 — Q1-Q2 raised · cost: 1m · fable-5-2 77k in + 618k cached / 6k out
