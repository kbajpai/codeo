# Issue #181 — plan

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/181 |
| Branch | `feat/181-session-title-prefix-session-id` |
| Updated | 2026-11-28 |

## Where this stands

Round 1, done. Q1-Q6 are answered and the plan is approved: `docs/plans/2026-11-28-session-title-sequence-181.md`, left unstaged for review. Next step: `/codeo:implement`.

## Questions

### Q1 — Where is the counter kept?

**Why it matters:** it decides which file the hook reads and writes, what "per container" means on each route, and whether anything shows in `git status`. The issue asks that the count survive a container restart and that a fresh clone or volume start again at `00`.

- Inside the clone's git directory, at `$(git rev-parse --git-path codeo/session-seq)`. The clone is on the container's own volume on every route (VS Code, cmd mode, sbx sandbox), so `codeo-home` and each `codeo-<N>` count separately. It never shows in `git status` and needs no ignore entry. A fresh clone starts at `00`. It also survives a VS Code **Rebuild Container**, where `~/.claude` and the sessions are lost: the count then carries on from where it was, which is harmless.
- Under Claude Code's config directory (`${CLAUDE_CONFIG_DIR:-$HOME/.claude}/codeo-session-seq`), next to the sessions it numbers. In cmd mode that is on the volume (`/workspaces/.claude`). In VS Code it is not on a volume, so a rebuild restarts the count at `00` together with the lost sessions.
- In the work tree under `.codeo/`, kept out of `git status` through the clone's `info/exclude`, as `window-title.sh` does for `.vscode/settings.json`. It works, but the hook then also writes `info/exclude`, and the file sits beside the dossiers.

I recommend the clone's git directory.

**Options:** the clone's git directory (recommended) · Claude Code's config directory · `.codeo/` with an exclude entry · no preference, you pick.

**Answer:**
The clone's git directory, as recommended. Given in the conversation: "go with your picks".

### Q2 — How does a session keep its number?

**Why it matters:** it decides what the state file holds and when a number is spent. The title is the only place the number is visible, but the hook cannot always rely on it: after `/clear`, Claude Code ignores the `SessionStart` title and the session is titled by `UserPromptSubmit`, and any run that arrives without `session_title` for a session the hook already numbered would spend another number.

- Title first, then a ledger. The state file keeps one line per numbered session, `<NN> <session id>`, the last 256 of them. The hook keeps the `<NN>` of an existing title in the new shape whose `<id8>` is this session's; otherwise it looks the session id up in the ledger; otherwise it takes the next number and records it. A number is spent at most once per session id, whatever the title says. A forked session (inherited title, another id) and an old-shape title take the next number.
- Title only. The state file holds one number, the last one given. The hook keeps the `<NN>` of an existing new-shape title whose `<id8>` matches, and takes the next number in every other case. Simpler, but a run without `session_title` for an already numbered session spends a number and changes what the session is called.

In both, a `/rename`d session spends no number, and a number is taken only when the hook is about to print a title. I recommend title first, then a ledger.

**Options:** title first, then a ledger (recommended) · title only · no preference, you pick.

**Answer:**
Title first, then a ledger, as recommended. Given in the conversation: "go with your picks".

### Q3 — What does the hook print when it cannot use the counter?

**Why it matters:** the counter can fail where the title cannot: the state file is unwritable, `flock` is missing, or the lock is not released within the wait (the hook has a 10-second timeout; I plan a 2-second wait on the lock). Stderr stays empty and the exit status stays 0 either way; the question is what the session is called.

- The old shape, `<window title> · <id8>`. The session is still named after its container and its id, and because the old shape is recognised as the hook's own, the next run that can use the counter moves it to the new shape. A run that fails again prints nothing, since the title is already that.
- Nothing. The session keeps Claude Code's default title until a later run succeeds.

I recommend the old shape.

**Options:** the old shape (recommended) · nothing · no preference, you pick.

**Answer:**
The old shape, as recommended. Given in the conversation: "go with your picks".

### Q4 — #217 also changes `CHANGELOG.md` and `.devcontainer/README.md`. Proceed, sequence, or re-scope?

**Why it matters:** this plan adds one bullet to `CHANGELOG.md` and rewrites the session-title sentence in `.devcontainer/README.md`. #217 (`feat/217-add-codeo-go-codeo-done`, assignee kbajpai, at step `plan`, working) lists both files in its footprint. The shared paths are `CHANGELOG.md` and `.devcontainer/README.md`. The edits are in different places (its `codeo go` and `codeo done` commands, this one's session title), so the worst case is a small conflict in the changelog's list when the second pull request merges.

**Options:** proceed and coordinate (recommended) · sequence after #217 · re-scope.

**Answer:**
Proceed and coordinate, as recommended. Given in the conversation: "go with your picks".

### Q5 — Does the changelog entry go in `CHANGELOG.md`, or in a `changelog.d/181.md` fragment?

**Why it matters:** the acceptance criterion says `CHANGELOG.md` describes the new shape. #207 (`feat/207-stop-parallel-issues-colliding-shared`, at `qc`, sent back to `/codeo:plan` in round 1) replaces direct edits with one fragment per issue under `changelog.d/` and is not merged. The answer decides which file the documentation task names, and it would also remove the `CHANGELOG.md` overlap in Q4.

- `CHANGELOG.md`, as the criterion says and as `main` works today. If #207 merges first, the entry is moved to a fragment when this branch takes the new base.
- `changelog.d/181.md`, on the assumption that #207 merges first. If it does not, the file is read by nothing on `main`.

I recommend `CHANGELOG.md`.

**Options:** `CHANGELOG.md` (recommended) · `changelog.d/181.md` · no preference, you pick.

**Answer:**
`CHANGELOG.md`, as recommended. Given in the conversation: "go with your picks".

### Q6 — Overlap check on the written footprint: #217 shares `glob:CHANGELOG.md` and `glob:.devcontainer/README.md`. Proceed, sequence, or re-scope?

**Why it matters:** `overlap.sh` ran on the footprint as written and printed `217	glob:.devcontainer/README.md` and `217	glob:CHANGELOG.md`; it counts a pair as raised only when a question quotes the issue and the token, and Q4 did not. This is the same overlap Q4 answered with *proceed and coordinate*. #217 is `feat/217-add-codeo-go-codeo-done`, assignee kbajpai, at step `plan` (working). The plan edits the title bullet in `.devcontainer/README.md` and adds a `## Unreleased` section to `CHANGELOG.md`; #217's edits are to its `codeo go` and `codeo done` text. If you want the answer to be the same as Q4, "same as Q4" is enough.

**Options:** proceed and coordinate (recommended) · sequence after #217 · re-scope.

**Answer:**
Proceed and coordinate, as recommended. Given in the conversation: "go with ur picks".

## Notes

- Settled by the issue, not asked: the first number in a fresh clone is `00`; `<NN>` is two uppercase hex digits; a lock change keeps `<NN>`; outside a container the hook prints nothing.
- An old-shape title takes the next number when the hook first sees it, so a migrated session is numbered by when it was migrated, not by when it began.
- Concurrency: the number is taken under `flock` on the state file's lock (`/usr/bin/flock` is in the dev container image); the write is a temp file and a rename.
- One pull request. No shared environment, no wiki module, no exclusive resources and no invariants document are configured.

## Outcome

| | |
|---|---|
| Plan | `docs/plans/2026-11-28-session-title-sequence-181.md` (unstaged at the hand-off, for the engineer's review) |
| Shape | a plan under `docs/plans/`, three tasks; no reference doc, since nothing here is a standing decision beyond the hook's header comment |

**Decisions.**
- Counter kept in the clone's git directory, `codeo/session-seq` (Q1). Rejected: Claude Code's config directory (a VS Code rebuild would restart the count at `00` with the lost sessions) and `.codeo/` with an `info/exclude` entry (the hook would write `info/exclude` too).
- A ledger of `<NN> <session id>` lines, the last 256 kept; a session keeps the number in its own title, else the ledger's, else the next (Q2). Rejected: title only, which spends a second number when a run arrives without `session_title`. My call: a `SessionStart` with `source: resume` keeps the inherited title's number even when the id differs; Task 1 step 1 checks that against Claude Code's hook documentation before code depends on it.
- A counter failure prints the old shape `<window title> · <id8>`, silent when the title already is that (Q3). Rejected: printing nothing.
- The number is taken under `flock -w 2` on a lock file beside the state file; the write is a temp file and `mv`.
- Overlap with #217 on `CHANGELOG.md` and `.devcontainer/README.md`: proceed and coordinate (Q4, Q6). Rejected: sequencing after #217, re-scoping.
- The changelog entry goes in `CHANGELOG.md` under a new `## Unreleased` section (Q5). Rejected: a `changelog.d/181.md` fragment, since #207 is not merged.

**Documentation the plan changes.** `.devcontainer/README.md` (the session-title bullet) and `CHANGELOG.md`. `docs/container-templates.md` lists `session-title.sh` only as a file copied as it is, so it does not move. No wiki module.

**Intake questions resolved here.** None; intake left none open.

### Footprint

```
files:      .devcontainer/scripts/session-title.sh, tests/devcontainer.test.sh, .devcontainer/README.md, CHANGELOG.md, docs/plans/2026-11-28-session-title-sequence-181.md
wiki:       none
exclusive:  none
sequenced:  none
```

## Log

- 2026-11-28 — Q1-Q5 raised · cost: 1m · fable-5-2 82k in + 566k cached / 7k out
- 2026-11-28 — Q6 raised (overlap with #217) · cost: 23m · fable-5-2 91k in + 897k cached / 11k out · sonnet-5-5 109k in + 873k cached / 17k out
- 2026-11-28 — planned: docs/plans/2026-11-28-session-title-sequence-181.md · cost: 0m · sonnet-5-5 1k in + 277k cached / 807 out · the engineering plugin's skills (system-design, architecture) were not used: no new component or technology choice
