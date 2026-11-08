# Issue #44 — issue

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/44 |
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
Literal `codeo [home]`, as the reference project does it: a workspace `window.title` written by the start script (engineer, after reading the reference project's approach).

### Q2 — "Enabled by default" for which sessions, and for whom?

**Why it matters:** decides the scope of the requirement.
- Every Claude Code session in the container — CLI and the VS Code extension — or only one of them?
- Only codeo's own dev container, or something codeo should also do for the projects that use it
  (a `/codeo:setup` concern)?

**Answer:**
Every Claude Code session in the container. Scope is codeo's own dev container (assumed, not objected to). Session titles (`codeo [home] · <id>`) are a separate follow-up, not part of this issue (engineer accepted the recommendation).

### Q3 — A new issue, or fold these into #40?

**Why it matters:** #40 is the open bucket of dev container follow-ups from #36's QC. These two are
behaviour changes rather than review leftovers, so I'd file one new issue covering both and
reference #40 and #36. Two separate issues is also possible.
**Options:** one new issue (recommended) · two new issues · add to #40.

**Answer:**
One new issue covering both points, linked to #36 and #40 (engineer accepted the recommendation).

## Notes

- Remote Control setting, from the reference project, pasted by the engineer: the key is
  `remoteControlAtStartup: true` in the user-scope `~/.claude/settings.json`, written by the
  Dockerfile with `jq '. + {remoteControlAtStartup: true}'`. It's baked into the image, so changing
  it means a rebuild. It also needs a claude.ai login (`claude auth login`, once per container);
  `CLAUDE_CODE_OAUTH_TOKEN`, `ANTHROPIC_API_KEY` and `ANTHROPIC_BASE_URL` each stop it working, and
  The reference project's `claude-login.sh` checks for them. If a session doesn't show in claude.ai/code,
  `/remote-control` prints the reason. The reference project's README documents this under "Remote Control and
  titles", so the title answer for Q1 may live there too. Not yet verified against codeo's image.

- Read from the reference project (private, `.devcontainer/`):
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

Filed as #44 (label `enhancement`, no Issue Type): Remote Control on at startup and a `codeo [home]` window title, one issue. Session titles are left to a follow-up.

## Log

- 2026-11-08 — Q1-Q3 raised
- 2026-11-08 — Remote Control setting recorded from the engineer's paste; Q1-Q3 still open
- 2026-11-08 — read the reference project's .devcontainer (title + Remote Control); Q1 proposed answer below, Q2-Q3 still open

## Draft

**Title:** Dev container defaults: Remote Control on at startup and a `codeo [home]` window title
**Type:** none (user-owned repository, `issue-types` prints nothing) · **Labels:** `enhancement`

### Description
Two defaults of codeo's dev container (#36) are wrong for the way codeo is developed. Claude Code's
Remote Control is off in a new container, so each session needs `/remote-control` by hand. And the VS
Code window is titled `codeo [Dev Container: codeo @ desktop-linux]` where `codeo [home]` is wanted.

### Motivation / Context
codeo is developed with codeo, in several containers at once (one per issue plus a home container).
Remote Control on from the start lets any session be driven from claude.ai/code or the mobile app, and
a window title that says which container this is stops two windows being mistaken for each other.

### Key Requirements
- Every interactive Claude Code session in the container (the VS Code panel and `claude` in a
  terminal, `/clear` included) starts with Remote Control on, without running `/remote-control`.
- Remote Control needs a claude.ai login made in the container. The container's start-up checks tell
  the engineer when it is missing, or when `CLAUDE_CODE_OAUTH_TOKEN`, `ANTHROPIC_API_KEY` or
  `ANTHROPIC_BASE_URL` is set, since each stops Remote Control working.
- The VS Code window is titled `codeo [home]` in the home container (no workflow lock), and
  `codeo [#<N>]` in a container holding issue N's lock.
- The title is written per clone and does not appear in `git status`.
- Any existing user-level Claude settings (plugins, update channel) are kept.

### Acceptance Criteria
- [ ] In a freshly built container after `claude auth login`, a new Claude Code session is listed in
      claude.ai/code without running `/remote-control`.
- [ ] A session started with `/clear` in the same container is also listed.
- [ ] With `CLAUDE_CODE_OAUTH_TOKEN`, `ANTHROPIC_API_KEY` or `ANTHROPIC_BASE_URL` set, or no claude.ai
      login, the start script reports it as a TODO and still exits 0.
- [ ] The window title reads `codeo [home]` with no `.codeo/active`, and `codeo [#<N>]` with one.
- [ ] Re-running the start script keeps the title right and leaves other keys in
      `.vscode/settings.json` alone.
- [ ] `git status` is clean after the start script has written the title.
- [ ] `~/.claude/settings.json` still has the plugins and update channel the image set.
- [ ] `tests/devcontainer.test.sh` covers the title and the login checks, and `bash tests/run.sh` passes.

### Out of Scope
- Naming sessions (`codeo [home] · <id>`) in claude.ai/code: a follow-up issue.
- Setting this up for projects that use codeo (`/codeo:setup`).
- The other items in #40.

### Reference
- Reference project (private): `.devcontainer/Dockerfile` merges
  `remoteControlAtStartup: true` into user-level settings; `scripts/window-title.sh` and
  `scripts/container-name.sh` write the title; `scripts/claude-login.sh` checks the login; README
  "Remote Control and titles".
- #36 (the dev container), #40 (follow-ups).
- Open question for `/codeo:plan`: whether `remoteControlAtStartup` behaves the same on the Claude
  Code version the image installs (2.1.319 here), and how `.vscode/` is kept out of `git status`
  (codeo's `.gitignore` has no line for it).
- 2026-11-08 — Q1-Q3 answered; draft written, awaiting approval
- 2026-11-08 — draft approved; filed as #44
