### Description

Inside a codeo container, `.devcontainer/scripts/session-title.sh` titles each Claude Code session `codeo [home] · <id8>` or `codeo [#<N>] · <id8>`. `<id8>` is the first eight characters of the session id. In a list of sessions those eight characters look random, so the title doesn't show which session is the newest.

Put a two-digit hex sequence number in front of the id, counted per container. An example title is `codeo [home] · 1A-2cb71525`. A later session in the same container gets a higher number, so the newest can be picked out by name, and the id still ties the title to `claude --resume` and the session's transcript.

### Motivation / Context

With several sessions open or resumable in one container (home, or `codeo-<N>`), the engineer wants to find the most recent one by its title alone, without opening each one.

### Key Requirements

- The title shape becomes `<window title> · <NN>-<id8>`. `<NN>` is two uppercase hex digits (`00`-`FF`), and `<id8>` stays the first eight characters of the session id.
- The counter is kept per container. `codeo-home` and each `codeo-<N>` count separately. The count survives a container restart, and a fresh clone or volume starts again at `00`.
- Every new session id takes the next number: a fresh start, a `/clear`ed session and a forked session. A resumed session keeps the number it already has. After `FF` the counter wraps to `00`.
- A session keeps its number for its life. A retitle on a lock change (`[home]` → `[#<N>]`) changes the window-title part only.
- Two sessions starting at the same moment in one container never get the same number (outside a wrap).
- A `/rename`d title is still left alone. A title in the old shape (`<window title> · <id8>`) is still recognised as one this hook set, so existing sessions move to the new shape and are not treated as renamed.
- Outside a dev container, cmd-mode container or sbx sandbox, the hook still prints nothing. Stderr stays empty and the exit status stays 0 on every path.

### Acceptance Criteria
- [ ] A new session in a container is titled `<window title> · <NN>-<id8>`, and the next new session there gets `<NN>` plus one.
- [ ] `/clear` and a fork each take the next number, and `claude --resume` of a session keeps its number.
- [ ] After `FF`, the next session gets `00`.
- [ ] The count carries over a container restart. `codeo-home` and `codeo-<N>` count independently.
- [ ] A lock change retitles `codeo [home] · <NN>-<id8>` to `codeo [#<N>] · <NN>-<id8>` with the same `<NN>`.
- [ ] A `/rename`d title is never changed. An old-shape `codeo [home] · <id8>` title is retitled to the new shape.
- [ ] Two sessions started at once in one container get different numbers.
- [ ] `CHANGELOG.md` and `.devcontainer/README.md` describe the new shape, and `bash tests/run.sh` passes with `tests/devcontainer.test.sh` covering the cases above.

### Out of Scope

- A timestamp in the title. This was considered and dropped in favour of the counter.
- Sharing the count across containers, machines or rebuilds of an issue.
- The VS Code window title (`codeo [home]`, `codeo [#<N>]`).

### Reference

`.devcontainer/scripts/session-title.sh`; `.claude/settings.json` (`SessionStart`, `UserPromptSubmit`); `tests/devcontainer.test.sh`; the original shape from #45, hardened in #47.
