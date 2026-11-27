# Issue #188 — plan

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/188 |
| Branch | `docs/188-close-177-qc-leftovers-utc` |
| Updated | 2026-11-27 |

## Where this stands

Round 3 is planned: Tasks 10-11 are approved and appended to the plan file. Next: `/codeo:implement`.

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

### Q5 — #195: proceed and coordinate on `glob:CHANGELOG.md`, `glob:skills/close/**` and `glob:tests/**`?

**Why it matters:** `overlap.sh 188` prints those three for #195 (branch `feat/195-identify-acting-user-strictly-verify`, assignee kbajpai, step plan). Q2 raised the same overlap in prose and was answered *proceed and coordinate*; this restates it with the printed tokens so the record and the script agree. If the answer stays *proceed and coordinate*, nothing in the plan changes; *sequence after #195* or *re-scope* would.

**Options:** proceed and coordinate (recommended, as answered at Q2) · sequence after #195 · re-scope.

**Answer:**
Proceed and coordinate. (The engineer's reply in the conversation, 2026-11-27: "proceed and coordinate".)

### Q6 — #204: proceed and coordinate on `glob:CHANGELOG.md`, `glob:skills/close/SKILL.md` and `glob:tests/**`?

**Why it matters:** `overlap.sh 188` prints those three for #204 (branch `chore/204-fix-codeo-close-opens-pr`, assignee kbajpai, step init). Q3 raised the same overlap in prose and was answered *proceed and coordinate*; this restates it with the printed tokens so the record and the script agree. If the answer stays *proceed and coordinate*, nothing in the plan changes; *sequence after #204* or *re-scope* would.

**Options:** proceed and coordinate (recommended, as answered at Q3) · sequence after #204 · re-scope.

**Answer:**
Proceed and coordinate. (The engineer's reply in the conversation, 2026-11-27: "proceed and coordinate".)

### Q7 — #206: proceed and coordinate on `glob:CHANGELOG.md`, `glob:skills/cleanup/SKILL.md` and `glob:tests/cleanup-skill.test.sh`?

**Why it matters:** `overlap.sh 188` prints those three for #206 (branch `fix/206-codeo-cleanup-prints-codeo-rm`, assignee kbajpai, step init). Q4 raised the same overlap in prose and was answered *proceed and coordinate*; this restates it with the printed tokens so the record and the script agree. If the answer stays *proceed and coordinate*, nothing in the plan changes; *sequence after #206* or *re-scope* would.

**Options:** proceed and coordinate (recommended, as answered at Q4) · sequence after #206 · re-scope.

**Answer:**
Proceed and coordinate. (The engineer's reply in the conversation, 2026-11-27: "proceed and coordinate".)

### Q8 — Round 2: which of QC round 1's non-blocking findings are fixed with F1?

**Why it matters:** QC round 1 sent the plan back for F1 (`docs/home-checkout.md:9` says `gh` still runs without `jq`; it does not). F2-F5 are non-blocking. Each one folded in adds a task step and widens the diff; F4 (pins for the docs sentences) would add `tests/readme.test.sh` to the footprint. Left out, a finding stays in `qc.md` for `/codeo:triage`.
**Options:** F2 + F3 wording (recommended) · F5 changelog suffix and pin scope (recommended) · F4 pins for the docs sentences · none, F1 only.

**Answer:**
F2 + F3 wording, and F5 changelog suffix and pin scope. Not F4. (The engineer, through the question tool, 2026-11-27.)

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

## Outcome

2026-11-27

**Plan:** `docs/plans/2026-11-27-close-177-qc-leftovers-188.md`, approved by the engineer, left unstaged for them to commit. Shape: an executable plan under `docs/plans/`, six tasks, one commit each; no reference doc under `docs/`, since nothing here is a standing decision.

**Decisions**
- Wording only, one pull request. No script is edited; the `note:` text the scripts print stays.
- F4's "nothing is asked without a tracker" goes into `docs/home-checkout.md` only (Q1). The overlays gain `CODEO_TRACK` and nothing about asking, because `codeo-sandbox.sh end` never asks. Rejected: adding the clause to all three lines.
- Overlaps with #195, #204 and #206 are accepted: proceed and coordinate (Q2-Q7). Rejected: sequencing after any of them, and dropping F3, F5 or F6 from this pull request.
- Found while planning, resolved in the plan and not a question: `docs/home-checkout.md` states no tracker condition at `:66` (the F4 citation), so Task 4 adds one at `:132`; `CHANGELOG.md:30` is `:40`; both overlays have `templates/containers/` copies that `tests/containers.test.sh` keeps identical, so they change with them.
- Each task is proved by `bash tests/run.sh` ending `all cases passed`; the `shell` suite has no single-test filter. No shared environment, so no task takes a lease. No invariants document is configured.

**Documentation the plan changes:** `docs/release-checklist.md`, `docs/home-checkout.md`, `skills/close/SKILL.md`, `skills/cleanup/SKILL.md`, `.codeo/overlays/{cleanup,close}.md` and their templates, `CHANGELOG.md`. No other page describes the five corrected sentences. No diagram changes.

**Intake questions resolved:** none; `init.md` left none open.


### Round 2

2026-11-27
(send-back from qc.md round 1)

**Plan:** `docs/plans/2026-11-27-close-177-qc-leftovers-188.md` gains `## Round 2` with Tasks 7-9, approved by the engineer and left unstaged for them to commit. Tasks 1-6 stay as written.

**Why:** QC's F1 (blocking): the F5 sentence at `docs/home-checkout.md:9` says `gh` still runs without `jq`, and it does not. `assignee_label` calls `scripts/github.sh`, which reads `.repo.owner` through `jq empty` (`scripts/github.sh:27`, `lib/env.sh:86`) and stops before any `gh` call; reproduced with a `PATH` holding no `jq` and a logging `gh` stub. The premise came from the issue and #177's QC round 2, and the plan inherited it.

**Decisions**
- Fix F1 by keeping "getting nothing from the assignee lookup" and saying `github.sh` stops on its config read before `gh` (Task 7).
- Fold in QC's non-blocking F2 ("when that file is missing"), F3 ("a validly named branch") and F5 (`(#188)` on the changelog bullet, and the cleanup pin read from step 4 only) (Tasks 7-9). Rejected: F4, pins for the three docs sentences, which would add `tests/readme.test.sh` to the footprint; it stays in `qc.md` for `/codeo:triage` (Q8).
- No script changes, no new file; the footprint is the one round 1 had, so no new overlap with #195, #204 or #206 (`overlap.sh 188` prints nothing).

**Documentation the round changes:** `docs/home-checkout.md`, `skills/cleanup/SKILL.md`, `CHANGELOG.md`.

**Intake questions resolved:** none.

### Round 3

2026-11-27
(send-back from qc.md round 3)

**Plan:** `docs/plans/2026-11-27-close-177-qc-leftovers-188.md` gains `## Round 3` with Tasks 10-11, approved by the engineer and committed with the plan file. Tasks 1-9 stand as written.

**Why:** QC round 3's F8 (blocking): `docs/home-checkout.md:9` says `live.sh`, without `jq`, gets "nothing from the assignee lookup", but that lookup runs only in a hosted web session (`scripts/live.sh:161`, `host == web`), and the paragraph is about running on the host. The plan inherited the gap from the issue's F5, whose own "it matters only for a web session" never reached the page. No question was needed: the fix follows from what `live.sh` does, observed by running `user_label` from `scripts/live.sh` with `jq` off `PATH` and a logging `gh` stub (`host=container` gave the `git config user.name` value, `host=web` gave `unknown`, `gh` was called 0 times, and `github.sh user login` exited 1 on `config.json: invalid JSON`).

**Decisions**
- Task 10 rewrites the end of the `home-checkout.md:9` bullet to say the signal's user comes from `git config user.name`, that `github.sh` stops at its `jq` config read before `gh`, and that only a hosted web session asks for the assignee, where without `jq` the label reads `unknown`. The text before it, which `tests/readme.test.sh:340` pins, stays.
- Task 11 folds in QC's non-blocking F9: the cleanup overlay and its template join their two back-to-back parentheticals with "; otherwise". The existing pins still match. Rejected: F4 (pins for the docs sentences, by the engineer's answer at Q8), F6 and F7 (the cleanup parenthesis not naming the name rule; step 17's "prefix" wording), which stay in `qc.md` for `/codeo:triage`.
- No script changes, no new file; the footprint is unchanged, so `overlap.sh 188` prints nothing and `overlap.sh --outside 188` prints nothing.

**Documentation the round changes:** `docs/home-checkout.md`, `.codeo/overlays/cleanup.md` and `templates/containers/.codeo/overlays/cleanup.md`.

**Intake questions resolved:** none.

### Footprint

```
files:      docs/release-checklist.md, CHANGELOG.md, skills/close/SKILL.md, skills/cleanup/SKILL.md, docs/home-checkout.md, .codeo/overlays/cleanup.md, .codeo/overlays/close.md, templates/containers/.codeo/overlays/cleanup.md, templates/containers/.codeo/overlays/close.md, tests/close-skill.test.sh, tests/cleanup-skill.test.sh, tests/close-removal.test.sh, docs/plans/2026-11-27-close-177-qc-leftovers-188.md
wiki:       none
exclusive:  none
sequenced:  none
```

## Log

- 2026-11-27 — Q1-Q4 raised · cost: 1m · fable-5-2 71k in + 555k cached / 5k out
- 2026-11-27 — Q1-Q4 answered by the engineer in conversation ("Go with your picks": the recommended option for each); plan drafted at .codeo/188/plan-draft.md, awaiting review · cost: unavailable, an answer turn with no separate usage
- 2026-11-27 — plan approved and written; footprint committed; Q5-Q7 raised (overlap.sh tokens for #195, #204, #206) · cost: unavailable, the hand-off line carries the total
- 2026-11-27 — Q5-Q7 answered (proceed and coordinate); planned: docs/plans/2026-11-27-close-177-qc-leftovers-188.md · cost: 15m · fable-5-2 78k in + 848k cached / 10k out · sonnet-5-5 108k in + 2M cached / 20k out
- 2026-11-27 — round 2 opened (send-back from qc.md round 1); Q8 raised and answered through the question tool; round-2 tasks drafted at .codeo/188/plan-draft.md, awaiting review · cost: unavailable, the hand-off line carries the total
- 2026-11-27 — round 2 approved; planned: docs/plans/2026-11-27-close-177-qc-leftovers-188.md (Tasks 7-9) · cost: 33m · fable-5-2 218k in + 995k cached / 7k out · sonnet-5-5 24k in + 955k cached / 2k out
- 2026-11-27 — round 3 opened (send-back from qc.md round 3); no question raised; Tasks 10-11 drafted at .codeo/188/plan-draft.md, awaiting review · cost: unavailable, the hand-off line carries the total
- 2026-11-27 — round 3 approved; planned: docs/plans/2026-11-27-close-177-qc-leftovers-188.md (Tasks 10-11) · cost: 5m · fable-5-2 406k in + 1.7M cached / 7k out · sonnet-5-5 19k in + 407k cached / 1k out
