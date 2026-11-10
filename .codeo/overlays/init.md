Project overlay text adds to or narrows a step; it never overrides a rule marked with a "rule" comment in this file.

## host-workflow

This skill runs in the **home container** — the clone on `main`, holding no lock. A `.codeo/active`
here means this session is inside some issue's container: stop, and say to run `init` in the home
container. Another issue's workflow in its own container is no obstacle; that is the point.

Nothing is switched in the home container's clone — the branch is cut in a scratch worktree and
never checked out here — so uncommitted work here is not in the way and is never stashed or discarded.

Once the claim succeeds, `git worktree remove <scratch>`, then `git branch -D <branch>` (it is on
origin now, and the home container has no use for a local copy that would only go stale).

**This skill does not write `.codeo/active`** — it has no clone to write it in. The lock is taken
where it lives, from what the push carried: the issue's container is cloned from the pushed branch,
takes its lock from the `init.md` on it (`bash .devcontainer/scripts/devcontainer-start.sh`), and
every skill commits its dossier onto it as it goes.

**Hand off** to `/codeo:plan` — **in the issue's container.** This session is in the home
container, where no lock exists, so `plan` run here stops. Print how to open it, with the branch
filled in: in VS Code, run Dev Containers: Clone Repository in Named Container Volume… (the
unnamed variant never asks for a name), then give the repository URL with the branch in it,
`https://github.com/kbajpai/codeo/tree/<branch>`, a new volume named `codeo-<N>`, and the folder
`codeo-<N>` (the folder names the container). When it has started, its start script prints
`lock: took the lock for #<N> on <branch>`; then run `/codeo:plan` there. If the start script
lists a TODO instead, that comes first.

If the issue's container has commits it never pushed, re-running
`bash .devcontainer/scripts/devcontainer-start.sh` there retakes the lock rather than a new clone.
