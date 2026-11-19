# Issue #112 — plan

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/112 |
| Branch | `feat/verify-live-session-signal-hosted` |
| Updated | 2026-11-19 |

## Where this stands

Explored and brainstormed; nothing is drafted yet. Q1-Q5 are open and the plan waits on them. Answer under each `**Answer:**`, then run `/codeo:plan` again.

## Questions

### Q1 — How does your hosted web session get the codeo plugin, and at which version?

**Why it matters:** the fifth criterion ("once a release carrying the hook is pinned in a web session, the hook publishes without a manual `beat`") can only be checked if the web session has the plugin installed at v1.0.7 or later, since the hook runs from the installed plugin and not from the checkout. I cannot see this from the repository: `.claude/settings.json` enables `codeo@codeo` but declares no marketplace, and `scripts/lock.sh` mentions "a web session's start script" that is not in this repository. If the session installs v1.0.7 (what `.codeo/config.json` pins), the plan checks the hook in the same run as the manual `beat`. If it installs something older or nothing, the plan first has a task that moves the pin (or says how to install it), or records the hook criterion as "does not fire: no plugin in the session" and files the follow-up.
**Options:** none to pick from. Please say where the install happens (an environment setup script, a marketplace setting on your account, something else), which ref it installs, and whether that same script runs `lock.sh take web`.

**Answer:**

### Q2 — Should the check be a written procedure only, or also a script kept in the repository?

**Why it matters:** it decides whether this pull request adds a file and a test, or only the plan, the dossier and the documentation.
**Options:**
- **A written procedure only (recommended)** — the plan lists the commands; the web session's Claude runs them from one prompt the plan gives you to paste, with `bash -x scripts/live.sh beat --force` showing whether the push or the REST fallback carried the write. Nothing new ships in the plugin. The check is done once; if the proxy's rules change later, the procedure is still in the plan and in `.codeo/done/112/`.
- **A script, `scripts/live-check.sh`, with a test** — one command that publishes, reports which path carried it, checks the branch tip, clears, and prints a transcript. Repeatable after any proxy or release change, but it ships to every project that installs the plugin for a check only this repository's maintainer runs, and it needs its own test cases against a local origin.

**Answer:**

### Q3 — If the push works, should the check still try the REST fallback on its own?

**Why it matters:** the issue lists "whether the REST fallback is allowed by the session's credential" as its second unknown, but adds "which matters if the push is refused". `live.sh` only reaches REST when the push fails, so a run where the push succeeds says nothing about REST. Trying it costs one extra step and writes and deletes one extra ref (`refs/codeo/live/112/web-<8>-rest`) on origin; skipping it leaves the fallback unverified in the one place it was built for.
**Options:**
- **Try it directly (recommended)** — after the main run, `bash scripts/github.sh ref put refs/codeo/live/112/<label>-rest <message-file>` and then `ref delete`, both outputs recorded. A refusal is recorded with its text and filed as a follow-up, and does not make #104's criterion "not met" when the push works.
- **Only if the push is refused** — the check follows `live.sh` exactly and records REST as "not exercised" when the push carries the write.

**Answer:**

### Q4 — Where is the result recorded?

**Why it matters:** the issue says "in this issue (or the pull request that closes it)". It decides the last task of the plan and what `/codeo:qc` reads as evidence.
**Options:**
- **`.codeo/112/implement.md` and a summary comment on #112 (recommended)** — the full commands and output go in the dossier, which is on the branch, in the pull request's diff and archived at close; a short comment on the issue gives the four answers (push or REST, the user named, the hook, the tip unchanged) and links to it. `/codeo:qc` grades from the dossier.
- **`implement.md` only** — no comment; the pull request that closes #112 carries the record in its diff.
- **A comment on #112 only** — the full transcript as an issue comment; the dossier points at it.

**Answer:**

### Q5 — Should the documentation say what the check found?

**Why it matters:** `docs/handoff.md` (*Who is working right now*) today says "where a push to that ref is refused" without saying whether a web session is such a place, and nothing tells a web user to set `CODEO_GITHUB_LOGIN`. If yes, the plan has a documentation task and a `CHANGELOG.md` bullet whose exact words depend on the result (the plan states the sentence for each outcome). If no, the pull request holds only the plan and the dossier, and the plan says "no page moves" so `/codeo:qc` reads that as deliberate.
**Options:**
- **Yes: one or two sentences in `docs/handoff.md` and a `CHANGELOG.md` bullet (recommended)** — what carries the signal in a web session, which user it names there and how `CODEO_GITHUB_LOGIN` changes that, as facts about what the system does. A fix for anything that does not work stays out, per the issue.
- **No** — the record in the dossier and the issue is enough; any documentation change rides with the follow-up issues.

**Answer:**

## Notes

**What exists today.** `scripts/live.sh beat` builds one parentless empty-tree commit and force-pushes it to `refs/codeo/live/<issue>/<machine>`; when the push fails it calls `github.sh ref put` (`POST git/commits`, then `PATCH` or `POST git/refs`). It says nothing about which path carried the write, so the check needs `bash -x` to tell. The user is `github.sh user login` (`GET /user`, else `$CODEO_GITHUB_LOGIN`), else `git config user.name`. The machine for a `web` lock is `web-` and the first 8 characters of the lock's `session:`. `hooks/live-signal.sh` runs `beat` in the background on `UserPromptSubmit` and `PostToolUse` and discards its output. v1.0.7 carries all of it, and `.codeo/config.json` pins v1.0.7.

**Already known from this container.** GitHub itself accepts the ref: `inflight.sh --except 112` shows `live:` lines for #102, #108 and #122, published from dev containers. So the only unknowns are the web session's proxy, its credential, its `user.name`, and whether the plugin's hook runs there.

**Calls I am making unless told otherwise.**
- The web session is bound to this branch and this issue (`bash scripts/lock.sh take web` in a checkout of `feat/verify-live-session-signal-hosted`), so the signal it publishes is `refs/codeo/live/112/web-<8>`. This container may show as a second live session on #112 at the same time; that is two lines, which is the designed behaviour.
- The "other clone" that reads the signal is this dev container. `/codeo:implement` runs `bash scripts/inflight.sh --live` and `bash scripts/inflight.sh` here within a minute of your saying the web session has published.
- The web-session tasks are marked `Runs on: the engineer's host` because only you can open one. A hosted session is Linux with bash, so no shell question is asked and its commands are labelled `Shell: bash`.
- The user label is recorded first as the session has it, with `CODEO_GITHUB_LOGIN` unset or as found. Then one more `beat --force` runs with `CODEO_GITHUB_LOGIN=kbajpai` to record that the override reaches the signal. If the first run names something other than your login, that is recorded and a follow-up is filed with `/codeo:issue`, per the third criterion.
- The scripts under test are the branch's own (`bash scripts/live.sh` from the checkout), which match v1.0.7 for `live.sh`, `github.sh` and the hook. The hook check uses whatever the session has installed (Q1).
- Nothing the check finds is fixed here. Each finding (a refused push, a refused REST call, a wrong user, a hook that does not fire) becomes its own issue through `/codeo:issue`, and the plan names which criterion each one closes as "recorded and filed".
- One pull request. No `scripts/`, `hooks/` or `skills/` file changes unless Q2 is answered with the script.
- If both writes are refused, the plan's last task records the refusal text and states #104's criterion "it works in a web session" as not met, in the record chosen at Q4.

**Other workflows in flight** (`inflight.sh --except 112`, 2026-11-19). #102 at implement and #122 at qc both have `CHANGELOG.md` in their footprints, #122 and #108 have `docs/handoff.md`. They overlap with this plan only if Q5 is answered yes; the overlap questions are raised once the footprint is drafted. #132 is at `init` with no footprint yet.

## Outcome

_Pending — written at the hand-off._

## Log

- 2026-11-19 — raised Q1-Q5; nothing drafted
