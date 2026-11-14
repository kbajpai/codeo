# Issue #73 — plan

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/73 |
| Branch | `docs/evaluate-docker-sandboxes-sbx-against` |
| Updated | 2026-11-14 |

## Where this stands

Round 2. Q1-Q5 are answered (in the conversation, recorded below as given); the plan is drafted in `.codeo/73/plan-draft.md` and awaits the engineer's approval. Round 1 had read the issue, `init.md`, `.devcontainer/` and the recent plans.

## Questions

### Q1 — Where should the written comparison live?

**Why it matters:** it decides which files the plan's tasks write and what proves them. `docs/` in this repository ships with the plugin (the skills read `docs/handoff.md` and `docs/dossier.md` from it), so a page there about codeo's own development environment goes to every project that installs codeo. `.devcontainer/README.md` is where the development environment is documented today, but the issue says `.devcontainer/` stays unchanged. #58 recorded its results in the issue itself.
**Options:**
- **A — `docs/dev-environment-sbx-evaluation.md`**, a standing page with a status banner and a contents table, plus a link to it in a comment on #73. Reviewed in the pull request like any change; ships with the plugin. This is my pick: the recommendation is a decision later issues will cite, and a page in the repository can be cited by path and line.
- **B — a comment (or a few) on #73 only**, as #58 did. Nothing ships with the plugin; the pull request then carries only the plan and the dossier, and the comparison is not reviewed as a diff.
- **C — somewhere else you name** (a `docs/dev/` folder for pages about developing codeo itself, say).

**Answer:**
A — `docs/dev-environment-sbx-evaluation.md`. (Given in the conversation, 2026-11-14.)

### Q2 — How much of the comparison is tried on your machine, and how much is cited?

**Why it matters:** this session cannot run `sbx`: the issue container has no Docker and no `sbx`, and a microVM cannot be started from inside it. Every "tried" point is therefore a task you run on your own host and paste the output of, marked `Runs on: the engineer's host`. The answer sets how many such tasks the plan has, and whether the acceptance criterion "states whether sbx runs on the current host (Windows + WSL2), with evidence" is met by a run or by a Docker doc.
**Options:**
- **A — hands-on.** You install `sbx` and run a checklist of about ten to fifteen commands across one or two sittings: install and version, start a sandbox on a clone of codeo, run `bash tests/run.sh` in it, log in to Claude and `gh` and check both survive a stop and start, install the two plugins, run two sandboxes at once, try a blocked network address, try attaching VS Code. Each point in the comparison is then marked *tried*, with the rest *cited*. This is my pick: three of the four drivers (lifecycle, logins, parallel agents) are about how it behaves, which the docs describe only in outline.
- **B — host check only.** You run three or four commands (install, version, one sandbox started and stopped). Only "runs on this host" is *tried*; everything else is *cited* from Docker's documentation.
- **C — cited only.** Nothing is installed. Host support is answered from Docker's stated requirements, and the comparison says plainly that nothing was tried.

**Answer:**
A — hands-on. (Given in the conversation, 2026-11-14.)

### Q3 — What is the host, and may `sbx` be installed on it?

**Why it matters:** `sbx` has host requirements (a Windows version, a hypervisor feature that may need turning on with administrator rights and a restart, a Docker account). If one of them rules the machine out, that is itself the finding for the host criterion and Q2's checklist shrinks to recording why. If `sbx` or Docker Desktop is already there, the install task is dropped. Please give, as far as you know them:
- the Windows edition and version (for example Windows 11 Pro 24H2);
- whether Docker Desktop is installed, and its version, or whether Docker runs another way (Docker Engine inside WSL2);
- whether `sbx` is already installed, or `docker sandbox` has been used before;
- whether you are willing to install `sbx` and turn on a Windows feature for this, restart included;
- whether a second machine (a Mac, a Linux box) is available and worth a comparison run, or the evaluation is this host only.

**Options:** none to pick from; the facts as you have them. "Don't know" for any line is fine, and the plan then starts with a task that finds it out.

**Answer:**
"As you recommend" (given in the conversation, 2026-11-14). Q3 offered no options, so this is read as: host facts unknown, and willing to do what Q2 A needs. The plan starts with a task that finds the facts out.

### Q4 — Which shell do you type in on the host?

**Why it matters:** the tasks you run on the host are written for the shell you use. A command that is one plain line works anywhere, but a few checks (looping over two sandboxes, capturing output to a file) are not, and those are labelled `Shell: <name>` and written for that shell. #67's Task 3 was written in bash and failed in PowerShell.
**Options:** PowerShell · a WSL2 distribution's bash (say which distribution) · Git Bash · something else.

**Answer:**
"I can use BASH on WSL if that makes it easier" (given in the conversation, 2026-11-14). Host tasks are written for bash in a WSL2 distribution.

### Q5 — What would have to be true for you to actually move, and what would rule it out?

**Why it matters:** the comparison ends in one recommendation, and the drivers in the issue can point different ways: `sbx` may be stronger on isolation and parallel agents and weaker on editing in VS Code, for instance. The answer sets how the points are weighed and which gaps count as "no equivalent, and that settles it" rather than "no equivalent, worked around". Two things I would otherwise have to guess: whether working in the VS Code window (the Claude Code extension, the window titles, the editor beside the session) is something you want to keep or are glad to leave, and whether Remote Control from another device, which the start script turns on today, has to keep working. Remote Control is out of scope as a topic, but losing it would still be a cost of moving.
**Options:** none; your own words.

**Answer:**
"As you recommend" (given in the conversation, 2026-11-14). Q5 offered no options, so this is read as: weigh the four drivers as the issue lists them; a lost VS Code window or a lost Remote Control is a cost to record, not a veto.

## Notes

- **Shape, as it stands before the answers.** One pull request. A plan under `docs/plans/` (the work is a scoped body of tasks), with the comparison as its product in the place Q1 names. The comparison is two tables and a recommendation: drivers and requirements against both setups, and each duty of the current setup against its `sbx` equivalent, workaround or "no equivalent"; every row marked *tried* or *cited*, a cited row carrying the Docker doc's URL and the date it was read.
- **The duties to map**, from the issue and `.devcontainer/`: the home/issue split; one clone per issue in a named volume; the start script's steps (trust and chown of the clone, the executable-bit repair, plugins, the workflow lock from `init.md`, the folder check, window title, Remote Control setting, `gh` wiring and the project scope check, git identity seeding, the Claude login check, the TODO list); `plugins.sh` (superpowers, and codeo at the pin in `.codeo/config.json`); window and session titles; the `codeo-gh` and `codeo-git` volumes; the `--memory=4g --cpus=2` limits; the three VS Code extensions.
- **Not verified yet:** `sbx`'s host requirements, how it mounts or clones a workspace, how it holds credentials, and whether an editor can attach. These are what the plan's tasks find out; nothing above assumes an answer.
- **Follow-up issues.** If the recommendation is migrate or hybrid, the plan's last task files them through `/codeo:issue` and links them on #73; that needs you in the conversation for each one.
- **Unchanged by this issue:** `.devcontainer/` and `skills/`. The plan states a proof for that (`git diff --stat main -- .devcontainer skills` prints nothing).
- **Other workflows in flight:** none (`inflight.sh --except 73`, 2026-11-14), so there is no footprint overlap to raise at this point.
- **Overlays:** `plan-shape`, `proof-of-done` and `wiki-rules` are not set (exit 3); the generic shape and the default proof apply. No invariants document, no shared environment, no wiki module, no exclusive resources.

### Footprint

```
files:      docs/dev-environment-sbx-evaluation.md, docs/plans/2026-11-14-evaluate-docker-sandboxes-sbx.md
wiki:       none
exclusive:  none
```

## Outcome

_Pending — written at the hand-off._

## Log

- 2026-11-14 — Q1-Q5 raised · cost: 1m · fable-5-2 50k in + 221k cached / 2k out
