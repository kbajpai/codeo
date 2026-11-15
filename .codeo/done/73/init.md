# Issue #73 — init

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/73 |
| Branch | `docs/evaluate-docker-sandboxes-sbx-against` |
| Updated | 2026-11-14 |

## Where this stands

Branch `docs/evaluate-docker-sandboxes-sbx-against` cut off `main` at 09e3013, claimed and pushed. Nothing is open; the next step is `/codeo:plan`, run in this issue's own container.

## Questions

None.

## Outcome

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/73 — Evaluate Docker Sandboxes (sbx) against the dev container setup and recommend whether to migrate |
| State | open · labels `documentation`, `question` |
| Branch | `docs/evaluate-docker-sandboxes-sbx-against` off `main` at `09e3013` |
| Board | `unavailable` — init ran in a hosted web session, where `board.sh status 73` prints `unavailable`; the engineer reported moving the card to Ready by hand (triage run 8, 2026-11-14), and the move to In progress is by hand too |

**Problem.** codeo is developed in a VS Code dev container: a home container on `main` and one container per issue, each its own clone in a named Docker volume, with a start script that trusts the clone, installs the pinned plugins, takes the workflow lock and sets titles. That setup shares the host kernel with passwordless sudo, opens only through VS Code, has a manual per-issue lifecycle (naming, cleanup #70, a Claude login lost on rebuild) and an untested story for parallel agents. Docker Sandboxes (`sbx`) run coding agents in a microVM per sandbox and might reduce those costs. This issue compares the two for codeo's own development and recommends migrate, hybrid or stay; it does not do the migration.

**Acceptance criteria** — verbatim from the issue, unchecked:
- [ ] A written comparison exists (where it lives is up to `/codeo:plan`) covering every driver
      and requirement above, with each point marked as tried or cited.
- [ ] Every duty of the current setup listed under Key Requirements has an sbx equivalent, a
      workaround, or "no equivalent".
- [ ] It states whether sbx runs on the current host (Windows + WSL2), with evidence.
- [ ] It ends with one recommendation and its rationale.
- [ ] If the recommendation is migrate or hybrid, the follow-up issues are filed and linked here.
- [ ] `.devcontainer/` and the workflow skills are unchanged by this issue.

**Out of scope.** Doing the migration, or changing `.devcontainer/` or any skill; how projects that use codeo run it (this is only about codeo's own development environment); other sandbox or remote options (Codespaces, Claude Code's built-in sandbox, Podman, …); Remote Control and cloud sessions.

**Open at intake.**
- Can an sbx sandbox express the home/issue split and the one-clone-per-issue model, or does the workflow lock have to work differently?
- Can VS Code (or another editor) attach to an sbx sandbox, or does sbx push work to the terminal?
- How do the Claude, `gh` and git logins persist across sandbox restarts?

## Log

- 2026-11-14 — initialized: branch docs/evaluate-docker-sandboxes-sbx-against off main at 09e3013 · cost: unavailable
