# Issue #45 — plan

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/45 |
| Branch | `feat/dev-container-title-each-claude` |
| Updated | 2026-11-08 |

## Where this stands

Round 1. Q1-Q3 answered (all three recommendations accepted); the plan is being drafted.

What the code and Claude Code do today:

- `.devcontainer/scripts/window-title.sh --print` prints the container title alone (`codeo [home]` or
  `codeo [#<N>]`, from `.codeo/config.json`'s `codename` and the `issue:` line of `.codeo/active`). #44
  wrote it for exactly this issue to call. It runs at container start; it does not re-run when the lock is
  taken mid-session (#44 Q2's decision).
- `.claude/settings.json` in this repository (tracked, project scope) holds only `enabledPlugins`. No hook is
  registered anywhere in the repository. The `shell` suite's `paths` cover `.devcontainer/**` but not
  `.claude/**`.
- Claude Code 2.1.319 is installed here. Its hooks reference (code.claude.com/docs/en/hooks) documents:
  - `SessionStart` hook stdout `{"hookSpecificOutput":{"hookEventName":"SessionStart","sessionTitle":"…"}}`
    sets the title "with the same effect as `/rename`" — but **"applies when `source` is `startup`,
    `resume`, or `fork`"**, not `clear`. The binary carries the strings `Hook sessionTitle applied`,
    `Hook sessionTitle cached`.
  - `UserPromptSubmit` hooks accept the same `sessionTitle` field (under `hookEventName: "UserPromptSubmit"`).
  - Both hooks receive `session_title` on stdin when a custom title is already set (`/rename`, `--name`, an
    earlier hook), documented as the way for a hook "to avoid overwriting an existing custom title". An
    auto-generated (AI) title is not a custom title and does not appear there.
  - Stdin also carries `session_id`, `source`, `transcript_path`, `cwd`, `hook_event_name`. `source` is one
    of `startup`, `resume`, `clear`, `compact`, `fork`; the `matcher` is a `|`-list of those.
  - `SessionStart` has no blocking control: exit 2 shows stderr to the user, other non-zero exits are a
    non-blocking error, and plain-text stdout on exit 0 is added to the model's context — so the hook must
    print exactly one JSON object or nothing.
  - `${CLAUDE_PROJECT_DIR}` in the command resolves to the project root and is exported to the hook.
- VS Code sets `REMOTE_CONTAINERS=true` inside the container (checked here); that is the gate the reference
  project used, and the one this plan will use for "outside a dev container nothing changes".

## Questions

### Q1 — Where is the hook registered: the tracked `.claude/settings.json`, or the user settings the start script writes?

**Why it matters:** decides whether the registration is a reviewable tracked change that every clone of
this repository carries (and that runs, gated, outside a dev container too), or a merge the start script
makes into `${CLAUDE_CONFIG_DIR}/settings.json` that exists only inside a container.

**Options:**
- *The tracked `.claude/settings.json` (my recommendation):* add a `hooks` block beside `enabledPlugins`,
  the command `bash "${CLAUDE_PROJECT_DIR}/<hook script>"`. Visible in the PR, identical in every container,
  testable with `jq` against the file. Outside a dev container the hook still runs and exits 0 silently
  because `REMOTE_CONTAINERS` is not `true` (criterion 5 holds: no hook-set title), at the cost of one
  sub-second process per session start for anyone who clones codeo.
- *The user settings, merged by `devcontainer-start.sh`:* the registration never exists outside a
  container, so nothing at all runs there; but it is invisible to review, it goes stale if the script moves,
  the start script's settings merge grows a hooks array (and must not duplicate it on re-run), and the
  existing `start_keeps_other_settings` tests get a harder job.
- *Both:* two registrations run the hook twice; the second is dead weight.

**Answer:**
Accepted the recommendation (the engineer picked it in the conversation): the tracked `.claude/settings.json`.

### Q2 — How is `/clear` covered, given `SessionStart`'s `sessionTitle` applies to `startup`, `resume` and `fork` only?

**Why it matters:** criterion 3 wants a `/clear`ed session titled the same way. The docs say a
`SessionStart` title is ignored when `source` is `clear`, so a hook on `startup|resume|clear` alone, as the
reference project registered it, would leave `/clear` sessions untitled on 2.1.319.

**Options:**
- *`SessionStart` on `startup|resume|fork` plus `UserPromptSubmit`, one script (my recommendation):* the
  script reads `hook_event_name` and answers with the matching `hookEventName`; it sets a title only when
  stdin carries no `session_title`. New and resumed sessions are titled at start; a `/clear`ed session (new
  id, no title) is titled at its first prompt. `UserPromptSubmit` runs on every prompt, so the script must be
  cheap (one `jq`, one `--print`) and print nothing when there is nothing to do.
- *`UserPromptSubmit` only:* one registration; every session is titled at its first prompt, not at start.
  Simpler, but a session opened and not yet prompted sits untitled in the picker and in claude.ai/code.
- *`SessionStart` on `startup|resume|clear` as the reference did, and check `/clear` by hand:* smallest
  change; contradicts the current docs, so it most likely comes back as a send-back on criterion 3.

**Answer:**
Accepted the recommendation (picked in the conversation): `SessionStart` on `startup|resume|fork` plus
`UserPromptSubmit`, one script, setting a title only when stdin carries no `session_title`.

### Q3 — Where does the hook script live, and how does it get the title text?

**Why it matters:** criterion 7 says window and session titles come from one script; the suite's `paths`
decide which files `scope.sh` counts as covered; and `.devcontainer/scripts/` is where #36 and #44 put the
container's own code.

**Options:**
- *`.devcontainer/scripts/session-title.sh`, calling `window-title.sh --print` (my recommendation):* the
  hook is a thin adapter — gate on `REMOTE_CONTAINERS=true`, read stdin with `jq`, skip when `session_title`
  is set, `title="$(window-title.sh --print) · ${session_id:0:8}"`, print the JSON; every failure path is
  `exit 0` with no output (criterion 6). The container title has one source, the file sits under paths the
  suite already covers, and `tests/devcontainer.test.sh` tests it the way it tests `window-title.sh`.
- *`.claude/hooks/session-title.sh`:* the conventional hooks directory, but it is outside every suite's
  `paths` (so `scope.sh` would not count a change to it) and splits the dev container's code across two
  trees.
- *A `--session <id>` mode inside `window-title.sh`:* literally one script, but it mixes a hook's stdin/JSON
  contract into a script that otherwise writes a file, and the hook command still needs a wrapper to read
  stdin.

**Answer:**
Accepted the recommendation (picked in the conversation): `.devcontainer/scripts/session-title.sh`, calling
`window-title.sh --print`.

## Notes

- Decisions this plan makes without asking, stated here so they can be rejected: the dev-container gate is
  `REMOTE_CONTAINERS=true` only (Codespaces and the `devcontainer` CLI are out of scope with "projects that
  use codeo"); the id is the first eight characters of `session_id`; the separator is ` · ` as the issue
  writes it; the hook never writes to stderr except nothing — a failure is silent, per criterion 6.
- The claude.ai/code listing cannot be seen by the suite; as #44 did, the plan's last section names the
  manual check for the engineer, recorded in `qc.md`.

## Outcome

_Pending — written at the hand-off._

## Log

- 2026-11-08 — Q1-Q3 raised · cost: unavailable (usage.sh output recorded at the hand-off)
