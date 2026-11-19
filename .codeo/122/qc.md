# Issue #122 — qc

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/122 |
| Branch | `feat/triage-s-flight-judging-103` |
| Updated | 2026-11-19 |

## Where this stands

Round 1 is written: clear, forward to `/codeo:close`. The build and the full `shell` suite pass, every acceptance criterion is met, and the independent review (opus) found no Critical or Important finding. Five non-blocking findings are recorded.

## Questions

None.

## Notes

No shared environment is configured, no invariants file, no wiki module and no overlay rules, so none of those checks apply.

## Outcome

### Round 1 — 2026-11-19

**Start of the round.** `bash scripts/sync-main.sh --abort-on-conflict`: `sync-main: the branch already contains origin/main` (no `also changed on main:` lines). `bash scripts/overlap.sh 122`: nothing printed (the overlaps with #102 and #108 are already raised and answered in `plan.md` Q4-Q5 and `implement.md` Q1-Q3). `bash scripts/overlap.sh --outside 122`: nothing printed, so no path outside the plan's footprint.

**Diff.** `git diff origin/main...HEAD --stat`: 12 files changed, 585 insertions, 27 deletions — `scripts/inflight.sh`, `skills/triage/SKILL.md`, `tests/inflight.test.sh`, `tests/triage-skill.test.sh`, `docs/handoff.md`, `docs/skills.md`, `CHANGELOG.md`, the plan, and the dossiers.

**Scope.** `bash scripts/scope.sh origin/main HEAD`:

```
scope: suite shell needed for unclassified paths:
  .codeo/122/implement.md
  .codeo/122/init.md
  .codeo/122/issue.md
  .codeo/122/plan.md
  CHANGELOG.md
suite.shell=true
```

**Build.** `shell` suite, `true`: exit 0.

**Suite.** `bash tests/run.sh` (the `shell` suite, whole; it has no `filter`), real time 5m1s: `all cases passed`, exit 0.

**Acceptance criteria**

| Criterion | Verdict | Settled by |
|---|---|---|
| Dismissing an unassigned workflow's question, then pushing to its branch, does not raise it again (or the stated limit is in the docs) | met | `skills/triage/SKILL.md` step 1.2 gives it the dateless fingerprint `unassigned:<N>` (`a dismissal of it holds across pushes`), pinned by four checks in `tests/triage-skill.test.sh`; `docs/skills.md:224` says the same. It is wording the model follows, so the proof is the pinned text, not a run. |
| With a live abandon at Ready, triage raises no `board:<N>:Ready` question that proposes `board.sh set <N> backlog` | met | the table row at `skills/triage/SKILL.md:137` expects Backlog or Ready for a live abandon, plus the sentence `Ready is not a mismatch for a live abandon`; both pinned in `tests/triage-skill.test.sh`. |
| `inflight.sh` on a resumed stash still in planning prints `/codeo:plan` as what it waits on | met | `scripts/inflight.sh:285` and `tests/inflight.test.sh` case `waits_after_a_resumed_stash_in_planning`; the reviewer removed that line in a scratch worktree and 3 of the 4 new cases failed. |
| *Resume*'s wording covers each `waits:` value that carries no step | met | `skills/triage/SKILL.md:310-317` names a step, `engineer — …`, `review — dossier archived` and `nothing known`; three checks in `tests/triage-skill.test.sh` (see F1 for one wording gap). |
| `docs/handoff.md` lists `nothing known`; `docs/skills.md:224` describes the `/codeo:close` case | met | `docs/handoff.md:157` and `docs/skills.md:224`. |

**Documentation.** The plan named `docs/handoff.md`, `docs/skills.md` and `CHANGELOG.md`; all three are in the diff and describe the shipped behaviour in the present tense with no issue numbers (the changelog is where issue numbers belong). No diagram moves. No page covers a behaviour the diff changes that the plan did not name. Two statements are slightly off: F1 and F2.

**Independent review.** Opus reviewer, given only the acceptance criteria and the diff. It said: ready to merge, no Critical or Important issue; `bash tests/inflight.test.sh` and `bash tests/triage-skill.test.sh` pass at HEAD; `--tsv` and `--branches` output does not change.

**Findings** (all scoped to this diff; none blocks the merge):

- F1 — non-blocking, `/codeo:plan`'s. `skills/triage/SKILL.md:316` and `docs/handoff.md:155` say `review — dossier archived` names "the pull request awaiting review". `inflight.sh` prints that for any archived dossier not yet on the base branch, including one with no pull request or one closed unmerged, which the board table (`SKILL.md:138`) treats as a case for `/codeo:close`. The plan's wording said "the pull request to review". Cause: the plan did not separate the two archived cases.
- F2 — non-blocking, `/codeo:implement`'s. `CHANGELOG.md:15` says inflight prints "the step before the park". It prints the step after the last finished step before the park (`/codeo:implement` when plan finished, case 63).
- F3 — non-blocking, `/codeo:plan`'s. `touched_of` (F22, `scripts/inflight.sh:99-115`) has no test. The plan chose this on purpose: git's `%cs` always parses, so the branch cannot be reached.
- F4 — non-blocking, `/codeo:plan`'s. `scripts/inflight.sh:285` steps past any `close` outcome no earlier rule took, not only a spent stash or abandon. A live stash whose `claim.sh --stash-live` check fails now prints a step where it printed `nothing known`. This follows the "any failure falls to the next" rule in `waits_of`, and the comment says "a `close` outcome that no rule above took".
- F5 — non-blocking, `/codeo:plan`'s. A *resume* answer on an `unassigned:<N>` item is not among the decisions that stop an item coming back, and the fingerprint has no date, so the workflow is asked about every run until someone is assigned. Arguably intended; the skill does not say so.
- Minors the implementers' reviews recorded and the final review confirmed: cosmetic line wraps in the `inflight.sh` header, `docs/handoff.md` and the triage skill; the new tests do not assert directly that a live stash still leads with `resume — …` (existing cases 34, 35 and 55 cover it). Pre-existing, not part of this change: a working dossier whose last finished step is `qc` with no verdict prints `nothing known`.

No issue was filed from this pass; F1-F5 are for `/codeo:triage` to collect from the archived dossier.

**Verdict: clear — forward to `/codeo:close`.**

## Log

- 2026-11-19 — qc round 1: build exit 0, `bash tests/run.sh` all cases passed, all 5 criteria met, no blocking finding (F1-F5 non-blocking), clear, forward to /codeo:close · cost: 6m · opus-5-5 322k in + 2.2M cached / 13k out · sonnet-5-5 40k in + 1.6M cached / 2k out
