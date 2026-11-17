# Issue #99 — plan

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/99 |
| Branch | `feat/make-sbx-issue-sandbox-usable` |
| Updated | 2026-11-17 |

## Where this stands

Round 1, finished. Q1-Q9 are answered, the footprint check prints nothing and no exclusive resource is named. The plan is approved and written at `docs/plans/2026-11-17-sbx-issue-sandbox.md`, unstaged for the engineer to commit. Next: `/codeo:implement`.

## Questions

### Q1 — Will you run the trials in Notes (S1-S9) now, before I draft, or should the plan carry them as its first tasks?

**Why it matters:** the issue says the #94 trial "may change what the other two assume", and the same holds for five more unknowns. With the results in hand I write one firm design for the start script, the VS Code step and the removal check. Without them the plan has to open with a trial task and write the #85 and #86 tasks with a branch for each outcome (real token or placeholder, push works or not, the dev container's start script runs in a sandbox or not), which is longer and leaves decisions to whoever implements it.

**Options:**
- *Run them now* (recommended): about 20 single commands in WSL2 bash, listed under Notes → Trials. Paste the output under each, with tokens and account names removed. S2 becomes the page's T13.
- *Carry them as tasks:* the plan's first task is the same list, marked `Runs on: the engineer's host`, and the later tasks branch on its results.
- *Run some:* say which; I plan the rest as tasks.

I wrote the commands for WSL2 bash with `sbx.exe`, as in #73's trials. Say so if you would run them in another shell.

**Answer:**
Linux bash and WSL2 bash, both, mostly WSL2 (engineer, in the conversation, 2026-11-17). Asked again with the question tool for the half left open: the plan carries the trials as its first host task, and the tasks that depend on them say what to do for each outcome (engineer, 2026-11-17). So the host script picks `sbx` or `sbx.exe` itself, and the Windows Git trust step runs only with `sbx.exe`.

### Q2 — What should run inside the sandbox at start: the dev container's own start script, or a new one?

**Why it matters:** it decides how much new code there is and what the start prints. The issue requires that `devcontainer-start.sh` is unchanged and keeps working, and allows `.devcontainer/` to change only to share code.

**Options:**
- *Run `devcontainer-start.sh` unchanged, in cmd mode* (recommended if trial S6 shows it works): a host script creates the sandbox and then runs `devcontainer-start.sh` in it with `CODEO_CMD_MODE=1`, as `codeo-container.sh` does in a container. The lock, the folder check, the plugins, the identity seeding, `gh auth setup-git` and the TODO lines are then the same code with the same tests. Its lines keep the prefix `devcontainer-start:`, and it also turns on Remote Control, which #85 puts out of scope for a sandbox (I would record that in the README as not tried, not remove it).
- *A new in-sandbox script that shares functions with it:* the steps move from `devcontainer-start.sh` into a file both scripts source. The sandbox script can leave steps out and print its own prefix, but the dev container's script is restructured, which is more than "unchanged".
- *A new standalone script:* nothing in `.devcontainer/` changes, and the lock, identity and TODO logic exists twice.

**Answer:**
Accepted the recommendation: run `devcontainer-start.sh` unchanged in cmd mode inside the sandbox (engineer, in the conversation, 2026-11-17). If the trial shows it cannot run there, the plan stops at that task and says so.

### Q3 — How does the sandbox get its clone, and may the script write the Windows Git trust line itself?

**Why it matters:** `sbx create --clone` copies whatever the host folder has checked out, so something has to put a host clone on the pushed branch first, and Windows Git has to trust that folder. This decides what the "one documented command" does on your host.

**Options:**
- *The script makes the host clone and adds the trust line* (recommended): `issue <N> <branch>` clones the branch into `./codeo-<N>` (refusing a folder that exists on another branch), runs `git.exe config --global --add safe.directory` for it when the line is missing, then creates the sandbox `codeo-<N>` from it. It writes one line to your Windows global Git config for each clone.
- *The script makes the host clone and only prints the trust command:* when the line is missing it prints the one `git.exe config` command and stops, so nothing outside the clone is written without you running it. The first create for each clone is then two commands.
- *No host clone (a mountless sandbox):* the sandbox is created with no host folder and the script clones the branch inside it, as `codeo-container.sh` does. No Windows Git trust step is needed at all. But this mode was never tried, and commits then leave the sandbox only by `git push`: `git fetch sandbox-<name>` does not exist without a host clone, which changes the removal check in Q5. It needs a trial of its own before I can plan it.

**Answer:**
Accepted the recommendation: the script makes the host clone and adds the Windows Git trust line itself (engineer, in the conversation, 2026-11-17).

### Q4 — How should the three VS Code extensions get into a sandbox window?

**Why it matters:** a Remote-SSH host has no `devcontainer.json`, so nothing installs Claude Code, ShellCheck and Markdown Mermaid there (T12). The criterion says they "are installed there" after one documented step. The routes differ in what they change on your machine.

**Options:**
- *A one-time setting on your Windows VS Code* (recommended): `remote.SSH.defaultExtensions` in your user settings lists the three, and VS Code then installs them on every SSH host it connects to, sandboxes included. The README gives the setting as a one-time setup step; the "one step" per sandbox is then the open command alone. It also applies to any other SSH host you connect to.
- *Recommendations in the repository:* `.vscode/extensions.json` names the three and VS Code offers to install them when the folder opens (one click per sandbox). Nothing on your machine changes. `.vscode/` is ignored here today because `window-title.sh` writes `settings.json` into it, so this file would need an exception.
- *The open command installs them:* the script runs VS Code's `--install-extension` against the sandbox for each of the three, then opens the folder. Whether that works against a Remote-SSH host is not known and needs a trial.

**Answer:**
Accepted the recommendation: a one-time `remote.SSH.defaultExtensions` user setting, documented as setup (engineer, in the conversation, 2026-11-17).

### Q5 — How should ending a sandbox work, and how far into `/codeo:cleanup` does it go?

**Why it matters:** the issue wants one way to finish an issue, sitting with #70's cleanup. Today `/codeo:close` and `/codeo:cleanup` print `docker rm -f codeo-<N>; docker volume rm codeo-<N>` from the overlay's `removal-command`, and neither can tell a sandbox from a container. `scripts/cleanup.sh` and `skills/cleanup/SKILL.md` are in #116's footprint, so changing them here collides with it.

**Options:**
- *A sub-command of the host script, named in the docs and the overlay text* (recommended): `end <N>` fetches the sandbox's commits into the host clone (`git fetch sandbox-codeo-<N>`), compares every sandbox branch with `origin`, and removes the sandbox only when nothing is unpushed; otherwise it lists the commits and stops. `--force` removes it after the fetch has kept the commits in `refs/sandboxes/`. The README says what to run for a sandbox where `/codeo:close` and `/codeo:cleanup` print the Docker commands. No plugin script or skill changes.
- *Also teach the printed removal command:* `/codeo:close` and `/codeo:cleanup` print the `end <N>` command for an issue that ran in a sandbox. That needs a way to record where an issue ran and changes `scripts/cleanup.sh` and two skills, which ship to every project that uses codeo and overlap #116. I would file this as its own issue rather than do it here.
- *Documentation only:* the README lists the fetch, the check and `sbx rm` as steps to run by hand. Nothing stops a removal with unpushed work, which the criterion asks for.

**Answer:**
Accepted the recommendation: an `end <N>` sub-command with `--force`, documented; no plugin script or skill changes here, and the printed removal command is not changed (engineer, in the conversation, 2026-11-17).

### Q6 — Where should #86's corrected wording go, now that #86 is closed and its text lives in #99's body?

**Why it matters:** two criteria of the #94 part are about #86's text ("#86's sentence agrees with it", "#86 cites one trial range"). The plan needs a task that edits a GitHub issue body, and it has to name which. The same goes for the #73 comment that carries the page's counts.

**Options:**
- *Edit the "Part of #86" section of #99's body* (recommended): that is the text now in force. The closed #86 is left as the record of what was filed, and the evaluation page's follow-up section points at #99.
- *Edit both #99's section and the closed #86.*
- *Edit neither:* the page alone is corrected, and the plan records that the two criteria are met by the page saying what #86 said wrongly.

**Answer:**
Accepted the recommendation: edit the "Part of #86" section of #99's body; the closed #86 stays as filed (engineer, in the conversation, 2026-11-17).

### Q7 — #116 also changes `.devcontainer/README.md`, `tests/devcontainer.test.sh` and `CHANGELOG.md`: proceed, wait, or re-scope?

**Why it matters:** #116 (branch `fix/follow-ups-70-71-104`, assignee kbajpai, at `qc`) lists `.devcontainer/README.md`, `tests/devcontainer.test.sh` and `CHANGELOG.md` in its footprint and has changed all three. The #114 part of this plan adds a paragraph to `.devcontainer/README.md`, cases to `tests/devcontainer.test.sh` (and their names to its `cases` list) and a bullet to `CHANGELOG.md`. Nothing else overlaps as far as the design goes today: #116 does not touch `devcontainer-start.sh`, `session-title.sh`, `.codeo/overlays/` or the evaluation page. With Q5's second option, `scripts/cleanup.sh` and `skills/cleanup/SKILL.md` would overlap too.

**Options:**
- *Proceed and coordinate* (recommended): each change is an addition to a list or a section; whichever merges second resolves small conflicts, which `/codeo:close` already routes. #116 is at `qc`, so it will very likely merge first and this branch merges `origin/main` before its documentation tasks.
- *Sequence after #116:* the #114 tasks wait until #116 merges.
- *Re-scope:* move the #114 part's README and changelog text out of this change.

**Answer:**
Accepted the recommendation: proceed and coordinate with #116 (engineer, in the conversation, 2026-11-17).

### Q8 — #116: `glob:.devcontainer/README.md`, `glob:tests/devcontainer.test.sh`, `glob:CHANGELOG.md` — confirm Q7 covers the footprint as written

**Why it matters:** `overlap.sh 99` printed these three tokens against the plan's committed footprint. They are the overlap Q7 already decided. Q7 named the paths but not these tokens, so the check does not recognise it as raised. #116 is on branch `fix/follow-ups-70-71-104`, assignee kbajpai, at `qc`. If you keep Q7's answer, nothing in the plan changes. Any other answer moves Tasks 1, 2 and 13.

**Options:** *proceed and coordinate* (recommended, as Q7) · *sequence after #116* · *re-scope*.

**Answer:**
Accepted the recommendation: proceed and coordinate with #116, as Q7 (engineer, in the conversation, 2026-11-17).

### Q9 — #103 also changes `glob:CHANGELOG.md`: proceed, wait, or re-scope?

**Why it matters:** #103 (branch `feat/let-codeo-triage-judge-flight`, assignee kbajpai, at `init`) lists `CHANGELOG.md` in its footprint. Its branch has changed nothing yet. This plan adds three bullets under `## Unreleased`, in Tasks 2 and 13. Nothing else overlaps: #103's other files are `scripts/inflight.sh`, `lib/env.sh`, the triage skill, `docs/skills.md` and `docs/handoff.md`, none of which this plan touches.

**Options:** *proceed and coordinate* (recommended: both add bullets to one list, and whichever merges second resolves a small conflict) · *sequence after #103* · *re-scope* (leave `CHANGELOG.md` out of this change).

**Answer:**
Accepted the recommendation: proceed and coordinate with #103 (engineer, in the conversation, 2026-11-17).

## Notes

### Confirmed for the #114 part (no question)

The issue asks planning to confirm where the trust decision is stored. Claude Code's documentation (permissions page, "What runs before you trust a folder", and the `.claude` directory page, read 2026-11-17) says: a folder is trusted by `projects["<path>"].hasTrustDialogAccepted: true` in `~/.claude.json`; with `CLAUDE_CONFIG_DIR` set the file is `$CLAUDE_CONFIG_DIR/.claude.json`; in a git repository the path is the repository root; and trust of a parent folder does not count as trust of the folder. It also says the VS Code extension "asks for the same trust" in its "Trust this folder in Claude Code?" dialog. This container agrees: `/workspaces/.claude/.claude.json` has `projects["/workspaces/codeo-99"].hasTrustDialogAccepted: true`.

Not documented: that the extension reads that same file. So the plan writes the key from the start script (after step 3c, same pattern: object check, temp file, one TODO, exit 0) and ends with a host task in which you create a new container in VS Code and confirm no dialog appears. Reports say a running Claude session can rewrite `.claude.json`, so the step runs after `plugins.sh` and before any session.

### Calls I am making unless you object

- The sandbox's host script and its README live in a new top-level folder `.sbx/` (`.sbx/codeo-sandbox.sh`, `.sbx/README.md`), not in `.devcontainer/`, because #85 excludes changes to `.devcontainer/` beyond sharing code. Its tests are `tests/sandbox.test.sh`, run against a stub `sbx.exe`, the way `tests/cmd-mode.test.sh` stubs `docker`.
- The host script takes the program names from `CODEO_SBX` (default `sbx.exe`) and `CODEO_SSH` (default `ssh.exe`), so a Linux or macOS host can set `sbx`.
- The git identity comes from the host's `git config --global` (else `GIT_AUTHOR_NAME` / `GIT_AUTHOR_EMAIL`) and reaches the start script as `GIT_AUTHOR_*`, as in `codeo-container.sh`.
- The sandbox is named `codeo-<N>` and the host clone folder is `codeo-<N>`, so the existing folder check compares the right name if the sandbox mirrors the folder name (S5 shows the path).
- Session titles: the host script writes a marker file `~/.codeo-sandbox` inside the sandbox, and `session-title.sh` treats it like `REMOTE_CONTAINERS=true`; this does not depend on whether `sbx` keeps environment variables for later sessions.
- The image pin is one line in `.sbx/claude-image` (a `docker.io/sbx/claude@sha256:…` reference) that the script passes to `sbx create`; how `create` takes a digest is read from S9's help output.
- The unexplained stops: a host task repeats "start one sandbox while another runs" 10 times and records `sbx ls` after each; the README states the count and what was seen, and `sbx run -d --name <name>` as the recovery.
- One plan file with four parts in the order #114, #94, #85, #86, one pull request. The trials are Task 5, before the tasks that depend on them; the acceptance run is the last task.
- `.codeo/config.json`'s `shell` suite gains `.sbx/**` in its `paths`, so changes there trigger the suite.

### Trials (for Q1)

Run in WSL2 bash from the folder that holds your clones (`~/Source` in #73). One command per line. Where a line has `<user>`, put your WSL user name. Paste each output under its line with tokens and account names removed.

**S1 — a scratch sandbox on `main`, and the `Image:` line.**

```
git clone https://github.com/kbajpai/codeo codeo-sbx-t
cd codeo-sbx-t
git.exe config --global --add safe.directory '%(prefix)///wsl.localhost/Ubuntu-24.04/home/<user>/Source/codeo-sbx-t'
sbx.exe create --clone --name codeo-t claude .
```

Paste the whole create output; the `Kit:` and `Image:` lines in full matter (a digest is not a secret). Also: do you still have the terminal output of T3, T8 and T10 with their `Image:` lines? The repository records only shortened digests (`4df39400…`, `0fb3e2c5…`). If not, the page quotes those as recorded and says they were shortened.

**S2 — is the sandbox's `gh` token the real one? (the page's T13)**

```
gh auth token
sbx.exe exec codeo-t gh auth token
sbx.exe exec codeo-t printenv GH_TOKEN
```

Do not paste the values. Say whether the three are the same string, and if not, what the sandbox's looks like (its length and first four characters, or the placeholder text).

**S3 — identity and environment.**

```
sbx.exe exec codeo-t git config user.name
sbx.exe exec codeo-t git config user.email
sbx.exe exec codeo-t printenv REMOTE_CONTAINERS
sbx.exe exec codeo-t ls /.dockerenv
sbx.exe exec codeo-t whoami
sbx.exe exec codeo-t pwd
```

**S4 — a push from inside.**

```
sbx.exe exec codeo-t gh auth setup-git
sbx.exe exec codeo-t git push origin HEAD:refs/heads/scratch/sbx-push-test
sbx.exe exec codeo-t git fetch origin
sbx.exe exec codeo-t git push origin --delete scratch/sbx-push-test
```

**S5 — the dev container's start script, unchanged, in the sandbox (for Q2).**

```
sbx.exe exec codeo-t env CODEO_CMD_MODE=1 bash .devcontainer/scripts/devcontainer-start.sh
sbx.exe exec codeo-t claude plugin list
```

On `main` it takes no lock, and its folder check will print one TODO about the folder name; that is expected here.

**S6 — the window title and opening the folder.** Use the path S3's `pwd` printed in place of `<path>`.

```
sbx.exe exec codeo-t bash .devcontainer/scripts/window-title.sh
cmd.exe /c code --folder-uri vscode-remote://ssh-remote+codeo-t.sbx<path>
```

Say whether VS Code opened on the clone folder, what the window title was, and which extensions the remote side lists.

**S7 — the trust file in a VS Code dev container (for the #114 part).** In any dev container you opened through VS Code and clicked "Trust folder" in:

```
jq .projects /home/dev/.claude/.claude.json
```

**S8 — an environment variable kept with the sandbox.**

```
sbx.exe create --help
sbx.exe exec --help
sbx.exe rm --help
sbx.exe template --help
```

**S9 — remove it, with a commit inside that was never pushed.**

```
sbx.exe exec codeo-t git commit --allow-empty -m scratch
git fetch sandbox-codeo-t
git for-each-ref refs/sandboxes
sbx.exe rm codeo-t
```

Paste the warning `rm` prints, then answer `y`.

## Outcome

| | |
|---|---|
| Plan | `docs/plans/2026-11-17-sbx-issue-sandbox.md` (approved 2026-11-17, unstaged for the engineer to commit) |
| Shape | An executable plan under `docs/plans/`, with no separate reference doc: the choices are small and local to this change, and `.sbx/README.md` (Task 13) is the standing reference for the sandbox route |
| Tasks | 14 in all: 12 proved by `bash tests/run.sh` or a named check, and 2 run on the engineer's host (Task 5 trials S1-S9, Task 14 acceptance) |

**Decisions.**
- Four parts, in this order: #114 (Tasks 1-2), #94 (Tasks 3-4 and 6), #85 (Tasks 7-8), #86 (Tasks 9-13). One branch and one pull request.
- Folder trust (#114) is a new step 3d in `devcontainer-start.sh`. It writes `projects["<top>"].hasTrustDialogAccepted` in `$CLAUDE_CONFIG_DIR/.claude.json`, written like step 3c. The key and the file are confirmed from Claude Code's documentation. That the VS Code extension reads the same file is checked on the host in Task 14.
- The sandbox route is a new host script, `.sbx/codeo-sandbox.sh`, with four sub-commands: `issue`, `open`, `shell` and `end`. It runs on Linux and WSL2 bash and picks `sbx` or `sbx.exe` itself (Q1).
- In the sandbox it runs the unchanged `devcontainer-start.sh` in cmd mode (Q2).
- It clones the branch on the host and writes the Windows Git trust line itself, only with `sbx.exe` (Q3).
- The three extensions come from a one-time `remote.SSH.defaultExtensions` user setting (Q4).
- `end <N> [--force]` refuses to remove a sandbox with commits not on `origin` (Q5).
- The image is pinned in `.sbx/claude-image`.
- Session titles in a sandbox come from a marker file read by `session-title.sh`.
- `.codeo/config.json`'s `shell` suite gains `.sbx/**` in its `paths`.
- #86's corrected wording goes into #99's body, not into the closed #86 (Q6).
- The S1-S9 trials are the plan's Task 5, not run before planning (Q1). Tasks 8, 10 and 11 depend on their results, and each names its fallback or the point where it stops.
- #116 and #103 overlap on `.devcontainer/README.md`, `tests/devcontainer.test.sh` and `CHANGELOG.md`. Both are proceed and coordinate (Q7-Q9).

**Rejected.**
- A new in-sandbox start script, shared or standalone (Q2).
- Printing the trust command instead of running it (Q3).
- A mountless sandbox (Q3).
- `.vscode/extensions.json`, or installing the extensions from the open command (Q4).
- Teaching `/codeo:close` and `/codeo:cleanup` about sandboxes, or documenting the removal steps only (Q5).
- Editing the closed #86 (Q6).
- Running the trials before drafting (Q1).

**Documentation the plan changes.**
- `.devcontainer/README.md` (Tasks 2 and 13).
- `.sbx/README.md`, new (Task 13).
- `.codeo/overlays/init.md`'s hand-off (Task 13).
- `docs/dev-environment-sbx-evaluation.md` (Tasks 3 and 6).
- `CHANGELOG.md` (Tasks 2 and 13).
- #99's body (Task 4), and #73's result comment if its counts change (Task 6).

**Intake questions resolved.**
- #114: where the trust is stored is settled from Claude Code's documentation, and Task 14 checks it in the extension.
- #94's token question, #85's push and `user.email`, and #86's `REMOTE_CONTAINERS` question and unexplained stops are not resolved by planning. They become Task 5's trials and Task 14's acceptance run. Session titles in a sandbox no longer depend on `REMOTE_CONTAINERS` (the marker file).

### Footprint

```
files:      .devcontainer/scripts/devcontainer-start.sh, .devcontainer/scripts/session-title.sh, .devcontainer/README.md, .sbx/**, tests/devcontainer.test.sh, tests/sandbox.test.sh, tests/init-overlay.test.sh, .codeo/config.json, .codeo/overlays/init.md, docs/dev-environment-sbx-evaluation.md, docs/plans/2026-11-17-sbx-issue-sandbox.md, CHANGELOG.md
wiki:       none
exclusive:  none
sequenced:  none
```

## Log

- 2026-11-17 — Q1-Q7 raised · cost: 3m · fable-5-2 118k in + 1.1M cached / 6k out · sonnet-5-5 76k in + 283k cached / 7k out
- 2026-11-17 — Q1-Q7 answered in the conversation; plan approved and written: docs/plans/2026-11-17-sbx-issue-sandbox.md; overlap.sh raised Q8-Q9 · cost: 43m · fable-5-2 144k in + 1.6M cached / 22k out · opus-5-5 179k in + 2.4M cached / 34k out · sonnet-5-5 76k in + 283k cached / 7k out · engineering plugin unavailable, its structure applied directly
- 2026-11-17 — planned: docs/plans/2026-11-17-sbx-issue-sandbox.md · cost: 46m · fable-5-2 144k in + 1.6M cached / 22k out · opus-5-5 183k in + 3.3M cached / 37k out · sonnet-5-5 76k in + 283k cached / 7k out · Q8-Q9 answered; engineering plugin unavailable, its structure applied directly
