# Issue #36 — plan

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/36 |
| Branch | `feat/add-dev-container-so-codeo` |
| Updated | 2026-11-07 |

## Where this stands

Round 2, after a send-back from `/codeo:qc` (qc.md round 1). Two blocking findings, both prescribed by the plan's own text: F1, `plugins.sh` runs `claude plugin marketplace remove` from inside the repository, and the CLI rewrites the tracked `.claude/settings.json` on every pin bump; F2, `devcontainer-start.sh` runs `sudo chown -R` on the clone's parent whenever the owner is not the current user, which can change the ownership of a bind-mounted host checkout on a rootless runtime. F1 has one sensible fix and no question. Q5 (F2) and Q6 (which non-blocking findings to fold in) are answered: both recommendations accepted. Drafting the round-2 amendment.

What this pass checked in the image (`codeo-dev-test`):
- A root-owned directory stays unusable for `dev` after `git config --global --add safe.directory`: `git status` and `touch` both fail with `Permission denied`. So the reviewer's suggested cure fixes git's "dubious ownership" refusal only when the clone is already readable and writable; a clone-in-volume made as root is neither, and a chown is still needed there.
- From inside the container, a named volume and a bind mount are distinguishable. In `/proc/self/mountinfo`, field 4 for a named volume mounted at `/workspaces/x` is `/var/lib/docker/volumes/<name>/_data`; for a bind mount of a host folder it is that folder's host path (`/home/<user>/…`). Podman volumes follow the same `…/volumes/<name>/_data` form. `findmnt` is in the image but not needed.

## Questions

### Q1 — Which ref does the container pin, and does superpowers get one too?

**Why it matters:** `plugins.sh` reinstalls whatever `.codeo/config.json` pins, so the pin decides which codeo the container runs: the last release, or whatever is on `main` at build time. The issue says "installed at the pinned ref, as the reference project's `plugins.sh` does", but the reference project pins only codeo and leaves superpowers at the marketplace's latest.

**Options:** codeo pinned to `v1.0.3` (the latest tag), superpowers unpinned as in the reference project (my recommendation: it matches the reference, and codeo is the only plugin whose version the repo's own tooling depends on) · codeo pinned to `v1.0.3` and superpowers pinned to a commit or tag you name · codeo pinned to `main` · something else.

**Answer:**
Accepted the recommendation.

### Q2 — How much of the reference project's start script does codeo's container need?

**Why it matters:** this sets the size of the work. The issue names only `plugins.sh` as a script to carry over, but the AC also need the `gh` login to work (`gh auth setup-git`, a hint for the missing `project` scope), and `/codeo:init` run in a container takes its lock through `lock.sh take container`.

**Options:**
- *Minimal (my recommendation):* a short `postCreateCommand` that runs `plugins.sh`, runs `gh auth setup-git` when logged in, and prints what is left to do (`gh auth login`, `gh auth refresh -s project`, `claude auth login`). No lock-taking and no container naming. `/codeo:init` binds the lock locally in whichever container you run it in, which `lock.sh` already supports.
- *Plus the lock:* also take the container lock at start, as the reference project does, and name the container `codeo-<N>` / `codeo-home` through `runArgs --name`.
- *Plus identity and Claude login scripts:* carry over `git-identity.sh` and `claude-login.sh` as well.

**Answer:**
Accepted the recommendation.

### Q3 — How is "done" proved for the acceptance criteria that need VS Code and a real login?

**Why it matters:** two criteria cannot be run from here. "Opening the repo in VS Code builds the container" needs the Dev Containers extension. "`gh auth status` shows the `project` scope … and the login survives a rebuild" needs your GitHub account. What I can prove here with `docker`: the image builds from a clean state, its contents are right (no .NET, Node, Terraform, gcloud or PostgreSQL), `bash tests/run.sh` passes in it as user `dev`, and `devcontainer.json` has the volume, `remoteUser` and `runArgs` the issue asks for.

**Options:** I prove everything `docker build` and `docker run` can show, and you confirm the VS Code open and the login-survives-rebuild by hand before `/codeo:close` (my recommendation; I list those two steps in the plan as manual checks) · I also try to install the `devcontainer` CLI on the host and use it for the build · you want the manual checks done differently.

**Answer:**
Accepted the recommendation.

### Q4 — The public repo may not name the reference project, but the issue's acceptance criterion does. What do we do?

**Why it matters:** `tests/agnostic.test.sh` fails when any tracked file names a project that uses codeo, because codeo is a public plugin that serves every project. The issue's text names that project in its Key Requirements and in the fifth acceptance criterion, and `init.md` copied them verbatim, as the init rules require. With the name in them, `bash tests/run.sh` already fails on this branch (it checks every tracked file, the dossiers included), and it would fail again when `/codeo:close` archives them under `.codeo/done/36/`. Every file this work adds, comments and the new test included, must also avoid the name.

**Options:**
- *Edit the issue (my recommendation):* you change #36's text to say "the reference project" instead of its name, I re-copy the criteria verbatim, and the criterion's intent is unchanged. Your action, since I never edit issue text.
- *Reword in the dossiers only:* the dossiers say "reference-project-specific tools" and keep a note that the issue's wording differs. I have done this already as a stopgap. The criterion QC judges against is then my rewording, not the issue's.
- *Exempt `.codeo/` from the agnostic test:* not recommended, since the dossiers are tracked in a public repo.

**Answer:**
Edit the issue. Done: the engineer edited #36, which no longer names the reference project, and its criteria match `init.md` verbatim. The dev container stays in this repo: a per-issue container is a clone of the issue's branch, so `devcontainer.json` must live in the repo being developed.

### Q5 — How should the start script fix a root-owned clone without touching a host checkout?

**Why it matters:** this is qc's F2. VS Code's clone-in-volume makes the clone as root, so `dev` can neither read it as a git repo nor write to it, and the whole pipeline (every commit) fails until ownership changes. A bind-mounted host folder under rootless Docker or Podman also *appears* root-owned inside the container, and a `chown -R` there changes the ownership of the engineer's own files on the host. The two cases look the same to `stat`, but not to `/proc/self/mountinfo` (above).

**Options:**
- *Gate the chown on a named volume (my recommendation):* always add `git config --global --add safe.directory <clone>` (harmless, cures the git refusal on every runtime); then chown **the clone itself, never its parent**, and only when (a) its owner is not the current user and (b) the mount that holds it is a named volume, read from `/proc/self/mountinfo` field 4 matching `/volumes/[^/]+/_data$`. A clone that is not the user's and is *not* on a named volume gets a TODO naming the situation and the command (`sudo chown -R …`, or run the container with the host UID), never an automatic chown. Tests cover the three cases with a stubbed mountinfo file: volume + foreign owner → chown of the clone; bind mount + foreign owner → TODO, no sudo; own uid → nothing.
- *Never chown:* `safe.directory` only, plus a TODO telling the engineer to `sudo chown` by hand when the clone is not theirs. Simplest, no risk to the host, but the first clone-in-volume container always comes up with a TODO before it can commit anything, which undercuts acceptance criterion 1's spirit.
- *Chown only when the owner is uid 0:* weaker than the first option, since a rootless runtime shows host files as uid 0 too.

**Answer:**
Accepted the recommendation.

### Q6 — Which non-blocking qc findings does this round fold in?

**Why it matters:** each is small, but each widens the diff `/codeo:implement` and the next `/codeo:qc` round have to carry; the ones left out go to `/codeo:triage` as loose ends.

**Options (my recommendation is to fold in the first group and defer the second):**
- *Fold in:* F5 (drop the pointless `/workspaces` line, or make its comment true), F6 (`has_plugin` matches the plugin name as a whole token, not an unanchored regex), F7 (`/home/${USERNAME}` instead of a hard-coded `/home/dev` in the Dockerfile `ENV`), F8 (`gh auth login -s project` as the one-step login the TODO list names), F9 (test cases: identity TODO with only `user.name` set and only `user.email` set; the `setup-git` failure TODO; the `plugin.ref` pin assertion loosened to "non-empty, well-formed tag or branch" so a pin bump does not need a test edit), F10 (this dossier's own `## Log` cost lines and `sequenced:` footprint key — fixed in this pass), F11 (`implement.md`'s `Deployed revision` line — `/codeo:implement` drops it in its round).
- *Defer to triage:* F3 (a volume for Claude's own login — Q2 decided against it and the issue asks only for `gh` to persist) and F4 (documenting the `plugin` key in `lib/env.sh` — it touches `lib/`, which the issue and the plan keep untouched; a one-line comment there is a separate, trivial issue).
- *Fold in everything, F3 and F4 included.*
- *Fold in only F1 and F2's fixes, nothing else.*

**Answer:**
Accepted the recommendation: fold in F5-F11, defer F3 and F4 to triage.

## Notes

Because codeo is a plugin that serves every project, not only this one, three things follow: no tracked file may name the reference project (so `tests/devcontainer.test.sh` assembles any such word from parts, as `agnostic.test.sh` does); `.devcontainer/` is generic to codeo's own needs (bash, jq, git, gh, shellcheck, Claude Code) and assumes nothing about a project that uses codeo; and the `plugin` pin and `codename` in `.codeo/config.json` are this repo's own settings, not defaults for anyone else. The plugin's source is `./`, so `.devcontainer/` also ships in every installed copy; it is inert there.

Calls I am making unless you say otherwise (none changes what gets built much):

- **Base image** is plain `ubuntu:24.04`, not the .NET SDK image. The git-core PPA is dropped, and git, jq, `shellcheck` and `gh` come from apt and GitHub's apt repository.
- **No `agy`, no `--name`, no bind mounts.** `agy` is not in the issue. `--name` needs the clone-in-volume workflow and collides when two containers share a folder name. Bind mounts are what fail when the host folder is missing.
- **Mounts** are the one named volume `codeo-gh` at `/home/dev/.config/gh`. The Dockerfile creates that directory owned by `dev` first, so the empty volume takes `dev`'s ownership on first mount. Claude's config stays per container, as in the reference project.
- **Ceiling** in `runArgs` is `--memory=4g --cpus=2`: the suite is shell scripts, and the the reference project values (12g, 6) are sized for six containers at once.
- **Claude Code** is installed with the native installer, latest, as in the reference project.
- **VS Code extensions:** `anthropic.claude-code`, `timonwong.shellcheck`, `bierner.markdown-mermaid`.
- **Config:** `.codeo/config.json` gains `"codename": "codeo"`, a `plugin` pin (Q1), and `.devcontainer/**` in the `shell` suite's `paths`, so a change under `.devcontainer/` is judged by the suite.
- **Tests:** a new `tests/devcontainer.test.sh` checks the files (valid JSON, `remoteUser`, `runArgs`, the `codeo-gh` mount and no other, no bind mounts, none of the excluded tools or the the reference project secrets names in any `.devcontainer/` file, the `codename`).
- **Docs:** `CHANGELOG.md` gets an `Unreleased` line. `README.md` is untouched (out of scope per the issue), and `docs/` describes the pipeline, not the repo's tooling, so no page moves.

### Footprint

```
files:      .devcontainer/Dockerfile, .devcontainer/scripts/plugins.sh, .devcontainer/scripts/devcontainer-start.sh, tests/devcontainer.test.sh, docs/plans/2026-11-07-dev-container.md, .codeo/36/implement.md
wiki:       none
exclusive:  none
sequenced:  none
```

## Outcome

**Plan:** `docs/plans/2026-11-07-dev-container.md` (left unstaged for the engineer to review and commit). Shape: an executable plan under `docs/plans/`, six tasks, each tests-first, with an options table and a Mermaid flow of the container's start-up. No reference doc under `docs/`.

**Decisions**
- The dev container lives in this repo, not in a separate private one (Q4): a per-issue container is a clone of the issue's branch and reads `devcontainer.json` from it. A private companion repo for golden replay data and shadow-run notes was suggested as a separate follow-up, not filed.
- Pin (Q1): `.codeo/config.json` gains `plugin{repo: kbajpai/codeo, ref: v1.0.3}` and `codename: codeo`; superpowers is installed unpinned.
- Start script (Q2): minimal. It takes ownership of a root-owned clone, runs `plugins.sh`, wires `gh` into git, and lists the outstanding logins and git identity as TODOs. It takes no lock and does not name the container.
- Proof (Q3): `docker build` / `docker run` here, plus two manual checks by the engineer before `/codeo:close` (VS Code clone-in-volume build; `gh` login surviving a rebuild).
- The issue's wording was changed (Q4) so no tracked file names a project that uses codeo; `init.md`'s criteria match the edited issue verbatim.

**Options rejected:** a separate repo for the container; codeo pinned to `main`; superpowers pinned; also taking the container lock; installing the `devcontainer` CLI on the host; the git-core PPA; commented JSONC.

**Calls made by the planner:** base image `ubuntu:24.04`; `runArgs` `--memory=4g --cpus=2`; strict-JSON `devcontainer.json`; no `agy`, no `--name`, no bind mounts; a git-identity TODO; `plugins.sh` captures `claude plugin list` before `grep -q` (the v1.0.3 `pipefail` fix).

**Documentation moved:** none. `README.md` is out of scope per the issue; `CHANGELOG.md` gets an `Unreleased` line (Task 6). No wiki module.

**Intake questions resolved:** the one left open at intake (the reference was not in the repository) was answered by the engineer cloning it locally; nothing from it is recorded in a tracked file.

**Issues filed:** none.

### Footprint

```
files:      .devcontainer/**, .codeo/config.json, tests/devcontainer.test.sh, CHANGELOG.md, docs/plans/2026-11-07-dev-container.md
wiki:       none
exclusive:  none
```

## Log

- 2026-11-07 — questions raised: Q1-Q3 (round 1) · cost: not recorded
- 2026-11-07 — Q1-Q3 answered; Q4 raised (round 2) · cost: not recorded
- 2026-11-07 — Q4 answered: keep the container in this repo; the engineer edited the issue (verified: no project name, criteria match init.md verbatim) · cost: not recorded
- 2026-11-07 — planned: docs/plans/2026-11-07-dev-container.md · cost: 25m · sonnet-5-5 90k in + 4.2M cached / 40k out · engineering:architecture applied; writing-plans used
- 2026-11-07 — send-back from qc.md round 1: Q5-Q6 raised (round 2) · cost: 2m · fable-5-1 314k in + 359k cached / 4k out
