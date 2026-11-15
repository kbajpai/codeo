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

**Acceptance criteria** — the full lists are in the issue body (`.codeo/97/issue.md` is not available; the issue was filed without a dossier), one per part, to be copied verbatim by `/codeo:plan` from https://github.com/kbajpai/codeo/issues/97 and not reworded. They cover: Part #41 — the `doctor` Reads list and `qc` sync-merge wording in `docs/skills.md`, a test that fenced lines are not counted, stable guard output order, literal matching of regex metacharacters; Part #43 — a mechanical footprint-omission test, no contradictory plan-skill ordering, the `board.sh set` messages and tests, the beyond-50-items lookup *(subject to Q1 of #43's original triage)*, the five wording items; Part #74 — abandon-exit closing blocks, `docs/handoff.md` rows, closing-exits guards that bite, plan-skill host-task wording pinned by test, an `## Unreleased` changelog entry, left minors fixed or dismissed in `plan.md`, and `bash tests/run.sh` passing.

**Out of scope.** Redesigning the footprint format or `overlap.sh`/`inflight.sh` semantics; changing `board.sh set`'s resolution order; re-describing other skills (#41); #70 (overlaps `skills/close/SKILL.md` step 17 and `docs/handoff.md`; the footprint check raises it); closing blocks for close's other pre-#69 stops; `/codeo:implement` on `Runs on: the engineer's host` tasks; dev container follow-ups.

**Open at intake.** #43's Key Requirement 4 and its beyond-50-items criterion are marked "subject to Q1" from the original triage, unresolved in the issue. #70 overlaps this issue and no sequence is promised.

## Log

- 2026-11-15 — initialized: branch docs/docs-skill-wording-test-guard off main at 90075d4 · cost: unavailable
