# Issue #138 — plan

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/138 |
| Branch | `fix/live-session-signal-does-not` |
| Updated | 2026-11-21 |

## Where this stands

Explored and brainstormed; nothing drafted. Q2 and Q4 are answered; Q1 chose a probe, whose output is Q5, and Q3 is restated as Q6. Q6 is answered (d); Q5 is open: the message that was to carry the probe output arrived without it. The Claude Code docs (read today) settle part of the intake's open list, so the questions below are narrower than the issue's: a push to a plain branch name is allowed, a push to a non-branch ref or a branch deletion is rejected, `enabledPlugins` plugins are not installed in a cloud session, and hooks in the repository's `.claude/settings.json` do run there. Next: paste the Q5 output here, then re-invoke `/codeo:plan`.

## Questions

### Q1 — Which route should a web session publish by: a branch under `refs/heads/`, nothing, or a probe first?

**Why it matters:** this is the design. The docs' GitHub-proxy section says the proxy "rejects branch deletions and pushes of anything other than a branch" and "doesn't limit which branches a push can update", which fits #112's run (a push to `refs/codeo/live/*` is not a branch, so HTTP 403). It says nothing on REST writes, and #112's `git/commits` write was refused. So a ref under `refs/heads/` is the one route the docs leave open, with two costs: `clear` cannot delete it (the signal only ages out after the TTL, as for a crash), and every web session leaves one more branch on origin, which `/codeo:triage` (branches with no PR) and `/codeo:cleanup` (branch gone from origin) would have to be taught to ignore. The reader's fetch also needs a second refspec. If the route is "nothing", criterion 1's second branch applies: the plan is documentation and a test that web sessions publish no signal, and Q2-Q4 shrink to what the documentation says.

**Options:**
- **(a) Publish to `refs/heads/codeo-live/<issue>/<machine>` from a web session (recommended, after (c) confirms it).** `live.sh` picks the ref by host: `web` uses the branch name, the others keep `refs/codeo/live/…`; `clear` is a no-op there; the reader fetches both namespaces; triage and cleanup skip `codeo-live/`.
- **(b) No signal from a web session.** Document it, make `live.sh beat` return quietly there, test that. Smallest change; a web session stays invisible to `inflight.sh`.
- **(c) Probe first.** Before drafting, you run the commands below in a hosted session on this branch and paste the output under the answer; the plan then follows (a) if the push works and (b) if not. #112 shows the docs and the real proxy can differ, and a plan built on the docs alone would be a guess.

  ```
  git push origin HEAD:refs/heads/codeo-live/138/web-probe
  git push origin --delete refs/heads/codeo-live/138/web-probe
  gh api user -q .login
  git config user.name
  ```
  (Run each as its own command. The first creates one throwaway branch on origin; the second should be refused if the docs are right, and then please delete the branch from GitHub by hand.)

**Answer:**
(c) Probe first (engineer, in the conversation, 2026-11-21: "Q1 (c) … per your recommendations"; recorded here by the skill). The probe output is asked for in Q5.

### Q2 — Where does the trigger live in a web session?

**Why it matters:** #112 found `codeo` absent in the session although `.claude/settings.json` enables `codeo@codeo`; the docs now say why: a cloud session does not install `enabledPlugins` plugins, and has no `/plugin`. They also say hooks in the repository's `.claude/settings.json` do run in a single-repository session. So this repository can carry its own trigger, but only for itself: a project that merely installs the plugin has no `hooks/live-signal.sh` in its checkout.

**Options:**
- **(a) A hook block in this repository's `.claude/settings.json` (recommended).** `UserPromptSubmit`/`PostToolUse` beat and `SessionEnd` clear, running `${CLAUDE_PROJECT_DIR}/hooks/live-signal.sh`. Works in this repository's web sessions with no install. The documentation says other projects need the plugin installed by the environment's setup script. In the dev container both this block and the plugin's hook fire; the stamp throttles the second to a no-op, and a test says so.
- **(b) Documentation only.** Say the signal needs the plugin installed by the environment's setup script (your Q1 answer on #112 said that is how you install it), and ship no hook. #112 shows it was not installed in the run; nothing in this repository would change that.
- **(c) Both (a) and the documentation of (b).** Same code as (a); the handoff page also says what other projects do.

**Answer:**
(a) A hook block in this repository's `.claude/settings.json` (engineer, in the conversation, 2026-11-21; recorded here by the skill).

### Q3 — Does your web environment's setup script run `lock.sh take web`, and does it pass a session id?

**Why it matters:** the hook does nothing without `.codeo/active`, and a lock written with no id says `session: unknown`, which gave the machine `vm` in #112 (that run took the lock by hand with no id, so it did not test a real start script). The docs list `CLAUDE_CODE_REMOTE_SESSION_ID` (a `cse_…` value) as set in cloud sessions, and hooks also get `session_id` on stdin, but do not say whether a setup script sees either. If your script takes the lock with an id, the plan only needs `live.sh` to read the id when the lock lacks one. If it takes none, or none with an id, the plan adds a `SessionStart` hook to this repository's settings that runs `lock.sh take web <session id>` (idempotent; `lock.sh` already refreshes `session: unknown` to a real id). Either way the machine label is built from the id with its `cse_` prefix removed, since the first 8 characters of `cse_…` carry only 4 of the id's own, and the label comes from `CLAUDE_CODE_REMOTE_SESSION_ID` (`CLAUDE_CODE_SESSION_ID` changes on `/clear`, which would rename the machine mid-session). Both are my calls; say so if you disagree.

**Options:** none to pick from; please say what the script runs, or paste it with secrets removed.

**Answer:**
The reply was "Q3 (b)", but Q3 had no lettered options, so it is not recorded as an answer to anything. Q6 restates the question with options.

### Q4 — What user should a web session's signal name, given `GET /user` is refused?

**Why it matters:** the criterion is the engineer's GitHub login, not `Claude`. `github.sh` documents `GET /user` as refused on a web session's proxy credential, and #112 never recorded what `user login` printed there; the docs say nothing on the default `user.name` or the login.

**Options:**
- **(a) `CODEO_GITHUB_LOGIN` and the issue's assignee (recommended).** `github.sh user login` already honours `CODEO_GITHUB_LOGIN`; the plan adds, for a web session only, a fallback to the bound issue's assignee (`issue view`, a repository-scoped read that works through the proxy; `init` assigns the engineer). The variable wins, so a different engineer on the issue sets it. The assignee can be someone other than the person at the keyboard, and the documentation says so. Falls to `git config user.name` last, as now.
- **(b) `CODEO_GITHUB_LOGIN` only.** You set it once in the environment's variables; no repository change beyond documentation. A web session without it names `Claude`, which fails the criterion silently.
- **(c) The assignee only.** No setting to remember, but a wrong name for anyone who did not claim the issue.

**Answer:**
(a) `CODEO_GITHUB_LOGIN`, then the issue's assignee, then `git config user.name` (engineer, in the conversation, 2026-11-21; recorded here by the skill).

### Q5 — Probe output from a hosted web session

**Why it matters:** Q1 chose to probe before drafting. The plan follows the branch route if the first push succeeds and the "no signal" route if it is refused, and Q4's answer depends on whether `gh api user` works there. Nothing is drafted until this is answered.

In a hosted session on this branch, run each of these as its own command and paste the output, with any token removed:

```
git push origin HEAD:refs/heads/codeo-live/138/web-probe
git push origin --delete refs/heads/codeo-live/138/web-probe
gh api user -q .login
git config user.name
```

The first creates one throwaway branch on origin; if the second is refused, delete that branch from GitHub by hand. If the session cannot run them, say so and the plan takes the "no signal" route with the docs as its only evidence.

**Answer:**

### Q6 — Does your web environment's setup script run `lock.sh take web`, and does it pass a session id?

**Why it matters:** this is Q3 with options. Without a lock the hook does nothing; with `session: unknown` the machine label falls back to the hostname. It decides whether the plan adds a `SessionStart` hook to this repository's settings that runs `lock.sh take web <session id>`.

**Options:**
- **(a) It takes the lock and passes the session id.** The plan only reads the id when the lock lacks one.
- **(b) It takes the lock and passes no id.** The plan adds a `SessionStart` hook that runs `lock.sh take web <id>`, which refreshes `session: unknown`.
- **(c) It does not take the lock.** Same hook, and it takes the lock itself.
- **(d) Not sure.** The plan adds the hook; it is idempotent in every case above.

**Answer:**
(d) Not sure (engineer, in the conversation, 2026-11-21; recorded here by the skill).

## Notes

**Calls made without a question** (correct any in an answer above):

- *Shape:* one plan under `docs/plans/`, one pull request, no reference doc. `engineering:system-design` and `engineering:architecture` are applied in the plan only as far as Q1's options table; the work changes one ref route, not a service boundary.
- *Tests:* `tests/live.test.sh` gains the web-session route, `tests/lock.test.sh` the lock taken with and without a session id, `tests/live-signal.test.sh` the hook block, all through the `shell` suite (`bash tests/run.sh`).
- *Documentation moved:* `docs/handoff.md` (*Who is working right now*) and `CHANGELOG.md`; no wiki module is configured.
- *Out of scope, as the issue says:* blocking or locking on liveness, and other findings of #104's QC and #118's leftovers.
- *In flight:* `inflight.sh --except 138` lists #151 and #149, both at `init` with no footprint and no changed files yet, so there is nothing to compare. The issue's note about #145 (`docs/handoff.md`) and #149 (`CHANGELOG.md`) is checked by `overlap.sh` once the footprint is written; any overlap becomes its own question then.
- *Unverified in the docs:* that `UserPromptSubmit`, `PostToolUse` and `SessionEnd` hooks in `.claude/settings.json` fire in a cloud session (the docs name `SessionStart` and say "the same hook events wherever it runs"), and that `gh api` REST writes other than `git/commits` are allowed. The plan's web-session task records both from the run, as #112 did for the writes.

## Outcome

_Pending — written at the hand-off._

## Log

- 2026-11-21 — Q1-Q4 raised; nothing drafted · cost: counted in the planned line later
- 2026-11-21 — Q1, Q2, Q4 recorded from the conversation; Q3 unclear, restated as Q6; Q5-Q6 raised; nothing drafted
- 2026-11-21 — Q6 recorded (d); the probe output named for Q5 was not in the message, Q5 stays open; nothing drafted
