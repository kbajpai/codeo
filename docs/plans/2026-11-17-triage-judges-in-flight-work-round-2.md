# Triage judges in-flight work — round 2 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `waits:` names what a workflow is actually waiting on, past any qc verdict a later round has already answered. A stash or abandon is never hidden by an open question. Triage's *resume* and board check stop contradicting each other. qc round 1's non-blocking findings are fixed.

**Architecture:** `waits_of` in `scripts/inflight.sh` reads the round markers the pipeline already writes on each later round's second line: `(send-back from qc.md round <k>)`, `(after plan.md round <j>`, `(send-back from close.md round <m>)`, and `close.md`'s `qc round at review: <k>`. When qc has not yet run, it names the step after the last finished one. A live stash or abandon leads the line, and open questions follow it. `skills/triage/SKILL.md` reads a stash from `waits:` starting `resume — `, and moves the card on *resume* only for one.

**Tech Stack:** bash, git (`git show <sha>:<path>`), awk, the repo's `tests/*.test.sh` harness (`bash tests/run.sh [pattern]`).

**Spec:** `.codeo/103/init.md` (`## Outcome`: the acceptance criteria), `.codeo/103/plan.md` (Q1-Q9; Q7-Q9 answer this round), `.codeo/103/qc.md` round 1 (F1-F11). Round 1's plan, `docs/plans/2026-11-17-triage-judges-in-flight-work.md`, stands except where this one changes it.

## Context and decisions

| Decision | Chosen | Rejected (why) |
|---|---|---|
| `waits:` past a verdict (Q7, F1) | Follow the round markers through close's and qc's send-backs; with no verdict, the step after `step:`. | qc's send-backs only (a review send-back still reads `/codeo:close`); dropping the route (triage loses the owed step). |
| Stash and open questions (Q8, F2) | One line, stash first: `resume — #7's stash is live; engineer — plan.md Q2`. | A separate `parked:` line; triage calling `claim.sh` itself. |
| *resume* and the card (Q9, F5) | Card to Ready only when `waits:` starts `resume — `; a quiet workflow gets the owed step named and no card move. | Always Ready, with the mismatch check expecting it. |
| Archived dossier (F4) | `review — dossier archived`: the line says what was read, not a PR state it never read. | Looking the PR up in `inflight.sh` (a network call per archived workflow). |
| One question, several fingerprints (F6) | The answer is recorded against every fingerprint; an option only one kind has records that kind's decision and `deferred` for the others. | Leaving it unsaid. |
| A failed board read (F7) | Like `unavailable`: reported once in the run's `## Outcome`, never a mismatch. | Treating it as `none`. |

`waits:` after this round, the first that applies (rules 1-2 combine on one line):

```mermaid
flowchart TD
    S{claim.sh --stash-live exit 0 or 4?} -- yes --> R["resume — <claim line>"]
    S -- no --> Q
    R --> Q{open questions?}
    Q -- yes --> E["…; engineer — plan.md Q2"]
    Q -- no, and nothing above --> A{dossier under done/?}
    A -- yes --> V["review — dossier archived"]
    A -- no --> C{close.md's last round a send-back, round m?}
    C -- yes --> C1{implement.md has '(send-back from close.md round m)'?}
    C1 -- no --> I1["/codeo:implement"]
    C1 -- yes --> C2{qc.md's last round newer than close.md's 'qc round at review: k'?}
    C2 -- no --> Q1["/codeo:qc"]
    C2 -- yes --> D
    C -- no --> D{qc.md has a verdict, round k?}
    D -- clear --> CL["/codeo:close"]
    D -- back to plan --> P1{plan.md has '(send-back from qc.md round k)' in its round j?}
    P1 -- no --> PL["/codeo:plan"]
    P1 -- yes --> P2{implement.md has '(after plan.md round j'?}
    P2 -- no --> I2["/codeo:implement"]
    P2 -- yes --> Q2["/codeo:qc"]
    D -- back to implement --> M1{implement.md has '(send-back from qc.md round k)'?}
    M1 -- no --> I3["/codeo:implement"]
    M1 -- yes --> Q3["/codeo:qc"]
    D -- none --> N{step:}
    N -- init --> NP["/codeo:plan"]
    N -- plan --> NI["/codeo:implement"]
    N -- implement --> NQ["/codeo:qc"]
    N -- other / none --> NK["nothing known"]
```

A marker counts only at the start of a line, after leading whitespace; text may follow it (`(after plan.md round 2, answering qc.md round 2)`). `close.md`'s send-back rounds are the headings `### Round <m> — review feedback` and `### Round <m> — conflicts with <anything>`. Its `qc round at review: <k>` is the line inside that round (backticks around it allowed). Without one, C2 reads "no".

## Global Constraints

- **Additive only, as in round 1.** `--tsv`, `--branches` and `--live` print exactly what they print today. The human block keeps every line and its order. Only the *values* of `waits:` change.
- **No new network call.** Git reads of the pushed branch and the existing `claim.sh --stash-live` call only.
- **Never fails the listing** under `set -euo pipefail`: a missing file or marker falls to the next rule.
- **`verdict:` is unchanged**: still qc's last decision span, printed whenever there is one.
- **Triage's board writes stay Ready and Backlog**; *fix it* is still named, never run.
- No invariants document; no shared environment (no `Needs lease:`); no `wiki` module; no `resources[]`.
- No config schema change. `CHANGELOG.md`'s existing #103 bullet is edited in place (unreleased), not duplicated.
- The `shell` suite has no `filter`, so each task's proof of done is the whole `bash tests/run.sh`. `bash tests/run.sh <pattern>` is used for red and green.
- **Documentation moved.** `scripts/inflight.sh`'s header and `docs/handoff.md` → *Who else is in flight* (Task 1). `skills/triage/SKILL.md`, `docs/skills.md` → *triage* and `lib/env.sh` (Task 2). `CHANGELOG.md` (Task 3). No wiki pages; `docs/dossier.md` does not move, since the markers it already documents are read, not changed.
- Overlap with #116 (Q6, proceed and coordinate) still holds. Re-read each docs section after `/codeo:implement` merges `origin/main`.

## Review Focus

- **The live case qc found:** a `qc.md` back to `/codeo:plan` in round 1, a `plan.md` `### Round 2` carrying `(send-back from qc.md round 1)`, and an implement round 2 without `(after plan.md round 2` reads `/codeo:implement`, not `/codeo:plan` (Task 1: `waits_after_a_replan`).
- **A stash with an open question** reads `resume — …; engineer — …` (Task 1: `waits_stash_before_questions`).
- **A send-back marker inside a fenced block or mid-sentence** does not count (Task 1: `waits_marker_must_start_a_line`).
- **A review send-back already answered and re-checked:** close round 2 review feedback with `qc round at review: 1`, implement answering close round 2, qc round 2 clear reads `/codeo:close` (Task 1: `waits_after_review_round_rechecked`).
- **Triage after *resume* on a quiet workflow** makes no card move, so the next run raises no mismatch (Task 2: the wording check `resume moves the card only for a stash`).

---

### Task 1: `waits:` follows the rounds; the stash leads; small `inflight.sh` fixes

**Files:**
- Modify: `scripts/inflight.sh` (`waits_of` and its helpers; the `## Log` date read; header comment)
- Modify: `docs/handoff.md` → *Who else is in flight* (rewrap the bullet; say what `waits:` names)
- Test: `tests/inflight.test.sh`

**Interfaces:**
- Consumes: round 1's `open_questions_in`, `verdict_of`, `last_step`, `claim.sh --stash-live`.
- Produces: `waits:` values: `resume — <claim line>`, optionally followed by `; engineer — <files and numbers>`; `engineer — …`; `review — dossier archived`; `/codeo:implement`; `/codeo:qc`; `/codeo:plan`; `/codeo:close`; `nothing known`. Triage (Task 2) reads a stash as a value starting `resume — `.

- [ ] **Step 1: Write the failing tests** (on round 1's `w_origin` pattern, one branch each):
  - `waits_after_a_replan` — `qc.md` round 1 ``**Verdict: back to `/codeo:plan`.**``; `plan.md` `## Outcome` with `### Round 2`, then `2026-11-17`, then `(send-back from qc.md round 1)`. `  waits:     /codeo:implement`. Add `implement.md` with a round whose second line is `(after plan.md round 2)`: `  waits:     /codeo:qc`.
  - `waits_after_an_implement_send_back_answered` — verdict back to `/codeo:implement` in round 1; `implement.md` with `(send-back from qc.md round 1)`. `  waits:     /codeo:qc`.
  - `waits_after_review_feedback` — `qc.md` round 1 clear; `close.md` `### Round 2 — review feedback` with `` `qc round at review: 1` ``; no implement marker. `  waits:     /codeo:implement`. Add `(send-back from close.md round 2)` to `implement.md`: `  waits:     /codeo:qc`.
  - `waits_after_review_round_rechecked` — as above plus `qc.md` `### Round 2` clear. `  waits:     /codeo:close`.
  - `waits_after_conflicts_with_base` — `close.md` `### Round 1 — conflicts with main`, nothing else after. `  waits:     /codeo:implement`.
  - `waits_names_the_next_step` — `step:` plan (plan outcome written, no implement): `  waits:     /codeo:implement`. `step:` implement, no `qc.md`: `  waits:     /codeo:qc`. `step:` init: `  waits:     /codeo:plan`.
  - `waits_nothing_known` (round 1's case) — change the fixture so no step has an outcome (`init.md` with a pending outcome). Still `  waits:     nothing known`.
  - `waits_stash_before_questions` — `close.md` `### Round 1 — stashed`, `plan.md` with an open `### Q2`. `  waits:     resume — #<N>'s stash is live; engineer — plan.md Q2`.
  - `waits_marker_must_start_a_line` — the replan case with the marker written as `see (send-back from qc.md round 1)` mid-line. Still `  waits:     /codeo:plan`.
  - `waits_on_review` (round 1's case) — expected value becomes `  waits:     review — dossier archived`.
  - `touched_log_date_with_crlf` — a `## Log` line `- 2026-11-15` ending in CRLF (and nothing else on it), tip older. `(init.md log)`.
  - `touched_log_ties_updated` — one file, `Updated` 2026-11-15 and log 2026-11-15, tip older. `(plan.md log)`.
- [ ] **Step 2: Run to see them fail.** `bash tests/run.sh inflight`. Expected: exit 1, the new and changed `waits_*` cases and `touched_log_date_with_crlf` failing with `want substring`. `touched_log_ties_updated` may already pass; keep it as a guard.
- [ ] **Step 3: Implement in `scripts/inflight.sh`.** `waits_of` gets the workflow's `step` (from `last_step`) as a further argument, and follows the flowchart above: stash first, then questions joined with `; `, then archived, then close send-back, then verdict, then next step. Helpers, each reading one file with `git show "$sha:$dir/<file>"` and never failing: `marker_round <sha> <path> <prefix>` prints the `### Round` number of the round that holds a line starting (after whitespace) with `<prefix>`, or nothing; `close_send_back <sha> <dir>` prints `<m> <k>` for `close.md`'s last round when it is a send-back (`k` empty when no `qc round at review:` line); `last_qc_round <sha> <dir>` prints the number of the last `### Round` in `qc.md`'s `## Outcome`, else 1 when it has an outcome. Lines inside a ``` or `~~~` fence do not count, by the same rule `open_questions_in` uses. CR is stripped before matching. In the `## Log` date read, strip CR first. The header comment lists the `waits:` values and their order.
- [ ] **Step 4: Edit `docs/handoff.md` → *Who else is in flight*.** Re-read it first. Rewrap the bullet to the file's width. Say what `waits:` names: a live stash or abandon first, then open questions, else the step the workflow owes next (read from the round markers and qc's verdict), or `review — dossier archived`.
- [ ] **Step 5: Run to see them pass.** `bash tests/run.sh inflight`. Expected: `all cases passed`.
- [ ] **Step 6: Proof of done.** `bash tests/run.sh` prints `all cases passed`. Then `bash scripts/inflight.sh` in this checkout prints, for #116, a `waits:` line other than `/codeo:plan` (its `plan.md` round 2 answers qc round 1).
- [ ] **Step 7: Commit** `scripts/inflight.sh`, `tests/inflight.test.sh`, `docs/handoff.md`: `fix(inflight): waits follows the rounds past qc's verdict, and a stash leads (#103)`.

### Task 2: Triage reads the stash from `waits:`, moves the card only for one, and closes the gaps

**Files:**
- Modify: `skills/triage/SKILL.md` (step 1.2 parked and board bullets; step 4 options; step 5 *Resume*)
- Modify: `lib/env.sh` (rewrap the `triage{parkedDays}` line)
- Modify: `docs/skills.md` → *triage* → *Reads and writes* (only if a sentence there turns untrue)
- Test: `tests/triage-skill.test.sh`

**Interfaces:**
- Consumes: Task 1's `waits:` values (a stash or abandon is a value starting `resume — `; an archived dossier is `review — dossier archived`).

- [ ] **Step 1: Write the failing wording checks** in `tests/triage-skill.test.sh`:
  - `"stash read from waits"` — `` a `waits:` value that starts `resume — ` ``
  - `"within the threshold and assigned"` — `within the threshold and assigned`
  - `"resume moves the card only for a stash"` — `only for a workflow whose `waits:` starts `resume — ``
  - `"quiet resume names the owed step"` — `names the step its `waits:` line shows`
  - `"each fingerprint records the answer"` — `recorded against every fingerprint the question carries`
  - `"a failed board read is not a mismatch"` — `a failed `board.sh status` read is never a mismatch`
  - Replace the check `"send-back is In progress with a PR open"` with `"working dossier expects In progress"`, matching the whole first table row: `` | dossier at `.codeo/<N>/`, no live stash or abandon | In progress (`board.statuses.inProgress`) | ``.
- [ ] **Step 2: Run to see them fail.** `bash tests/run.sh triage-skill`. Expected: exit 1, six `FAIL: … — no [...]` lines (the replaced row check passes already).
- [ ] **Step 3: Edit `skills/triage/SKILL.md`.** Re-read step 1.2, step 4 and step 5 first.
  - Parked bullet: "One within the threshold is listed …" becomes "One within the threshold and assigned is listed …" (F3). Rewrap the bullet to its neighbours' width.
  - Board bullet: "stash and abandon come from `waits:`" becomes "a stash or abandon is a `waits:` value that starts `resume — `". Add: a failed `board.sh status` read is never a mismatch; report it once in the run's `## Outcome` with the line it printed, as for `unavailable` (F7). Change the one-question sentence to say the answer is recorded against every fingerprint the question carries, and that an option only one kind has (*fix it*, *file it*) records that kind's decision and `deferred` for the others, so those come back (F6).
  - Step 4's parked-work *resume* and step 5's **Resume**: the `board.sh set <N> ready` move applies only for a workflow whose `waits:` starts `resume — `. For one raised only for its age, *resume* names the step its `waits:` line shows, to run in that issue's checkout, and makes no card move (Q9).
- [ ] **Step 4: Rewrap `lib/env.sh`'s `triage{parkedDays}` line** to the key list's continuation style. In `docs/skills.md` → *triage*, re-read the first bullet and change it only if it says something now untrue.
- [ ] **Step 5: Run to see them pass.** `bash tests/run.sh triage-skill`. Expected: `all cases passed`. Then `git show 06a5778:skills/triage/SKILL.md > /tmp/claude-1000/old-triage.md` and `TRIAGE_SKILL=/tmp/claude-1000/old-triage.md bash tests/triage-skill.test.sh` shows the six new checks failing.
- [ ] **Step 6: Proof of done.** `bash tests/run.sh` prints `all cases passed`.
- [ ] **Step 7: Commit** the changed files: `fix(triage): read a stash from waits, move the card only for one, close the round-1 gaps (#103)`.

### Task 3: Changelog

**Files:**
- Modify: `CHANGELOG.md` (the existing #103 bullet under `## Unreleased`)

- [ ] **Step 1:** Re-read the bullet. Edit it in place so it says that `waits:` names a live stash or abandon first (with any open questions after it), then open questions, then `review — dossier archived`, else the step the workflow owes next, read from the round markers and qc's verdict; and that triage's *resume* moves the card to Ready only for a stash or abandon. Change no other line.
- [ ] **Step 2: Proof of done.** `bash tests/run.sh` prints `all cases passed`, and `grep -c 'dossier archived' CHANGELOG.md` prints `1`.
- [ ] **Step 3: Commit** `CHANGELOG.md`: `docs(changelog): #103 round 2`.

## qc round 1 findings → tasks

| Finding | Task |
|---|---|
| F1 `waits:` stale past a verdict | Task 1 |
| F2 stash hidden by a question | Task 1 (line), Task 2 (triage reads it) |
| F3 unassigned within the threshold | Task 2 |
| F4 `review — PR open` with no PR read | Task 1 |
| F5 *resume* on a quiet workflow | Task 2 |
| F6 fingerprints of a combined question | Task 2 |
| F7 failed board read | Task 2 |
| F8 weak table-row check | Task 2 |
| F9 CRLF log date; malformed `CODEO_TODAY` | Task 1 (CRLF); `CODEO_TODAY` is test-only and stays as is |
| F10 tie test | Task 1 |
| F11 unwrapped lines | Task 1 (`docs/handoff.md`), Task 2 (`SKILL.md`, `lib/env.sh`) |
