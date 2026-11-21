# Issue #138 — plan

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/138 |
| Branch | `fix/live-session-signal-does-not` |
| Updated | 2026-11-21 |

## Where this stands

**Round 2, after a send-back from `/codeo:qc` round 1** (F1, F4, F11 and `tests/devcontainer.test.sh` missing from the footprint): Q10 is answered (a: the beat hook takes the lock, and the `SessionStart` group goes). The round is drafted to `.codeo/138/plan-draft.md` (not committed) and waits for the engineer's approval at the review gate; the round's plan file is written only after it. The state after round 1, kept for the record: Explored and brainstormed; nothing drafted. Q2 and Q4 are answered; Q1 chose a probe, whose output is Q5, and Q3 is restated as Q6. Q1-Q7 are answered. The probe showed that a web session can create a branch and force-push a new parentless commit over it, that deleting is refused, and that `gh api user` returns the login, so the design is a signal branch `codeo-live/<issue>/<machine>` that expires rather than being cleared. The footprint is recorded under `## Notes`, and `overlap.sh` found two overlaps, with #149 and #151 (Q8, Q9, open). Both are answered *proceed and coordinate*. The engineer approved the draft and the plan is written to `docs/plans/2026-11-21-live-signal-web-session-138.md` (unstaged, for review); the outcome is written and nothing is open. The Claude Code docs (read today) settle part of the intake's open list, so the questions below are narrower than the issue's: a push to a plain branch name is allowed, a push to a non-branch ref or a branch deletion is rejected, `enabledPlugins` plugins are not installed in a cloud session, and hooks in the repository's `.claude/settings.json` do run there. Next: review and commit the plan, then `/codeo:implement`, then re-invoke `/codeo:plan`.

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
Pasted by the engineer from a hosted session, 2026-11-21 (output reproduced in short; recorded here by the skill), on `fix/live-session-signal-does-not`:
- `git push origin HEAD:refs/heads/codeo-live/138/web-probe` — exit 0, `* [new branch] HEAD -> codeo-live/138/web-probe`.
- `git push origin --delete refs/heads/codeo-live/138/web-probe` — exit 1, `RPC failed; HTTP 403 curl 22 The requested URL returned error: 403`.
- `gh api user -q .login` — exit 0, `kbajpai`.
- `git config user.name` — exit 0, `Claude`.

### Q6 — Does your web environment's setup script run `lock.sh take web`, and does it pass a session id?

**Why it matters:** this is Q3 with options. Without a lock the hook does nothing; with `session: unknown` the machine label falls back to the hostname. It decides whether the plan adds a `SessionStart` hook to this repository's settings that runs `lock.sh take web <session id>`.

**Options:**
- **(a) It takes the lock and passes the session id.** The plan only reads the id when the lock lacks one.
- **(b) It takes the lock and passes no id.** The plan adds a `SessionStart` hook that runs `lock.sh take web <id>`, which refreshes `session: unknown`.
- **(c) It does not take the lock.** Same hook, and it takes the lock itself.
- **(d) Not sure.** The plan adds the hook; it is idempotent in every case above.

**Answer:**
(d) Not sure (engineer, in the conversation, 2026-11-21; recorded here by the skill).

### Q7 — Does the proxy accept a force-push of a new parentless commit over an existing branch?

**Why it matters:** Q5 showed that creating a branch works and deleting one is refused. A beat does neither: it replaces the previous signal with a new parentless commit by force-push, so a signal never accumulates history. That non-fast-forward update to an existing branch is the one step not yet seen working from a web session. If it is accepted, the plan builds the branch route as designed. If it is refused, a web session could publish once and never refresh, so the signal would expire after 15 minutes, and the plan has two choices to ask you about: no signal from a web session, or a signal branch whose beats each add one empty commit on top of the last (about 12 an hour, never deleted).

The probe branch from Q5 is still on origin, because the delete was refused. In a hosted session on this branch, run each as its own command and paste the output:

```
git hash-object -t tree -w /dev/null
git commit-tree 4b825dc642cb6eb9a060e54bf8d69288fbee4904 -m probe-signal
```

The second prints a commit id. Put it in place of `<id>` here:

```
git push --force origin <id>:refs/heads/codeo-live/138/web-probe
```

Then delete `codeo-live/138/web-probe` on GitHub (Branches page of `kbajpai/codeo`); nothing else of the probe is left behind.

**Answer:**
Pasted by the engineer from a hosted session, 2026-11-21 (recorded here by the skill): `git hash-object -t tree -w /dev/null` printed `4b825dc…`; `git commit-tree … -m probe-signal` printed `31c254941aa429bbccbb72d2ade2d71a376887f8`; `git push --force origin 31c2549…:refs/heads/codeo-live/138/web-probe` exited 0 with `+ 5f0f0ba...31c2549 … (forced update)` after a `warning: push negotiation failed; proceeding anyway with push`. A non-fast-forward update to an existing branch is accepted. The branch route is built as designed.

### Q8 — #149 also edits `docs/handoff.md` and `CHANGELOG.md`: proceed and coordinate, sequence after #149, or re-scope?

**Why it matters:** `overlap.sh` printed `149	glob:docs/handoff.md` and `149	glob:CHANGELOG.md`. #149 is branch `fix/close-non-blocking-findings-143`, assigned to kbajpai, at step `plan (working)`; its footprint lists both files, and neither has changed on its branch yet. This plan rewrites the *Who is working right now* bullet in `docs/handoff.md` and adds one `CHANGELOG.md` bullet. Two branches adding to the same file usually merge with a textual conflict that `scripts/sync-main.sh` stops on, and the later branch resolves it by keeping both. No `exclusive` resource is shared.

**Options:**
- **(a) Proceed and coordinate (recommended).** The two documentation tasks come last, run `bash scripts/sync-main.sh` first, and keep both sides on a conflict; the same call #112, #118 and #116 made.
- **(b) Sequence after #149.** Nothing starts until #149 merges.
- **(c) Re-scope.** Leave the `docs/handoff.md` and `CHANGELOG.md` edits out of this change and make them in a later one.

**Answer:**
(a) Proceed and coordinate (engineer, in the conversation, 2026-11-21: "Q8 (a)"; recorded here by the skill).

### Q9 — #151 also edits `CHANGELOG.md`: proceed and coordinate, sequence after #151, or re-scope?

**Why it matters:** `overlap.sh` printed `151	glob:CHANGELOG.md`. #151 is branch `docs/install-codeo-one-command-document`, assigned to kbajpai, at step `plan (working)`; its footprint lists `CHANGELOG.md`, which has not changed on its branch yet. This plan adds one bullet to it. The merge outcome is the one described in Q8.

**Options:**
- **(a) Proceed and coordinate (recommended).** As in Q8 (a).
- **(b) Sequence after #151.** Nothing starts until #151 merges.
- **(c) Re-scope.** Leave the `CHANGELOG.md` bullet out of this change.

**Answer:**
(a) Proceed and coordinate (engineer, in the conversation, 2026-11-21: "Q9 (a)"; recorded here by the skill).

### Q10 — Round 2: where should a hosted session's lock be taken?

**Why it matters:** `/codeo:qc` round 1 sent the plan back (`qc.md`, `### Round 1`: F1, F4, F11, and `tests/devcontainer.test.sh` missing from the footprint). F11 is the design question: in the engineer's hosted run (Task 7) `.codeo/active` did not exist at the start of the session, although `CLAUDE_CODE_REMOTE=true`, the checkout was on this branch and the repository's `SessionStart` hook was in the file; the same hook's command ran later in the session (probably on `resume`) and refreshed the lock's session id. So a session that starts on this branch publishes nothing until a lock is taken. Why `startup` did not run it is not known, and finding out costs another hosted run. The beat hooks do fire (`UserPromptSubmit`, `PostToolUse`), and the plugin's own `hooks/live-signal.sh` is what they run. Having that script take the lock when none exists makes the first prompt enough, in this repository and, since `hooks/hooks.json` runs the same script, in any project that installs the plugin: that also settles F4's substance (today installing the plugin alone publishes nothing).

**Options:**
- **(a) `hooks/live-signal.sh beat` takes the lock when none exists (recommended).** Only when `CLAUDE_CODE_REMOTE=true` and `.codeo/active` is missing, in the background with the beat, it runs `lock.sh take web <CLAUDE_CODE_REMOTE_SESSION_ID without cse_>` (idempotent; it may check out the dossier branch, as it already does at a start script) and then `live.sh beat`. The repository's own `SessionStart` group is dropped: the beat hooks cover it, and F9's stdout noise goes with it. The repository's `.claude/settings.json` keeps the gated beat groups, since cloud sessions do not install `enabledPlugins`; `docs/handoff.md` says a project needs either those groups or the plugin installed by the environment's setup script, and that either then takes the lock itself. One cost: a lock taken from a prompt hook can switch the checkout to the dossier branch mid-session when the session began elsewhere.
- **(b) The same, and keep the `SessionStart` group.** It still takes the lock early when `SessionStart` does run (on `resume` it did), at the price of F9's `lock:` lines reaching the session.
- **(c) Find out why `startup` did not run it first.** A diagnostic round in a hosted session (for example a hook that logs its environment and `cwd` to a file you read back) before the plan changes anything; no design change now, and F11 stays open until it is answered.

**Answer:**
(a) `hooks/live-signal.sh beat` takes the lock when none exists, and the repository's `SessionStart` group is dropped (engineer, in the conversation, 2026-11-21: "Q10 (a), per your recommendation"; recorded here by the skill).

## Notes

### Footprint

```
files:      .claude/settings.json, hooks/live-signal.sh, scripts/live.sh, skills/triage/SKILL.md, tests/live.test.sh, tests/live-signal.test.sh, tests/triage-skill.test.sh, tests/devcontainer.test.sh, docs/handoff.md, CHANGELOG.md, docs/plans/2026-11-21-live-signal-web-session-138.md, docs/plans/2026-11-21-live-signal-web-session-138-round-2.md
wiki:       none
exclusive:  none
sequenced:  none
```

**Round 2 calls made without a question** (send-back from `qc.md` round 1; correct any in an answer above):
- *F1:* for a web session the user chain ends at `unknown` after the assignee, with no `git config user.name` (Q2 answered (b) there); `tests/live.test.sh`'s `web_user_without_an_assignee_falls_to_git_user_name` becomes a case that expects `unknown`, and the sentence in `docs/handoff.md` follows.
- *F4:* `docs/handoff.md` says the groups in `.claude/settings.json` are this repository's own, and what another project needs (Q10's answer decides the wording).
- *F5:* a case runs the registered start-up command with `CLAUDE_CODE_REMOTE=true` and no session id (the lock then says `session: unknown`); under Q10 (a) the same case is written against `live-signal.sh`.
- *F7, F8:* one sentence each in `docs/handoff.md`: the assignee fallback names the issue's first assignee, and `CODEO_GITHUB_LOGIN` is read before `GET /user` for the signal.
- *F10:* `tests/devcontainer.test.sh` joins the footprint; with Q10 (a) so do `hooks/live-signal.sh` and `tests/live-signal.test.sh` (already in).
- *Not in this round (Q3 a in `qc.md`):* the fetch collision (F3), the leftover `codeo-live/*` branches (F2) and the fork case (F6) stay later work.
- *Shape:* a second plan file, `docs/plans/2026-11-21-live-signal-web-session-138-round-2.md`, with the tasks of this round only; the first plan stays as the record of what was built. Documentation moved: `docs/handoff.md` and `CHANGELOG.md` (the bullet gains the fixes); no wiki.
- *In flight:* #149 and #151 are at `qc` and still list `docs/handoff.md` and `CHANGELOG.md`; both overlaps were answered *proceed and coordinate* (Q8, Q9) and `overlap.sh` does not raise them again.

**Later work, not in this plan:** the `codeo-live/<issue>/web-<id>` branches a web session leaves on origin (the proxy refuses to delete them) need removing, by hand or by a later change; to file with `/codeo:issue` in the home checkout, which refuses here.

**Calls made without a question** (continued): `gh api user` works from a web session (Q5), so the issue's open item "whether `GET /user` is refused there" is answered: it is not, in that run. Q4's answer stays as decided; the assignee fallback then only matters where it is refused, and it costs one read.

**Calls made without a question** (correct any in an answer above):

- *Shape:* one plan under `docs/plans/`, one pull request, no reference doc. `engineering:system-design` and `engineering:architecture` are applied in the plan only as far as Q1's options table; the work changes one ref route, not a service boundary.
- *Tests:* `tests/live.test.sh` gains the web-session route, `tests/lock.test.sh` the lock taken with and without a session id, `tests/live-signal.test.sh` the hook block, all through the `shell` suite (`bash tests/run.sh`).
- *Documentation moved:* `docs/handoff.md` (*Who is working right now*) and `CHANGELOG.md`; no wiki module is configured.
- *Out of scope, as the issue says:* blocking or locking on liveness, and other findings of #104's QC and #118's leftovers.
- *In flight:* `inflight.sh --except 138` lists #151 and #149, both at `init` with no footprint and no changed files yet, so there is nothing to compare. The issue's note about #145 (`docs/handoff.md`) and #149 (`CHANGELOG.md`) is checked by `overlap.sh` once the footprint is written; any overlap becomes its own question then.
- *Unverified in the docs:* that `UserPromptSubmit`, `PostToolUse` and `SessionEnd` hooks in `.claude/settings.json` fire in a cloud session (the docs name `SessionStart` and say "the same hook events wherever it runs"), and that `gh api` REST writes other than `git/commits` are allowed. The plan's web-session task records both from the run, as #112 did for the writes.

## Outcome

**Plan:** `docs/plans/2026-11-21-live-signal-web-session-138.md` — 7 tasks, unstaged for review. **Shape:** a plan under `docs/plans/` only (the `REQUIRED SUB-SKILL` banner, Goal / Architecture / Tech Stack / Spec / Global Constraints / Review Focus, checkbox tasks), with a decision record and a sequence diagram folded in. No separate reference doc: `docs/handoff.md` carries what outlives the work. `engineering:system-design` and `engineering:architecture` were not installed; their structure (Context / Decision / Options / Trade-offs / Action items) is applied directly in the plan's decision record.

**What was decided** (Q1-Q9, from the probe in a hosted session):
- **Route (Q1 c, Q5, Q7).** A web session publishes to `refs/heads/codeo-live/<issue>/<machine>`: the probe showed a branch push and a force-push of a new parentless commit are accepted and a delete is refused (HTTP 403). Rejected: no signal from a web session; a chain of fast-forward signal commits (needed only had the force-push been refused).
- **Clearing.** A web signal is never deleted; it expires after the TTL, and `clear` is a no-op for it. The stale branches are later work (see `## Notes`).
- **Trigger (Q2 a).** Hooks in this repository's `.claude/settings.json`, active only when `CLAUDE_CODE_REMOTE=true`. Rejected: relying on `enabledPlugins` (cloud sessions do not install it) and documentation only. Beyond the question: no `SessionEnd` entry, since there is nothing to delete.
- **Lock and session id (Q3, Q6 d).** A `SessionStart` hook runs `lock.sh take web` with `CLAUDE_CODE_REMOTE_SESSION_ID` minus its `cse_` prefix; `live.sh` also reads that variable when the lock says `session: unknown`.
- **User (Q4 a).** `CODEO_GITHUB_LOGIN`, else `GET /user` (which worked in the probe), else for web the issue's assignee, else `git config user.name`.
- **Overlaps (Q8, Q9).** #149 on `docs/handoff.md` and `CHANGELOG.md`, #151 on `CHANGELOG.md`: proceed and coordinate for both; Tasks 5 and 6 run `sync-main.sh` first.
- **Tasks.** Tasks 1-6 are proved by `bash tests/run.sh`; Task 7, the hosted-session check, is `Runs on: the engineer's host` and last. No task needs a lease: no shared environment is configured.

**Documentation the plan changes:** `docs/handoff.md` → *Who is working right now* (and its diagram) and `CHANGELOG.md` (one bullet); `skills/triage/SKILL.md` gains a clause (code, not documentation). No wiki pages.

**Intake question resolved:** `GET /user` is not refused in a web session (Q5: `gh api user` returned `kbajpai`); whether a web session's start script passes a session id stays unknown, which the `SessionStart` hook makes unnecessary.

## Log

- 2026-11-21 — Q1-Q4 raised; nothing drafted · cost: counted in the planned line later
- 2026-11-21 — Q1, Q2, Q4 recorded from the conversation; Q3 unclear, restated as Q6; Q5-Q6 raised; nothing drafted · cost: counted in the planned line below
- 2026-11-21 — Q6 recorded (d); the probe output named for Q5 was not in the message, Q5 stays open; nothing drafted · cost: counted in the planned line below
- 2026-11-21 — Q5 recorded from the pasted probe (push ok, delete 403, login kbajpai); Q7 raised (force-push over an existing branch); nothing drafted · cost: counted in the planned line below
- 2026-11-21 — Q7 recorded (force-push accepted); footprint written; overlap.sh found #149 and #151, Q8-Q9 raised; nothing drafted · cost: counted in the planned line below
- 2026-11-21 — Q8, Q9 recorded (proceed and coordinate); draft written to plan-draft.md and presented for review; engineering:system-design and engineering:architecture not installed, their structure applied directly · cost: counted in the planned line below
- 2026-11-21 — planned: docs/plans/2026-11-21-live-signal-web-session-138.md · cost: 82m · fable-5-2 86k in + 802k cached / 6k out · sonnet-5-5 230k in + 4.7M cached / 56k out · no /codeo:issue filed; engineering:system-design and engineering:architecture unavailable
- 2026-11-21 — round 2: Q10 recorded (a); draft written to plan-draft.md and presented for review · cost: counted in the planned line later
- 2026-11-21 — round 2 (send-back from qc.md round 1): Q10 raised (where a hosted session's lock is taken); nothing drafted · cost: 1m · sonnet-5-5 6k in + 1.5M cached / 6k out
