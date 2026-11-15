# Issue #108 — issue

## Where this stands

Drafted from triage run 8 (the engineer chose to file and consolidate). Approved by the engineer; filed.

## Questions

None.

## Draft

**Title:** Follow-ups #97 left: overlap.sh and qc-verdict.sh error handling, test guards, and wording that disagrees
**Type:** none (no Issue Types); **Labels:** enhancement

### Description

Non-blocking findings from #97's QC and implement rounds (`.codeo/done/97/qc.md` rounds 2-3, `.codeo/done/97/implement.md`) that #97 carried "for `/codeo:triage`": two scripts that can let a check pass when it should not, three test guards that cannot fail or break on a re-wrap, and wording that disagrees with itself across skills and docs.

### Motivation / Context

The scripts matter most: `overlap.sh` and `qc-verdict.sh` are gates other workflows trust. The rest are hygiene. Triage run 8 decided to file them as one issue, as #97 did for #34, #39 and #69.

### Key Requirements

- `scripts/overlap.sh`: `changes()` reports a git failure (a mistyped `--base` or `--head`) instead of returning an empty path list; an empty `--base ""` or `--head ""` is an error, not treated as absent; the header describes `--base` given alone (F14, F18).
- `scripts/qc-verdict.sh`: the `## Outcome` match is anchored, so `## Outcomes` does not match; a case covers a PR that only adds files under `docs/plans` and `.codeo`, and one covers a `### Round 2` outside `## Outcome`.
- Tests: `tests/board.test.sh` `beyond-50` exercises a second page, or says plainly that it cannot (F8, F20); `title-read-fails` asserts the exit code; `case_close_step17_lead` and the `and not blocking by rule:` check in `tests/qc-skill.test.sh` survive a re-wrap; `row_for` in `tests/closing-exits.test.sh` matches a whole label; the `RETURN` trap in `bites` is cleared (F19).
- Wording: `skills/init/SKILL.md:321,329` agrees with `docs/handoff.md`'s `init — no lock` row about a lock after `lock: TODO` (F10, F21); `skills/close/SKILL.md` and `docs/handoff.md:391`/`docs/skills.md:190` agree about what an abandon leaves in the checkout when the remote branch was deleted (F12, F17); `skills/qc/SKILL.md:161-164` agrees with step 8 about whose finding a footprint gap is (F13); `skills/qc/SKILL.md` step 6 says how to detect a second plan round; the comment above `touched` in `qc-verdict.sh` says only delivered archives are footprint-checked.
- CHANGELOG: the `board.sh` clause no longer says "follows every page of an issue's project items, so an issue on a large board is found" if `lookup` reads only the issue's own `projectItems`; the host-task clause says the rule is older than this release (F15, F16).

### Acceptance Criteria

- [ ] `overlap.sh --outside <N> --base nosuchref` exits non-zero with a message; `--base ""` exits non-zero.
- [ ] `qc-verdict.sh` does not treat `## Outcomes` as `## Outcome`; the two new cases exist and pass.
- [ ] Each test guard named above fails when the text it guards is re-wrapped or the behaviour is broken (shown by a mutation).
- [ ] `skills/init/SKILL.md`, `docs/handoff.md`, `skills/close/SKILL.md`, `docs/skills.md` and `skills/qc/SKILL.md` no longer disagree on the points named; a test pins each.
- [ ] The two CHANGELOG clauses match the code.
- [ ] `bash tests/run.sh` passes and `CHANGELOG.md` records the change.

### Out of Scope

- A paging `gh` stub, if `beyond-50` can only be made honest (not live) in this change.
- Changes to the pipeline's behaviour; this is wording, guards and two scripts' error handling.

### Reference

- `.codeo/done/97/qc.md` rounds 2-3: F8, F10, F12-F21; `.codeo/done/97/implement.md` minors.
- Related: #97, #74, #43.
- Triage run 8: `.codeo/intake/triage/2026-11-15-8.md` Q5.

## Outcome

Filed as #108.

## Log

- 2026-11-15 — drafted from triage run 8 · cost: unavailable
