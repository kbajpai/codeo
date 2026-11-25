# Issue #177 — init

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/177 |
| Branch | `docs/177-close-163-166-168-leftovers` |
| Updated | 2026-11-25 |

## Where this stands

Initialized: branch `docs/177-close-163-166-168-leftovers` cut off `origin/main` at `d0977374fef597e371ebfb2e27ad2dddbf67b238`, and pushed. Next step: `/codeo:plan` in the issue's container.

## Questions

None.

## Outcome

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/177 — Close the #163, #166 and #168 leftovers: README sandbox and jq claims, cleanup overlay order, cleanup closing block, `<machine>` placeholder, and stale plan wording |
| State | open · labels `documentation`, `priority: low` |
| Branch | `docs/177-close-163-166-168-leftovers` off `main` at `d0977374fef597e371ebfb2e27ad2dddbf67b238` |
| Board | Ready → In progress |

**Problem.** `/codeo:qc` left non-blocking findings on #163 (F1-F6 and two parked minors), #166 (F2-F5) and #168 (F1-F4), none filed. Each is text that is true on the main path but untrue on another path the code takes, or stale after the change that made it: README sandbox and `jq` claims, the cleanup and close overlays' step order, the cleanup closing block, the `<machine>` placeholder, and stale plan and changelog wording. The issue lists each place.

**Acceptance criteria** — verbatim from the issue, unchecked:
- [ ] `README.md:256` and `:199` hold for a sandbox, and for `/codeo:doctor` and `live-signal.sh` without `jq`.
- [ ] `.codeo/overlays/cleanup.md` and `close.md` put the `git status` precondition before the removal commands and state when the row is marked.
- [ ] `CHANGELOG.md:20` no longer calls the README example invented; the `(#157)` clause is not repeated under `(#166)`.
- [ ] The close overlay's sandbox clause is complete, and `tests/track.test.sh` restores `TMPDIR`.
- [ ] `skills/cleanup/SKILL.md` step 4 names the leftover command for a run whose only output is a `failed name` issue.
- [ ] `skills/close/SKILL.md` makes the `<machine>` command usable at once, and says the branch stays on `origin` only when a beat pushed.
- [ ] The stale `(unstaged)` and `## Unreleased` lines in #168's workflow record are corrected or marked historical.
- [ ] The release checklist names the timezone for the changelog date.

**Out of scope.** Redesigning `/codeo:cleanup` or the live signal. #168's grep-count deviation, already recorded in its `implement.md`.

**Open at intake.** None.

## Log

- 2026-11-25 — initialized: branch docs/177-close-163-166-168-leftovers off main at d0977374fef597e371ebfb2e27ad2dddbf67b238 · cost: 1m · sonnet-5-5 17k in + 533k cached / 2k out
