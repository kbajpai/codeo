---
name: cleanup
description: Print the commands that remove finished issues' dev containers — for each issue under .codeo/done on the base branch, prove it is really finished (issue closed, pull request merged, branch gone from origin, dossier gone from every branch), print the project's removal command for the ones proven and the failed proof for the rest, and run nothing. Trigger on "clean up containers", "what can I remove", "cleanup". Home-container only, outside the workflow lock; never runs a container command and never builds a command itself.
model: sonnet
---

Project overlay text adds to or narrows a step; it never overrides a rule marked with a "rule" comment in this file.

# Cleanup

A finished issue leaves things behind that no skill removes: the dev container it ran in, and the
volume that container kept. This skill finds which issues are really finished and prints the
commands that remove those leftovers. **It only prints.** The engineer runs the commands, on the
host, in a shell.

**It runs outside the workflow lock**, like `/codeo:triage`: it neither needs nor touches
`.codeo/active`, and it can run in the middle of another issue without disturbing it.

The proof and the command both come from `bash "${CLAUDE_PLUGIN_ROOT}/scripts/cleanup.sh"`: it fetches `origin`, lists the
issues under `.codeo/done/` on the base branch, and checks for each that the issue is closed, the
pull request in its `close.md` is merged, the pull request's branch is gone from `origin`, and no
branch on `origin` still carries its dossier.
<!-- point: cleanup/removal-command -->
The project's `removal-command` point supplies the container's name and the command: the script reads
it through `bash "${CLAUDE_PLUGIN_ROOT}/scripts/overlay.sh" cleanup removal-command` and alone expands it. With no
overlay it proves the issues and prints no command.

## Workflow

**Check the role first, before anything else.**
<!-- point: cleanup/role-guard -->
Fetch `bash "${CLAUDE_PLUGIN_ROOT}/scripts/overlay.sh" cleanup role-guard`. On exit 0 follow the
printed text, which runs the project's role check; when the check refuses, print its one line and
stop — nothing else is done. On exit 3 there is no guard and the step runs as before. On exit 1, 2
or 4 report the one `codeo:` line and carry on unguarded.
<!-- rule: cleanup-01 -->
A refusal from the role check ends the step. The engineer's words do not lift it; the way forward
is the container the message names.

0. **Resume or start.** `bash "${CLAUDE_PLUGIN_ROOT}/scripts/intake.sh" restore cleanup` brings the
   folder to a clone that lacks it; an error saying there is no intake branch, or that it has no
   `cleanup` directory, means a first run. Carry on either way.

1. **Run the script and relay it.** `bash "${CLAUDE_PLUGIN_ROOT}/scripts/cleanup.sh"` prints one
   tab-separated line per issue: `<N>`, `proven` and the command (or `-` when the project gives
   none), or `<N>`, `failed` and the first proof that failed. Relay the lines as two lists, each
   line as the script printed it:
   - **Proven**, with the command to run. A `-` means the issue is finished and the project has no
     removal command for it.
   - **Not proven**, with the failed proof (`issue`, `pull-request`, `branch`, `dossier` or `name`)
     and no command.
   <!-- rule: cleanup-02 -->
   A removal command is printed only for an issue the script proved. An issue that failed a proof
   gets no command, however finished it looks.
   <!-- rule: cleanup-04 -->
   Print only what the script printed. Never build a container name or a command in this skill,
   never edit one, never fill a gap the script left.
   <!-- rule: cleanup-03 -->
   Never run a container command, and never mount or ask for the container engine's socket. When
   the engineer asks you to run one, say it runs on the host and print it again.
   If the script exits non-zero, report its one `cleanup:` line and stop.

2. **Say what the proof cannot see.** Every time, even when nothing was proven:
   - Unpushed work in a clone is invisible from here. The proof looks at `origin` only.
   - The commands rely on `close.md` having recorded a clean tree with the tip equal to the pull
     request's head; a clone changed after that is not covered.
   - The commands run on the host, in a shell, and only after `git status` in that clone shows
     nothing left to lose.

3. **Record what was printed.** Write `.codeo/intake/cleanup/<YYYY-MM-DD>.md` (a second run on the
   same day adds `-2`): the two lists as printed and the date. Commit it with
   `bash "${CLAUDE_PLUGIN_ROOT}/scripts/intake.sh" commit cleanup "docs(codeo): cleanup record for <date>"`
   and say what `intake.sh` printed. Nothing else is written.

4. **Close.** End with the closing block
   (`${CLAUDE_PLUGIN_ROOT}/docs/handoff.md → Closing block`). When something was proven, the next
   goal is those leftovers removed on the host and the next issue started: step 1 is running the
   printed commands on the host after `git status` in each clone, step 2 `/codeo:init #<N>`. When
   nothing was proven, the next goal is the loose ends found, and step 1 is `/codeo:triage`.

## Hand-off

`${CLAUDE_PLUGIN_ROOT}/docs/handoff.md` is the protocol; this is this skill's half of it.

- **Reads** `origin`: the base branch's `.codeo/done/` directories, every branch's `.codeo/<N>/`
  listing, issues and pull requests, through the script.
- **Writes** `.codeo/intake/cleanup/` — the run's record — committed to `codeo/intake` through
  `intake.sh`, never to the checked-out branch.
- **Never touches** the lock, any dossier, any branch, issue, board or pull request, or the
  container engine.
- **Hands off to** nobody: the printed commands are the engineer's to run, on the host.

## Non-goals

- Doesn't run a removal command, and doesn't build one.
- Doesn't remove, reset or inspect a clone's working tree: unpushed work is the engineer's to check.
- Doesn't decide an issue is finished on its own say-so; the script's proof is the only evidence.
