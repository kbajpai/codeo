# Issue #108 — init

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/108 |
| Branch | `feat/follow-ups-97-left-overlap` |
| Updated | 2026-11-19 |

## Where this stands

Drafted, awaiting review: branch `feat/follow-ups-97-left-overlap` to be cut off `origin/main` at `4a4572e9624bad14b5753a3f455190a31789b290`. Next step: `/codeo:plan` in the issue's container.

## Questions

None.

## Outcome

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/108 — Follow-ups #97 left: overlap.sh and qc-verdict.sh error handling, test guards, and wording that disagrees |
| State | open · labels per the issue |
| Branch | `feat/follow-ups-97-left-overlap` off `main` at `4a4572e` |
| Board | Ready → In progress |

**Problem.** Non-blocking findings from #97's QC and implement rounds that were left for triage. Two gate scripts can let a check pass when it should not: `overlap.sh` returns an empty path list on a git failure and treats an empty `--base`/`--head` as absent, and `qc-verdict.sh` matches `## Outcomes` as `## Outcome` and lacks two cases. Three test guards cannot fail or break on a re-wrap, and wording disagrees across `skills/init`, `skills/close`, `skills/qc`, `docs/handoff.md` and `docs/skills.md`. Two CHANGELOG clauses overstate the code.

**Acceptance criteria** — verbatim from the issue, unchecked:
- [ ] `overlap.sh --outside <N> --base nosuchref` exits non-zero with a message; `--base ""` exits non-zero.
- [ ] `qc-verdict.sh` does not treat `## Outcomes` as `## Outcome`; the two new cases exist and pass.
- [ ] Each test guard named above fails when the text it guards is re-wrapped or the behaviour is broken (shown by a mutation).
- [ ] `skills/init/SKILL.md`, `docs/handoff.md`, `skills/close/SKILL.md`, `docs/skills.md` and `skills/qc/SKILL.md` no longer disagree on the points named; a test pins each.
- [ ] The two CHANGELOG clauses match the code.
- [ ] `bash tests/run.sh` passes and `CHANGELOG.md` records the change.

**Out of scope.** A paging `gh` stub, if `beyond-50` can only be made honest (not live) in this change; changes to the pipeline's behaviour (this is wording, guards and two scripts' error handling).

**Open at intake.** None recorded in the issue. Main moved since filing (#133 merged); `/codeo:plan` re-checks line references such as `skills/init/SKILL.md:321,329` and `docs/handoff.md:391`.

## Log

- 2026-11-19 — drafted for review
