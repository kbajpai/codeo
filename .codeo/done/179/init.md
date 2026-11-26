# Issue #179 — init

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/179 |
| Branch | `docs/179-close-171-leftovers-readme-wording` |
| Updated | 2026-11-25 |

## Where this stands

Initialized: branch `docs/179-close-171-leftovers-readme-wording` cut off `origin/main` at `d0977374fef597e371ebfb2e27ad2dddbf67b238`, and pushed. Next step: `/codeo:plan` in the issue's container.

## Questions

None.

## Outcome

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/179 — Close the #171 leftovers: README wording, two test guards, and the handoff and role-guard docs |
| State | open · labels `documentation`, `priority: low` |
| Branch | `docs/179-close-171-leftovers-readme-wording` off `main` at `d0977374fef597e371ebfb2e27ad2dddbf67b238` |
| Board | Ready → In progress |

**Problem.** `/codeo:qc` left non-blocking findings H1-H6 on #171, and its plan promised three more items, none filed. README, `docs/updating.md`, `docs/handoff.md` and `tests/readme.test.sh` each say something untrue on one path or guard weakly. The issue lists each place and its fix.

**Acceptance criteria** — verbatim from the issue, unchecked:
- [ ] The doctor-checks intro in README.md describes only what `scripts/doctor.sh` checks, and the two non-doctor entries sit under their own heading or are labelled as such.
- [ ] README.md "Start here" step 6 says the workflow finishes on the second `/codeo:close`.
- [ ] The README lock entry separates the TODOs a fresh `/codeo:init` fixes from the ones that say to reconcile by hand.
- [ ] A repeated heading's link resolves in `tests/readme.test.sh`, and the header names which path checks hold only because codeo uses itself.
- [ ] `docs/updating.md` "Updating superpowers" says to restart open sessions.
- [ ] `docs/handoff.md` and `docs/skills.md` give the same skill count.
- [ ] A page tells another project how to adopt the role guard.
- [ ] "Setting a project up" renders as intended in a strict Markdown renderer.
- [ ] `bash tests/run.sh` passes, in a clean worktree too.

**Out of scope.** Changing doctor, the lock script or the installer. Findings already in #173, #177 or #170.

**Open at intake.** None.

## Log

- 2026-11-25 — initialized: branch docs/179-close-171-leftovers-readme-wording off main at d0977374fef597e371ebfb2e27ad2dddbf67b238 · cost: 0m · sonnet-5-5 18k in + 559k cached / 2k out
