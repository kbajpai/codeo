# Issue #181 — plan

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/181 |
| Branch | `feat/181-session-title-prefix-session-id` |
| Updated | 2026-11-28 |

## Where this stands

Round 1. Q1-Q5 are answered (every recommendation taken). The plan is drafted in `.codeo/181/plan-draft.md` and awaits the engineer's approval; nothing is written under `docs/plans/` before that.

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

## Notes

- Settled by the issue, not asked: the first number in a fresh clone is `00`; `<NN>` is two uppercase hex digits; a lock change keeps `<NN>`; outside a container the hook prints nothing.
- An old-shape title takes the next number when the hook first sees it, so a migrated session is numbered by when it was migrated, not by when it began.
- Concurrency: the number is taken under `flock` on the state file's lock (`/usr/bin/flock` is in the dev container image); the write is a temp file and a rename.
- One pull request. No shared environment, no wiki module, no exclusive resources and no invariants document are configured.

## Outcome

_Pending — written at the hand-off._

## Log

- 2026-11-28 — Q1-Q5 raised · cost: 1m · fable-5-2 82k in + 566k cached / 7k out
