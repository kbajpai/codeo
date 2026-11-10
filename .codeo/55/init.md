# Issue #55 — init

| | |
|---|---|
| Skill | init |
| Issue | #55 |

## Where this stands

Draft, awaiting the engineer's approval. Branch `feat/dev-container-home-container-starting` off `main` at `15bac0b8341ba0b14dd765d389c9f03de3091305`. Not yet pushed.

## Questions

None.

## Outcome

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/55 — Dev container: a home container for starting work and one container per issue |
| State | open · labels `enhancement` |
| Branch | `feat/dev-container-home-container-starting` off `main` at `15bac0b8341ba0b14dd765d389c9f03de3091305` |
| Board | Ready → In progress |

**Problem.** codeo's dev container is one container per clone and takes no lock, so `/codeo:init` binds whichever checkout it runs in and a second issue needs a hand-built clone with nothing naming it. The issue brings roadmaster's shape: a home container (clone on `main`, no lock, where `/codeo:issue`, `/codeo:init` and `/codeo:triage` run) and one container per issue (clone of the pushed branch, lock taken at start, where plan → implement → qc → close run). It covers the `init` host-workflow overlay, lock-taking in the start script, lock-derived name/title/folder check, and the `devcontainer.json` naming, with #54's name-validity requirement folded in.

**Acceptance criteria** — verbatim from the issue, unchecked:
- [ ] With the home container open, `/codeo:init #<N>` pushes the branch, assigns the issue, moves the card, writes no `.codeo/active` and leaves the home checkout on `main`.
- [ ] The same command prints the clone-in-named-volume instructions with the branch URL and `codeo-<N>` filled in, and does not launch `claude --cloud`.
- [ ] Running `/codeo:init` inside an issue container (a `.codeo/active` present) stops and says to run it in the home container.
- [ ] A container cloned from the pushed branch ends its start script with `lock: took the lock for #<N>`, and `.codeo/active` names that issue and branch.
- [ ] The home container's start script takes no lock, and `docker ps` and the window title show `codeo-home` / `codeo [home]`; the issue container shows `codeo-<N>` / `codeo [#<N>]`.
- [ ] A clone folder whose name disagrees with the lock gets a `todo:` line naming the correct folder.
- [ ] A clone folder with a space, `+`, `@`, non-ASCII or a leading `.`/`_` starts, with a valid name or a stated reason.
- [ ] Two containers (`codeo-home` and `codeo-<N>`, or two issue containers) run at once in separate VS Code windows without touching each other's lock.
- [ ] Each new script has a test under `tests/`; `bash tests/run.sh` passes and `CHANGELOG.md` records the change.

**Out of scope.** Launching `claude --cloud "/codeo:plan"` from `init` and web-session hosting; roadmaster's project-specific parts (secrets store, DEV lease, `agy`, per-project mounts); any change under `scripts/`, `lib/`, `hooks/` or `skills/` of the plugin itself; a host script that clones or opens VS Code.

**Open at intake.** None. #54 stays open in Backlog although its name-validity requirement is folded in here; its fate is the engineer's. #51 shares `devcontainer-start.sh` and is to follow this issue.

## Log

- 2026-11-10 — initialized: branch feat/dev-container-home-container-starting off main at 15bac0b8341ba0b14dd765d389c9f03de3091305 · cost: 1m · sonnet-5-5 14k in + 517k cached / 3k out
