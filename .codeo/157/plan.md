# Issue #157 — plan

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/157 |
| Branch | `fix/live-session-signal-leftovers-138` |
| Updated | 2026-11-23 |

## Where this stands

Q1-Q3 are answered (A, A, A) and nothing is open. The plan is drafted at `.codeo/157/plan-draft.md` and waits for the engineer's approval; it is then saved under `docs/plans/`.

What I found (read against `scripts/live.sh`, `hooks/live-signal.sh`, `scripts/lock.sh`, `docs/handoff.md`, `skills/close/SKILL.md`, `tests/live.test.sh` and `.codeo/done/138/qc.md` at `efd02d8`):

- **F22.** `fetch` (`scripts/live.sh:208`) maps `refs/codeo/live/*` and `refs/heads/codeo-live/*` onto one local namespace, `refs/codeo/live/*`. Git refuses two sources for one destination, so one equal `<issue>/<machine>` pair fails the whole fetch, and `inflight.sh` prints `live: unknown` for every workflow.
- **F23.** A web session cannot delete its branch (the proxy refuses deletions), so `clear` returns early for `host: web` (`scripts/live.sh:200`). Nothing else deletes it. `/codeo:close` step 16 runs `live.sh clear`, which names only this checkout's own signal. `docs/handoff.md:172-173` says the branch stays "until someone deletes it" and gives no command; no page names the CI trigger.
- **F25.** The label is `web-` plus the first 8 characters of the lock's `session`, else of `CLAUDE_CODE_REMOTE_SESSION_ID` (`scripts/live.sh:116-122`). In the hosted run the lock first said `session: unknown`, so the first beat used the environment's id (`web-01Sa1Zqc`); `lock.sh` then refreshed the lock with a later, different id and the next beat used that (`web-01Sa1Zqb`). So the label follows whichever id is read at each beat.
- **Who can delete a web branch.** Only a session that is not a hosted web session: a container or local `/codeo:close`, or the engineer by hand. A workflow that ran and closed entirely in web sessions has no step that can delete its branch.
- **In flight:** `inflight.sh --except 157` prints `no other workflow in flight`. No overlap to ask about.
- The `shell` suite has no single-test filter: each task's proof is `bash tests/run.sh <test file pattern>`, then the whole `bash tests/run.sh`.
- No invariants document, no shared environment and no `wiki` module are configured.

My calls, stated so they can be corrected (not questions):

- **F22 fix: two local namespaces, both rows read.** `fetch` maps the web branches to `refs/codeo/live-web/*` instead of `refs/codeo/live/*`, and `list` reads both. An equal `<issue>/<machine>` pair then gives two rows (one `web`, one `container` or `local`), which is true: they are two sessions. A clone's old local `refs/codeo/live/<n>/web-*` copies are pruned by the next fetch. What a web session writes on origin does not change (out of scope). A test puts both refs on origin and asserts `fetch` exits 0 and `list` prints both.
- **One plan under `docs/plans/`, one pull request, no reference doc.** `docs/handoff.md` (the "Who is working right now" paragraph and its sequence diagram), the header comment of `scripts/live.sh` and `CHANGELOG.md` (`## Unreleased`) are the pages that move.
- **Where the close sweep runs (if Q1 picks it):** at every place `/codeo:close` already runs `live.sh clear`: a finished close, a stash and an abandon. A web session still working the issue publishes again on its next beat.
- The `engineering` plugin is not installed here; no new component or technology choice is involved, so its structure is not needed.

## Questions

### Q1 — F23: what removes a leftover `codeo-live/<issue>/*` branch?

**Why it matters:** it decides whether `skills/close/SKILL.md` and `skills/cleanup/SKILL.md` are edited and whether `live.sh` gets a new verb, or whether only `docs/handoff.md` changes. A hosted web session can never delete the branch itself, so every option needs a docs sentence for that case.
**Options:**
- **A — `/codeo:close` sweeps, and `/codeo:cleanup` prints what is left (my pick).** A new `live.sh sweep <issue>` deletes every `refs/heads/codeo-live/<issue>/*` on origin (nothing for a web session, which cannot). `/codeo:close` runs it in the command that clears the signal and deletes the lock. For a workflow closed in a web session, `/codeo:cleanup` (home checkout, already prints commands and runs nothing) prints one `git push origin --delete …` line per leftover branch of a finished issue. The docs say both, and give the by-hand command.
- **B — `/codeo:close` sweeps only.** As A without the `/codeo:cleanup` part. A workflow closed in a web session keeps its branch until the engineer deletes it by hand; the docs give the command. Smaller, but that is the case most likely to have a web branch.
- **C — docs only.** `docs/handoff.md` says when the branch can be deleted and with which command. No code.

**Answer:**
A — `/codeo:close` sweeps through a new `live.sh sweep`, and `/codeo:cleanup` prints the delete command for a finished issue's leftover branches. (Engineer: "go with your picks", 2026-11-23; given in the conversation, recorded here.)

### Q2 — F23: only document the CI run on every beat, or also mark the web signal `[skip ci]`?

**Why it matters:** the criterion needs only the docs sentence. Adding `[skip ci]` changes the web signal's commit message (a new case in `tests/live.test.sh`, one more sentence in the docs).
**Options:**
- **A — docs, plus `[skip ci]` in the web signal's commit message (my pick).** GitHub Actions skips `push` workflows when the head commit's message contains `[skip ci]`, so the beat stops running CI there. `list` reads the signal's fields by line prefix, so older readers are unaffected. The docs still name the trigger, and say other CI systems may not honour the marker and that excluding `codeo-live/**` from the workflow's branches is the sure way.
- **B — docs only.** The page names the trigger and tells the project to exclude `codeo-live/**` in its `on: push` filter.

**Answer:**
A — docs, plus `[skip ci]` in the web signal's commit message. (Engineer: "go with your picks", 2026-11-23; given in the conversation, recorded here.)

### Q3 — F25: how does a web session keep one label when its session id changes?

**Why it matters:** it decides what the `machine` of a web signal means, how many branches one issue can leave behind, and what the docs must still say about duplicates.
**Options:**
- **A — remember the first label (my pick).** The first beat writes its label to `<git dir>/codeo-live-machine`; later beats in that checkout reuse it, whatever the lock or the environment says by then. The label stays `web-<first 8>`. One session in one checkout shows as one row. A session whose VM was reclaimed starts in a new checkout and gets a new label, so a duplicate for up to the TTL is still possible there; the docs say so.
- **B — one fixed label per issue: `web`.** Every web session on issue N publishes `codeo-live/N/web`. No duplicate is possible and an issue leaves at most one branch. Two web sessions on one issue at once share one row (as two containers with one volume name do today; `CODEO_MACHINE` separates them), and the row no longer says which session.
- **C — accept and document.** No code; the docs state the duplicate and its 15-minute bound.

**Answer:**
A — remember the first label in the checkout's git directory. (Engineer: "go with your picks", 2026-11-23; given in the conversation, recorded here.)

## Notes

None yet.

## Outcome

_Pending — written at the hand-off._

## Log

- 2026-11-23 — Q1-Q3 raised · cost: 2m · fable-5-2 74k in + 518k cached / 10k out
