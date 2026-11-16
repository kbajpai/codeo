# Issue #104 — implement

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/104 |
| Branch | `feat/publish-live-session-signal-so` |
| Plan | `docs/plans/2026-11-15-live-session-signal.md` |
| Updated | 2026-11-16 |

## Where this stands

Round 1 done: Tasks 1-6 of the plan are built, each passed its own spec-and-quality review, and one whole-branch review plus one fix wave and its scoped re-review followed. The build step (the `shell` suite's `build`, `true`) exits 0. Task 7, the by-hand web-session check, is the engineer's and has not been run. No open question.

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

## Log

- 2026-11-16 — round 1: Tasks 1-6 built and reviewed, one fix round on Task 2, one whole-branch fix wave and re-review, build exits 0 · cost: 67m · sonnet-5-5 913k in + 33.2M cached / 185k out
