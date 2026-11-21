# Issue #144 — init

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/144 |
| Branch | `fix/close-108-leftovers-overlap-sh` |
| Updated | 2026-11-21 |

## Where this stands

Initialized: branch `fix/close-108-leftovers-overlap-sh` cut off `origin/main` at `2e02100a256de327d5f85d51d57db98a98672da1` and pushed. Next step: `/codeo:plan` in the issue's container.

## Questions

None.

## Outcome

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/144 — Close the #108 leftovers: `overlap.sh` failures read as "no overlap", the `## Outcome` heading rule, and `/codeo:init`'s closing block |
| State | open · labels `bug` |
| Branch | `fix/close-108-leftovers-overlap-sh` off `main` at `2e02100` |
| Board | Ready → In progress |

**Problem.** Three #108 QC findings were never filed. F6: `overlap.sh` now exits non-zero with `overlap: cannot diff …` on a failed diff, but the skills and `docs/handoff.md` still read its output as "each line is an overlap", so a failure can pass as "no overlap". F10: `dossier-check.sh` and `inflight.sh` match `/^## Outcome/` as a prefix while `qc-verdict.sh` anchors it, so a `## Outcomes` heading is judged differently. F4: after a lock is taken and a volume or sandbox TODO prints, `/codeo:init`'s closing block names no next command, and a test forbids `/codeo:plan` there.

**Acceptance criteria** — verbatim from the issue, unchecked:
- [ ] Each of `skills/plan`, `skills/implement`, `skills/qc`, `skills/close` and `docs/handoff.md` says that `overlap: cannot diff …` with a non-zero exit is a stop to report, not "no overlap", and a test pins the sentence in each.
- [ ] A dossier with a `## Outcomes` heading is judged the same by `dossier-check.sh`, `inflight.sh` and `qc-verdict.sh`, and a test fails if one of them differs.
- [ ] The comment at `scripts/inflight.sh:205` matches whichever rule is chosen.
- [ ] After a lock was taken and a volume or sandbox TODO printed, `/codeo:init`'s closing block names a next command, `docs/handoff.md` says the same, and the test that forbids `/codeo:plan` there is changed to match.
- [ ] The documentation pages the changes touch describe the behaviour in the present tense.

**Out of scope.** #108's nits (F2, F3, F5, F8, F9); changing `overlap.sh`'s or `qc-verdict.sh`'s own exit behaviour.

**Open at intake.** Whether the `## Outcome` heading should be anchored everywhere (as `qc-verdict.sh` does) or the prefix match kept and `qc-verdict.sh` loosened; `inflight.sh:205` calls the prefix match deliberate. Which command the lock-taken-then-TODO closing block names, given the existing test forbids `/codeo:plan` in that paragraph. Note: #143 is in flight but touches `.devcontainer/` only; #145 (Ready, not started) edits `docs/handoff.md` and `skills/triage/SKILL.md`, so start it after this one.

## Log
- 2026-11-21 — initialized: branch fix/close-108-leftovers-overlap-sh off main at 2e02100 · cost: 1m · sonnet-5-5 16k in + 434k cached / 3k out
