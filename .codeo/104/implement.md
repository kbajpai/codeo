# Issue #104 — implement

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/104 |
| Branch | `feat/publish-live-session-signal-so` |
| Plan | `docs/plans/2026-11-15-live-session-signal.md` |
| Updated | 2026-11-16 |

## Where this stands

Round 2 done, after a send-back from `/codeo:qc` round 1: the two blocking findings (F1, the octal `beat` that hid every later signal; F2, a documentation claim the hook could not keep) and the polish findings F4, F6 and F8 are fixed and reviewed, and the live tests no longer depend on a monotonic wall clock (the cause of their recurring flakes, found this round). The build step (the `shell` suite's `build`, `true`) exits 0. Task 7, the by-hand web-session check, is deferred to #112. No open question.

## Questions

None.

## Notes

- `sync-main.sh` (the installed plugin, 1.0.6) merged `origin/main` cleanly (commit `5c6252c`, 1 commit, #109) and then exited 1 on its own `comm: file 2 is not in sorted order` error: that script is the version from before #98's collation fix, which this branch's own copy already carries. The merge stands. The both-changed list was recomputed by hand with the fixed pipeline (`LC_ALL=C comm -12` over both sides' changed files since the merge base) and is empty; `overlap.sh 104` printed nothing.
- Base-branch changes since the plan was drafted (from #70) touched `scripts/github.sh`, `skills/triage/SKILL.md`, `docs/handoff.md`, `docs/skills.md` and `CHANGELOG.md`; every task re-read its files before editing and kept the existing lines.
- No shared environment is configured: no lease was taken, nothing was deployed.
- The full `bash tests/run.sh` takes over two minutes here; each implementer ran it before committing. Grading it is `/codeo:qc`'s.
- The pre-flight scan of the plan found three stale details and one hermeticity hazard, ruled on before Task 1 (see Outcome → Deviations).

## Outcome

2026-11-16

**Built.** Six of the plan's seven tasks, each by its own implementer on the subagent model (`sonnet`) with its own review:

- Task 1, `a085f15`: `scripts/github.sh` gains `ref put <ref> <message-file>` and `ref delete <ref>`, the REST write path (`git/commits` then `PATCH` or `POST git/refs`), with five cases in `tests/github.test.sh`.
- Task 2, `d67ec0c` and `a258012` (one fix round): `scripts/live.sh` with `beat`, `clear`, `fetch` and `list`; `tests/live.test.sh`. Fix round 1 bounded the login lookup and added `--no-verify` to both pushes.
- Task 3, `0ff627c`: `scripts/inflight.sh` prints `live:` lines after `changed:` (and `live: unknown (could not fetch the signals)` on a failed fetch) and gains `--live`; seven cases in `tests/inflight.test.sh`; `--tsv` and `--branches` are untouched.
- Task 4, `ad8863d`: `hooks/live-signal.sh` and three `hooks/hooks.json` entries (`UserPromptSubmit` and `PostToolUse` run `beat`, `SessionEnd` runs `clear`); `tests/live-signal.test.sh`.
- Task 5, `e6a37e6`: documentation (below) and the one triage sentence.
- Task 6, `5ff3e99`: the `CHANGELOG.md` entry.
- Final wave, `abc9cc9`, `30d6c8c`, `8785a52`: one fix agent for the whole-branch review's findings (below).

**Documentation pages changed.** `docs/handoff.md` (*Parallel workflows*: a *Who is working right now* bullet with the sequence diagram, and a clause in *Who else is in flight*), `docs/skills.md` (*triage* → *Reads and writes*), `skills/triage/SKILL.md` (one sentence), `CHANGELOG.md` (the `Shared state:` line and one bullet). `docs/dossier.md` and `README.md` do not move, as the plan says.

**Build.** The `shell` suite's `build` is `true`: exit 0.

**Deviations from the plan.**
- *Task 1.* `scripts/github.sh` now dispatches with `case $group in` (the base branch added `pr get`), so `ref` is a new top-level group arm beside `label`, not an arm of the plan's "final `case`".
- *Task 2.* The plan's `CODEO_MACHINE='a/b/../c'` → `a-b-..-c` cannot be a ref: git refuses `..`. Runs of two or more dots collapse to `-`, so the ref is `refs/codeo/live/104/a-b---c` and the test asserts that. A label that is `.`, `..`, starts with `.`, ends with `.` or ends with `.lock` is made safe (one extra case, `machine_label_never_forms_an_unsafe_ref_name`).
- *Task 4.* The hook tests put a stub `gh` first on `PATH` and set `CODEO_GITHUB_LOGIN`, because the hook runs the real scripts and the real `github.sh` would otherwise call the network.
- *Task 6.* The plan said to replace `Shared state: unchanged from v1.0.6.`; the base branch had already changed that line (the `/codeo:cleanup` clause), so ours is appended to it.
- *Test hygiene added beyond the plan.* New cases for a hung login lookup, `pre-push` hooks being skipped, hostile ref contents on read, a dot at the 64th character, and `..` traversal in the `github.sh` guard.

**Review.** Task reviews: Tasks 1, 3, 4, 5, 6 clean; Task 2 needed one fix round (two Important findings, both addressed on re-review). The whole-branch review (on `sonnet`, because the project's subagent model never escalates) returned *with fixes*, six Important findings, all fixed in one wave and confirmed by one scoped re-review (*all findings addressed, no new Critical or Important breakage*):
- the `refs/codeo/live/*` guard in `github.sh` accepted `..` traversal; it now requires `^refs/codeo/live/[0-9]+/[A-Za-z0-9._-]+$` for both verbs;
- the REST commit used the authenticated user's name and email; it now sends `codeo-live <codeo-live@invalid>` as author and committer;
- `live.sh list` printed message fields uncleaned; it now cleans `user` and `machine`, and skips a signal whose host is not `container|web|local` or whose issue is not 1-9 digits;
- a dot at the 64th character of a machine label made an invalid ref; the cut now comes first;
- `tests/inflight.test.sh` lost its executable bit in Task 3; restored;
- the flaky `beat_is_throttled_and_force_is_not` (below).

**The flaky test, and what is not known.** `tests/live.test.sh` `beat_is_throttled_and_force_is_not` failed once in a loaded full-suite run (`force republishes: want [1] got [0]`) and the fix agent saw it twice more before hardening. The root cause is not proven. The circumstantial cause: the scratch origin lacked `gc.auto 0`, `maintenance.auto false` and `receive.autogc false` (sibling tests set them), so a detached maintenance run after a push could race the next push, and the stubbed `github.sh ref put` then masked the failed push by exiting 0. Hardened on every route: the origin config, a stub that fails by default so a silent REST fallback is a visible failure, `CODEO_LIVE_PUSH_TIMEOUT=60`, and a wait-for-the-epoch-to-change loop instead of `sleep 1`. After that `tests/live.test.sh` and `tests/live-signal.test.sh` passed 10 of 10 runs each, one set under load.

**Left as polish** (the whole-branch reviewer judged each *leave*): `github.sh` `${2:?}` printing a bash error instead of a `github:` line, the discarded `PATCH` stderr before the `POST` fallback, no failure-path tests for `ref put|delete`; an empty `user login` answer skipping the `user.name` fallback, `source`/`cd` before the exit-0 wrapper in `live.sh`, a fixed message-file path, a dead `$?` assertion, an unreachable-origin test that does not exercise the timeout; `inflight.sh`'s `list --tsv || true`, the fetch's stderr discarded in the human mode, a `two_machines` test that never asserts the `codeo-7` line, nothing proving `--tsv` and `--branches` skip the fetch; the hook computing its plugin path after `cd`, `sleep 1` before negative assertions, a short-lived stray `beat` when a scratch directory is deleted.

**Not run: Task 7.** The plan's by-hand check in a real web session (`bash scripts/live.sh beat --force`, then `bash scripts/inflight.sh --live` from another clone, then `bash scripts/live.sh clear`) is the engineer's. It is the only way to settle the fourth acceptance criterion and whether GitHub accepts the ref and the REST calls. Nothing from it has been recorded; `/codeo:qc` marks that criterion *not yet checkable* until it is.

### Round 2

2026-11-16
(send-back from qc.md round 1)

**Sync.** `bash scripts/sync-main.sh` (the installed plugin, 1.0.6) merged `origin/main` (`bb396d1`, #111) and stopped on one conflict, `CHANGELOG.md` (exit 2). Resolved against both changes' intent: the base branch had rewritten the dev-container follow-ups bullet in place and added a new `#96's QC` bullet, so both of its lines are kept and this branch's `#104` bullet stays last; the `Shared state:` line was not in conflict. Committed as `94cf8f2` and pushed. The both-changed list, recomputed by hand with `LC_ALL=C comm -12` because the installed script lists nothing on a conflict: `CHANGELOG.md` only. `overlap.sh 104` printed nothing.

**Findings checked against the code before any change** (`superpowers:receiving-code-review`): F1, F2, F4, F6 and F8 all held (F1 was reproduced: `bash -c 'b=09; echo $((1700000000 - b))'` prints `value too great for base`); F3, F5 and F7 are the plan's design points and carry no work in this round.

**Built.** One task, one implementer on the subagent model (`sonnet`), two fix rounds after its review:
- `0632b57`, **F1 (blocking):** `scripts/live.sh` `list` accepts a `beat` only as `^[1-9][0-9]{0,11}$` and an `issue` only as `^[1-9][0-9]{0,8}$`, so a zero-padded value is skipped and the rest of the listing survives. Two cases: `list_skips_zero_padded_beat_and_issue_and_keeps_the_rest` in `tests/live.test.sh` and `a_malformed_signal_does_not_hide_the_ones_after_it` in `tests/inflight.test.sh` (a bad signal planted between two good ones; exit 0, both good lines, the later workflow's `live:` line still shown). **F6:** `beat` writes its message to a per-process file (`mktemp` beside the old path), so concurrent beats cannot delete each other's; case `concurrent_forced_beats_do_not_share_a_message_file` (two machines, ten rounds). **F8:** the `hooks/live-signal.sh` header says the hook judges the project the JSON's `cwd` names and falls back to the process directory only when the JSON carries none.
- `e0b94d9`, **F2 (blocking) and F4:** `docs/handoff.md` no longer says the session is told when nothing could be published: it says the hook discards `beat`'s output and that `beat --force` run by hand prints the one `live:` line that says why. Both `docs/handoff.md` and the `CHANGELOG.md` bullet now say a session with no prompt or tool call for 10 to 15 minutes stops reading as live.
- `ae440b9` and `ecc1bc0`, fix rounds for what round 2's review and a stress run found in the tests themselves (below): no exact-age assertion, TTL boundaries with at least 5 s of margin, distinct commit dates per `live` invocation in the test helper, and a negative refresh interval in the "refresh 0" case.

**Documentation pages changed.** `docs/handoff.md` (*Who is working right now*) and `CHANGELOG.md` (the `#104` bullet). No other page.

**Build.** The `shell` suite's `build` is `true`: exit 0. Each implementer ran the covering test files, and the whole `bash tests/run.sh` once before its first commit; grading it is `/codeo:qc`'s.

**Deviations from the plan and the brief.**
- *F2.* Dropping the claim, not making the hook log somewhere, is a deviation from the plan's Task 5 wording (the plan promised "the session says so once", which its own Task 4 design cannot do). Ruling: the smallest repair, with no new file or place to document; if the engineer wants failures surfaced in the session, that is a design change for `/codeo:plan`.
- *The republish check in the tests.* The fix instruction suggested counting ref updates through a hook on the scratch origin; the implementer found that pushing an identical commit is "up to date" and fires no hook, so each `live` call in `tests/live.test.sh` gets distinct `GIT_AUTHOR_DATE` and `GIT_COMMITTER_DATE` from a counter file instead. `scripts/live.sh` is untouched by that.
- *The "refresh 0" case* sets `CODEO_LIVE_REFRESH_SECONDS=-100` so a backward clock step cannot throttle it; it now tests that a non-positive interval never throttles, not the literal `0` (its label still says "refresh 0": a Minor, left).

**The flaky tests: the cause is found.** Round 1 recorded the root cause of `beat_is_throttled_and_force_is_not` as not proven. It recurred in this round after that round's hardening, and a stress run of `tests/live.test.sh` under CPU load then failed a different case, `list_hides_an_expired_signal_and_shows_it_again_inside_the_ttl` (`ttl 60 hides 61 s`: `list` printed age 60 for a signal planted at now minus 61). Only a wall clock that stepped backwards explains that, and it does: this container's clock (WSL2, `hyperv_clocksource_tsc_page`) is not monotonic. Sampling `date +%s%N` for 45 s under load gave 5036 samples with 4 backward steps, up to 618 ms. The same mechanism produces the earlier failures (after a backward step two beats share an epoch second and build byte-identical commits, so the ref's sha does not change). `scripts/live.sh` is not affected: a same-content republish is a no-op and `list` clamps a negative age to 0. The tests were the fragile part, and the fix above removes their dependence on second-granularity ordering. After it `tests/live.test.sh`, `tests/inflight.test.sh` and `tests/live-signal.test.sh` each passed 5 of 5 runs idle and 5 of 5 under eight busy loops. A different environment (a runner with a monotonic clock) would not have shown any of these.

**Review.** The implementer's work was reviewed on `sonnet` (the project's subagent model never escalates): the first review found the code and docs correct and one Important defect in a new test (an exact age against the wall clock, `ae440b9` fixed it), and the scoped re-review of both fix rounds returned *all findings addressed, no new Critical or Important breakage*. No second whole-branch review was run for this small send-back round; `/codeo:qc`'s independent review follows. Left as polish: the "refresh 0" label above, the over-long header line in `hooks/live-signal.sh`, and two concurrent same-machine beats colliding on the origin's ref lock (a throttle race, untested, older than this round; the next beat refreshes it).

**Still not run: Task 7.** The by-hand web-session check was deferred, at the engineer's say-so, to #112 (filed from this round's QC); `/codeo:qc` grades the fourth acceptance criterion as deferred with that reason. Findings F3 (the web-session user label), F5 (a clock running ahead stretches the expiry) and F7 (the `SessionEnd` timeout against a slow `clear`) are the plan's design points and are unchanged.

## Log

- 2026-11-16 — round 2 (send-back from qc round 1): F1, F2, F4, F6, F8 fixed and reviewed, two fix rounds on the tests, root cause of the flaky live tests found (a non-monotonic clock), build exits 0 · cost: 24m · opus-5-5 526k in + 29k cached / 1k out · sonnet-5-5 265k in + 20M cached / 62k out

- 2026-11-16 — round 1: Tasks 1-6 built and reviewed, one fix round on Task 2, one whole-branch fix wave and re-review, build exits 0 · cost: 67m · sonnet-5-5 913k in + 33.2M cached / 185k out
