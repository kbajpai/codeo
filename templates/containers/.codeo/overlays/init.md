Project overlay text adds to or narrows a step; it never overrides a rule marked with a "rule" comment in this file.

## host-workflow

This skill runs in a **home checkout** (the host clone named `@CODENAME@-home`, or the home container) — the clone on `main`, holding no lock. A `.codeo/active`
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
  `https://github.com/@REPO_SLUG@/tree/<branch>`, a new volume named `@CODENAME@-<N>`, and the folder
  `@CODENAME@-<N>` (the folder names the container). This route records the branch row only; the
  container, image and volume are not recorded.
- *From a command line:* on the host, not inside this container, in a terminal, run
  `bash codeo-container.sh issue <N> <branch>`. `codeo-container.sh` is the file the download line in
  `.devcontainer/README.md` saves; it needs only Docker. If `@CODENAME@-<N>` exists (a stash being resumed), remove it first with `codeo rm <N>`, once `git status` in it shows nothing unpushed, or the command refuses. Then
  `bash codeo-container.sh shell <N>` opens a shell in `@CODENAME@-<N>`; start `claude` there.
- *In a Docker Sandboxes sandbox:* on the host, run `bash codeo-sandbox.sh issue <N> <branch>`, then `bash codeo-sandbox.sh open <N>` (VS Code) or `bash codeo-sandbox.sh shell <N>`. `codeo-sandbox.sh` is the file the download line in `.sbx/README.md` saves. A sandbox is ended with `codeo rm <N>` (which runs `bash codeo-sandbox.sh end <N>`), not with `docker rm`.

Whichever route, when the container has started its start script prints
`lock: took the lock for #<N> on <branch>`; then run `/codeo:plan` there. If the start script
lists a TODO instead, that comes first.

If the issue's container has commits it never pushed, re-running
`bash .devcontainer/scripts/devcontainer-start.sh` there retakes the lock rather than a new clone.

## role-guard

Run `bash .devcontainer/scripts/role.sh --check init` from the project root. Exit 0: go on. Exit 1: print its one line to the engineer and stop; that is the whole answer and nothing in this session lifts it. Exit 2: report its `role:` line and go on. Any other exit (the script is missing, or failed): report what it printed and go on.
