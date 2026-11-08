# Issue #39 — qc

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/39 |
| Branch | `fix/fix-board-sh-set-logical` |
| Updated | 2026-11-08 |

## Where this stands

Round 1 is written and clear: no blocking finding. Seven non-blocking findings are recorded below; none sends the change back. Routed to `/codeo:close`.

## Questions

None.

## Outcome

### Round 1 — 2026-11-08

**Under review.** `origin/main...HEAD` on `fix/fix-board-sh-set-logical`: 14 files, 563 insertions, 87 deletions (the code, tests and docs of the plan `docs/plans/2026-11-08-board-keys-and-footprint-union.md`, plus the dossiers). No shared environment is configured, so there is no `#### Environment` block.

**Commands run and their output**
- `bash scripts/sync-main.sh --abort-on-conflict` → `sync-main: the branch already contains origin/main` (exit 0). Nothing to re-check.
- `bash scripts/overlap.sh 39` → no output (exit 0); `bash scripts/inflight.sh --except 39` earlier showed no other workflow in flight.
- `bash scripts/scope.sh origin/main HEAD` →
  ```
  scope: suite shell needed for unclassified paths:
    .codeo/39/implement.md
    .codeo/39/init.md
    .codeo/39/issue.md
    .codeo/39/plan.md
    CHANGELOG.md
  suite.shell=true
  ```
  (Exit 0. `CHANGELOG.md` and `.codeo/**` fall under no suite's `paths`, so scope runs the suite for them; unchanged configuration, not a finding.)
- Build: the `shell` suite's build command is `true` → exit 0.
- Suite: `bash tests/run.sh` → `all cases passed`, exit 0.
- `bash scripts/overlap.sh --outside 39` → no output: nothing the branch changed lies outside its footprint.
- Overlays `qc/invariants-extra` and `qc/wiki-rules` → both exit 3: none. No invariants file and no wiki module are configured.
- `shellcheck scripts/board.sh | grep -c '^In '` → `6`; the same command on `scripts/board.sh` at the base commit `245d10e` → `6`. No new finding.
- `jq` on a config with `board.statuses` absent and on one with `statuses: {}` → `null` for both, so `codeo_cfg` returns 1 either way and the new defaults apply in both.

**Criteria**

| Criterion | Verdict | Settled by |
|---|---|---|
| With `board.statuses` unset, the call triage makes to mark Ready moves the card to the project's Ready option. | met | `tests/board.test.sh` "ready without statuses" (config `statuses: {}`; asserts `Backlog → Ready on #2` and `--single-select-option-id O_READY`); `scripts/board.sh` `default_status`, resolution order configured → default → pass-through |
| The same for Backlog. | met | `tests/board.test.sh` "backlog without statuses" (asserts `Ready → Backlog on #2`, `O_BACKLOG`) |
| A `set` that fails leaves the card's prior state (or absence) unchanged. | met — per card; the removal is best effort and can itself fail, which is reported (F5); it is not atomic across projects, by the script's documented design | `tests/board.test.sh` `no-option-no-add` (no `item-add` when no project has the option), `undo-fresh-add`, `keep-existing-card`, `undo-fails` |
| After a two-round plan, `overlap.sh --outside <N>` prints only files really outside the branch's changes. | met — by the rule and check in `skills/plan/SKILL.md:305-308`, the option accepted at plan Q3; nothing mechanical enforces it (F1) | `tests/overlap.test.sh` `replaced-block`, `union-block`, `both-blocks`; `tests/plan-skill.test.sh` pins |
| Tests cover each of the above. | met — as designed at plan Q3; for the fourth the tests are wording pins plus cases that pin `overlap.sh`'s existing behaviour and pass on the base revision (F1) | `tests/board.test.sh`, `tests/overlap.test.sh`, `tests/plan-skill.test.sh` |

**Documentation check.** The plan names `docs/handoff.md`, `docs/dossier.md`, `skills/init/SKILL.md` and `CHANGELOG.md`; all four are changed and the first three read in the present tense with no issue number. `docs/skills.md` lines 57, 181 and 214 make no claim the change contradicts. Findings F2, F6 and F8 are the pages that say something imprecise or that the change leaves behind.

**Independent review.** One `QC review:` pass on the configured reviewer model, given the acceptance criteria and the diff only. Its assessment was "with fixes"; the corrections it asked for are F1-F4, F6 and F7 below, none of which changes what the code does for the three board criteria. Quoted in plain text: it found the board changes correct and well tested, and it did not find a defect in the code paths the criteria name.

**Findings** — all `non-blocking`; every one is within the diff.
- **F1 — non-blocking, plan's.** Criterion 4 rests on a skill instruction, not on code: `overlap.sh`, `inflight.sh` and `dossier-check.sh` are unchanged, the three new `tests/overlap.test.sh` cases pass against the base revision, and the `tests/plan-skill.test.sh` cases grep the sentence. A planning pass that skips the instruction reproduces the #36 result, and nothing fails until qc reports the files as a non-blocking finding (`skills/qc/SKILL.md` step 6). This is the shape the engineer chose at plan Q3 ("the rule, with a check"; the scripts-union option was rejected), so it is not a defect against the plan. A mechanical check, for instance in `dossier-check.sh`, is a candidate for `/codeo:triage`.
- **F2 — non-blocking, implementer's.** `CHANGELOG.md:11` says `set` "removes a card whose write failed" (the code removes only a card it added) and states as a fact that the new block means `overlap.sh --outside` "finds nothing the new block omits" (that holds only if the plan step is followed, F1). Two wording fixes.
- **F3 — non-blocking, plan's.** `skills/plan/SKILL.md:305-308` puts the new check inside sub-step 4, which runs after the outcome is written and the footprint has left `## Notes`, then says to "raise what it prints as at sub-step 2", which stops with `## Outcome` still pending and amends the footprint in `## Notes`. If the re-run printed anything, the instructions contradict each other. Rarely reachable: sub-step 1 already compared the branch's changes with other workflows. The sentence is the plan's Task 3 text.
- **F4 — non-blocking, implementer's.** `scripts/board.sh:282` (and the header, line 30): when the issue is on no board and no synced project offers the option, the message reads `no project #N is on has the option …`, which is wrong because the issue is on none; before the change the card had been added first, so it was true.
- **F5 — non-blocking, implementer's.** `scripts/board.sh:214-216` reports a failed title read as `could not add #N to project #P`, though nothing was being added; `:270` discards the delete's stderr, so the hand-removal line gives no reason; the comment at `:268-269` ("so the board is as it was") overstates a best-effort removal.
- **F6 — non-blocking, plan's.** Pages the plan did not name still describe the keys or the add without the new behaviour: `lib/env.sh:29-31` ("a name that is not a key passes through", with no mention of the defaults), `skills/triage/SKILL.md:220` ("adds the issue to the board if it is not on it").
- **F7 — non-blocking, plan's.** No `tests/board.test.sh` case has `board.statuses` absent altogether; every config carries `statuses`. The code path is the same (both give `null`, checked above), but the criterion says "unset".
- **F8 — non-blocking, implementer's.** `docs/handoff.md` says the replacing footprint block "carries the earlier round's files too", broader than the skill's "still changes"; `docs/dossier.md` does not say the check runs after the earlier block is replaced.

Blocking findings: none. Issues filed for this pass: none.

**Verdict: clear — forward to `/codeo:close`.**

## Log

- 2026-11-08 — qc round 1: clear, 8 non-blocking findings · cost: 5m · opus-5-5 393k in + 2.4M cached / 15k out · sonnet-5-5 35k in + 648k cached / 7k out
