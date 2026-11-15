# Issue #96 — plan

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/96 |
| Branch | `feat/dev-container-follow-ups-40` |
| Updated | 2026-11-15 |

## Where this stands

Round 1. The issue's five sections, the dev container scripts and their tests are read. Most of the work has one sensible shape and needs no answer; those calls are listed under `## Notes` so you can correct any of them. Seven questions are open. Q1 is the only one that changes the design; Q2-Q5 are short; Q6 and Q7 are the overlaps with #70 and #98. No draft is written until they are answered.

## Questions

### Q1 — A clone folder Docker rejects as a container name (`my project`, `_x`): keep the folder as the name, or start everywhere?

**Why it matters:** #54's criterion says such a container "starts, with a valid container name", by the name "falling back to a valid one". `devcontainer.json` cannot do that: `--name=${containerWorkspaceFolderBasename}` is substituted by VS Code as it stands, with no way to transform it, and Docker refuses the name before any of our scripts runs. So the criterion can only be met by giving up the folder as the Docker name, which is what #50 added. The answer decides whether `runArgs`, `folder-check.sh`'s reason for existing, the README's table and *The folder rule* change, or only the CHANGELOG.

**Options:**

- **Keep the name, document the limit (my pick).** `runArgs` is unchanged. The README already states the limit; the CHANGELOG gains it (that was the other half of #50 F1). The criterion stays unmet as written, so you would amend it on #96 (I never edit the issue), or `/codeo:qc` reports it as not met. Reason: the documented flow only ever uses `codeo-home` and `codeo-<N>`, which are always valid, and `docker ps` showing `codeo-96` is worth more than starting from a folder nobody is told to use.
- **Drop `--name`, add a label.** `runArgs` carries `--label=codeo.folder=${containerWorkspaceFolderBasename}` in place of the name (a label takes any text). Every folder starts; Docker picks a random name; `docker ps` no longer shows `codeo-<N>` unless asked for the label. The "name already in use" clash disappears with it, and so does #88's README wording item. The README table, *The folder rule*, *Rebuilding*, `container-name.sh --docker` and `folder-check.sh`'s wording all change, and every existing container gets a new name on its next rebuild. Needs a check on your machine that both folders start.
- **Drop `--name`, nothing in its place.** As above without the label.

A host-side rename (an `initializeCommand` that sanitises the name) is not offered: in the named-volume flow that command does not run on your machine with Docker to hand, and I cannot verify it from here.

**Answer:**

### Q2 — The CPU cap: remove it, or keep a cap of 2 another way?

**Why it matters:** `--cpus=2` makes Docker refuse to create the container on a 1-CPU host, and on a host without CPU cgroup support. Removing it lets the container use every host CPU; keeping a cap needs a different flag and a check I cannot run here.

**Options:**

- **Remove `--cpus=2`; `--memory=4g` stays (my pick).** Proved inside the suite: `runArgs` is pinned to exactly the name and the memory cap. No dependence on how a Docker version treats a flag.
- **Keep a cap of 2 with `--cpu-period=100000` and `--cpu-quota=200000`.** As I recall Docker's checks, a quota is not compared with the host's CPU count and is dropped with a warning where the kernel lacks support, so the container starts in both cases and is still capped at 2. This rests on my memory of Docker's behaviour, not on a test: it adds a task you run on your machine (Q5) to confirm it, and rootless Podman may differ.

**Answer:**

### Q3 — The optional item: should Claude's login and plugins survive a rebuild?

**Why it matters:** it is the one item #40 marks optional, and `init.md` left it open. Doing it means a volume at `/home/dev/.claude`, which needs the directory created in the Dockerfile with the right owner, and #40's own Out of Scope excludes image changes. It also decides whether `.devcontainer/Dockerfile` and the README's *Rebuilding* paragraph are in this plan.

**Options:**

- **Leave it out and file it as its own issue (my pick).** The README already says `~/.claude` is lost on a rebuild and what to do. The design has a real choice in it that deserves its own pass: a volume shared by every container (like `codeo-gh`) would also share the plugin registry, and two containers on branches with different `plugin.ref` pins would each reinstall codeo over the other; a volume per container survives a rebuild but still needs a login in every new issue container, which is the more frequent cost.
- **Leave it out, file nothing.** Recorded here as dismissed.
- **Do it here, one volume per container.** `source=codeo-claude-${devcontainerId},target=/home/dev/.claude,type=volume`, plus the Dockerfile line. Survives a rebuild of that container only.
- **Do it here, one shared volume.** `codeo-claude` for all containers. One login for everything; the pin conflict above has to be solved in `plugins.sh` first.

**Answer:**

### Q4 — Who edits the v1.0.6 Release body on GitHub?

**Why it matters:** #81 asks for the auto-generated `## What's Changed` and `**Full Changelog**` lines to be removed from the published v1.0.6 Release. `docs/release-checklist.md` opens with "Nothing here is done by an agent", and editing a published Release is visible to everyone. The answer decides whether the plan has a task `/codeo:implement` runs with `gh release edit`, or one marked for you.

**Options:**

- **You run it (my pick).** The plan carries one task marked as yours with the exact command (`gh release edit v1.0.6 --notes-file <file>`, the file being the changelog section the plan writes into the repository for the purpose, or printed for you to paste) and the check that proves it (`gh release view v1.0.6 --json body`). It can be run from this container, since `gh` is logged in here. This keeps the checklist's rule true.
- **`/codeo:implement` runs it.** Same command, run by the agent in this container. The checklist's opening sentence then gets an exception.
- **Leave the Release as it is.** The checklist says why v1.0.6 differs, which the criterion also allows.

Either way the checklist gains the missing step 8: how a Release is created from the changelog section, without GitHub's generated notes.

**Answer:**

### Q5 — Which shell do you type in on your own machine?

**Why it matters:** only if Q1 or Q2 is answered with an option that needs a check on your machine (starting a container from a folder named `my project`, or on a capped CPU). Such a task is marked `Runs on: the engineer's host`, and its command has to work in the shell you use; a command that cannot be written to suit every shell is labelled with yours. If Q1 and Q2 both take my pick, there is no such task and this needs no answer beyond "n/a".

**Options:** PowerShell · Git Bash · WSL bash · something else (name it) · n/a.

**Answer:**

### Q6 — This plan and #70 change the same files: proceed, sequence, or re-scope?

**Why it matters:** #70 (`feat/guard-home-only-skills-against`, assignee kbajpai, step `plan (working)`) lists in its footprint `glob:.devcontainer/README.md`, `glob:CHANGELOG.md` and `glob:tests/**`, and this plan changes `.devcontainer/README.md`, `CHANGELOG.md`, `tests/devcontainer.test.sh`, `tests/codeo-root.test.sh` and `tests/container-name.test.sh`. Both add an Unreleased bullet to the changelog and both edit the dev container README; whichever merges second resolves those by keeping both. #70's new script (`.devcontainer/scripts/role.sh`) is not touched here. The answer decides whether this plan carries a "merge `origin/main` first, keep both bullets" step in its last task, waits for #70, or drops something.

**Options:**

- **Proceed and coordinate (my pick).** The overlaps are additive: separate changelog bullets, separate README paragraphs, separate test cases. The plan's last task merges `origin/main` before touching `CHANGELOG.md` and the README, as #57's plan did with #76.
- **Sequence after #70.** This plan is written now and built once #70 has merged; recorded as `sequenced:` in the footprint.
- **Re-scope.** Say what to drop from this plan.

**Answer:**

### Q7 — This plan and #98 both change `CHANGELOG.md`: proceed, sequence, or re-scope?

**Why it matters:** #98 (`fix/fix-sync-main-sh-exiting`, assignee kbajpai, step `init (working)`) lists `glob:CHANGELOG.md` in its footprint; it has changed no file yet, so that line is all there is to compare. Both add an Unreleased bullet. The answer decides the same thing as Q6, for this one file.

**Options:**

- **Proceed and coordinate (my pick).** Two separate bullets under `## Unreleased`; the second branch to merge keeps both.
- **Sequence after #98.**
- **Re-scope.**

**Answer:**

## Notes

### Calls made without a question

Each of these has one sensible answer given the issue and the code. Say so in any answer above if one is wrong.

- **One plan, one pull request.** The issue asks for one pass; the output is `docs/plans/2026-11-15-dev-container-follow-ups-96.md`, a plan in the shape of `2026-11-14-dev-container-follow-ups.md`, with no separate reference doc.
- **`lib/env.sh` changes, by one comment line.** #40 requires the `plugin` key in its key reference. The "nothing under `scripts/`, `lib/`, `hooks/`, `skills/`" lines belong to #54, #88 and #91 and apply to their own sections, as the issue's preamble says.
- **Already met on `main`, so mapped and not rebuilt:** the duplicate `safe.directory` entry (the start script checks before adding, and a test pins "once"); a non-regular `~/.claude/settings.json` gets a TODO; `runArgs` is already pinned to its exact array by `run_args_name_the_container_after_its_clone`, so a second `--memory` already fails (the loose sibling case is folded into it).
- **#81, the half-written `~/.gitconfig`: settled, the window exists.** In this container `stat ~/.gitconfig` gives birth `13:11:58.459`, modify and change both `13:11:58.500`. A rename moves the change time past the modify time on this filesystem (checked with a probe file), and here they are equal, so the file was created at its own path and written about 41 ms later, not written elsewhere and moved into place. The plan therefore closes the window: the start script reads the host copy only once it has stopped changing, with a test. `/codeo:implement` records this on the issue as a comment.
- **#81, includes: documented, not followed.** VS Code copies only `~/.gitconfig` into the container; a file it includes stays on the host, so following `[include]` would find nothing. The README says that only values written directly in `~/.gitconfig` count.
- **#88's six left minors: five fixed, one dismissed.** Fixed: the `lock-calls-mine` assertion that is trivially true, the loose `grep -o boom | wc -l`, the CHANGELOG's one-parenthetical statement of the limit (rewritten anyway by the "cannot both exist" wording), the `--docker` usage line in `container-name.sh`, and the `registry` helper that splits on `@`. Dismissed: `home_folder_on_a_configured_base_is_silent` also passing at the base, because the issue itself says its two sibling cases carry the proof.
- **`claude auth status` moves to `$HOME`**, the way `plugins.sh` already runs every `claude` call; the bind-mount TODO explains the user-namespace mapping in place of the `sudo chown -R` advice; the `cd ""` quirk and the stray `>=` comment are fixed alongside.
- **Documentation this moves:** `.devcontainer/README.md` and `docs/release-checklist.md`. No other page under `docs/` describes the dev container.
- **No shared environment, no invariants document, no wiki** are configured, so no task carries a lease and there is nothing to check the plan against beyond the issue. The `shell` suite has no single-test filter, so each task's proof is `bash tests/run.sh` ending `all cases passed`.

### Footprint

```
files:      .devcontainer/devcontainer.json, .devcontainer/README.md, .devcontainer/scripts/devcontainer-start.sh, .devcontainer/scripts/plugins.sh, .devcontainer/scripts/window-title.sh, .devcontainer/scripts/codeo-root.sh, .devcontainer/scripts/container-name.sh, tests/devcontainer.test.sh, tests/codeo-root.test.sh, tests/container-name.test.sh, lib/env.sh, CHANGELOG.md, docs/release-checklist.md, docs/plans/2026-11-15-dev-container-follow-ups-96.md
wiki:       none
exclusive:  none
```

Draft: Q1 and Q3 can add `.devcontainer/Dockerfile` and `.devcontainer/scripts/folder-check.sh`.

## Outcome

_Pending — written at the hand-off._

## Log

- 2026-11-15 — Q1-Q7 raised · cost: 4m · fable-5-2 111k in + 1.2M cached / 20k out
