# New issue — issue

| | |
|---|---|
| Issue | _not filed yet_ |
| Branch | none — `/codeo:issue` cuts no branch |
| Updated | 2026-11-08 |

## Where this stands

Round 1. Request: two defaults the dev container added in #36/#38 gets wrong. (1) Claude Code's
Remote Control is off in a fresh container; the engineer expects it on without running
`/remote-control`. (2) The VS Code window title reads `codeo [Dev Container: codeo @ desktop-linux]`;
the engineer expects `codeo [home]`.

Checked: `.devcontainer/devcontainer.json` sets `"name": "codeo"` and no `window.title`; the image
bakes only `~/.claude/settings.json` (plugins, marketplaces, `autoUpdatesChannel`) — nothing about
Remote Control; `devcontainer-start.sh` doesn't touch it either. No open issue covers either point;
#40 (dev container follow-ups) is the nearest, and covers neither. Blocked on Q1–Q3.

## Questions

### Q1 — Where does "home" come from, and what exactly should the bracket read?

**Why it matters:** VS Code builds `[Dev Container: <name> @ <docker context>]` itself from the
`name` in `devcontainer.json` and the Docker context. Renaming the container to `home` gives
`codeo [Dev Container: home @ desktop-linux]`; getting the literal `codeo [home]` is a different
requirement (a window-title setting). The acceptance criterion depends on which you mean.
**Options:** literal `codeo [home]` · only the container's name should be `home` · something else
(e.g. it matches what the reference project shows — say which).

**Answer:**

### Q2 — "Enabled by default" for which sessions, and for whom?

**Why it matters:** decides the scope of the requirement.
- Every Claude Code session in the container — CLI and the VS Code extension — or only one of them?
- Only codeo's own dev container, or something codeo should also do for the projects that use it
  (a `/codeo:setup` concern)?

**Answer:**

### Q3 — A new issue, or fold these into #40?

**Why it matters:** #40 is the open bucket of dev container follow-ups from #36's QC. These two are
behaviour changes rather than review leftovers, so I'd file one new issue covering both and
reference #40 and #36. Two separate issues is also possible.
**Options:** one new issue (recommended) · two new issues · add to #40.

**Answer:**

## Notes

- Remote Control setting, from the reference project (RoadMaster), pasted by the engineer: the key is
  `remoteControlAtStartup: true` in the user-scope `~/.claude/settings.json`, written by the
  Dockerfile with `jq '. + {remoteControlAtStartup: true}'`. It's baked into the image, so changing
  it means a rebuild. It also needs a claude.ai login (`claude auth login`, once per container);
  `CLAUDE_CODE_OAUTH_TOKEN`, `ANTHROPIC_API_KEY` and `ANTHROPIC_BASE_URL` each stop it working, and
  RoadMaster's `claude-login.sh` checks for them. If a session doesn't show in claude.ai/code,
  `/remote-control` prints the reason. RoadMaster's README documents this under "Remote Control and
  titles", so the title answer for Q1 may live there too. Not yet verified against codeo's image.

- Read from `sarathi-vl/roadmaster` (private, `.devcontainer/`), the reference project:
  - **Title:** `scripts/window-title.sh` writes `"window.title": "<codename> [#<N>]"` (or
    `<codename> [home]`) into the clone's own `.vscode/settings.json`, which is gitignored; workspace
    scope because `window.title` is window-scoped and `devcontainer.json` has no variable for the issue
    number. The start script calls it. `scripts/container-name.sh` picks the text: `[#<N>]` when
    `.codeo/active` holds an `issue:` line, else `[home]`; `--docker` gives the Docker name
    (`<codename>-<N>` / `<codename>-home`). The codename comes from `.codeo/config.json`.
  - **Remote Control:** Dockerfile merges `remoteControlAtStartup: true` into user-scope settings.json
    (project scope ignores `true`). `claude-login.sh` turns each missing prerequisite into a start-script
    TODO. README "Remote Control and titles" also says sessions are listed in claude.ai/code as
    `<codename> [#<N>] · <id>`, via a `.claude/hooks/session-title.sh` hook.
  - **Does not carry over as is:** codeo's `.gitignore` has no `.vscode/` line, and codeo has no
    `.codeo/project.sh` (it reads config with `scripts/config.sh`).

## Outcome

_Pending — written at filing._

## Log

- 2026-11-08 — Q1-Q3 raised
- 2026-11-08 — Remote Control setting recorded from the engineer's paste; Q1-Q3 still open
- 2026-11-08 — read RoadMaster's .devcontainer (title + Remote Control); Q1 proposed answer below, Q2-Q3 still open
