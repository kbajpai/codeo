# Issue #145 — implement

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/145 |
| Branch | `fix/close-102-126-122-leftovers` |
| Updated | 2026-11-21 |

## Where this stands

Round 1 done: all seven tasks of `docs/plans/2026-11-21-close-102-126-122-leftovers-145.md` built, reviewed and committed; the configured build exits 0. Next step: `/codeo:qc`.

## Questions

None.

## Notes

No shared environment is configured, so no lease was taken and nothing was deployed.

## Outcome

**Round 1.** Started once #144 had merged, as the plan's Q5-Q8 required. `sync-main.sh` merged `origin/main` twice: first #144 (PR #147; it changed `scripts/inflight.sh`'s `## Outcome` matching and the files the plan's Tasks 4 did not edit, so no re-check of this branch's work was needed), then #143 (PR #148, `.devcontainer/`, `.sbx/README.md`, `tests/codeo-command.test.sh` and one `CHANGELOG.md` line; merged without a conflict, Q9's overlap). `overlap.sh` printed nothing.

**Built** (one commit per task, each reviewed by a fresh reviewer; one whole-branch review; one fix wave):
- Task 1 `df81a89` — `scripts/doctor.sh` quotes the plugin path in the `label create` command it prints; a case runs the printed command from a path with a space (`tests/doctor.test.sh`).
- Task 2 `34f17c7` — `skills/issue/SKILL.md` reads `.issue.priority == true`, proposes no general-pass `priority:` label, asks again for a priority outside the four, and files at most one; `docs/skills.md` and `tests/issue-skill.test.sh` match.
- Task 3 `0f9201c` — `scripts/claim.sh`: the header's Known-limit sentence rewritten, the line-211 message says only what `--carries` read, the line-221 message ends `rename or delete it on origin`; `tests/claim.test.sh` pins all three.
- Task 4 `edff089` — comments only in `scripts/inflight.sh` (header, comment above `waits_of`) and `docs/handoff.md`: `review — dossier archived` means the archive is not on the base branch yet, and the fallback steps past any `close` outcome no earlier rule took; a case in `tests/inflight.test.sh`.
- Task 5 `7fc7799` — `skills/triage/SKILL.md` and `docs/skills.md`: *resume* for `review — dossier archived` names the open pull request or `/codeo:close`; *resume* on an unassigned workflow stops nothing; `tests/triage-skill.test.sh` pins both.
- Task 6 `8c981e0` — a fake-`git` case for `touched_of`'s unparsable tip date (`tests/inflight.test.sh`), with a mutation shown to fail it.
- Task 7 `af2dc4d` — `CHANGELOG.md`: "(or the step after the last one finished before the park)" and one new `## Unreleased` bullet.
- Fix wave `8d10ea1` — `skills/issue/SKILL.md` says the priority pass is *below*, and `tests/triage-skill.test.sh` pins `with none, or one closed unmerged, it`.

**Documentation pages changed:** `skills/issue/SKILL.md`, `skills/triage/SKILL.md`, `docs/handoff.md`, `docs/skills.md`, `CHANGELOG.md`, and comments in `scripts/inflight.sh` and `scripts/claim.sh`. No wiki module.

**Build:** the `shell` suite's `build` (`true`) exits 0. The full `bash tests/run.sh` ran green after Task 7 (a QC matter; recorded as evidence only); `issue-skill`, `triage` and `skills-doc` were green after the fix wave.

**Deviations from the plan:**
- Task 4's negative assertion was narrowed: the plan's "does not contain `once close has opened its PR`" would also match an unrelated comment at `scripts/inflight.sh:46`, so the case asserts the absence of the whole old header fragment (`` `review — dossier archived` once close has opened its PR ``).
- Task 5 uses `Answering` (capital) in its pin, and inline `grep` checks in place of a not-contain helper the file did not have.
- Whole-branch review and every task review ran on `sonnet`, the configured subagent model, never escalated.
- The plan's Task 2 sentence "the priority pass above" was wrong in direction; fixed in the fix wave rather than in the plan.

**Plan gaps:** none; no behaviour was added that no documentation task covers.

## Log

- 2026-11-21 — implement round 1: 7 tasks + 1 fix wave built and reviewed, build exit 0 · cost: 26m · sonnet-5-5 593k in + 16.8M cached / 83k out
