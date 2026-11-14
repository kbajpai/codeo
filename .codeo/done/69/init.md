# Issue #69 — init

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/69 |
| Branch | `feat/fix-closing-blocks-that-name` |
| Updated | 2026-11-14 |

## Where this stands

Branch `feat/fix-closing-blocks-that-name` cut off `main` at 91894c1, claimed and pushed. Nothing is open; the next step is `/codeo:plan`, run in this issue's own container.

## Questions

None.

## Outcome

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/69 — Fix closing blocks that name a command that cannot run, and keep plan host commands shell-neutral |
| State | open · labels `enhancement` |
| Branch | `feat/fix-closing-blocks-that-name` off `main` at `91894c1` |
| Board | Ready → In progress |

**Problem.** Four skills end with a closing block that names the engineer's next command, and on some exits that command cannot run: `/codeo:close` after a failed cleanup that keeps the lock tells the engineer to remove the checkout they need; a stash that failed halfway points at `/codeo:init`, which stops on the lock the stash kept; `/codeo:init` after `lock: TODO` still names `/codeo:plan`, which refuses without a lock; and `/codeo:issue` names `/codeo:init` where the board's Ready gate refuses a new issue. A plan's host-run commands written for bash also failed on the engineer's PowerShell, and a few wording notes from #67 were merged as they stood. One issue covers all of it, with no change to what the pipeline decides.

**Acceptance criteria** — verbatim from the issue, unchecked:
- [ ] After a failed lease release, branch deletion or push that keeps the lock, `/codeo:close`'s closing block names `/codeo:close` as its first step and does not name removing the checkout.
- [ ] After an interrupted stash that keeps `.codeo/active`, the closing block names `/codeo:close --stash` as its first step; `/codeo:init #<N>` is named only after a completed stash; a failed board move adds the manual Ready repair before it.
- [ ] After `/codeo:init` prints `lock: TODO`, its closing block names a recovery step and does not name `/codeo:plan`; `/codeo:plan` is named only once the lock was taken.
- [ ] With a board, after `/codeo:issue` files an issue whose Status is not Ready, the closing block names `/codeo:triage` before `/codeo:init #<N>`; with no board, or with a Ready issue, it names `/codeo:init #<N>` as it does today.
- [ ] A test in `tests/` fails if any of the four closing blocks goes back to naming the command that cannot run in its state (alongside `tests/closing-block.test.sh`, which already fails when a skill does not cite the block).
- [ ] A task in a plan that the engineer runs on their own host has a command that runs from their shell without editing, or names the shell it is written for, and `/codeo:plan` says how it decides.
- [ ] `CHANGELOG.md`'s dev container entry no longer says the tools are "at 26.04's versions" without exempting `gh` and Claude Code, and no longer lists three Rust coreutils as if complete; `.devcontainer/README.md` says all of `~/.claude` is lost on a rebuild.
- [ ] `CHANGELOG.md` has an `## Unreleased` entry for this change, and `bash tests/run.sh` passes.

**Out of scope.** The move of the dev container image to `ubuntu:26.04` itself (#67, merged); the two stale lines in the archived `.codeo/done/61/plan.md` and the local-only `v1.0.4` tag in one clone (known and left); the open dev container follow-ups #40, #51, #54 and #57.

**Open at intake.**
- Can `/codeo:issue` read the new issue's board Status itself (`board.sh status <N>`), and what does it say when the board is not configured or the read is unavailable? `/codeo:plan` settles this.
- Is the closing-block rule ("name only a command that can run in the state this exit leaves") written once in `docs/handoff.md` and checked there, or four separate edits to four skills? `/codeo:plan` settles this.

Also settled at filing: the pull request or pull requests that carry this may be split as `/codeo:plan` sees fit.

## Log

- 2026-11-14 — initialized: branch feat/fix-closing-blocks-that-name off main at 91894c1 · cost: 1m · sonnet-5-5 16k in + 2.2M cached / 3k out
