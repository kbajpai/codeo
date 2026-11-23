# Issue #157 — plan

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/157 |
| Branch | `fix/live-session-signal-leftovers-138` |
| Updated | 2026-11-23 |

## Where this stands

Round 2, after the send-back in `qc.md` round 1: Q4 is open and nothing is drafted until it is answered. Round 1's plan (`docs/plans/2026-11-23-live-signal-leftovers-157.md`) is built and committed; Q1-Q3 stand as answered.

What the send-back found, checked against `scripts/live.sh` and `hooks/live-signal.sh` on this branch:

- **F1 (blocking).** `clear` removes the saved web label (`scripts/live.sh:228`), and `hooks/live-signal.sh:52-53` runs `clear` at every `SessionEnd`, web sessions included. `/codeo:close` step 16 is the only other caller. A web `clear` deletes nothing on origin, so the old branch stays; a session that ends and resumes in the same checkout under another id then publishes a second label, and two rows show for up to the TTL. `docs/handoff.md:209` and `CHANGELOG.md` say such a session shows as one row. Round 1's Q3 answer ("until `clear`") did not account for `clear` running at session end.
- **F2-F5 (non-blocking)** are small documentation and test gaps in files already in the footprint.

My calls for round 2, stated so they can be corrected (not questions):

- **F2-F5 are fixed in this round too**, since each is a sentence or one test in a file the round already opens: the `CHANGELOG.md` header lines (shared state, mixed-version note), a test that runs `inflight.sh --live` against the collision, the `cleanup` entry in `docs/skills.md`, and a sentence on the `create` event in `docs/handoff.md`.
- **One short plan file** for the round, `docs/plans/2026-11-23-live-signal-leftovers-157-round-2.md`, on the same branch and pull request.

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

### Q4 — F1: when does a web checkout forget its saved label?

**Why it matters:** it decides whether `scripts/live.sh` and its tests change again or only the docs do, and what the docs may truthfully say about one row. Asked because `qc.md` round 1 sent the change back on it.
**Options:**
- **A — never: the label belongs to the checkout (my pick).** `clear` stops removing `<git dir>/codeo-live-machine`; nothing removes it. Only a web host ever reads or writes the file, and a web `clear` cannot delete the branch anyway, so there is nothing for the removal to keep in step with. A session that ends and resumes in the same checkout keeps one label and one row. A later issue worked in the same web checkout publishes under the same `web-<first 8>` label, which then names the checkout, not the current session id; the docs say so. A reclaimed VM is still a new checkout and can still show twice for up to the TTL.
- **B — only at `/codeo:close`.** The `SessionEnd` hook keeps the label and step 16 removes it, through a flag or a second verb on `live.sh`. Same result as A within one issue; the label follows the session id again for the next issue in that checkout. Costs a new interface on `live.sh`, a hook change and a `skills/close/SKILL.md` change, for a distinction no reader of the rows uses.
- **C — docs only.** The code stays. `docs/handoff.md` and `CHANGELOG.md` say a session that ends and resumes under another id can show twice for up to the TTL. Meets the criterion's second half, but leaves the duplicate #138's hosted run actually produced whenever a session end falls between the two ids.

**Answer:**

## Notes

None.

## Outcome

| | |
|---|---|
| Plan | `docs/plans/2026-11-23-live-signal-leftovers-157.md` (unstaged, approved 2026-11-23) |
| Shape | One executable plan under `docs/plans/`, 8 tasks, one pull request; no reference doc, since nothing here is a standing decision |

**Decisions.** F22: web branches fetch into `refs/codeo/live-web/*` and `list` reads both namespaces, so equal labels give two rows (rejected: one namespace with a collision rule). Q1 A: new `live.sh sweep`, run by `/codeo:close` with `clear`, and `/codeo:cleanup` prints the delete command for a proven issue (rejected: close only; docs only). Q2 A: `[skip ci]` in the web signal's subject plus docs (rejected: docs only). Q3 A: the first web label is kept in `<git dir>/codeo-live-machine` until `clear` (rejected: one fixed label `web`; documenting the duplicate only). A web session still working the issue republishes after a sweep, and a reclaimed VM can still show twice for up to the TTL; both are in the docs task.

**Documentation the plan changes.** `docs/handoff.md` (the live-signal paragraph and its sequence diagram), `docs/skills.md` (`close`, `cleanup`), the `scripts/live.sh` header, `skills/close/SKILL.md`, `skills/cleanup/SKILL.md`, `CHANGELOG.md`.

**Intake questions resolved here.** None; init left nothing open. No `/codeo:issue` filed. The `engineering` plugin is not installed and no component choice was involved, so its structure was not used.

### Footprint

```
files:      scripts/live.sh, scripts/cleanup.sh, skills/close/SKILL.md, skills/cleanup/SKILL.md, docs/handoff.md, docs/skills.md, CHANGELOG.md, tests/live.test.sh, tests/live-signal.test.sh, tests/close-skill.test.sh, tests/cleanup.test.sh, tests/cleanup-skill.test.sh, docs/plans/2026-11-23-live-signal-leftovers-157.md
wiki:       none
exclusive:  none
sequenced:  none
```

## Log

- 2026-11-23 — Q1-Q3 raised · cost: 2m · fable-5-2 74k in + 518k cached / 10k out
- 2026-11-23 — planned: docs/plans/2026-11-23-live-signal-leftovers-157.md · cost: 12m · fable-5-2 80k in + 718k cached / 11k out · sonnet-5-5 126k in + 1.9M cached / 26k out
- 2026-11-23 — round 2: Q4 raised after the send-back in qc.md round 1 · cost: 1m · fable-5-2 117k in + 23k cached / 1k out
