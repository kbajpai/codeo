# Issue #188 — plan

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/188 |
| Branch | `docs/188-close-177-qc-leftovers-utc` |
| Updated | 2026-11-27 |

## Where this stands

Q1-Q4 are answered. The plan is drafted at `.codeo/188/plan-draft.md` and waits for the engineer to approve it, ask for changes or reject it.

## Questions

### Q1 — Does "say nothing is asked without a tracker" apply to all three F4 lines, or to `docs/home-checkout.md` only?

**Why it matters:** the acceptance criterion reads "the three tracker-condition lines (F4) name
`CODEO_TRACK` as well as `codeo-track.sh`, and say nothing is asked without a tracker". The two overlay
lines (`.codeo/overlays/cleanup.md:12`, `.codeo/overlays/close.md:11`) are about `codeo-sandbox.sh end`,
which marks a row and never asks anything, tracker or not; only `issue` asks (`track_confirm`,
`.sbx/codeo-sandbox.sh:43-45`). Finding F4 itself puts the "nothing is asked" gap in `home-checkout.md`
alone. With *home-checkout only*, the overlays gain `CODEO_TRACK` and nothing else, and the pull request
says the criterion's second half was applied where it is true. With *all three*, each overlay sentence
also gains a clause about `issue` asking nothing, in a sentence about `end`.

Two things found while reading, which hold either way: `docs/home-checkout.md` has no "sits beside" text
(the cited `:66` is the `## The tracking comment` section, now `:127` and `:132`, which state no tracker
condition at all), so that file gains the condition rather than having it corrected; and both overlays
have a copy under `templates/containers/.codeo/overlays/` that `tests/containers.test.sh`
(`codeos_own_overlays_equal_the_render`) keeps identical, so the templates change with them.

**Options:** home-checkout only (recommended) · all three · no preference, you pick.

**Answer:**
Home-checkout only. (The engineer's reply in the conversation, 2026-11-27: "Go with your picks", taking the recommended option.)

### Q2 — #195 overlaps on `skills/close/**`, `CHANGELOG.md` and `tests/**`: how to proceed?

**Why it matters:** #195 (branch `feat/195-identify-acting-user-strictly-verify`, assignee kbajpai, at
step plan, waiting for `/codeo:implement`) lists `skills/close/**`, `CHANGELOG.md` and `tests/**` in its
footprint. This plan edits `skills/close/SKILL.md` (step 17's live-signal paragraph, F3), its pin in
`tests/close-skill.test.sh:232`, and `CHANGELOG.md` (one comma at `:40`, one new line under
`## Unreleased`). #195 also lists `scripts/live.sh`; this plan does not edit it, but F5 describes its
`assignee_label`, so if #195 changes that function the F5 sentence is re-read at whichever merges second.
*Proceed and coordinate* drafts as is and the second to merge rebases over one-sentence edits.
*Sequence after #195* holds this plan's hand-off until #195 merges. *Re-scope* drops F3 and F5 from this
pull request, named as dismissed.

**Options:** proceed and coordinate (recommended: the edits are single sentences in a paragraph #195's
subject does not reach) · sequence after #195 · re-scope.

**Answer:**
Proceed and coordinate. (The engineer's reply in the conversation, 2026-11-27: "Go with your picks", taking the recommended option.)

### Q3 — #204 overlaps on `skills/close/SKILL.md`, `CHANGELOG.md` and `tests/**`: how to proceed?

**Why it matters:** #204 (branch `chore/204-fix-codeo-close-opens-pr`, assignee kbajpai, at step init,
waiting for `/codeo:plan`) lists `skills/close/SKILL.md`, `CHANGELOG.md` and `tests/**`. It reorders when
`/codeo:close` archives and opens the pull request; this plan rewords two clauses in step 17's hosted-web
paragraph of the same file and the pin at `tests/close-skill.test.sh:232`. If #204 renumbers the steps,
that pin's step number (`17`) moves, and the second to merge carries the other's change. *Proceed and
coordinate* accepts that rebase. *Sequence after #204* waits for a workflow that has no plan yet.
*Re-scope* drops F3, named as dismissed.

**Options:** proceed and coordinate (recommended) · sequence after #204 · re-scope.

**Answer:**
Proceed and coordinate. (The engineer's reply in the conversation, 2026-11-27: "Go with your picks", taking the recommended option.)

### Q4 — #206 overlaps on `skills/cleanup/SKILL.md`, `CHANGELOG.md` and `tests/cleanup-skill.test.sh`: how to proceed?

**Why it matters:** #206 (branch `fix/206-codeo-cleanup-prints-codeo-rm`, assignee kbajpai, at step init,
waiting on the engineer for its `issue.md` Q1) lists `scripts/cleanup.sh`, `skills/cleanup/SKILL.md`,
`CHANGELOG.md` and `tests/cleanup-skill.test.sh`. This plan corrects one parenthesis in
`skills/cleanup/SKILL.md:84` (F6) to match what `scripts/cleanup.sh` does today, and changes the
`'when codeo-track.sh sits beside'` pin at `tests/cleanup-skill.test.sh:111` (F4). #206 changes what
`cleanup.sh` prints, so it may rewrite the very sentence F6 corrects. *Proceed and coordinate* fixes the
sentence now and #206 re-reads it against its own change. *Sequence after #206* waits for a workflow that
has no plan yet. *Re-scope* drops F6's `SKILL.md` half and leaves it to #206, named as dismissed here;
the comma in `CHANGELOG.md` stays.

**Options:** proceed and coordinate (recommended) · sequence after #206 · re-scope.

**Answer:**
Proceed and coordinate. (The engineer's reply in the conversation, 2026-11-27: "Go with your picks", taking the recommended option.)

## Notes

- Shape, unless an answer changes it: one plan under `docs/plans/`, one pull request, wording only. No
  script changes; the `note:` text in `.sbx/codeo-sandbox.sh` and `.devcontainer/codeo-container.sh`
  ("codeo-track.sh is not beside this script") is script output and stays as it is.
- Pins that move with the wording: `tests/close-skill.test.sh:232` (`per branch it printed`),
  `tests/cleanup-skill.test.sh:111` and `tests/close-removal.test.sh:32`
  (`when codeo-track.sh sits beside`).
- The stray comma the issue cites at `CHANGELOG.md:30` is now at `:40`, in the released `v1.0.9` section.
  Earlier leftover rounds (#177, #179) each added one line to the changelog; this one adds one under
  `## Unreleased`.
- No invariants document is configured and no shared environment, so there is no invariant check and no
  lease task.

### Footprint

```
files:      docs/release-checklist.md, CHANGELOG.md, skills/close/SKILL.md, skills/cleanup/SKILL.md, docs/home-checkout.md, .codeo/overlays/cleanup.md, .codeo/overlays/close.md, templates/containers/.codeo/overlays/cleanup.md, templates/containers/.codeo/overlays/close.md, tests/close-skill.test.sh, tests/cleanup-skill.test.sh, tests/close-removal.test.sh, docs/plans/2026-11-27-close-177-qc-leftovers-188.md
wiki:       none
exclusive:  none
sequenced:  none
```

## Outcome

_Pending — written at the hand-off._

## Log

- 2026-11-27 — Q1-Q4 raised · cost: 1m · fable-5-2 71k in + 555k cached / 5k out
- 2026-11-27 — Q1-Q4 answered by the engineer in conversation ("Go with your picks": the recommended option for each); plan drafted at .codeo/188/plan-draft.md, awaiting review
