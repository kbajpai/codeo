# Issue #138 — qc

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/138 |
| Branch | `fix/live-session-signal-does-not` |
| Updated | 2026-11-21 |

## Where this stands

Round 1 ran to the point of a verdict. Q1-Q3 are answered (run Task 7 first; drop the `git config user.name` fallback for a web session; the fetch collision and leftover branches are later work). The build and the full `shell` suite pass, the independent review is in, and every finding is classified under `## Notes`. Q4 is open: the hosted-session evidence for criteria 1 and 4. No verdict is written while a question is open. Next: run Task 7 and answer Q4, then re-invoke `/codeo:qc`, which re-runs the pass from the start; it is expected to route back to `/codeo:plan` (F4 blocking, and Q2 (b) changes the plan's user chain).

## Questions

### Q1 — Criteria 1 and 4 can only be settled in a hosted session. Settle them before a verdict, or clear with the check pending?

**Why it matters:** criterion 1 (the workflow shows live in `inflight.sh --live` on another clone) and criterion 4 (it publishes without a manual `beat`, the trigger being present in a web session) need a real hosted session. Plan Task 7 is that check, and it is the engineer's: it has not been run. Every test here uses a local origin and stubs, so neither criterion has evidence from a web session, and the docs record two things as unverified: that `UserPromptSubmit` and `PostToolUse` hooks from `.claude/settings.json` fire in a cloud session, and that `SessionStart` runs `lock.sh take web` there. A clear verdict on code alone would state those criteria as met without evidence.

**Options:**
- **(a) Run Task 7 first (recommended).** You start a hosted session on this branch, send one prompt with no manual `beat`, run `bash scripts/inflight.sh --live` here, and paste the row (or the failure) under this answer; this pass then re-runs and settles both criteria on that evidence.
- **(b) Clear without it.** Both criteria read *not yet checkable* in the round, the verdict is decided on the other findings, and Task 7 is run after the pull request opens.

**Answer:**
(a) Run Task 7 first (engineer, in the conversation, 2026-11-21: "Q1 (a) … per your recommendations"; recorded here by the skill). The evidence is asked for in Q4.

### Q2 — A web signal can still name `Claude`. Accept that, or change the fallback?

**Why it matters:** criterion 5 says the signal names the engineer's GitHub login, "not the harness identity". For a web session `user_label` (`scripts/live.sh:136-142`) tries `CODEO_GITHUB_LOGIN`, then `GET /user`, then the issue's first assignee, then `git config user.name`, which a web session holds as `Claude` (Q5 of the plan dossier). `GET /user` worked in the probe, so the last step is reached only when all three fail. You chose that chain (plan Q4 a), so the code matches the plan; the question is whether the plan's last step is acceptable against the criterion. Test `web_user_without_an_assignee_falls_to_git_user_name` (`tests/live.test.sh:650`) and a sentence in `docs/handoff.md` pin it.

**Options:**
- **(a) Accept it.** Non-blocking; the degraded case shows `Claude`, which is visibly not a person.
- **(b) Drop `git config user.name` for a web session (recommended).** The user falls to `unknown`; a send-back changes the plan's Q4 chain, the test and the handoff sentence. Criterion 5 then holds in every case.

**Answer:**
(b) Drop `git config user.name` for a web session (engineer, in the conversation, 2026-11-21: "Q2 (b)"; recorded here by the skill). F1 is therefore blocking, and the plan's Q4 chain changes.

### Q3 — Fix the fetch collision and the branch pile-up in this change, or file them as later work?

**Why it matters:** two review findings are not blocking but touch the design. (1) `live.sh fetch` (`scripts/live.sh:205`) maps `refs/codeo/live/*` and `refs/heads/codeo-live/*` onto the one destination; when both hold the same `<issue>/<machine>` git aborts the fetch (`fatal: Cannot fetch both …`, rc 128, reproduced by the reviewer and by the implement round's review), and `inflight.sh` then prints `live: unknown` for every reader for as long as the never-deleted web branch exists. It needs equal labels, for example `CODEO_MACHINE` set alike in a web environment and a container. (2) Each web session leaves a `codeo-live/<issue>/web-<id>` branch that nothing removes; triage now hides them. If you want either in this change, the send-back goes to `/codeo:plan` (a plan round with new tasks); otherwise they stay as later work for `/codeo:issue`.

**Options:**
- **(a) Later work for both (recommended).** Neither is reachable on the normal path; each is filed from the home checkout.
- **(b) Fix the collision here, file the pile-up.** Web branches fetch into their own namespace (for example `refs/codeo/live-web/*`) and `list` reads both.
- **(c) Fix both here.** (b) plus a cleanup step that removes finished issues' `codeo-live/<N>/*` branches.

**Answer:**
(a) Later work for both (engineer, in the conversation, 2026-11-21: "Q3 (a)"; recorded here by the skill). F2 and F3 stay non-blocking.

### Q4 — Task 7's hosted-session evidence

**Why it matters:** Q1 chose to run Task 7 before a verdict, so criteria 1 and 4 are settled on a real run. The verdict itself is already determined: F4 is blocking and Q2 (b) changes the plan's user chain, so the route is back to `/codeo:plan`. The run decides how criteria 1 and 4 read in the round, and whether the plan round must also fix the hooks (if they do not fire, or `SessionStart` takes no lock, in a hosted session). Nothing is written to the round until it is answered.

Steps (the branch tip on origin is `659e071` or later):
1. Start a new hosted session on `kbajpai/codeo`, on the branch `fix/live-session-signal-does-not`.
2. Send it one prompt: `Run "cat .codeo/active" and show me the raw output.` Do not run any `beat`.
3. Paste that output under this answer (it shows whether `SessionStart` took the lock, and with which session id), and say when you sent the prompt.
4. Reply here that it is done. I then run `bash scripts/inflight.sh --live` and `git ls-remote origin 'refs/heads/codeo-live/*'` in this container and record the rows.
5. After at least 5 minutes, send one more prompt in the same session (anything), and say so. I run the same two commands again to see the signal refreshed in place.
6. Afterwards, delete the `codeo-live/138/*` branches on GitHub (Branches page of `kbajpai/codeo`); the earlier probe branch `codeo-live/138/web-probe` too, if it is still there.

If the hosted session cannot run the prompt, or the file is missing, say so and paste what it printed; that is itself the evidence.

**Answer:**

## Notes

**Task 7 evidence so far** (pasted by the engineer from hosted sessions, 2026-11-21; recorded by the skill; Q4 stays open). First session: on a stale checkout (`4b55d8e`, #112's old branch, gone from origin), `.codeo/active` absent — no evidence about this branch's hooks. Second session, 19:3x UTC, branch selected correctly: `git branch --show-current` printed `fix/live-session-signal-does-not`, `git log --oneline -1` printed `7777c6f docs(codeo): qc dossier for #138 — Q1-Q3 answered, Q4 raised`, and `cat .codeo/active` printed `cat: .codeo/active: No such file or directory`. So on the right checkout the repository's `SessionStart` hook did not leave a lock. Cause not yet known (the hook not running in a cloud session, `CLAUDE_CODE_REMOTE` not `true` where the hook runs, or `lock.sh take web` failing); diagnosed with the commands under Q4's follow-up. Origin shows no `codeo-live/138/web-*` branch.

**Task 7 evidence, continued** (same session, pasted by the engineer; recorded by the skill). `printenv CLAUDE_CODE_REMOTE` printed `true`; `printenv CLAUDE_CODE_REMOTE_SESSION_ID | cut -c1-8` printed `cse_01Sa`; `jq -r '.hooks.SessionStart[].hooks[].command' .claude/settings.json` printed the two commands (`session-title.sh`, and the gated `lock.sh take web "${CLAUDE_CODE_REMOTE_SESSION_ID#cse_}"`), so the checkout carries the hook as committed. `bash scripts/lock.sh take web` run by hand printed `lock: took the lock for #138 on fix/live-session-signal-does-not`, and `cat .codeo/active` then read `issue: 138`, `branch: fix/live-session-signal-does-not`, `started: 2026-11-21`, `host: web`, `session: unknown`. Checked here at 19:33:25Z, after that manual take and the session's later tool calls and prompts: `git ls-remote origin 'refs/heads/codeo-live/*'` listed `refs/heads/codeo-live/138/web-01Sa1Zqb` (tip `947d492…`) beside the old probe branch; `bash scripts/inflight.sh --live` listed `138	kbajpai	web-01Sa1Zqb	web	76`; the signal commit (fetched, one commit, parentless) says `issue: 138`, `user: kbajpai`, `machine: web-01Sa1Zqb`, `host: web`; and the feature branch's tip on origin was `edf3410`, my own dossier push, so the signal did not move it.

What that settles: criterion 1 (the workflow shows live in `inflight.sh --live` on another clone), criterion 3 (tip unchanged) and criterion 5 for the web session (the login `kbajpai`, machine `web-` plus 8 characters; here from `CLAUDE_CODE_REMOTE_SESSION_ID`, since the manual lock said `session: unknown`) are met by this run; the `UserPromptSubmit` and `PostToolUse` hooks from `.claude/settings.json` fire in a cloud session and publish without a manual `beat` once a lock exists. What it does not: **the `SessionStart` hook left no lock** — in a correctly checked-out session with `CLAUDE_CODE_REMOTE=true` and the hook present in the file, `.codeo/active` did not exist until `lock.sh take web` was run by hand. So criterion 4 ("publishes without a manual `beat`, and the trigger is present in a web session") holds for the beats but not for taking the lock: a session that starts on this branch publishes nothing until something takes the lock. Why `SessionStart` did not do it is not known from this run (not run in a cloud session, run before the checkout was on this branch, or failed silently under `|| true`). F11 below.

Still to see: the refresh in place after 5 minutes (the hook's force-push over the existing branch).

**Commands run this pass, with their output**
- `bash scripts/sync-main.sh --abort-on-conflict`: `sync-main: the branch already contains origin/main`, exit 0. `bash scripts/overlap.sh 138`: nothing, exit 0.
- `git diff origin/main...HEAD --stat`: 14 files, 862 insertions, 39 deletions (code and tests: `.claude/settings.json`, `scripts/live.sh`, `skills/triage/SKILL.md`, `tests/devcontainer.test.sh`, `tests/live-signal.test.sh`, `tests/live.test.sh`, `tests/triage-skill.test.sh`; docs: `docs/handoff.md`, `CHANGELOG.md`; the rest `.codeo/` and `docs/plans/`).
- `bash scripts/scope.sh origin/main HEAD`: `scope: suite shell needed for unclassified paths:` (`.claude/settings.json`, `.codeo/138/…`, `CHANGELOG.md`, …) and `suite.shell=true`, exit 0. No environment is configured, so there is no `deploy=` line and no environment step.
- Build: the `shell` suite's `build` is `true`, rc 0.
- Test: `bash tests/run.sh` (the whole suite, since the diff changes its code and tests): rc 0, last line `all cases passed`.
- `bash scripts/overlay.sh qc invariants-extra` and `qc wiki-rules`: exit 3 (none). No invariants file is configured.
- `bash scripts/overlap.sh --outside 138`: `tests/devcontainer.test.sh`.
- Independent review (opus, `QC review:`) of `956a86f..3decf19` with the seven acceptance criteria as its requirements: no Critical; four Important; five Minor; "Ready to merge? With fixes". Its two checks that I repeated hold: `user_label` ends at `git config user.name` for a web session, and `hooks/hooks.json` has no `SessionStart` entry.

**Acceptance criteria, as far as this pass got** (no verdict until Q1-Q3 are answered)

| # | Criterion | Provisional verdict | Settled by |
|---|---|---|---|
| 1 | Shows live in `inflight.sh --live` on another clone, or documented as not | not yet checkable — needs a hosted session (Q1) | `fetch_maps_web_branches_to_signals` covers the local-origin path |
| 2 | No write that returned 403 in #112 | met | `web_beat_publishes_a_branch_not_a_live_ref` (no `refs/codeo/live`, no `ref put`), `scripts/live.sh:153,181-185` |
| 3 | Feature branch tip unchanged | met | the same case compares `refs/heads/feat/x` before and after |
| 4 | Publishes without a manual `beat`; trigger present in a web session | not yet checkable — needs a hosted session (Q1) | `settings_beat_hook_publishes_in_a_web_session` runs the registered command locally |
| 5 | Names the engineer's login and `web-<8>` | `web-<8>` met; login depends on Q2 | `web_machine_*`, `user_env_login_wins`, `web_user_falls_back_to_the_assignee`, `web_user_without_an_assignee_falls_to_git_user_name` |
| 6 | `docs/handoff.md` matches | met for this repository; see F4 | `docs_state_the_web_session_signal` |
| 7 | Tests cover the web behaviour, the lock with and without a session id | met in part; see F5 | the live cases cover the label with and without an id; the hook's lock take is tested only with an id |

**Findings, classified** (every finding points at a line this change touched)
- **F1 — non-blocking, pending Q2; the plan's (its Q4 chain).** A web signal can name `Claude`: `scripts/live.sh:136-142`, `tests/live.test.sh:650`, `docs/handoff.md:188-191`. Blocking if Q2 is answered (b).
- **F2 — non-blocking; the plan's accepted trade-off, later work unless Q3 says otherwise.** Web signal branches accumulate on origin and nothing removes them (`scripts/live.sh:197`, `skills/triage/SKILL.md:177`).
- **F3 — non-blocking; the plan's design (two sources onto one destination), pending Q3.** `scripts/live.sh:205`: a label collision aborts `fetch` for every reader.
- **F4 — blocking; the plan's.** `docs/handoff.md:173-176`: "a project that only installs the plugin needs the environment's setup script to install it" leaves no signal, because `hooks/hooks.json` has no `SessionStart` lock take and `live-signal.sh` exits without `.codeo/active`; and "the repository's own hooks" reads as if every project had them, when only this repository's `.claude/settings.json` does. The code follows the plan; the plan's Q2 premise was wrong for other projects. Cause checked in the files; not a failing test.
- **F5 — non-blocking; the plan's (Task 4 listed only the with-id case).** No test runs the registered `SessionStart` command with `CLAUDE_CODE_REMOTE=true` and no session id (`tests/live-signal.test.sh:256-277`); the lock would say `session: unknown`.
- **F6 — non-blocking; later work.** A forked or resumed web session keeps the first session's id in the lock (`lock.sh` refreshes only `session: unknown`), so two sessions share one `codeo-live/<N>/web-<id>` branch.
- **F7 — non-blocking.** `assignees[0]` may name a co-assignee (`scripts/live.sh:131`); worth a sentence in `docs/handoff.md`.
- **F8 — non-blocking.** `CODEO_GITHUB_LOGIN` is read before `GET /user` in `live.sh:135-136` but after it in `github.sh user_login` (`github.sh:35-41`), so for a container with the variable set the signal and `init`'s assignee can name different logins; documented for the signal, not reconciled.
- **F9 — non-blocking.** `lock.sh take web` prints `lock: …` lines on `SessionStart` stdout (`.claude/settings.json:22`), which a hook adds to the session's context; probably harmless.
- **F10 — non-blocking on a first-round plan; the plan's (the work needs the file).** The branch changed `tests/devcontainer.test.sh`, which the footprint does not list: the new hook groups broke its exact-match assertion, so the file had to change. Only a new plan round can add the path, and from `### Round 2` on it blocks the pull request.

- **F11 — blocking; the plan's.** The repository's `SessionStart` hook (`.claude/settings.json`, the `lock.sh take web` group) left no lock in a hosted session (Task 7 evidence above), so a session that starts on this branch publishes nothing until the lock is taken by hand. The code does what the plan says; the plan's premise that a `SessionStart` hook would take the lock was not borne out, and the fix is a design choice (for example taking the lock from the beat hook itself when `CLAUDE_CODE_REMOTE=true` and no lock exists, or finding why `SessionStart` did not run), so it is the plan's.

**Later work, to file with `/codeo:issue` in the home checkout** (it refuses here): the fetch collision (F3) and the leftover `codeo-live/*` branches (F2), unless Q3 brings them into this change; both are already recorded in `implement.md`.

## Outcome

_Pending — written at the hand-off._

## Log

- 2026-11-21 — round 1 stopped at step 10: build and the full suite pass, review in, Q1-Q3 raised · cost: 6m · opus-5-5 408k in + 2.7M cached / 18k out · sonnet-5-5 31k in + 624k cached / 3k out
- 2026-11-21 — Q1-Q3 recorded from the conversation (a, b, a); Q4 raised for Task 7's hosted-session evidence; no verdict · cost: 20m · opus-5-5 408k in + 2.7M cached / 18k out · sonnet-5-5 85k in + 2.3M cached / 13k out
