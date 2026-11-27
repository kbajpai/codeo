Project overlay text adds to or narrows a step; it never overrides a rule marked with a "rule" comment in this file.

## host-workflow

This skill runs in a **home checkout** (the host clone named `codeo-home`, or the home container) — the clone on `main`, holding no lock. A `.codeo/active`
here means this session is inside some issue's checkout: stop, and say to run `init` in a home
checkout. Another issue's workflow in its own container is no obstacle; that is the point.

Nothing is switched in the home checkout's clone — the branch is cut in a scratch worktree and
never checked out here — so uncommitted work here is not in the way and is never stashed or discarded.

After the claim push succeeds (and for a resume too), run `bash .devcontainer/codeo-track.sh add <N> branch <branch>` from the project root: it records the branch in the issue's tracking comment, and a second run changes nothing. Relay a `track:` line it prints and carry on whatever its exit status.

Once the claim succeeds, `git worktree remove <scratch>`, then `git branch -D <branch>` (it is on
origin now, and the home checkout has no use for a local copy that would only go stale).

**This skill does not write `.codeo/active`** — it has no clone to write it in. The lock is taken
where it lives, from what the push carried: the issue's container is cloned from the pushed branch,
takes its lock from the `init.md` on it (`bash .devcontainer/scripts/devcontainer-start.sh`), and
every skill commits its dossier onto it as it goes.

**Hand off** to `/codeo:plan` — **in the issue's container.** This session is in a home
checkout, where no lock exists, so `plan` run here stops. Print the ways to open it, with the
number and branch filled in:

- *In VS Code:* run Dev Containers: Clone Repository in Named Container Volume… (the
  unnamed variant never asks for a name), then give the repository URL with the branch in it,
  `https://github.com/kbajpai/codeo/tree/<branch>`, a new volume named `codeo-<N>`, and the folder
  `codeo-<N>` (the folder names the container). This route records the branch row only; the
  container, image and volume are not recorded.
- *From a command line:* on the host, not inside this container, in a terminal, run
  `codeo issue <N> <branch> --container` (the `codeo` command keeps `codeo-container.sh` in its own home directory, so no clone of the project is needed on the host, and the script needs only Docker). From a host clone of the project, `bash .devcontainer/codeo-container.sh issue <N> <branch>` does the same. If `codeo-<N>` exists (a stash being resumed), remove it first with `codeo rm <N>`, once `git status` in it shows nothing unpushed, or the command refuses. Then
  `codeo shell <N>` (from a host clone, `bash .devcontainer/codeo-container.sh shell <N>`) opens a shell in `codeo-<N>`; start `claude` there.
- *In a Docker Sandboxes sandbox:* on the host, the simplest is `codeo issue <N> <branch> --sandbox`, then `codeo open <N>` (VS Code) or `codeo shell <N>`: the `codeo` command keeps `codeo-sandbox.sh` (downloaded from `.sbx/codeo-sandbox.sh` on `main`) and the `codeo-<N>` clone in its home directory. Without it, put `codeo-sandbox.sh` in a folder outside the project clone, because the script makes the `codeo-<N>` clone in the folder it runs from, and run `bash codeo-sandbox.sh issue <N> <branch>`, then `bash codeo-sandbox.sh open <N>` or `bash codeo-sandbox.sh shell <N>` there. A sandbox is ended with `codeo rm <N>` (which runs `bash codeo-sandbox.sh end <N>` in that folder), not with `docker rm`.

Whichever route, when the container has started its start script prints
`lock: took the lock for #<N> on <branch>`; then run `/codeo:plan` there. If the start script
lists a TODO instead, that comes first.

If the issue's container has commits it never pushed, re-running
`bash .devcontainer/scripts/devcontainer-start.sh` there retakes the lock rather than a new clone.

## role-guard

Run `bash .devcontainer/scripts/role.sh --check init` from the project root. Exit 0: go on. Exit 1: print its one line to the engineer and stop; that is the whole answer and nothing in this session lifts it. Exit 2: report its `role:` line and go on. Any other exit (the script is missing, or failed): report what it printed and go on.
