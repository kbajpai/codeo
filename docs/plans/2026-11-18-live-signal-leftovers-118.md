# Live-signal leftovers from #104 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Close the four leftovers of #104's live-session signal (the "refresh 0" label, the over-long header lines, the same-machine ref-lock collision, failure surfacing) and the two #116 QC findings F8 and F9, so that the tests, the code comments and `docs/handoff.md` say exactly what the code does.

**Architecture:** Wording and test changes only. No script behaviour changes: the failure-surfacing question (F2) is decided as "stay silent", and the same-machine collision is documented and pinned by a test that asserts what matters (both beats exit 0, the signal is fresh) rather than prevented.

**Tech Stack:** bash, `bash tests/run.sh` (the `shell` suite).

**Spec:** `.codeo/118/init.md` (`## Outcome`: the issue and its six acceptance criteria) and `.codeo/118/plan.md` (Q1-Q3 answered). Builds on `docs/plans/2026-11-15-live-session-signal.md` and `docs/plans/2026-11-17-follow-ups-116-qc-round-1.md`, whose tasks are built and stay as they are.

## Global Constraints

- **F2 decision (criterion 4), recorded here: stay silent.** `hooks/live-signal.sh` keeps discarding `beat`'s output and printing nothing. The signal is information only, no script waits on it, a failed beat is retried at the next refresh interval, and `bash scripts/live.sh beat --force` run by hand already prints the one `live:` line that says why. `docs/handoff.md` already says so; no code or sentence changes for it. Surfacing failures in the session stays a possible later design change. (Plan Q1, option a.)
- **Collision (criterion 3), documented and tested, not prevented.** Two beats started together from one checkout can both push the same ref; one can lose the origin's ref lock and print one `live:` line, which the hook discards, while the other has just published, so the signal is fresh either way. (Plan Q2, option a.) Two containers that share a volume name are two checkouts: `CODEO_MACHINE` is already the documented answer.
- **The "refresh 0" case keeps `CODEO_LIVE_REFRESH_SECONDS=-100`.** Only its label changes. Testing the literal `0` would bring back the flake #104 round 2 removed (a clock that steps back one second throttles a beat at `0`).
- **The 20-second figure is documented, not derived.** `hooks/hooks.json` is static JSON and cannot read `CODEO_LIVE_PUSH_TIMEOUT`; it stays `10 10 20`, pinned by `tests/live-signal.test.sh`.
- **No script behaviour changes.** `scripts/live.sh` changes only in comments; `hooks/live-signal.sh` only re-wraps its header comment.
- **Line length.** Every line this plan writes or re-wraps is at most 100 characters, the width `scripts/live.sh`'s and `hooks/live-signal.sh`'s headers keep.
- **Documentation this change moves:** `docs/handoff.md` (*Parallel workflows* → *Who is working right now*: the `SessionEnd` figure and the collision limit) and `CHANGELOG.md` (one bullet). `docs/skills.md`, `README.md` and `docs/dossier.md` move nothing. No wiki module is configured.
- **Overlap (plan Q3, proceed and coordinate).** #99 also edits `CHANGELOG.md`. Task 4 is last, runs `bash scripts/sync-main.sh` first, and keeps both sides on a conflict.
- **Suite.** The `shell` suite has no `filter`: a task's proof is the test file it touches (`bash tests/<file>.test.sh`, ending `all cases passed`), then `bash tests/run.sh`, ending `all cases passed`. No task carries `Needs lease:` or `Runs on:`: there is no shared environment, and every command runs in this checkout.
- **Invariants.** None configured.

## Review Focus

- A re-wrap of the header in `hooks/live-signal.sh` must keep its two claims: it does nothing without a project or lock, and it always exits 0 and prints nothing (Task 1).
- The collision test must not assert an empty stderr: a losing beat legitimately prints one `live:` line. It asserts exit 0 for both, one signal, and a small age (Task 3).
- The F8 check must not pass on the `ref delete` already named in `live.sh`'s header line 16; it reads the `CODEO_LIVE_PUSH_TIMEOUT` entry only (Task 2).
- The new `docs/handoff.md` sentences must keep `20 seconds`, `the login lookup` and the other substrings `docs_state_the_live_signal_limits` already pins (Tasks 2 and 3).
- The changelog bullet must sit with the live-signal bullets of `## Unreleased` and not disturb the `Config schema` / `Shared state` / `Safe to bump` lines above them (Task 4).

---

### Task 1: The "refresh 0" label says what it tests, and the hook header fits (criteria 1, 2)

**Files:**
- Modify: `tests/live.test.sh:210-212`, `hooks/live-signal.sh:2-9`
- Test: `tests/live-signal.test.sh`, `tests/live.test.sh`

- [ ] **Step 1: Write the failing test.** In `tests/live-signal.test.sh`, before the final `sleep 1`, add the case `hook_header_fits_100_columns`: `over=$(awk 'length > 100 {print FNR ": " length}' "$hook")` and `assert_eq "lines over 100 columns" "" "$over"`.
- [ ] **Step 2: Run `bash tests/live-signal.test.sh`.** Expected: `FAIL: hook_header_fits_100_columns — lines over 100 columns: want [] got [3: 102` and `7: 143]`, and a non-zero exit.
- [ ] **Step 3: Re-wrap `hooks/live-signal.sh`'s header (lines 2-9) at 100 columns.** Same words, same two claims; only line breaks change. Nothing below line 10 changes.
- [ ] **Step 4: Relabel the case in `tests/live.test.sh:211-212`.** The assertion label `refresh 0 republishes` becomes `a non-positive refresh interval never throttles`, and the `assert_pushed_quietly refresh0` label becomes `nonpositive`. The command line `CODEO_LIVE_REFRESH_SECONDS=-100 run beat` and its comment stay; the comment is shortened to at most 100 columns.
- [ ] **Step 5: Proof of done:** `bash tests/live-signal.test.sh` and `bash tests/live.test.sh` each print `all cases passed`; `grep -c 'refresh 0' tests/live.test.sh` prints `0`; `awk 'length > 100' hooks/live-signal.sh` prints nothing.
- [ ] **Step 6: Commit** `test: the refresh-interval case is labelled for what it tests; the hook header fits (#118)`.

### Task 2: The timeout comment names both bounded calls; the 20-second figure says what it assumes (criteria 5, 6)

**Files:**
- Modify: `scripts/live.sh:47-48` and `scripts/live.sh:54-55` (comments only), `docs/handoff.md:173` (the *Who is working right now* bullet)
- Test: `tests/live-signal.test.sh`

- [ ] **Step 1: Write the failing tests** in `tests/live-signal.test.sh`.
  - Case `live_sh_comment_names_both_bounded_calls`: `entry` is the `CODEO_LIVE_PUSH_TIMEOUT` environment entry of `scripts/live.sh`'s header, that line plus the continuation lines that follow it (`awk '/^#   CODEO_LIVE_PUSH_TIMEOUT/{f=1;print;next} f&&/^# {10,}/{print;next} {f=0}'`), joined on one line; assert it contains `github.sh ref put` and `github.sh ref delete`.
  - In `docs_state_the_live_signal_limits`, add to the `for want in …` list the string ``at the default `CODEO_LIVE_PUSH_TIMEOUT` ``, and a check that the bullet contains `can end \`clear\` during the REST delete`.
- [ ] **Step 2: Run `bash tests/live-signal.test.sh`.** Expected: `FAIL live_sh_comment_names_both_bounded_calls` naming `github.sh ref delete`, and two `FAIL docs_state_the_live_signal_limits: no [...]` lines.
- [ ] **Step 3: Edit `scripts/live.sh`'s comments.** The `CODEO_LIVE_PUSH_TIMEOUT` entry names the REST fallback as `github.sh ref put` for a `beat` and `github.sh ref delete` for a `clear`, all of its calls together. The *Limits* bullet on `clear` adds: the 20 seconds is two bounds at the default of 8; at 10 or more the hook can end `clear` during the REST delete, and the signal then only ages out after the TTL. Every new line at most 100 columns.
- [ ] **Step 4: Edit `docs/handoff.md`.** In the bullet, "The `SessionEnd` hook gets 20 seconds, the two bounds of a `clear`." becomes a sentence with the same opening that adds "at the default `CODEO_LIVE_PUSH_TIMEOUT` of 8; set it to 10 or more and the hook can end `clear` during the REST delete, so the signal then only expires." Nothing else in the bullet changes.
- [ ] **Step 5: Proof of done:** `bash tests/live-signal.test.sh` prints `all cases passed`; `bash tests/live.test.sh` prints `all cases passed`.
- [ ] **Step 6: Commit** `docs: the timeout comment names ref put and ref delete; the 20 seconds assumes the default (#118)`.

### Task 3: Two beats from one checkout are documented and pinned (criterion 3)

**Files:**
- Modify: `tests/live.test.sh` (after `concurrent_forced_beats_do_not_share_a_message_file`), `scripts/live.sh` (*Limits*), `docs/handoff.md` (the same bullet)
- Test: `tests/live.test.sh`, `tests/live-signal.test.sh`

- [ ] **Step 1: Write the test** `two_simultaneous_beats_from_one_checkout_leave_a_fresh_signal` in `tests/live.test.sh`, in the style of the case above it: `new_world; clone_with_lock 104 container codeo-104`; ten rounds of `live "$clone" beat --force` started twice in the background with stderr to two files, both waited on. Per round: both exit 0, and each stderr is empty or begins `live: could not publish`. After the rounds: `refs` lists exactly one ref (`refs/codeo/live/104/codeo-104`); then `run fetch` and `run list --tsv` print one line whose age column matches `^[0-5]$`.
- [ ] **Step 2: Run `bash tests/live.test.sh`.** Expected: PASS. This case pins behaviour the code already has, so there is no failure to see first; to see it can fail, temporarily add `return 0` as the first line of `beat()` in `scripts/live.sh`, run the file (expected: `FAIL: two_simultaneous_beats_from_one_checkout_leave_a_fresh_signal` on the ref count), then `git checkout scripts/live.sh`.
- [ ] **Step 3: Write the failing doc check.** In `docs_state_the_live_signal_limits` (`tests/live-signal.test.sh`) add to the `for want in …` list `lose the origin's ref lock` and `fresh either way`. Run `bash tests/live-signal.test.sh`; expected: two `FAIL … no [...]` lines.
- [ ] **Step 4: Document the limit.** `scripts/live.sh`'s *Limits*: one bullet, two beats started together from one checkout can both push the same ref and one can lose the origin's ref lock; the other has then just published, so the signal is fresh either way. `docs/handoff.md`: the same, in the bullet, after "A failed publish is not retried until the next refresh interval.", plus that two containers sharing a volume name are two checkouts and `CODEO_MACHINE` separates them. The sentence contains the exact phrases `lose the origin's ref lock` and `fresh either way`. Lines at most 100 columns in `live.sh`.
- [ ] **Step 5: Proof of done:** `bash tests/live.test.sh` and `bash tests/live-signal.test.sh` each print `all cases passed`.
- [ ] **Step 6: Commit** `test: two beats from one checkout leave a fresh signal; the limit is documented (#118)`.

### Task 4: The changelog says what changed (documentation, last)

**Files:**
- Modify: `CHANGELOG.md` (`## Unreleased`)

- [ ] **Step 1: Sync.** `bash scripts/sync-main.sh`; expected exit 0, or exit 2 naming `CHANGELOG.md` (#99 also edits it), resolved by keeping both sides.
- [ ] **Step 2: Add one bullet** at the end of the `## Unreleased` bullets, after the live-signal bullets, in the voice of its neighbours: the live-signal tests and docs are tidied; the docs say the `SessionEnd` 20 seconds assumes the default `CODEO_LIVE_PUSH_TIMEOUT`, and that two beats from one checkout can lose the origin's ref lock without leaving the signal stale; a session is deliberately not told when a signal cannot be published (#118). The `Config schema`, `Shared state` and `Safe to bump mid-workflow` lines above stay as they are (nothing here changes them).
- [ ] **Step 3: Proof of done:** `grep -c '#118' CHANGELOG.md` prints `1`; `bash tests/run.sh` prints `all cases passed`.
- [ ] **Step 4: Commit** `docs: changelog for the live-signal leftovers (#118)`.
