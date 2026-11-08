# Issue #45 — issue

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/45 |
| Branch | none |
| Updated | 2026-11-08 |

## Where this stands

Follow-up split out of #44 at the engineer's request ("Yes, please go ahead"). Everything needed was
read from RoadMaster's `.claude/hooks/session-title.sh` during #44's pass, so there are no open
questions. Draft below awaits approval.

## Questions

None open.

## Notes

- Scope, title format and hook mechanics are as described in the draft; RoadMaster's hook registers on
  `SessionStart` for `startup|resume|clear`, exits 0 on any failure, skips a session that already has a
  title, and only acts when `REMOTE_CONTAINERS=true`.
- Depends on #44's `container-name.sh`-style script (one source for window and session titles).

## Outcome

Filed as #45 (label `enhancement`, no Issue Type): session titles after the container, split out of #44.

## Draft

**Title:** Dev container: title each Claude Code session after its container (`codeo [home] · <id>`)
**Type:** none · **Labels:** `enhancement`

### Description
Sessions in claude.ai/code and Claude Code's session picker are listed by a bare id. Title each one after
the container it runs in, such as `codeo [home] · a21b9973` or `codeo [#44] · a21b9973`, so a remote
session can be matched to its container.

### Motivation / Context
Several dev containers run at once, and #44 puts each of their sessions in claude.ai/code. Without a
title they can't be told apart.

### Key Requirements
- Inside a dev container, a new session is titled `<container title> · <first eight characters of the
  session id>`, using the same container title as the window (`codeo [home]` or `codeo [#<N>]`).
- It applies on startup, resume and `/clear`.
- A title already set (by `/rename`, or by an earlier start of a resumed session) is never overwritten.
- Outside a dev container nothing changes.
- A failure to work out the title never blocks or delays a session.

### Acceptance Criteria
- [ ] A new session in the home container is listed as `codeo [home] · <id8>`.
- [ ] A session in a container holding issue N's lock is listed as `codeo [#N] · <id8>`.
- [ ] A session started with `/clear` is titled the same way.
- [ ] A session renamed with `/rename` keeps its name after a resume.
- [ ] Outside a dev container the session has no hook-set title.
- [ ] With the title script missing or failing, the session still starts, with exit status 0 and no output.
- [ ] The window title and the session title come from one script, and tests cover it.
- [ ] `bash tests/run.sh` passes.

### Out of Scope
- The window title and Remote Control on at startup (#44).
- Anything for projects that use codeo.

### Reference
- Depends on #44.
- RoadMaster (`sarathi-vl/roadmaster`, private): `.claude/hooks/session-title.sh` and its `SessionStart`
  registration in `.claude/settings.json`; README "Remote Control and titles".
- 2026-11-08 — draft approved; filed as #45
