# Init — #181

| | |
|---|---|
| Issue | #181 |
| Step | init |

## Where this stands

Draft, awaiting approval. Branch `feat/181-session-title-prefix-session-id` off `main` at `13ac02c52f10b9b597c77bf8a67968e10319634f`. Next: approval, then the claim push.

## Questions

None.

## Outcome

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/181 — Session title: prefix the session id with a per-container hex sequence number (`codeo [home] · 1A-2cb71525`) |
| State | open · labels `enhancement`, `priority: low` |
| Branch | `feat/181-session-title-prefix-session-id` off `main` at `13ac02c52f10b9b597c77bf8a67968e10319634f` |
| Board | Ready → In progress |

**Problem.** `.devcontainer/scripts/session-title.sh` titles each Claude Code session `codeo [home] · <id8>` or `codeo [#<N>] · <id8>`, and the first eight characters of a session id look random, so the newest session can't be picked out from a list by title. The title gains a two-digit hex sequence number counted per container: `<window title> · <NN>-<id8>`. Each new session id (fresh, `/clear`, fork) takes the next number, a resumed session keeps its own, the count survives a container restart and wraps after `FF`. Concurrent starts never share a number, a `/rename`d title is left alone, and an old-shape title is still recognised and moved to the new shape.

**Acceptance criteria** — verbatim from the issue, unchecked:
- [ ] A new session in a container is titled `<window title> · <NN>-<id8>`, and the next new session there gets `<NN>` plus one.
- [ ] `/clear` and a fork each take the next number, and `claude --resume` of a session keeps its number.
- [ ] After `FF`, the next session gets `00`.
- [ ] The count carries over a container restart. `codeo-home` and `codeo-<N>` count independently.
- [ ] A lock change retitles `codeo [home] · <NN>-<id8>` to `codeo [#<N>] · <NN>-<id8>` with the same `<NN>`.
- [ ] A `/rename`d title is never changed. An old-shape `codeo [home] · <id8>` title is retitled to the new shape.
- [ ] Two sessions started at once in one container get different numbers.
- [ ] `CHANGELOG.md` and `.devcontainer/README.md` describe the new shape, and `bash tests/run.sh` passes with `tests/devcontainer.test.sh` covering the cases above.

**Out of scope.** A timestamp in the title; sharing the count across containers, machines or rebuilds of an issue; the VS Code window title (`codeo [home]`, `codeo [#<N>]`).

**Open at intake.** None.

## Log

- 2026-11-28 — initialized: branch feat/181-session-title-prefix-session-id off main at 13ac02c52f10b9b597c77bf8a67968e10319634f · cost: unavailable
