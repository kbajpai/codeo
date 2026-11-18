# Issue #118 — plan

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/118 |
| Branch | `feat/live-signal-leftovers-104-refresh` |
| Updated | 2026-11-18 |

## Where this stands

Explored and brainstormed; two questions are open (Q1, Q2) and nothing is drafted past them. Four of the six acceptance criteria need no decision and are settled as the skill's own calls under `## Notes`; say so under either answer if one of them is wrong. The same-machine collision was reproduced here (below), and what it showed changes how Q2 reads: the beat that loses the ref lock loses it to a beat that has just published, so the signal is not stale.

## Questions

### Q1 — When a signal cannot be published, should the session say so (F2), or stay silent?

**Why it matters:** staying silent is no code at all: the plan records the decision and the docs keep what they say today. Surfacing is a design change in three files: `live.sh` has to leave the failure somewhere (the `beat` hook runs detached and returns before the push ends, so it cannot report its own result), `hooks/live-signal.sh` has to read that on a later hook call and print it once, and the rule "always prints nothing" in the hook's header and its tests goes. It also decides Q2: a hook that reports failures would report the harmless collision as one unless the collision is handled.

**Options:**
- **(a) Stay silent (recommended).** The signal is information only, no script waits on it, a failed beat is retried at the next refresh, and `live.sh beat --force` by hand already prints the reason. The plan records the decision; `docs/handoff.md` already says the hook says nothing.
- **(b) The session says so once.** A failed `beat` writes its one `live:` line to a file under `.git/`; the next `UserPromptSubmit` hook prints it as a hook warning once per distinct reason and removes it; a successful beat removes it too. An engineer whose signals never publish (no right to push `refs/codeo/live/*`, and no REST) finds out in the session instead of never.
- **(c) Stay silent here, and file a `/codeo:doctor` check as its own issue.** `doctor` would run one forced beat and a `clear` and report the `live:` line. Nothing in this change; the persistent case is still found, by the command whose job is "why does codeo fail". Filed through `/codeo:issue`.

**Answer:**
(a) Stay silent (engineer, in the conversation, 2026-11-18: "recommended for both"; recorded here by the skill).

### Q2 — Two beats at once from one checkout: document the limit and test that it is harmless, or stop it happening?

**Why it matters:** reproduced here against a scratch origin with the REST fallback stubbed to fail, as the tests stub it: in 30 rounds of two simultaneous beats from one checkout, 4 to 5 rounds had one beat print `live: could not publish`. In every such round the other beat had published, so the ref was fresh; the loser's commit carried the same second. On GitHub the loser then tries the REST write, which normally succeeds, so the line is rarer still. Documenting costs one sentence and one test that asserts what matters (both exit 0, the ref exists and is fresh). Handling costs about a dozen lines in `live.sh` (an atomic claim under `.git/` held for the publish, with a rule for a stale claim left by a killed beat) and a test that asserts no beat ever warns.

**Options:**
- **(a) Document and test (recommended with Q1 (a) or (c)).** `docs/handoff.md` and `live.sh`'s *Limits* say one of two simultaneous beats can lose the ref lock, that the other has then just published, and that the signal is fresh either way. A new case in `tests/live.test.sh` runs the pair ten times and asserts both exit 0 and the signal is listed with a small age; it does not assert an empty stderr.
- **(b) Handle it: one beat at a time per checkout (needed with Q1 (b)).** `beat` claims the throttle atomically before it publishes; a second beat that finds the claim returns at once, since the first is publishing the same thing. A claim older than twice `CODEO_LIVE_PUSH_TIMEOUT` plus a margin is taken over. The test asserts no warning in ten rounds. Two containers sharing a volume name are not covered: they are two checkouts, and `CODEO_MACHINE` is already the documented answer.

**Answer:**
(a) Document and test (engineer, in the conversation, 2026-11-18: "recommended for both"; recorded here by the skill).

## Notes

**Calls made without a question** (each satisfies its criterion as the issue words it; correct any of them in an answer above):

- *The "refresh 0" label* (criterion 1): relabel the assertion to say what it tests, a non-positive interval never throttles, and keep `CODEO_LIVE_REFRESH_SECONDS=-100`. Testing the literal `0` would bring back the flake #104 round 2 removed: with `0`, a clock that steps back one second throttles the beat.
- *Header lines* (criterion 2): `hooks/live-signal.sh` lines 3 (102 characters) and 7 (143) are re-wrapped at 100, the width the rest of that header and `live.sh`'s keep. Longer code lines elsewhere are not this issue's.
- *The timeout comment* (criterion 5, F8): `live.sh`'s `CODEO_LIVE_PUSH_TIMEOUT` line names both `github.sh ref put` and `github.sh ref delete`.
- *The 20-second figure* (criterion 6, F9): document it, do not derive it. `hooks/hooks.json` is static JSON and cannot read an environment variable. `docs/handoff.md` and `live.sh`'s *Limits* say 20 seconds is two bounds at the default 8; with `CODEO_LIVE_PUSH_TIMEOUT` at 10 or more the hook can end `clear` during the REST delete, and the signal then expires after the TTL. `tests/live-signal.test.sh`'s `docs_state_the_live_signal_limits` case pins the new sentence.
- *Shape*: one plan under `docs/plans/`, one pull request, no reference doc. Documentation moved: `docs/handoff.md` (*Who is working right now*) and `CHANGELOG.md`.

**Config.** No invariants document, no shared environment, no `wiki` module, no exclusive resources. One suite, `shell` (`bash tests/run.sh`, no `filter`), so each task's proof is the test file it changes run directly, then the whole suite.

**The collision spike.** A throwaway script in the session's scratch directory (not in the repository): the `tests/live-signal.test.sh` world, `gh` stubbed to fail, two `live.sh beat --force` started together in one clone. Forced: 5 of 30 rounds had one failed beat. Unforced with the stamp removed each round (the throttle race itself): 4 of 30. The failure line is the stubbed REST fallback's, after the push lost the lock.

### Footprint

```
files:      hooks/live-signal.sh, scripts/live.sh, tests/live.test.sh, tests/live-signal.test.sh, docs/handoff.md, CHANGELOG.md, docs/plans/2026-11-18-live-signal-leftovers-118.md
wiki:       none
exclusive:  none
```

## Outcome

_Pending — written at the hand-off._

## Log

- 2026-11-18 — Q1-Q2 raised · cost: 1m · fable-5-2 78k in + 494k cached / 5k out
