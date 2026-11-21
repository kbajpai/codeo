### Description

Today the home role — `/codeo:issue`, `/codeo:init`, `/codeo:triage` and `/codeo:cleanup` — runs in the `codeo-home` dev container, a clone of `main` with no lock and, on purpose, no container engine or Docker socket. Each issue runs `/codeo:plan` through `/codeo:close` in its own `codeo-<N>` container or sbx sandbox.

This issue evaluates an alternative: run the home role in a plain clone on the engineer's physical machine, keeping issues in containers or sandboxes. It compares the options (keep the home container, move home to the host, or a hybrid such as an optional host home, and home in an sbx sandbox if relevant) and recommends one. It ships no change itself.

### Motivation / Context

- **Home cannot run Docker.** Because `codeo-home` has no Docker socket, `/codeo:init` and `/codeo:cleanup` can only print the commands that open and remove issue containers; the engineer runs them on the host. #55 put "a host script that clones or opens VS Code" out of scope as not possible from inside a container.
- **Overhead of a container for light work.** Filing issues and triaging means starting the home container, and a rebuild loses `~/.claude` (the Claude Code login, sessions and settings).
- **Two places on the host side.** The `codeo` host command (#133) already lives on the host and opens, lists and removes issue containers; home in a container is a second place the engineer moves between.
- **Exploration.** The trade-off is worth recording even if the answer is to keep things as they are.

### Key Requirements

- The evaluation judges each option on at least:
  - **Role guard** — whether home-only skills can still be kept out of issue checkouts, and issue skills out of home, when home is on the host. Today `role.sh` treats anything that is not a guarded container as `unguarded`.
  - **Host access and safety** — what an agent session in the home role can reach on the host versus in a container with no Docker socket.
  - **Setup and upkeep** — what the engineer installs and keeps current by hand (Claude Code, `gh`, the codeo plugin, git identity) versus what the image and start script provide, and the login and rebuild cost of each.
  - **What it unlocks** — for example `/codeo:init` opening the issue's container itself, `/codeo:cleanup` removing what it proves finished, and the fit with the `codeo` host command.
- Hosts considered: Linux, macOS and Windows/WSL. The evaluation states, per host, whether each option is workable.
- Backward compatibility: an engineer who keeps using `codeo-home` must not be broken by whatever is recommended; the evaluation says how the recommendation treats them.

### Acceptance Criteria
- [ ] An evaluation document is committed to the repository and compares keep / move-to-host / hybrid on the four criteria above, with the evidence for each judgement.
- [ ] The document states, for Linux, macOS and Windows/WSL, whether each option is workable and what it would need there.
- [ ] The document ends with one recommendation and the reason for it.
- [ ] If the recommendation is anything other than "keep as is", follow-up issues for the work it implies are filed and linked from this issue; if it is "keep", no follow-up is filed and the issue says so.
- [ ] Open questions the evaluation cannot settle are listed in the document rather than answered by assumption.

### Out of Scope

- Moving issue work out of containers or sandboxes: `/codeo:plan` through `/codeo:close` stay where they run today.
- Implementing the recommendation: scripts, the role guard, skill overlays and README changes belong to the follow-up issues.

### Reference

- `.devcontainer/README.md` — the home/issue table, *Roles and the guard* (the `unguarded` condition), and *Removing a finished container* (no Docker socket in home, on purpose).
- `.devcontainer/scripts/role.sh`, `.devcontainer/scripts/devcontainer-start.sh`, `.devcontainer/codeo-container.sh`.
- #55 (introduced the home container), #73 (precedent: sbx evaluation with a recommendation), #113 (cmd mode, Linux and macOS), #133 (the `codeo` host command).
