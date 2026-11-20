### Description

Three findings #108's QC recorded as non-blocking were never filed and are still present on `origin/main`: skills and docs that read `overlap.sh`'s output as if a failure were "no overlap", two scripts that read the `## Outcome` heading differently from `qc-verdict.sh`, and a closing block with no next command.

### Motivation / Context

`/codeo:triage` (run 10, 2026-11-20) collected them from `.codeo/done/108/qc.md` (rounds 1 and 3, both clear) and `implement.md` ("Plan gap, not fixed here"). Read against `origin/main` on 2026-11-20:

- **F6.** `scripts/overlap.sh` now exits non-zero with `overlap: cannot diff …` when a diff fails; it used to print nothing. The places that run it say "Each line it prints is an overlap" (`skills/implement/SKILL.md:84`, `skills/qc/SKILL.md:92,166`, `skills/close/SKILL.md:216`, `skills/plan/SKILL.md:310`, `docs/handoff.md:214`) and none says that a non-zero exit with that line is a stop to report, not "no overlap". A skill that reads the failure as "no overlap" can pass a real overlap, the fault #108 fixed in the script.
- **F10.** `scripts/dossier-check.sh:479` and `scripts/inflight.sh:84,180,209,224` match `/^## Outcome/` (a prefix), while `scripts/qc-verdict.sh` matches `/^## Outcome[[:space:]]*$/`. A `## Outcomes` heading therefore reads as an Outcome section in some of them and not in others. `inflight.sh:205` has a comment treating the prefix match as intended ("as in `last_qc_round`"), so which way they should agree is open.
- **F4.** `skills/init/SKILL.md:346-358`: when a lock was taken and a volume or sandbox TODO then printed, the "Closing block — no lock" paragraph has a goal ("the lock taken") that is already met and names no next command, while a test forbids `/codeo:plan` in that paragraph. `docs/handoff.md` agrees with the skill.

### Key Requirements

- A non-zero exit from `overlap.sh` with an `overlap: cannot diff …` line is treated as a stop to report, not as "no overlap", everywhere a skill or doc runs or describes it.
- Every reader of the `## Outcome` heading (`dossier-check.sh`, `inflight.sh`, `qc-verdict.sh`) treats a given heading the same way; which way is `/codeo:plan`'s decision.
- In the lock-taken-then-TODO case, `/codeo:init`'s closing block names a next command; which command is `/codeo:plan`'s decision.

### Acceptance Criteria
- [ ] Each of `skills/plan`, `skills/implement`, `skills/qc`, `skills/close` and `docs/handoff.md` says that `overlap: cannot diff …` with a non-zero exit is a stop to report, not "no overlap", and a test pins the sentence in each.
- [ ] A dossier with a `## Outcomes` heading is judged the same by `dossier-check.sh`, `inflight.sh` and `qc-verdict.sh`, and a test fails if one of them differs.
- [ ] The comment at `scripts/inflight.sh:205` matches whichever rule is chosen.
- [ ] After a lock was taken and a volume or sandbox TODO printed, `/codeo:init`'s closing block names a next command, `docs/handoff.md` says the same, and the test that forbids `/codeo:plan` there is changed to match.
- [ ] The documentation pages the changes touch describe the behaviour in the present tense.

### Out of Scope

- #108's nits (F2, F3, F5, F8, F9): test-name, comment and wording issues, dismissed in triage.
- Changing `overlap.sh`'s or `qc-verdict.sh`'s own exit behaviour.

### Reference

- `.codeo/done/108/qc.md` (F4, F6, F10) and `implement.md` on `origin/main`; #108 (closed), PR #142.
- `scripts/overlap.sh`, `scripts/qc-verdict.sh`, `scripts/dossier-check.sh`, `scripts/inflight.sh`, `skills/init/SKILL.md`, `docs/handoff.md`.
- `.codeo/intake/triage/2026-11-20.md`, Q2.

### Open questions

- Whether the `## Outcome` heading should be anchored everywhere (as `qc-verdict.sh` does) or the prefix match kept and `qc-verdict.sh` loosened; `inflight.sh:205` calls the prefix match deliberate.
- Which command the lock-taken-then-TODO closing block names, given the existing test forbids `/codeo:plan` in that paragraph.
