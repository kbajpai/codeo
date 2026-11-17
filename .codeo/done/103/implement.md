# Issue #103 — implement

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/103 |
| Branch | `feat/let-codeo-triage-judge-flight` |
| Updated | 2026-11-17 |

## Where this stands

Round 3 is done. It fixes qc round 2's blocking F12 and the non-blocking F17 in `scripts/inflight.sh`. Both were reviewed, and the build passes. Next: `/codeo:qc`.

## Questions

None.

## Outcome

| | |
|---|---|
| Plan | `docs/plans/2026-11-17-triage-judges-in-flight-work.md` (committed `281de05`) |
| Base branch | `origin/main` already contained; `sync-main.sh` merged nothing, so nothing else changed on the base |
| Overlaps | `overlap.sh 103` printed none |
| Build | `shell` suite build `true`: exit 0 |
| Shared environment | none configured: no lease, no deploy |

**Built**, through `superpowers:subagent-driven-development`, every implementer and reviewer on `sonnet`:
- Task 1, `06d6ba1`: `inflight.sh` prints `touched:   <date> (<source>), <d> days ago` after `changed:` — the newest of the branch tip, each dossier's `Updated` row and its last `## Log` date, ties going to the dossier; unparseable dates skipped; `CODEO_TODAY` overrides today for tests.
- Task 2, `79e176a` + fix `654a5eb`: `waits:` (engineer with file and question numbers · resume with `claim.sh --stash-live`'s line · `review — PR open` · the step after qc's verdict · `nothing known`) and `verdict:` (qc's last decision span, only when there is one). The fix round made the open-question reading match `dossier-check.sh` (`~~~` and longer fences, `## Questions <suffix>`, a `# ` heading ending the section) and the clear test match `qc-verdict.sh` (`clearly` is not clear); the verdict is computed once per block. `docs/handoff.md` → *Who else is in flight* names the three lines.
- Task 3, `ab5d8f8` + fix `4490b64`: `skills/triage/SKILL.md` reads `.triage.parkedDays // 7`, asks about a workflow touched more than that many days ago (fingerprint `parked:<N>:<touched date>`) and lists the rest, and compares `board.sh status` with an expected-Status table (fingerprint `board:<N>:<Status found>`); `lib/env.sh` and `docs/skills.md` document the key and default; nine wording checks in `tests/triage-skill.test.sh`.
- Task 4, `06a5778`: one `CHANGELOG.md` bullet.

**Documentation changed:** `scripts/inflight.sh`'s header, `docs/handoff.md` (*Who else is in flight*), `lib/env.sh` (config key list), `docs/skills.md` (*triage* → *Reads and writes*), `CHANGELOG.md`.

**Deviations from the plan, and why:**
- Task 1 loosened the `changed:`→`live:` assertion in `human_block_shows_a_live_session`, which the plan gave to Task 2; it had to, since `touched:` already sat between them.
- The plan's wording check `named, never run` already occurred in the skill, so it could not fail; it was replaced by a string unique to the new option, verified to fail against the pre-task skill.
- The plan's mismatch option `board.sh set <N> <status>` has no target for the "archived, no pull request or closed unmerged" row; there *fix it* names `/codeo:close` in that issue's checkout (its stash sets Ready, its abandon Backlog).
- The plan left two things unsaid that review asked for: step 5 now has a *Fix it* action (record `fix named — <command>`, run nothing; it returns while the mismatch persists), and one workflow is one triage question, carrying every fingerprint (parked, board, stash or branch) found for it.
- The sub-skill's final whole-branch review was not run: rule `implement-09` gives the review to `/codeo:qc`.

**Minor review notes left for qc to weigh:** no test for a log date tying an `Updated` row in the same file; a malformed `CODEO_TODAY` prints an empty day count; `docs/handoff.md`, `skills/triage/SKILL.md` and `lib/env.sh` each carry one unwrapped long line from the edits; the triage mismatch bullet refers forward to the branch bullet's `pr list-for-branch` and leaves the `waits:` vocabulary for a stash or abandon implicit; the ledger example in the skill has no `fix named` row.

### Round 2

2026-11-17
(after plan.md round 2)

| | |
|---|---|
| Plan | `docs/plans/2026-11-17-triage-judges-in-flight-work-round-2.md` (committed `311f715`) |
| Base branch | `sync-main.sh`: the branch already contains `origin/main` |
| Overlaps | `overlap.sh 103` printed none |
| Build | `shell` suite build `true`: exit 0 |
| Shared environment | none configured |

**Built** (every implementer and reviewer on `sonnet`):
- Task 1, `779af7c`: `waits:` puts a live stash or abandon first (`resume — …`, with any open questions after it as `; engineer — …`). It then shows open questions, then `review — dossier archived`. Otherwise it gives the step owed next, read from the round markers: `(send-back from qc.md round <k>)`, `(after plan.md round <j>`, `(send-back from close.md round <m>)` and `close.md`'s `qc round at review:`. With no verdict it gives the step after `step:`, else `nothing known`. The fence logic is shared between questions and markers. A CRLF `## Log` date is read. Tie and CRLF tests are added, and `docs/handoff.md` is rewrapped and updated. Existing cases whose expected `waits:` follows from the new rules were changed to match: `/codeo:implement` after a plan outcome, `review — dossier archived`, and a pending-init fixture for `nothing known`.
- Task 2, `de17297`: in `skills/triage/SKILL.md`, a stash or abandon is a `waits:` value starting `resume — `. *resume* moves the card to Ready only for one; for a quiet workflow it names the step `waits:` shows. An unassigned workflow is asked about whatever its date. A combined question's answer is recorded against every fingerprint, with `deferred` for kinds an option doesn't fit. A failed `board.sh status` read is never a mismatch. The table-row check now pins the whole row, and `lib/env.sh` is rewrapped. Against the pre-round-1 skill, the six new checks fail.
- Task 3, `9e91d75`: the #103 `CHANGELOG.md` bullet is edited in place.

The branch's `inflight.sh` against origin now prints `waits:` from these rules; for #116, whose qc round 2 is clear, it reads `/codeo:close`.

**Documentation changed:** `scripts/inflight.sh`'s header, `docs/handoff.md` (*Who else is in flight*), `skills/triage/SKILL.md`, `lib/env.sh`, `CHANGELOG.md`. `docs/skills.md` is unchanged; its triage bullet is still true.

**Deviations:** none from the plan's decisions. Task 3 was checked from its one-line diff by the controller instead of a reviewer dispatch.

**Minor review notes left for qc:**
- A verdict naming both `/codeo:plan` and `/codeo:implement` routes to implement. This order is inherited.
- Fences are recognised at column 0 only. This is inherited.
- For a quiet workflow, "the step its `waits:` line shows" is undefined when `waits:` names no step (`nothing known`, `review — dossier archived`).
- F6's one-kind options name *fix it* and *file it* but not *resume*.
- Some wrapped lines in the skill are ragged.

### Round 3

2026-11-17
(send-back from qc.md round 2)

| | |
|---|---|
| Plan | `docs/plans/2026-11-17-triage-judges-in-flight-work-round-2.md` (unchanged; this round fixes code that did not do what it says) |
| Base branch | `sync-main.sh` merged `origin/main` (1 commit, `f2f4588`) with no conflict. It exited 1 after the merge: `comm` complained that its input was not sorted while it listed the changed files. A second run printed `sync-main: the branch already contains origin/main` (exit 0). |
| Also changed on main | `CHANGELOG.md`, `docs/handoff.md`, `docs/skills.md`. Each was re-checked. This branch's #103 bullet, the *Who else is in flight* paragraph and the triage *Reads* bullet are intact, and none has a conflict marker. Main's edits are to other paragraphs. |
| Overlaps | `overlap.sh 103` printed none |
| Build | `shell` suite build `true`: exit 0 |
| Shared environment | none configured |

**Findings taken from qc.md round 2** (checked against the code with `superpowers:receiving-code-review` before any change):
- **F12 (blocking): holds, fixed.** Reproduced: with `## Log` after the send-back round, `close_send_back` printed nothing.
  - `da46e34`: `close_send_back` now reads `### Round` headings and the `qc round at review:` line only inside `## Outcome`, the same way `last_qc_round` does. A later `## ` heading ends the read but keeps the last round's send-back.
  - The `close_review` fixture and #51's fixture gained the real `## Outcome` and `## Log` shape. The cases `waits_after_review_feedback` and `waits_after_conflicts_with_base` failed before the fix. `waits_after_review_round_rechecked` passed before it by falling through to the same answer.
  - `9160e9f` adds `waits_close_log_is_not_read_as_a_round`. A `qc round at review: 3` in close.md's `## Log` must not count: `/codeo:qc` is right, and `/codeo:close` would mean the Log was read. The implementer showed this case fails against a version that reads the Log.
- **F17 (non-blocking): holds, fixed.** `4b30e2c`: `verdict_of` strips CR. `verdict_with_crlf` failed before the fix: a Verdict span wrapped over two CRLF lines printed a `\r`.
- **F15 (non-blocking): not taken.** The fix belongs in `scripts/claim.sh`, which is outside this change's footprint. It stays recorded in `qc.md`.
- **F13, F14, F16:** these are the plan's, and stay recorded in `qc.md`.

**Built** (implementer and reviewer both on `sonnet`). `bash tests/inflight.test.sh` printed `all cases passed` (the implementer's run). Task review: spec ✅, approved. Its minor notes, left as they are:
- `/^## Outcome/` is a prefix match, the same as `last_qc_round`'s.
- The comment above `close_send_back` could also say that rounds are read only inside `## Outcome`.

**Documentation changed:** none. `scripts/inflight.sh`'s header and `docs/handoff.md` already say `waits:` follows a close send-back, which is now true of a real dossier.

**Deviations:** three commits instead of the two the brief named, because the stronger Log case went in its own commit.

## Log

- 2026-11-17 — implemented: 4 tasks, 6 commits (06d6ba1..06a5778), build ok · cost: 37m · opus-5-5 78k in + 11.1M cached / 27k out · sonnet-5-5 344k in + 4.2M cached / 53k out
- 2026-11-17 — implemented round 2: 3 tasks, commits 779af7c..9e91d75, build ok · cost: 31m · opus-5-5 24k in + 7.2M cached / 11k out · sonnet-5-5 238k in + 2.7M cached / 39k out
- 2026-11-17 — implemented round 3: F12 and F17, commits da46e34..9160e9f, build ok · cost: 6m · opus-5-5 166k in + 1.6M cached / 4k out · sonnet-5-5 264k in + 2M cached / 16k out
