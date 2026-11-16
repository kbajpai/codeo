# Issue #104 — qc

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/104 |
| Branch | `feat/publish-live-session-signal-so` |
| Plan | `docs/plans/2026-11-15-live-session-signal.md` |
| Updated | 2026-11-16 |

## Where this stands

Round 1 done: the build and the full suite pass, four of the five acceptance criteria are met or settled by tests, and the fourth (a web session) is not yet checkable because the plan's by-hand Task 7 has not been run. The independent review found two defects serious enough to block the merge, and both are `/codeo:implement`'s. Sent back to `/codeo:implement`. No open question.

## Questions

None.

## Notes

- Nothing was fixed in this pass; no code, test, plan or documentation page was edited.
- The installed plugin's `sync-main.sh` (1.0.6) merged `origin/main` (#71, `738aaa4`) cleanly as `baf823a`, then exited 1 on its pre-#98 `comm` collation bug. The merge stands; the both-changed list was recomputed with byte-order sorting.
- No invariants file, no shared environment and no `wiki` module are configured, and the `qc` overlay sections `invariants-extra` and `wiki-rules` are absent (exit 3): the criteria and the conventions of the pages under `docs/` are the whole standard.

## Outcome

### Round 1 — 2026-11-16

**Sync.** `bash scripts/sync-main.sh --abort-on-conflict`: `sync-main: merged origin/main (1 commit(s))`, then three `comm: … not in sorted order` lines and exit 1 (the installed plugin's pre-#98 script; this branch's own `scripts/sync-main.sh` carries the fix). Recomputed with `LC_ALL=C comm -12` over both sides' changes since the merge base, four files changed on both sides, none conflicted (`git diff --diff-filter=U` empty), and each was re-checked against this branch's work:
- `sync-main: also changed on main: CHANGELOG.md` — the `Shared state:` line still carries `/codeo:cleanup`'s clause and ours; our bullet is intact.
- `sync-main: also changed on main: docs/handoff.md` — the *Who is working right now* bullet and its diagram are intact.
- `sync-main: also changed on main: docs/skills.md` — the triage `live:` clause is intact (line 224).
- `sync-main: also changed on main: skills/triage/SKILL.md` — the `live:` sentence is intact (line 114).

`overlap.sh 104` printed nothing; `overlap.sh --outside 104` printed nothing (no path outside the footprint).

**Scope.** `scope.sh origin/main HEAD`: `suite.shell=true` (the diff touches `scripts/**`, `hooks/**`, `tests/**`, `docs/**`, `skills/**`, and the unclassified paths `.codeo/104/*` and `CHANGELOG.md`). No `deploy=` line: no environment is configured.

**Build.** The `shell` suite's `build` is `true`: exit 0.

**Tests.** `bash tests/run.sh` (the `shell` suite, whole): `all cases passed`, exit 0.

**Acceptance criteria.**

| Criterion | Verdict | Settled by |
|---|---|---|
| While a codeo skill is working an issue, `inflight.sh` run from another clone shows that workflow as live, with the user and the machine | met — for every well-formed signal (see F1 for one that is not) | `tests/live.test.sh` `fetch_then_list_shows_a_live_session_from_another_clone`; `tests/inflight.test.sh` `human_block_shows_a_live_session` (`live:      bob on codeo-7 (container), 30s ago`); `tests/live-signal.test.sh` `beat_publishes_in_the_background` (the hook publishes) |
| After the session ends or crashes, the workflow stops showing as live within the documented expiry, with no manual step | met — as documented, with the caveats in F4 and F5 | `tests/live.test.sh` `list_hides_an_expired_signal_and_shows_it_again_inside_the_ttl`; `tests/inflight.test.sh` `an_expired_signal_prints_nothing`; `tests/live-signal.test.sh` `clear_deletes_the_ref` (clean exit) |
| Neither the feature branch nor its PR gains a commit from the signal | met | `tests/live.test.sh` `beat_adds_nothing_to_the_branch_or_the_pull_request` (origin's `refs/heads` byte-identical, `HEAD` and the tree unchanged); `scripts/live.sh` builds a parentless commit with `git commit-tree` and pushes only `refs/codeo/live/*` |
| It works in a web session | not yet checkable — the by-hand check (plan Task 7) has not been run; see F3 | the git and REST paths are tested against local origins and a stubbed `github.sh` only (`beat_falls_back_to_rest_when_the_push_is_refused`); nothing here reaches a hosted session or GitHub |
| `bash tests/run.sh` passes. `CHANGELOG.md` records the change | met | `bash tests/run.sh`: `all cases passed`; `CHANGELOG.md` line 7 (`Shared state:`) and the `## Unreleased` bullet naming #104 |

**Documentation check.** `docs/handoff.md` *Parallel workflows* (the new bullet and diagram), `docs/skills.md` (*triage* → *Reads and writes*), `skills/triage/SKILL.md` and `CHANGELOG.md` were checked against `scripts/live.sh`'s header and code. The names, numbers and formats match (the ref, 300/900/8 seconds, the four environment variables, the machine label, the `live:` and `live: unknown` lines, the `--live` columns). Two statements do not hold: F2 and F4. `docs/dossier.md` and `README.md` move nothing, as the plan says.

**Independent review** (opus, given the acceptance criteria and the diff only). Its assessment, quoted: "With fixes. The core mechanism meets the branch, PR, expiry and no-GraphQL requirements and is well tested, but there are three gaps. One bad signal can hide every other live session, the handoff doc promises a failure message the hook throws away, and the web-session criterion is unproven, with the user label likely naming the harness identity there." Its Critical list was empty. Everything it raised is classified below; its F1 was reproduced here (`bash -c 'b=09; echo $((1700000000 - b))'` prints `value too great for base (error token is "09")`) and its F2 was confirmed in `hooks/live-signal.sh:21`, which sends `beat`'s output to `/dev/null`.

**Findings.**

- **F1 — blocking, `/codeo:implement`'s.** `scripts/live.sh:189,193`: `list` accepts a `beat` that matches `^[0-9]+$`, so a zero-padded value such as `09` passes and `$((now - beat))` then reads it as octal and aborts the whole loop under `set -e`. Anyone with push access can plant such a ref (the code's own comment says every field is checked for exactly that), and it makes `live.sh list --tsv` and `inflight.sh --live` print only the signals before it and exit 1, and makes the human blocks silently drop every live session after it (`live_rows=$(… || true)`), which defeats the first criterion for the sessions behind it. Cause: the check allows leading zeros and the arithmetic is base-8. The same hole exists for `issue` (`0104` passes `^[0-9]{1,9}$` but never matches a block). Fix direction: accept only `^[1-9][0-9]{0,11}$` for `beat` and `^[1-9][0-9]{0,8}$` for `issue` (or force base 10), with a test that plants a zero-padded beat between two valid signals.
- **F2 — blocking, `/codeo:implement`'s.** `docs/handoff.md` (*Who is working right now*) says that where neither the push nor the REST write works "nothing is published and the session says so once". The code does not do that: `hooks/live-signal.sh:21` runs `live.sh beat` with stdout and stderr sent to `/dev/null`, so the one `live:` warning never reaches anyone. The sentence comes from the plan's Task 5 text, which the plan's own Task 4 design (a silent hook) cannot satisfy, so the plan is the origin; the smallest repair is a documentation edit that drops the claim, recorded as a deviation, and needs no re-plan. A page that states something the code does not do is read long after anyone remembers the issue.
- **F3 — non-blocking, `/codeo:plan`'s.** In a hosted web session `GET /user` is refused (`scripts/github.sh:29-35`), so the signal's user is `$CODEO_GITHUB_LOGIN` when set, else `git config user.name`, which there is the harness's identity and probably not the engineer. That is the design the plan's Q5 recorded and the engineer approved, so the code matches the plan, but nothing sets `CODEO_GITHUB_LOGIN` in a web session, and whether the proxy accepts a `git push` or the REST calls to `refs/codeo/` is unknown. This settles with the by-hand check (Task 7), whose result belongs in the next `implement.md` round; if the check shows the label is wrong or both writes are refused, that is the next round's input and this criterion reads `not met`.
- **F4 — non-blocking, `/codeo:implement`'s.** `docs/handoff.md` and `CHANGELOG.md` say a session idle for 15 minutes stops reading as live. Beats are throttled to one per 5 minutes, so the signal lapses 15 minutes after the last *published* beat, that is after 10 to 15 minutes of idleness. Say "within 10 to 15 minutes".
- **F5 — non-blocking, `/codeo:plan`'s.** `scripts/live.sh:194`: a `beat` in the future counts as age 0, so a crashed session whose clock ran ahead reads as live for that skew plus 15 minutes, and a planted far-future beat reads as live until someone deletes it. The plan's Global Constraints chose this ("a writer's clock ahead counts as age 0"); a cap would be a design decision, and the second criterion holds only when clocks agree. Noted for triage.
- **F6 — non-blocking, `/codeo:implement`'s.** `scripts/live.sh:139`: `codeo-live-message` is a fixed path in the git directory, and the throttle's check-then-write is not atomic, so two `PostToolUse` beats firing together can delete each other's message file. The other beat normally wins. Use a per-process file (`mktemp` in the git directory). Already ledgered as a deferred minor in `implement.md`.
- **F7 — non-blocking, `/codeo:plan`'s.** `hooks/hooks.json` gives `SessionEnd` a 10-second timeout while `clear` can take 8 seconds for the push `--delete` plus 8 for the REST delete, so the REST delete can be killed and the signal then only expires. The plan fixed both numbers. Noted for triage.
- **F8 — non-blocking, `/codeo:implement`'s.** `hooks/live-signal.sh:6` says the hook never judges the process directory; with no `jq` or no `cwd` in the JSON it falls back to `git -C .`, which is the process directory. Reword the header.

**Out of scope, recorded once.** The reviewer declined to judge, and nothing here changes: a local hostname on a public repository (the machine is named by requirement), a planted signal impersonating a user (information only, and only collaborators can push), an idle open session dropping off the listing (the criterion is "while a codeo skill is working").

**Filed.** No issue was filed by this pass.

**Routing.** F1 and F2 block the merge and are `/codeo:implement`'s; F4, F6 and F8 ride along in the same round as non-blocking polish (opening no round for them alone); F3, F5 and F7 are the plan's design points, noted for the engineer and for triage, and settle or not with Task 7. Before or while the next round runs, the engineer should run the plan's Task 7 (`bash scripts/live.sh beat --force` in a web session, `bash scripts/inflight.sh --live` from another clone, then `bash scripts/live.sh clear`) and record the three outputs in `implement.md`, since the web-session criterion cannot be graded without them.

**Verdict: back to `/codeo:implement`.**

## Log

- 2026-11-16 — round 1: build and full suite pass, criteria 1-3 and 5 met, criterion 4 not yet checkable, two blocking findings (F1, F2), sent back to `/codeo:implement` · cost: 5m · opus-5-5 533k in + 3.5M cached / 22k out · sonnet-5-5 33k in + 1.8M cached / 8k out
