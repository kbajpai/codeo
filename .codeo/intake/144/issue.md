# Issue #144 — issue

Called from `/codeo:triage` (run 10, 2026-11-20, Q2): the engineer answered *file it* for F4, F6 and F10 only; the nits (F2, F3, F5, F8, F9) are dismissed. Problem as understood: #108 (`overlap.sh`, `qc-verdict.sh` error handling) closed clear with three non-blocking findings nobody filed (`.codeo/done/108/qc.md` rounds 1 and 3; `implement.md` calls F6 "Plan gap, not fixed here"). Read against `origin/main` on 2026-11-20, all three are still there:

- **F6:** `overlap.sh` now exits non-zero with `overlap: cannot diff …` when a diff fails, where it used to print nothing. The skills that run it say "Each line it prints is an overlap" (`skills/implement/SKILL.md:84`, `skills/qc/SKILL.md:92,166`, `skills/close/SKILL.md:216`, `skills/plan/SKILL.md:310`, `docs/handoff.md:214`) and none says a non-zero exit is a stop to report rather than "no overlap".
- **F10:** `scripts/dossier-check.sh:479` and `scripts/inflight.sh:84,180,209,224` match `/^## Outcome/` (a prefix), while `scripts/qc-verdict.sh` anchors with `/^## Outcome[[:space:]]*$/`, so a `## Outcomes` heading reads differently between them. `inflight.sh:205` has a comment that treats the prefix match as intended ("as in `last_qc_round`").
- **F4:** `skills/init/SKILL.md:346-358`: after a lock was taken and a volume or sandbox TODO printed, the "no lock" closing block's goal ("the lock taken") is already met and no next command is named, while a test forbids `/codeo:plan` in that paragraph; `docs/handoff.md` agrees with the skill.

No open issue covers these (`issue search` finds only closed #97, #108, #116).

## Questions

1. **F10: which way should the headings agree?** The scripts disagree, and `inflight.sh:205` says the prefix match is deliberate. Proposed: the issue states only the requirement, that every reader of `## Outcome` treats a given heading the same way (`## Outcomes` is either an Outcome section everywhere or nowhere), and `/codeo:plan` picks the direction. Or do you want it fixed one way now (anchor everything, as `qc-verdict.sh` does)?

2. **F4: what should the engineer be told to run in the lock-taken-then-TODO case?** The skill's block says nothing and the test forbids `/codeo:plan`. Proposed: the criterion is that the closing block names a next command in that case and the test is changed to match; which command is `/codeo:plan`'s call. Agreed, or do you already know the answer?

## Outcome

Filed as #144 after approval.

## Log

2026-11-20 — questions raised · cost: unavailable
2026-11-20 — approved and filed as #144 · cost: unavailable
