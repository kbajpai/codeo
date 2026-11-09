# Issue #45 — init

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/45 |
| Branch | `feat/dev-container-title-each-claude` |
| Updated | 2026-11-08 |

## Where this stands

Initialized: branch `feat/dev-container-title-each-claude` off `main` at ce69314. Next: `/codeo:plan`.

## Questions

None.

## Outcome

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/45 — Dev container: title each Claude Code session after its container (`codeo [home] · <id>`) |
| State | open · labels `enhancement` |
| Branch | `feat/dev-container-title-each-claude` off `main` at ce69314 |
| Board | Ready → In progress |

**Problem.** Sessions in claude.ai/code and the session picker are listed by a bare id. Several dev
containers run at once (#44 puts each in claude.ai/code), so they cannot be told apart. Each session
inside a dev container should be titled `<container title> · <first eight characters of the session id>`,
reusing the window title from #44, on startup, resume and `/clear`, without overwriting an existing
title and without ever blocking a session.

**Acceptance criteria** — verbatim from the issue, unchecked:
- [ ] A new session in the home container is listed as `codeo [home] · <id8>`.
- [ ] A session in a container holding issue N's lock is listed as `codeo [#N] · <id8>`.
- [ ] A session started with `/clear` is titled the same way.
- [ ] A session renamed with `/rename` keeps its name after a resume.
- [ ] Outside a dev container the session has no hook-set title.
- [ ] With the title script missing or failing, the session still starts, with exit status 0 and no output.
- [ ] The window title and the session title come from one script, and tests cover it.
- [ ] `bash tests/run.sh` passes.

**Out of scope.** The window title and Remote Control on at startup (#44); anything for projects that use codeo.

**Open at intake.** None. Depends on #44, which is merged (PR #46). The issue body names the private
reference project; the engineer is scrubbing it (not this skill's to edit).

## Log

- 2026-11-08 — initialized: branch feat/dev-container-title-each-claude off main at ce69314 · cost: unavailable
