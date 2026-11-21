# Live-session signal in a hosted web session, round 3 — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** The beat hook's lock take stops undoing a stash or an abandon and stops switching branches mid-turn; a web session publishes as a web session whatever its lock's `host` says; and `docs/handoff.md` says truthfully which projects get the hook.

**Architecture:** `lock.sh take` gains one opt-in: with `CODEO_LOCK_SKIP_PARKED=1` it takes no lock for a dossier whose `close.md` ends in a `— stashed` or `— abandoned` round (the same rule `claim.sh` reads). `hooks/live-signal.sh` sets it, runs the take in the foreground, bounded, and only on `UserPromptSubmit`, claims each refresh interval atomically, and starts only the beat detached. `live.sh` reads `CLAUDE_CODE_REMOTE=true` as host `web` whatever the lock says.

**Tech Stack:** bash, git, `jq`; the `shell` suite (`bash tests/run.sh`).

**Spec:** issue #138 (https://github.com/kbajpai/codeo/issues/138) and its acceptance criteria; `.codeo/138/qc.md` `### Round 2` (F12, F13, F14, F15, F18, F19, F20) and the answers to Q11 and Q12. This round adds to `docs/plans/2026-11-21-live-signal-web-session-138.md` and `…-round-2.md`, which stay as the record of what was built.

## Decision record

| | |
|---|---|
| **Context** | QC round 2 found the beat hook taking a lock back after `/codeo:close --stash` or an abandon (both delete `.codeo/active` and leave the dossier at `.codeo/<N>/`, which `lock.sh take` finds), a take running detached mid-turn on `PostToolUse` (it can `git checkout -B` while the model works), a handoff paragraph telling other projects to add groups that only work here, and a web session whose init took a `local` lock making the writes #112 saw refused. |
| **Decision** | `lock.sh` refuses parked dossiers when asked to (`CODEO_LOCK_SKIP_PARKED=1`, Q11 a); the hook takes the lock only on `UserPromptSubmit`, in the foreground, atomically per interval; `live.sh` treats `CLAUDE_CODE_REMOTE=true` as web (Q12 a); the handoff page says what works where. |
| **Options rejected** | Parked rule only with the take still detached on both events (Q11 b); once per session (Q11 c: a stash in the same session stays parked but a new session on a stashed branch takes the lock, and a failed first try is never retried); document the `local`-lock case only, or leave it as later work (Q12 b, c). |
| **Trade-offs** | A take on a prompt now delays that prompt by the take's own time (a fetch, maybe a checkout), bounded below the hook's 10-second timeout, and happens at most once per interval; the opt-in env var keeps `/codeo:init`'s resume of a stash taking its lock the usual way. |
| **Action items** | Tasks 1-6 below. |

```mermaid
sequenceDiagram
    participant S as Web session
    participant H as hooks/live-signal.sh beat
    participant L as scripts/lock.sh
    participant V as scripts/live.sh
    S->>H: UserPromptSubmit (hook_event_name in the JSON)
    H->>H: web, .codeo/ present, no lock, interval claimed atomically?
    H->>L: foreground, bounded: CODEO_LOCK_SKIP_PARKED=1 lock.sh take web <id>
    L->>L: dossier whose close.md ends stashed or abandoned? take nothing
    H-->>V: detached: live.sh beat (host web for any lock, CLAUDE_CODE_REMOTE=true)
    S->>H: PostToolUse
    H-->>V: lock present: detached beat only; no lock: nothing
```

## Global Constraints

- **No invariants document is configured** (`.invariants` is unset).
- The signal stays information only; `beat` and `clear` exit 0 whatever happens. The hook prints nothing, always exits 0, never blocks a prompt for longer than its take's bound (`timeout` under the hook's 10 seconds, when a `timeout` binary exists) and starts the beat detached with every stream closed.
- The new behaviour runs only when `CLAUDE_CODE_REMOTE` is `true`; container and local sessions behave as before. `lock.sh take` without `CODEO_LOCK_SKIP_PARKED` behaves exactly as before for every host (`/codeo:init` resuming a stash relies on it).
- A web session's publish writes only to `refs/heads/codeo-live/*`, never changes the feature branch's tip and has no REST fallback.
- **Order:** every task here is proved by the `shell` suite in the issue's own checkout; Task 6, the hosted-session check, needs the engineer's host and is last. No shared environment is configured, so no task carries a lease marker.
- **Documentation moved:** `docs/handoff.md` (*Who is working right now* and its diagram) and `CHANGELOG.md` (Tasks 4 and 5). No wiki module.
- Overlap with #149 (`docs/handoff.md`, `CHANGELOG.md`) and #151 (`CHANGELOG.md`) was answered *proceed and coordinate* (round 1's Q8, Q9): Tasks 4 and 5 run `bash scripts/sync-main.sh` first and keep both sides on a conflict.
- **Later work, not in this plan** (`qc.md` Q3 a): leftover `codeo-live/*` branches (and CI that runs on every pushed branch), the fetch collision on equal machine labels, the forked-session label.
- **Implementers run focused tests only** (named per task); the controller runs the whole suite before the hand-off, since round 1's "suite green" claim from an implementer was wrong.

## Review Focus

1. **A stashed or abandoned dossier in a web session** must stay lockless across any number of tool calls and prompts (Task 2, Task 3 `hook_does_not_take_a_lock_for_a_stashed_dossier`).
2. **`/codeo:init` resuming a stash** must still take its lock: `lock.sh take` without the env var ignores `close.md` (Task 2, `take_without_skip_parked_still_takes_a_stashed_dossier`).
3. **A tool call mid-turn** must never run the take: `PostToolUse` with no lock does nothing (Task 3, `hook_posttooluse_never_takes_the_lock`).
4. **Two hooks at the same instant** must produce one take, not two (Task 3, `hook_two_simultaneous_hooks_take_once`).
5. **A `local` or `container` lock in a web session** must publish as web, not make the refused writes (Task 1).

---

### Task 1: A web session publishes as web whatever the lock says (`scripts/live.sh`)

**Files:**
- Modify: `scripts/live.sh` (`read_lock`, the header comment)
- Test: `tests/live.test.sh`

**Interfaces:**
- Produces: in `read_lock`, when `CLAUDE_CODE_REMOTE` is `true` the value of `host` is `web`, for the machine label, the route (`push_ref`), the REST-fallback guard, `clear` and the signal's `host:` line; the lock file is left as it is. Without it nothing changes.

- [ ] **Step 1: Write the failing tests** in `tests/live.test.sh`: `local_lock_in_a_web_session_publishes_as_web` (a `local` lock, `CLAUDE_CODE_REMOTE=true`, `CLAUDE_CODE_REMOTE_SESSION_ID=cse_abcdef0123456789`; assert the signal is on `refs/heads/codeo-live/104/web-abcdef01`, `refs/codeo/live/` holds nothing, the message says `host: web`, `$STUB_LOG` has no `ref put`); `container_lock_in_a_web_session_publishes_as_web` (the same with a container lock); `local_lock_outside_a_web_session_stays_local` (`CLAUDE_CODE_REMOTE` unset: the existing local behaviour).
- [ ] **Step 2: Run to see them fail** — `bash tests/run.sh live.test`; expected: FAIL on the first two (the signal lands in `refs/codeo/live/…` with `host: local` or `container`).
- [ ] **Step 3: Implement** in `read_lock`, then note it in the header's `host:` line.
- [ ] **Step 4: Run to see them pass** — `bash tests/run.sh live`; expected `all cases passed`.
- [ ] **Step 5: Commit** — `git add scripts/live.sh tests/live.test.sh` then `git commit -m "fix: a web session publishes as web whatever its lock's host says (#138)"`.

**Proof of done:** `bash tests/run.sh live` prints `all cases passed`.

---

### Task 2: `lock.sh take` can skip a parked dossier (`scripts/lock.sh`)

**Files:**
- Modify: `scripts/lock.sh` (`take`, the header comment)
- Test: `tests/lock.test.sh`

**Interfaces:**
- Produces: with `CODEO_LOCK_SKIP_PARKED=1` in the environment, `take`, after `find_issue` has found the one dossier, reads the last `### Round <n>` heading of `<state>/<N>/close.md` (when that file exists); when it matches `^### Round [0-9]+ — (.+ — )?(stashed|abandoned)([^[:alnum:]].*)?$` (the `park_re` in `scripts/claim.sh`) it takes no lock and prints `lock: TODO — #<N> is stashed or abandoned: no lock taken` on stderr, like the script's other TODO lines, and still exits 0. Anything else, including no `close.md`, a later non-parked round, or the variable unset, behaves exactly as before.

- [ ] **Step 1: Write the failing tests** in `tests/lock.test.sh`, in its existing style (a repo with a live dossier naming the branch): `take_skips_a_stashed_dossier_when_asked` (a `close.md` whose last round heading is `### Round 1 — stashed`; with the variable set no `.codeo/active` and the TODO line; exit 0); `take_skips_an_abandoned_dossier_when_asked` (`### Round 2 — abandoned`); `take_ignores_an_earlier_park` (`close.md` with `— stashed` followed by a later `### Round 2 — 2026-11-21` round: the lock is taken); `take_without_skip_parked_still_takes_a_stashed_dossier` (the stashed dossier, variable unset: the lock is taken).
- [ ] **Step 2: Run to see them fail** — `bash tests/run.sh lock.test`; expected: FAIL on the first two (a lock is taken).
- [ ] **Step 3: Implement** in `take` as under Produces.
- [ ] **Step 4: Run to see them pass** — `bash tests/run.sh lock`; expected `all cases passed`.
- [ ] **Step 5: Commit** — `git add scripts/lock.sh tests/lock.test.sh` then `git commit -m "feat: lock.sh take can skip a stashed or abandoned dossier (#138)"`.

**Proof of done:** `bash tests/run.sh lock` prints `all cases passed`.

---

### Task 3: The beat hook takes the lock only on a prompt, in the foreground (`hooks/live-signal.sh`)

**Files:**
- Modify: `hooks/live-signal.sh` (and its header, every line at most 100 columns)
- Test: `tests/live-signal.test.sh`

**Interfaces:**
- Consumes: `lock.sh take web` with `CODEO_LOCK_SKIP_PARKED=1` (Task 2), the hook JSON's `.hook_event_name`.
- Produces: with no `.codeo/active`, `beat` does something only when `.hook_event_name` is `UserPromptSubmit`, `CLAUDE_CODE_REMOTE=true`, `<root>/.codeo` is a directory and this interval's claim succeeds; the claim is a file `$(git rev-parse --git-path codeo-live-lock-try).<interval bucket>` created with noclobber (the bucket is `now / ${CODEO_LIVE_REFRESH_SECONDS:-300}`, and 0 or a non-number uses 300), so exactly one of two simultaneous hooks proceeds; the winner runs in the foreground `CODEO_LOCK_SKIP_PARKED=1 bash lock.sh take web "${CLAUDE_CODE_REMOTE_SESSION_ID#cse_}"` bounded by `timeout 8` when `timeout` exists, with every stream on `/dev/null`, then, when `.codeo/active` now exists, starts `live.sh beat` detached. `PostToolUse` or any other event with no lock does nothing. With a lock the hook behaves as before. Old claim files are removed when a new one is made.

- [ ] **Step 1: Write the failing tests** in `tests/live-signal.test.sh` (its scratch origin, `new_world_with_dossier`, and the stub-plugin copy whose `scripts/lock.sh` logs each call and takes no lock): first, at the top, unset `CLAUDE_CODE_REMOTE` and `CLAUDE_CODE_REMOTE_SESSION_ID` as `tests/live.test.sh` does, and change the existing hook-JSON inputs of round 2's cases to carry `"hook_event_name":"UserPromptSubmit"`. New or changed cases: `hook_posttooluse_never_takes_the_lock` (no lock, `PostToolUse`: the stub log stays empty and nothing is published); `hook_does_not_take_a_lock_for_a_stashed_dossier` (a real `lock.sh`, a dossier whose `close.md` ends `### Round 1 — stashed`, `UserPromptSubmit`, then a second after a new interval: no `.codeo/active`, no `codeo-live` branch); `hook_takes_the_lock_in_the_foreground` (the hook has returned, with the lock file present, before it exits: assert `.codeo/active` exists immediately after the hook returns, with no polling, then poll for the published branch); `hook_two_simultaneous_hooks_take_once` (two `UserPromptSubmit` hooks started together, five times over with a fresh claim each: the stub log has exactly one line per pair); `hook_bounds_the_take` (a stub `lock.sh` that sleeps 30 s: the hook returns within 12 s, with the lock absent); the round-2 cases for no lock outside a web session, no `.codeo/`, an existing lock and the once-per-interval claim stay and still pass.
- [ ] **Step 2: Run to see them fail** — `bash tests/run.sh live-signal`; expected: FAIL on the PostToolUse, stashed, foreground, simultaneous and bounded cases.
- [ ] **Step 3: Implement** in `hooks/live-signal.sh` as under Produces; keep the silent, always-exit-0 contract; update the header.
- [ ] **Step 4: Run to see them pass** — `bash tests/run.sh live`; expected `all cases passed`.
- [ ] **Step 5: Commit** — `git add hooks/live-signal.sh tests/live-signal.test.sh` then `git commit -m "fix: the beat hook takes the lock on a prompt, in the foreground, never for a parked dossier (#138)"`.

**Proof of done:** `bash tests/run.sh live` prints `all cases passed`.

---

### Task 4: `docs/handoff.md` — *Who is working right now*

**Files:**
- Modify: `docs/handoff.md` (the bullet and its `sequenceDiagram`)
- Test: `tests/live-signal.test.sh` (`docs_state_the_web_session_signal`)

**Documentation:** page `docs/handoff.md`, section *Parallel workflows → Who is working right now*. Afterwards it says, in the present tense, with no issue numbers and no history: the hook takes the lock only on a prompt (never after a tool call), in the foreground and bounded, at most once per refresh interval, never for a dossier whose `close.md` ends in a stash or an abandon (a stashed workflow resumed through `/codeo:init` takes its lock the usual way), and a take may check out the dossier branch between turns; a web session publishes as a web session whatever its lock's `host` says, when `CLAUDE_CODE_REMOTE` is `true`; the two gated groups in this repository's `.claude/settings.json` run this repository's own `hooks/live-signal.sh`, so they work only here, and another project gets the hook by installing the plugin through its environment's setup script, since cloud sessions do not install `enabledPlugins`; no other step is needed there beyond the project having `.codeo/` and a committed dossier for the branch; the diagram's flow is the one in this plan's diagram. Remove "Either way nothing else is needed" and "add the same two groups". Run `bash scripts/sync-main.sh` first; keep both sides on a conflict with #149.

- [ ] **Step 1: Extend the failing test** `docs_state_the_web_session_signal`: `docs/handoff.md` contains `never for a`, `whatever its lock`, `only here` and `committed dossier`, and no longer contains `nothing else is needed` or `same two groups`.
- [ ] **Step 2: Run to see it fail** — `bash tests/run.sh live-signal`; expected: FAIL on the new strings.
- [ ] **Step 3: Sync and edit** — `bash scripts/sync-main.sh`, then rewrite the section as above.
- [ ] **Step 4: Run to see it pass** — `bash tests/run.sh live-signal`; expected `all cases passed`, then `bash tests/run.sh plan-skill`, `closing-block` and `inflight` (they read this page).
- [ ] **Step 5: Commit** — `git add docs/handoff.md tests/live-signal.test.sh` then `git commit -m "docs: what a web session's hook does and which projects get it (#138)"`.

**Proof of done:** `bash tests/run.sh live-signal` prints `all cases passed`.

---

### Task 5: `CHANGELOG.md`

**Files:**
- Modify: `CHANGELOG.md` (the one bullet ending `(#138)` and the `Shared state:` line under `## Unreleased`)

**Documentation:** the bullet says the hook takes the lock only on a prompt, in the foreground, never for a stashed or abandoned dossier, and that a web session publishes as web whatever its lock says; and the `Shared state:` line says origin gains a `codeo-live/<issue>/<machine>` branch namespace for web sessions' signals, which a plugin from before it lists in triage as parked work and does not read in `inflight.sh`. Run `bash scripts/sync-main.sh` first; keep every bullet on a conflict (#149, #151).

- [ ] **Step 1: Sync** — `bash scripts/sync-main.sh`; expected exit 0, or a conflict to resolve by keeping both sides.
- [ ] **Step 2: Edit the bullet and the line.**
- [ ] **Step 3: Run the focused suites** — `bash tests/run.sh live` and `bash tests/run.sh devcontainer`; expected `all cases passed` each.
- [ ] **Step 4: Commit** — `git add CHANGELOG.md` then `git commit -m "docs: changelog for the parked-dossier rule and the shared-state note (#138)"`.

**Proof of done:** `bash tests/run.sh live` prints `all cases passed`.

---

### Task 6: The hosted-session check, on the build that results

Runs on: the engineer's host

**Files:** none changed. The result goes in `.codeo/138/implement.md`.

Needs the branch pushed with Tasks 1-5. Both attempts on round 2's build landed on stale checkouts, so step 1 is a gate.

- [ ] **Step 1: Start a new hosted session** (not a resumed one) on `kbajpai/codeo`, on `fix/live-session-signal-does-not`, and send `Run "git log --oneline -1" and show me the raw output.` The commit must be this round's last; **if it is not, stop here** and report what it printed and which environment and branch settings the session shows.
- [ ] **Step 2: Send one ordinary prompt** (`say hello`), then as a separate message `Run "cat .codeo/active" and show me the raw output.` Expected: the file exists with `host:    web` and `session:` followed by the session's id without `cse_`, with no manual `lock.sh` run.
- [ ] **Step 3: Check from this container** — `bash scripts/inflight.sh --live`; expected: a row `138`, `kbajpai`, `web-` plus 8 characters, `web`, an age under 900 seconds.
- [ ] **Step 4: Check the refresh** — after at least 5 minutes send any prompt and run `bash scripts/inflight.sh --live` again; expected: the age has dropped.
- [ ] **Step 5: Clean up** on the host: `git push origin --delete codeo-live/138/web-<8 characters>`.
- [ ] **If a step fails,** record the output verbatim under `## Notes` and report it; the criteria it covers are then not met.

**Proof of done:** the tip in step 1, the lock file in step 2, the row in step 3 and the age change in step 4, pasted into the dossier.

---

## Self-review

- **Findings coverage.** F12: Tasks 2, 3. F15: Task 3 (prompt only, foreground, bounded). F20: Task 3 (atomic claim). F13: Task 4. F14: Task 1 (and Task 4's sentence). F18: Task 5. F19: Task 3 (the unsets). F16, F17: later work.
- **Criteria coverage.** 2: Task 1 (no refused write even for a `local` lock). 4: Tasks 2, 3, 6. 6: Task 4.
- **Footprint.** Adds `scripts/lock.sh` and `tests/lock.test.sh` to round 2's twelve files.
- **Types.** `CODEO_LOCK_SKIP_PARKED`, the claim file name `codeo-live-lock-try.<bucket>`, `hook_event_name` and `park_re` are the same wherever they appear.
