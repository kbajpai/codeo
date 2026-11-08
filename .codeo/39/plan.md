# Issue #39 — plan

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/39 |
| Branch | `fix/fix-board-sh-set-logical` |
| Updated | 2026-11-08 |

## Where this stands

Round 1. Q1-Q3 are answered (all recommendations accepted). The plan is drafted at `.codeo/39/plan-draft.md` and awaits the engineer's review; the plan file under `docs/plans/` is written only after approval. One detail moved from Q3's wording: the `--outside` check runs after the earlier footprint block is replaced (sub-step 4), because `overlap.sh` reads every block.

What the code does today, as far as the two defects go:

- `scripts/board.sh:122-125` maps `set`'s third argument to an option name only when `board.statuses.<arg>` is configured; `codeo_cfg` returns 1 for an absent key, so `ready` passes through as a literal option name. `init` and `close` sidestep this by deriving the names themselves (`config.sh get '.board.statuses.ready // "Ready"'`) and passing the name; `triage` is the only skill that passes a key (`skills/triage/SKILL.md:25-26`).
- `scripts/board.sh:180-205` adds the issue to every synced project it is missing from *before* `:218-244` reads each project's Status options and finds, or does not find, the option. So on a project without the option the add has already happened when the write is skipped, and the card is left with Status unset. The same order leaves a fresh card behind when the field lookup (`:222`) or the write (`:248-250`) fails.
- The "replace" rule for a re-planned footprint is text, in three places that say the same thing: `skills/plan/SKILL.md` step 10 sub-step 4 ("The new `### Footprint` replaces the earlier round's"), `docs/dossier.md → What a finished dossier looks like`, and `docs/handoff.md → A send-back`. `tests/plan-skill.test.sh` pins that wording. `overlap.sh` and `inflight.sh` read every `### Footprint` block in the file, and `dossier-check.sh` reports a second block as `footprint-single` drift — which is why the rule removes the old block rather than leaving two. `overlap.sh --outside <N>` already prints exactly the paths a footprint misses; nothing runs it before the footprint is committed.

## Questions

### Q1 — Where does the fix for `set <N> ready` live: the script, the skill that calls it, or both?

**Why it matters:** this decides whether every caller of `board.sh set` may pass a logical key, or only an option name. Today `init` and `close` pass names they derive from the config, and `triage` passes keys the script may not accept.

**Options:**
- *The script defaults the keys (my recommendation):* `board.sh set` resolves the five keys `docs/handoff.md`'s board table already names — `ready`, `backlog`, `inProgress`, `inReview`, `done` — to the conventional option names (`Ready`, `Backlog`, `In progress`, `In review`, `Done`) when `board.statuses` leaves them out; a configured entry still wins, and any other string still passes through as an option name. One place owns the mapping, as the script's own header says is the point of it; `triage`'s call works unchanged, and `init`/`close` keep working since they pass names. A project whose board spells an option in lowercase (`ready`) would configure `board.statuses.ready: "ready"` — a corner worth one line in the docs, no more. Touches `scripts/board.sh`, `tests/board.test.sh`, `docs/handoff.md:119-123`.
- *The skill stops passing keys:* `skills/triage/SKILL.md` derives `$READY` and `$BACKLOG` the way `init` and `close` do and passes the names; the script is unchanged. Smaller diff, but the script keeps accepting a key it then treats as a name, and the next skill to pass one hits the same wall.
- *Both:* the script defaults the keys and triage passes names anyway. Belt and braces; the second half is then dead weight.

**Answer:**
Accepted the recommendation (the engineer, in the conversation: "I accept all your recommendations"): the script defaults the five keys; a configured `board.statuses` entry still wins.

### Q2 — How does a failed `set` leave the card as it was: by checking before it adds, by undoing a fresh add, or both?

**Why it matters:** acceptance criterion 3 says a failed `set` leaves the card's prior state or absence unchanged, without qualifying which failure. The observed failure is the no-option case; two rarer ones (the field lookup fails, the write fails) leave a fresh card behind by the same order of operations.

**Options:**
- *Check before adding, and undo a fresh add whose write fails (my recommendation):* `set` reads each synced project's Status options first; a project without the option, or whose lookup fails, is reported and skipped before any add, so the observed failure makes no card. Then it adds where it is about to write, and when the write on a project it just added to fails, it deletes that item again (`gh project item-delete <project> --owner <owner> --id <item>`), best effort — a delete that fails is one more stderr line naming the item. The exit status and the per-project stderr lines are as today. Meets the criterion as written; costs one more `gh` verb in the stub and two more test cases.
- *Check before adding only:* the same reorder, no delete. Fixes every failure the lookup can see and keeps the script free of compensating calls, but a write that fails after a successful add still leaves a card with Status unset — the criterion would be met for the reported case and not in general.
- *Undo only:* keep today's order and delete the fresh card whenever its write is skipped or fails. Every no-option `set` then makes two `gh` writes to end where it started; checking first is cheaper and clearer.

**Answer:**
Accepted the recommendation (same words): check each project's options before adding, and delete a fresh add whose write fails.

### Q3 — What makes a re-planned footprint the union: the planning rule with a mechanical check, or the scripts reading every round's block?

**Why it matters:** this decides whether the fix is to how `/codeo:plan` writes the block (text in the skill and the two protocol docs, pinned by `tests/plan-skill.test.sh`) or to what `overlap.sh` and `inflight.sh` read, and whether a later round may ever *drop* a file from the footprint.

**Options:**
- *The rule, with a check (my recommendation):* a round after a send-back still writes one block, and that block covers the branch — the round's own files plus every file an earlier round named that the branch still changes. The skill proves it the way `qc` found the defect: at step 10 sub-step 1, after the draft block is under `## Notes`, it runs `overlap.sh --outside <N>`, and every path it prints goes into `files:` before the block is committed (round 1 prints nothing there — the branch has changed only dossiers — so round 1 is unaffected). `overlap.sh`, `inflight.sh` and `dossier-check.sh` are unchanged; the one-block rule and the `footprint-single` check stand. Changes `skills/plan/SKILL.md` step 10, `docs/dossier.md`, `docs/handoff.md`, the pins in `tests/plan-skill.test.sh`, and adds an `overlap.test.sh` case: a two-round `plan.md` whose round-2 block is the union makes `--outside` print only what is really outside, and one whose block replaced round 1's makes it print round 1's files — the defect, pinned.
- *The scripts union every block:* `overlap.sh` and `inflight.sh` read all `### Footprint` blocks in the file and the rounds each keep their own. No skill text changes, but it reverses the reason the replace rule exists: a re-scoped round could never drop a file, `dossier-check.sh`'s `footprint-single` check would have to go, and a stale block would go on producing overlaps — the very thing the rule was written to stop.
- *The rule alone, no check:* say "union" in the skill and the docs and trust the planner. Cheapest, and exactly what the replace rule relied on; the check is what makes this a fix rather than a rewording.

**Answer:**
Accepted the recommendation (same words): one block that covers the branch, checked with `overlap.sh --outside <N>` at step 10 sub-step 1; the scripts are unchanged.

## Notes

Calls I am making unless you say otherwise:

- **One plan, one pull request**, two task groups (the board fix, the footprint rule), as the issue's own Q1 decided.
- **`init` and `close` keep deriving the option names** from the config and passing them. Whichever way Q1 goes, that still works; switching them to keys is a simplification the issue's *Out of Scope* keeps out of this change.
- **`CHANGELOG.md`** gets an `Unreleased` bullet, as the last two plans did. `scripts/board.sh`'s header comment and `docs/handoff.md`'s board paragraph say what `set` accepts; `docs/dossier.md` and `docs/handoff.md` say what a re-planned footprint carries. No other page under `docs/` describes either.
- **Tests** follow the two files that already exist: new cases in `tests/board.test.sh` against its `gh` stub (a logical key with `statuses: {}`, a configured key winning, the no-option `set` making no add, the failed write undoing a fresh add), new cases in `tests/overlap.test.sh` (Q3), and new `must_contain` pins in `tests/plan-skill.test.sh` for the reworded step 10.
- **The installed plugin is v1.0.3**, so this workflow's own later steps run the old rule; the fix reaches the pipeline at the next release.

## Outcome

_Pending — written at the hand-off._

## Log

- 2026-11-08 — Q1-Q3 raised · cost: 4m · fable-5-1 101k in + 806k cached / 14k out
- 2026-11-08 — Q1-Q3 answered; plan drafted at .codeo/39/plan-draft.md, awaiting review · cost: 11m · fable-5-1 109k in + 1.2M cached / 16k out · sonnet-5-5 176k in + 777k cached / 17k out
