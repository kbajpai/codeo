# Live-signal leftovers, round 2 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A web checkout keeps its first live-signal label for good, so a session that ends and resumes under another id shows as one row, and the documentation and tests say what is true after that.

**Architecture:** `live.sh clear` stops removing `<git dir>/codeo-live-machine`; only a web host reads or writes it, and a web `clear` deletes nothing on origin, so nothing needs the removal. The label then names the checkout, not the current session id. Four documentation and test gaps from `qc.md` round 1 (F2-F5) are closed in the same round.

**Tech Stack:** bash 4.3+, git, the `shell` suite (`bash tests/run.sh`).

**Spec:** `.codeo/157/qc.md` round 1 (F1-F5) and Q4 of `.codeo/157/plan.md` (answered A). Builds on `docs/plans/2026-11-23-live-signal-leftovers-157.md`, already implemented.

## Global Constraints

- No invariants document, no shared environment: no `Needs lease:`; every task is proved in this checkout.
- Out of scope: F24 and which ref namespace a web session writes, as in round 1.
- `live.sh` still exits 0 whatever happens.
- Docs describe the system after the change, in the present tense, with no issue numbers other than the `(#157)` suffix `CHANGELOG.md` entries carry.
- Proof is `bash tests/run.sh <file pattern>` (the `shell` suite has no single-test filter); the last task runs the whole suite.
- Pages that move: `scripts/live.sh` header, `docs/handoff.md`, `docs/skills.md`, `CHANGELOG.md`.

## Review Focus

- A web checkout that has beaten, cleared (a `SessionEnd`) and resumed under another session id publishes one branch: task 1 pins it.
- `clear` on a web host still removes the throttle stamp, so the next beat is not throttled: task 1 keeps the existing assertions.
- A container or local checkout never reads the saved label: round 1's tests already pin it; task 1 leaves them as they are.
- The CHANGELOG header still describes the shared state truthfully for a mixed-version team: task 2 pins its words.

### Task 1: `clear` keeps the saved web label (F1)

**Files:**
- Modify: `scripts/live.sh` (`clear`, and the header lines that say `clear` removes the label: the `live.sh clear` verb text, the machine paragraph and the web-checkout bullet)
- Test: `tests/live.test.sh` (replace `web_clear_forgets_the_label`)

**Interfaces:**
- Consumes: `label_file()`, `saved_label()`, `machine_label()` from round 1, unchanged.
- Produces: `clear` removes the throttle stamp only; the label file persists in the checkout.

- [ ] **Step 1: Write the failing test.** Replace `web_clear_forgets_the_label` with `web_clear_keeps_the_label`: a web lock with session `abcdef0123456789`, `run beat --force`, `run clear`, `clone_with_lock 104 web 99999999aaaaaaaa`, `run beat --force`; assert `one branch` equals `refs/heads/codeo-live/104/web-abcdef01` from `heads`, and assert the label file still exists after `clear`.
- [ ] **Step 2: Run it to see it fail.** `bash tests/run.sh live.test` fails `web_clear_keeps_the_label` with two branches.
- [ ] **Step 3: Implement.** In `clear`, `rm -f "$(stamp)"` only. In the header, say a web `clear` removes the stamp and keeps `codeo-live-machine`, and the label names the checkout until the checkout goes.
- [ ] **Step 4: Prove it.** `bash tests/run.sh live.test` and `bash tests/run.sh live-signal` print `all cases passed`.
- [ ] **Step 5: Commit** `fix: a web checkout keeps its first live-signal label across clear`.

### Task 2: Documentation and changelog (F1 wording, F2, F4, F5)

**Files:**
- Modify: `docs/handoff.md` (the label sentence at the machine paragraph; the CI sentence), `docs/skills.md` (the `cleanup` purpose and reads/writes), `CHANGELOG.md` (the `## Unreleased` header lines and the label bullet)
- Test: `tests/live-signal.test.sh` (pins in `docs_state_the_web_session_signal`)

**Interfaces:**
- Consumes: task 1's behaviour.
- Produces: the pages' final wording.

- [ ] **Step 1: Pin the words first.** In `docs_state_the_web_session_signal` add the tokens `names the checkout` and `create` event (`'a `create` event'`) to the handoff list; a second loop over `CHANGELOG.md` requires `older plugin` (mixed-version note) and forbids `until \`live.sh clear\``. Run `bash tests/run.sh live-signal`: fails on each.
- [ ] **Step 2: `docs/handoff.md`.** The label sentence says a web checkout keeps the label of its first beat in `<git dir>/codeo-live-machine`, that `clear` leaves it, so a session that ends and resumes, or whose id changes, shows as one row, that the label names the checkout (a later issue worked there publishes under it), and that a reclaimed VM or a new checkout gets a new label and the old row shows for up to the TTL. The CI sentence adds that each new web branch also fires a `create` event, which `[skip ci]` does not suppress.
- [ ] **Step 3: `docs/skills.md`.** The `cleanup` purpose opens with the container removal commands and the leftover-branch delete command together; its reads list adds `refs/remotes/origin/codeo-live/<N>/*` for a proven issue.
- [ ] **Step 4: `CHANGELOG.md`.** `Shared state` adds that `/codeo:close` deletes the issue's `codeo-live/<issue>/*` branches on origin and that readers keep web signals in the local `refs/codeo/live-web/*`; `Safe to bump mid-workflow` adds that a reader on an older plugin keeps the old fetch and still aborts on a collision until it updates. The label bullet says the label is kept in the checkout, `clear` leaves it, and a new checkout gets a new label with the old row showing up to the TTL.
- [ ] **Step 5: Prove it.** `bash tests/run.sh live-signal` prints `all cases passed`.
- [ ] **Step 6: Commit** `docs: the saved web label, the create event, cleanup's branch output`.

### Task 3: `inflight.sh --live` against the collision (F3)

**Files:**
- Test: `tests/inflight.test.sh`

**Interfaces:**
- Consumes: the plant helper near line 223 and the real `live.sh`; the stubbed-fetch case at lines 264-278 is the model for running `--live`.
- Produces: a case `live_survives_a_web_and_a_container_signal_with_equal_labels`.

- [ ] **Step 1: Write the test.** Plant `refs/codeo/live/<n>/<m>` and `refs/heads/codeo-live/<n>/<m>` in the origin with equal `<n>/<m>`, run `inflight.sh --live` with the real `live.sh`; assert exit 0, stdout holds one row for each host, and stderr has no `live:`. (It passes against round 1's code, so it is a regression pin, not a new behaviour: check it fails with the old `+refs/heads/codeo-live/*:refs/codeo/live/*` refspec put back, then restore.)
- [ ] **Step 2: Prove it.** `bash tests/run.sh inflight` prints `all cases passed`.
- [ ] **Step 3: Commit** `test: inflight --live survives equal web and container labels`.

### Task 4: The whole suite

- [ ] **Step 1:** `bash tests/run.sh` prints `all cases passed`.

## Documentation the plan changes

`scripts/live.sh` header, `docs/handoff.md`, `docs/skills.md`, `CHANGELOG.md`: tasks 1-2.
