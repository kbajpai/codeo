# Issue #99 — implement

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/99 |
| Branch | `feat/make-sbx-issue-sandbox-usable` |
| Plan | `docs/plans/2026-11-17-sbx-issue-sandbox.md` |
| Updated | 2026-11-17 |

## Where this stands

Round 1, paused at Task 5. Tasks 1, 2, 3, 4 and 7 are done: commits `9c376ce`, `5ac3e7b`, `f45a6da` and `4e6fbdb`, and #99's body edited. Each was reviewed and found clean. `sync-main.sh` reported that the branch already contains `origin/main`, and `overlap.sh 99` printed nothing. Waiting on the engineer: run trials S1-S9 (`.codeo/99/plan.md` → Notes → Trials) in WSL2 bash and paste each output under `## Trials` below, with tokens and account names removed. Tasks 6, 8, 10, 11 and 12 read their results. Then run `/codeo:implement` again.

## Questions

None.

## Trials

_Task 5 — the engineer's output for S1-S9 (WSL2 bash, Ubuntu-24.04), with tokens and account names removed._

**S1, first attempt.** The plan's `<user>` placeholder was pasted as it was, so `create` refused:

```
    ○ claude — now ships as a kit; resolving docker.io/sbx/claude:latest

  error: --clone cannot use \\wsl.localhost\Ubuntu-24.04\home\<user>\Source\codeo-sbx-t as a Git repository: git failed: fatal: detected dubious ownership in repository at '//wsl.localhost/Ubuntu-24.04/home/<user>/Source/codeo-sbx-t'
    try: git.exe config --global --add safe.directory "%(prefix)///wsl.localhost/Ubuntu-24.04/home/<user>/Source/codeo-sbx-t"
```

- The `claude` agent is now a kit, and it resolves `docker.io/sbx/claude:latest`.
- `create`'s own hint uses the same `safe.directory` form that Task 8 writes.

**S1, retry** (sbx v0.53.0; v0.54.0 was offered):

```
    ○ claude — now ships as a kit; resolving docker.io/sbx/claude:latest
    ✓ workspace — Git repository at \\wsl.localhost\Ubuntu-24.04\home\<user>\Source\codeo-sbx-t

  SANDBOX
    Name:       codeo-t
    Agent:      claude
    Kit:        docker.io/sbx/claude@sha256:fd56087ae3f35db02c34657e7eaafa9817f8b268b1ac08139cc13d8277593332
    Workspace:  \\wsl.localhost\Ubuntu-24.04\home\<user>\Source\codeo-sbx-t → /wsl.localhost/Ubuntu-24.04/home/<user>/Source/codeo-sbx-t (rw)
    Skills:     0 entries · read-only
      Source:   ~\AppData\Local\DockerSandboxes\sandboxes\state\agent-skills
      Target:   /home/agent/.claude/skills
    Image:      docker.io/sbx/claude@sha256:fd56087ae3f35db02c34657e7eaafa9817f8b268b1ac08139cc13d8277593332
    CPU:        20
    Memory:     32 GiB

  IMAGE
    ✓ image — ready
    Git daemon:  git://127.0.0.1:60011/codeo-sbx-t
    Remote:      sandbox-codeo-t

    ✓ Created sandbox codeo-t
        source \\wsl.localhost\Ubuntu-24.04\home\<user>\Source\codeo-sbx-t → /run/sandbox/source (ro)
        try: sbx run --name codeo-t
```

- **A third digest.** On 2026-11-17 `:latest` resolved to `fd56087a…`, which matches neither `4df39400…` (T3/T8) nor `0fb3e2c5…` (T10). `Kit:` and `Image:` carry the same full digest, so it is the reference Task 10 pins. The engineer did not say whether the T3, T8 and T10 output survives, so the page keeps those two digests as recorded, shortened.
- **The default size is the whole host,** 20 CPUs and 32 GiB, which is why Task 8 passes `--cpus 2 --memory 4g`.
- **The working folder inside is the host path made POSIX:** `/wsl.localhost/Ubuntu-24.04/home/<user>/Source/codeo-sbx-t` (rw). The read-only source is at `/run/sandbox/source`. S3's `pwd` shows which of the two `exec` starts in.
- `create` adds a git remote, `sandbox-codeo-t`, to the host clone, served by the Git daemon on `127.0.0.1`.

**S2.**

```
gh auth token                              → gho_<real token, not pasted>
sbx.exe exec codeo-t gh auth token         → gho_sbxproxymanaged000000000000000000000
sbx.exe exec codeo-t printenv GH_TOKEN     → gho_sbxproxymanaged000000000000000000000
```

The sandbox never holds the real token. `gh` and `GH_TOKEN` inside it both see the same 40-character placeholder, `gho_sbxproxymanaged` padded with zeros. sbx's proxy presumably swaps in the real credential on the way out. S4 shows whether a push works with it.

## Notes

- Ruling (Task 3): the "was not tried" check counts occurrences (15 → 14), not lines. `grep -c` counts lines, and the Host paragraph is one line that keeps its single mention.
- Ruling (Task 4): the #94 section of #99's body still quotes "T5 to T12" as the finding it describes, so `grep -c 'T5 to T12'` prints 1. The #86 section carries none, and "T8 to T12" appears 3 times.
- Minor, for QC: an empty `.claude.json` gets a "could not write" TODO from step 3d, where step 3c fills an empty `settings.json`.

## Outcome

_Pending — written at the hand-off._

## Log
- 2026-11-17 — Tasks 1-4 and 7 done; paused at Task 5 for the engineer's trials · cost: 38m · opus-5-5 55k in + 9.1M cached / 19k out · sonnet-5-5 312k in + 4.2M cached / 44k out
