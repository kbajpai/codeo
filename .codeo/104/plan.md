# Issue #104 — plan

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/104 |
| Branch | `feat/publish-live-session-signal-so` |
| Updated | 2026-11-15 |

## Where this stands

Round 2. Q1-Q7 are answered (all as recommended; Q2's reading is stated under it). The plan is drafted at `.codeo/104/plan-draft.md` (7 tasks, uncommitted by design) and its footprint checked against the other workflows in flight, which raised one question, Q8 (#71). The draft is not up for approval until Q8 is answered; reading it meanwhile is welcome. After Q8, re-run `/codeo:plan`: it writes the plan to `docs/plans/2026-11-15-live-session-signal.md` for review.

## Questions

### Q1 — Where does the signal live?

**Why it matters:** it decides the script that writes it, what `inflight.sh` fetches, and how much history the signal leaves behind. The issue allows "the intake branch or another ref".
**Options:**
- **A ref of its own per session, outside `refs/heads/` (recommended)** — `refs/codeo/live/<N>/<machine>`, pointing at one parentless commit with an empty tree whose message carries the fields. Each refresh force-pushes a new commit over the old one, so there is no history, no branch in GitHub's branch list, no CI run and no race with lease pushes. `inflight.sh` reads them all with one extra fetch (`+refs/codeo/live/*:refs/codeo/live/*`). Two machines on one issue show as two live sessions, since each has its own ref. New to this codebase: nothing uses a custom ref namespace yet.
- **A file on `codeo/intake`** — `.codeo/intake/live/<N>-<machine>.md`, written through `intake.sh`'s existing plumbing. Follows the lease precedent, but every refresh is a commit on the intake branch (about 100 a day per session at a 5-minute refresh), and each one can lose a push race against a lease or a triage commit and retry.
- **A branch per session** — `codeo/live/<N>/<machine>`, force-pushed. As the first option, but visible in the branch list, and every script that walks `refs/remotes/origin` (`inflight.sh`, `claim.sh`, triage's branch scan) needs an exclusion.

**Answer:**
A ref of its own per session, as recommended (engineer, in the conversation, 2026-11-15: "Accepted as recommendations").

### Q2 — Can a hosted web session push to a ref that is not its own branch?

**Why it matters:** the criterion "it works in a web session" depends on it, and I cannot test it from this container. If the push is refused there, the plan adds a second write path through REST (`POST /repos/{owner}/{repo}/git/commits`, then create or update the ref with `git/refs`), which is one more task and one more set of tests. If pushes to `codeo/intake` already work from a web session, that is evidence for the intake option in Q1 but says nothing about a `refs/codeo/` ref.
**Options:** pushes to any ref work there · only branch pushes work (then Q1 becomes a branch or the intake file, or REST writes the ref) · unknown — build the REST fallback, used when the push is refused, and record a by-hand web check for `/codeo:qc`.

**Answer:**
Accepted as recommendations (engineer, in the conversation, 2026-11-15). No option of this question was marked recommended; the planner reads that as the third option: build the REST fallback, used when the push is refused, and record a by-hand web check for `/codeo:qc`. Correct this line if another option was meant.

### Q3 — What keeps the signal fresh?

**Why it matters:** it decides what "live" means and whether the refresh depends on the model remembering to do it.
**Options:**
- **A plugin hook (recommended)** — a second entry in `hooks/hooks.json`, on `UserPromptSubmit` and `PostToolUse`, that runs only when `.codeo/active` exists, refreshes at most once per interval (Q4), and pushes in the background so no tool call waits on the network. "Live" then means *a Claude session is active in a checkout bound to the issue*, whether or not a skill is mid-step. A `SessionEnd` hook deletes the ref, so a clean exit stops showing at once and only a crash waits for the expiry.
- **The skills call it** — each of init, plan, implement, qc and close runs `live.sh beat` at its start and its stops. "Live" means *a codeo skill ran recently*. A long `implement` run can outlast the expiry between calls, it edits five `SKILL.md` files (all inside #70's footprint) and it relies on the model.
- **Both** — the hook, plus one explicit call at each skill's start so the signal appears without waiting for the first tool call.

**Answer:**
A plugin hook, as recommended (engineer, in the conversation, 2026-11-15: "Accepted as recommendations").

### Q4 — How long until a dead session stops reading as live, and is that configurable?

**Why it matters:** the expiry is the documented number in the second acceptance criterion, and a config key means a `lib/env.sh` entry, a default and tests for both.
**Options:**
- **Refresh every 5 minutes, expire after 15, fixed (recommended)** — three missed refreshes before a session reads as dead; an environment variable (`CODEO_LIVE_TTL_SECONDS`, as `CODEO_LEASE_GRACE_SECONDS` does for leases) overrides it for tests and odd cases. No config key.
- **The same defaults, with a config key** — `live{refreshSeconds,expirySeconds}` in `.codeo/config.json`.
- **Other numbers** — say which.

The reader judges expiry from the signal's own timestamp against its own clock, so two machines whose clocks disagree by minutes shift the window by that much. I would document that and not try to correct for it.

**Answer:**
Refresh every 5 minutes, expire after 15, fixed, as recommended (engineer, in the conversation, 2026-11-15: "Accepted as recommendations").

### Q5 — What exactly are "the user" and "the machine", given that this repository is public?

**Why it matters:** whatever the signal names is readable by anyone who fetches the ref. It decides what the writer looks up and what `inflight.sh` prints.
**Proposal:**
- **User:** the GitHub login from `github.sh user login` (which honours `$CODEO_GITHUB_LOGIN` where `GET /user` is refused, as in a web session), else `git config user.name`. Never the email address: leases fall back to `user.email`, and I would not copy that into a signal on a public repository.
- **Machine:** `$CODEO_MACHINE` when set; otherwise by the lock's `host` — `container`: the volume name from the lock (`codeo-104` here; the container's own hostname is a random id such as `c68a409ad456`); `web`: `web` plus the lock's session id; `local`: the output of `hostname`.

**Options:** as proposed · never publish a real hostname (a `local` checkout then says `local` unless `$CODEO_MACHINE` is set) · something else — say what.

**Answer:**
As proposed (engineer, in the conversation, 2026-11-15: "Accepted as recommendations").

### Q6 — How should `inflight.sh` show it?

**Why it matters:** #103 will also add facts to `inflight.sh` and promises that the existing `--tsv` columns keep their order. Two issues appending columns to the same rows would have to agree on that order.
**Options:**
- **A `live:` line in the human block, and a separate machine-readable listing (recommended)** — the block gains `  live:      kbajpai on codeo-104 (container), 3m ago`, once per live session, printed only when there is one; `--tsv` and `--branches` are untouched; a new `inflight.sh --live` prints `issue<TAB>user<TAB>machine<TAB>host<TAB>last-seen` for status reporters.
- **Always print the line** — `live: no` when nothing is live, so the absence of a session is stated.
- **Append a column to `--tsv`** — `live` or empty as a sixth column, with the order agreed with #103.

A failed fetch of the signals would print `live: unknown` and never drop the line silently.

**Answer:**
A `live:` line in the human block and a separate `--live` listing, as recommended (engineer, in the conversation, 2026-11-15: "Accepted as recommendations").

### Q7 — Does `/codeo:triage`'s own text change in this issue?

**Why it matters:** the first criterion says triage reports live workflows "through `inflight.sh`". Triage already prints what `inflight.sh` prints, so the line reaches it with no skill edit. Changing `skills/triage/SKILL.md` as well puts this issue inside the footprints of #71 and #70, both of which edit that file, and moves the skills-inventory fixture.
**Options:**
- **One sentence in triage (recommended)** — a workflow with a live session is listed with its `live:` line quoted and is not asked about as parked work. Accepts the overlap with #71 and #70, which becomes an overlap question once the footprint is drafted.
- **No triage edit** — triage shows the line because `inflight.sh` prints it; what triage concludes from it is left to #103, which rewrites that paragraph anyway.

**Answer:**
One sentence in triage, as recommended (engineer, in the conversation, 2026-11-15: "Accepted as recommendations").

### Q8 — #71 edits four files this plan edits; how do the two branches proceed?

**Why it matters:** the draft footprint (`.codeo/104/plan-draft.md`, last section) overlaps #71's. Two branches editing one file merge cleanly only when their hunks are apart, and that is a coordination question, not one this plan can settle alone.
**What overlaps:** #71, branch `feat/file-new-issues-straight-board`, assignee kbajpai, last finished step `implement` (working). `overlap.sh` names it on `CHANGELOG.md`, `glob:CHANGELOG.md`, `docs/handoff.md`, `glob:docs/handoff.md`, `docs/skills.md`, `glob:docs/skills.md`, `skills/triage/SKILL.md` and `glob:skills/triage/SKILL.md`. In this plan the edits are small and additive: a changelog bullet and the `Shared state:` line (Task 6), one bullet and one clause in the two docs, and one sentence in the triage step that reads `inflight.sh` (Task 5). #107 (`feat/dev-container-follow-ups-96`, kbajpai, at `init`) has no footprint yet and has changed no file, so there is nothing to compare. #70 has merged since the branch was cut; `/codeo:implement` merges `origin/main` first.
**Options:**
- **Proceed and coordinate (recommended)** — keep the plan as drafted. `/codeo:implement` and `/codeo:qc` merge `origin/main` each round, so whichever of the two lands second resolves its own hunks; Tasks 5 and 6 re-read the lines they edit before editing them.
- **Sequence after #71** — this issue waits for #71's merge before `/codeo:implement` starts, so the two never share an unmerged file. Costs the wait; #71 is already at `implement`.
- **Re-scope** — drop the triage sentence and its docs clause (Q7's recommendation), leaving `CHANGELOG.md` and `docs/handoff.md` as the only shared files.

**Answer:**

## Notes

**What exists today.** `inflight.sh` derives everything from pushed branches: one block per workflow, `--tsv` rows for status reporters, `--branches` for `overlap.sh`. The lock `.codeo/active` is gitignored and local. Leases on `codeo/intake` are the only pushed shared state, written with plumbing in a throwaway index. The plugin already ships one hook (`hooks/subagent-model.sh`) that acts only when `.codeo/active` exists, which is the pattern Q3's recommendation follows.

**Calls I am making unless told otherwise.**
- One new script, `scripts/live.sh`, with `beat`, `clear` and `list`; `inflight.sh` calls `list`. The hook is a thin wrapper around `beat`.
- The signal is keyed by issue and machine, so two sessions on one issue both show. That is the case most worth seeing.
- A refresh never fails or delays the session: any error is swallowed after one line on stderr, and with origin unreachable nothing is published.
- `/codeo:close` does not clear the signal by hand. The session-end hook and the expiry cover it, and an expired ref is ignored by every reader. Expired refs are deleted by the next `beat` for the same issue and machine; a ref left by a machine that never returns stays on origin, unread. If that should be swept, say so under any answer.
- One pull request. Documentation moves in `docs/handoff.md` (*The lock*, *Parallel workflows*), `docs/skills.md`, `lib/env.sh`'s header if Q4 adds a key, and `CHANGELOG.md`.
- Liveness stays information only: no script refuses or waits because of it.

**Other workflows in flight** (`inflight.sh --except 104`, re-run 2026-11-15 after the answers). #107 is at `init` with no footprint yet. #71 is at `implement` and overlaps on four files (Q8). #70 merged while this was being planned; `origin/main` now has its changes to `scripts/github.sh`, `skills/triage/SKILL.md`, `docs/handoff.md`, `docs/skills.md` and `CHANGELOG.md`, which this branch does not have yet. #103, the sibling issue, is open and not started; it will edit `scripts/inflight.sh` and `tests/inflight.test.sh` too, which is why Q6 left `--tsv` alone.

**Design checked against the code.** Scratch repositories confirmed the git side: `git fetch --prune origin '+refs/codeo/live/*:refs/codeo/live/*'` succeeds when no such ref exists, a force-push of a new parentless empty-tree commit over the old one works, and a deletion on origin is pruned by the next fetch. Not tried from here, and so not asserted by the plan: a push of that ref to GitHub itself, and anything in a web session (Q2, plan Task 7).

## Outcome

_Pending — written at the hand-off._

## Log

- 2026-11-15 — Q1-Q7 raised · cost: 3m · fable-5-2 115k in + 1M cached / 14k out
- 2026-11-15 — Q1-Q7 answered and recorded; plan drafted (.codeo/104/plan-draft.md); footprint overlap with #71 raised as Q8 · cost: 6m · sonnet-5-5 192k in + 2.6M cached / 43k out
