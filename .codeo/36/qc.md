# Issue #36 — qc

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/36 |
| Branch | `feat/add-dev-container-so-codeo` |
| Updated | 2026-11-07 |

## Where this stands

Round 2 is written and the change is clear: both blocking findings of round 1 are fixed and re-proved against the real Claude CLI and real mounts, the suites pass on the host and in the image, and the independent review found nothing blocking. Forward to `/codeo:close`. The two manual checks in `implement.md` (VS Code clone-in-volume build; `gh` login surviving a rebuild) remain the engineer's.

## Questions

None.

## Notes

Not a finding, for the engineer: criteria 1, 3 and 4 need a VS Code build and a real GitHub login, which this pass cannot run. They are the two manual checks `implement.md` lists.

## Outcome

### Round 1 — 2026-11-07

**Scope.** `sync-main.sh --abort-on-conflict`: `sync-main: the branch already contains origin/main`. `overlap.sh 36`: nothing printed, exit 0. `overlap.sh --outside 36`: nothing printed, exit 0. `scope.sh origin/main HEAD`:

```
scope: suite shell needed for unclassified paths:
  .codeo/36/implement.md
  .codeo/36/init.md
  .codeo/36/plan.md
  .codeo/config.json
  CHANGELOG.md
suite.shell=true
```

No `deploy=` line: no suites-and-environment pair is configured. No shared environment, so there is no `#### Environment` block. The diff is 11 files, 1055 insertions: the five `.devcontainer/` files, `tests/devcontainer.test.sh`, `.codeo/config.json`, `CHANGELOG.md`, the plan and the dossiers.

**Build.** The `shell` suite's build command is `true`: exit 0.

**Suite.** `bash tests/run.sh` on the host: `all cases passed rc=0 `. The same command inside the image built from this branch, as user `dev` (UID 1000), repo mounted at `/work`: `all cases passed`, `image-suite-rc=0`. `bash tests/devcontainer.test.sh`: `all cases passed`. shellcheck in the image over `.devcontainer/scripts/*.sh tests/devcontainer.test.sh`: no output, `shellcheck-rc=0`.

**Criteria**

| Criterion | Verdict | Settled by |
|---|---|---|
| Opening the repo in VS Code builds the container without any host folder or volume created beforehand | untestable here — needs VS Code with the Dev Containers extension. The configuration has what it needs: `.devcontainer/devcontainer.json` mounts one `type=volume` and no bind mount, and `docker build` of the same Dockerfile succeeded | `tests/devcontainer.test.sh` cases `no_bind_mounts_or_secrets`, `gh_login_is_one_named_volume`; manual check (a) in `implement.md` |
| `bash tests/run.sh` passes inside the container | met | the in-image run above: `all cases passed`, rc 0 |
| `gh auth status` shows the `project` scope once logged in, and the login survives a rebuild | untestable here — needs a real GitHub login and a rebuild. The reviewer confirmed a fresh `codeo-gh` volume mounts owned by `dev` and writable; the start script's `project`-scope TODO is covered by `start_project_scope_missing_is_a_todo` | manual check (b) in `implement.md` |
| `/codeo:doctor` reports ready | not yet checkable — needs a `gh` login. In a fresh container `doctor.sh` prints `ok` for config, schema, codename (`codeo`), suites, deps, overlays and superpowers (`cannot verify`), and `fail` for gh-auth, gh-scopes, board and ruleset, rc 1, only because nothing is logged in | the in-image `doctor.sh` run; manual check (b) |
| The image contains none of the reference-project-specific tools | met | in the image, `command -v` of dotnet, node, npm, terraform, gcloud, psql, kubectl and docker finds nothing (`tools-checked` with no `UNEXPECTED` line); `dockerfile_has_none_of_the_excluded_tools`; no `secrets` volume, `localEnv` or `.codeo-secrets` in `devcontainer.json` |

**Footprint.** No path outside the plan's footprint.

**Documentation.** The plan says no page moves, and that holds: no page under `docs/` or the README describes the repository's own tooling, and the README is out of scope per the issue. `CHANGELOG.md`'s new line matches the change. One comment in the change says something untrue: `.devcontainer/Dockerfile` creates `/workspaces` and its comment implies it matters, but a bind mount or the clone-in-volume volume always hides it (F5).

**Independent review.** Dispatched with the criteria and the diff only (code, tests, config, changelog; no dossier). The reviewer's assessment, quoted in plain text: ready to merge with fixes. It ran the real `claude` CLI in the image: `marketplace add kbajpai/codeo@v1.0.3`, the `.codeo.source.ref` shape in `known_marketplaces.json`, `claude auth status` exiting 1 when logged out, and a throwaway `codeo-gh` volume coming up owned by `dev`.

**Findings**

- F1 — blocking, plan's. `.devcontainer/plugins.sh:12,38` runs `claude plugin marketplace remove codeo` from inside the repo (line 12 `cd`s to the top level). The CLI then rewrites the project's tracked `.claude/settings.json`. Reproduced in this pass in the image, in a scratch repo whose `.claude/settings.json` enables `codeo@codeo`, after installing codeo at `v1.0.3`:

  ```
  -- after remove, run inside repo:
   M .claude/settings.json
  {
    "enabledPlugins": {}
  }
  ```

  Every pin bump, the case the script's header advertises, leaves a dirty tree and drops the project-level enablement from the tracked file; a fresh install does not, because the remove finds nothing. The test's stub `claude` (`tests/devcontainer.test.sh:158-161`) does not model the side effect, so nothing catches it. Cause: the plan's Task 4 script body prescribes the `cd` to the top level and runs every `claude plugin …` call from there; the code does what the plan says. The change is to run the `claude plugin marketplace` and `install` calls from outside the repository after reading the config, and to add a case that the tracked tree is unchanged after a pin change.
- F2 — blocking, plan's. `devcontainer-start.sh:15-19` runs `sudo chown -R "$(id -u):$(id -g)" "$(dirname "$clone")"` whenever the clone's owner is not the current UID, not only for a clone-in-volume. The reviewer reasons that under rootless Docker, Docker Desktop for Linux or rootless Podman a bind-mounted host checkout appears root-owned in the container, so the recursion would change the ownership of the engineer's own files on the host. I did not run those runtimes, and the code is as described. Opening the repository in a container is the first acceptance criterion's path, and the harm is to the user's files, so I treat it as blocking. Cause: Task 5 of the plan prescribes the `chown -R` of the parent directory. A safer cure for the dubious-ownership error is `git config --global --add safe.directory` on the clone, which touches no files; a chown, if kept, should apply only when the workspace is not a bind mount.
- F3 — non-blocking, implement's. The Claude Code login and installed plugins live in `/home/dev/.claude`, which is not in a volume, so each rebuild needs `claude auth login` again. The plan decided this (Q2); the start script lists the TODO each time.
- F4 — non-blocking, plan's. `plugin` is a new top-level key in `.codeo/config.json` that `lib/env.sh`'s key reference does not list.
- F5 — non-blocking, implement's. `Dockerfile` creates `/workspaces` for no effect, and its comment implies it matters.
- F6 — non-blocking, implement's. `plugins.sh:17` `has_plugin` uses an unanchored `grep -q "$1"`, so `xcodeo@codeo-fork` would count as codeo; `grep -qF` with a boundary, or `claude plugin list --json`, is exact.
- F7 — non-blocking, implement's. `Dockerfile:44-45` hard-codes `/home/dev` for `CLAUDE_CONFIG_DIR` and `PATH` though `ARG USERNAME` can change the user.
- F8 — non-blocking, plan's. `devcontainer-start.sh:38` tells a logged-out user to run `gh auth login` and then `gh auth refresh -s project`; `gh auth login -s project` does both in one step.
- F9 — non-blocking, implement's. Carried from the task reviews: no test sets only `user.name` or only `user.email`, so the identity TODO's `||` is not pinned; the `setup-git` failure and chown failure TODOs have no case; `tests/devcontainer.test.sh` pins `plugin.ref == "v1.0.3"`, so each pin bump needs a test edit.

- F10 — non-blocking, plan's. `dossier-check.sh .codeo/36` prints four `FAIL` lines for `plan.md`: three `## Log` lines (112-114) carry no ` · cost: `, and the `### Footprint` at line 102 lacks the `sequenced` key (`sequenced: none` is the form for a key with nothing under it). The footprint is what `overlap.sh` reads, so the next plan pass should write all four keys.
- F11 — non-blocking, implement's. The same checker reports one `drift` for `implement.md` line 38: "**Deployed revision:** not applicable; …" does not start its line as `Deployed revision: <x>`. With no shared environment, the line should be omitted.

No issue filed for this pass.

**Verdict: back to `/codeo:plan`.**

### Round 2 — 2026-11-07

(re-run of the whole pass after the send-back of round 1, through `/codeo:plan` round 2 and `/codeo:implement` round 2)

**Scope.** `sync-main.sh --abort-on-conflict`: `sync-main: the branch already contains origin/main`. `overlap.sh 36`: nothing printed, exit 0. `git diff origin/main...HEAD --stat`: 12 files, 1526 insertions, 1 deletion. `scope.sh origin/main HEAD`:

```
scope: suite shell needed for unclassified paths:
  .codeo/36/implement.md
  .codeo/36/init.md
  .codeo/36/plan.md
  .codeo/36/qc.md
  .codeo/config.json
  CHANGELOG.md
suite.shell=true
```

No `deploy=` line and no shared environment is configured, so there is no `#### Environment` block. The overlays `invariants-extra` and `wiki-rules` both exited 3: none. `overlap.sh --outside 36` printed `.devcontainer/devcontainer.json` and `CHANGELOG.md` (N7).

**Build.** The `shell` suite's build command is `true`: exit 0.

**Suite.** `bash tests/run.sh` on the host: `all cases passed rc=0`. The same command in the image `codeo-dev-test` (rebuilt with `--no-cache` in `/codeo:implement`, as user `dev`, repo mounted read-only at `/work`): `all cases passed`, `image-suite-rc=0`. `bash tests/devcontainer.test.sh` and `bash tests/agnostic.test.sh`: `all cases passed`. shellcheck in the image over `.devcontainer/scripts/*.sh tests/devcontainer.test.sh`: no output, `shellcheck-rc=0`.

**The round-1 blocking scenarios, re-run against the current code in the image**
- F1: a scratch repo committing this repo's `.claude/settings.json`; `plugins.sh` runs, the pin moves, it runs again: both `rc=0`, `porcelain=[]`, `settings.json` still `{"enabledPlugins":{"codeo@codeo":true}}`.
- F2, bind mount: a copy of the repo owned by uid 4242, bind-mounted; the start script prints `the clone at /workspaces/y is not owned by you and is not on a Docker volume, so it was left alone: …`, `exit=0`, and the host owner stays 4242 for the directory and for a file inside it.
- F2, named volume: a copy of the repo owned by root in a named volume; the start script leaves `/workspaces/x` and `/workspaces/x/tests/run.sh` owned by `dev`, `exit=0`, and the tree is writable. The volume was removed afterwards.

**Criteria**

| Criterion | Verdict | Settled by |
|---|---|---|
| Opening the repo in VS Code builds the container without any host folder or volume created beforehand | untestable here — needs VS Code with the Dev Containers extension. The configuration has what it needs: `jq` of `.devcontainer/devcontainer.json` gives one mount, `source=codeo-gh,target=/home/dev/.config/gh,type=volume`, `grep` for `secrets`, `localEnv` and `type=bind` finds nothing, and `docker build --no-cache` of the same Dockerfile exited 0 | `tests/devcontainer.test.sh` cases for the single volume mount and no bind mounts; manual check (a) in `implement.md` |
| `bash tests/run.sh` passes inside the container | met | the in-image run above: `all cases passed`, `image-suite-rc=0` |
| `gh auth status` shows the `project` scope once logged in, and the login survives a rebuild | untestable here — needs a real GitHub login and a rebuild. A fresh `codeo-gh` volume mounts owned by `dev` and writable (`stat` of `/home/dev/.config/gh` is `dev` in the image, and the reviewer mounted a throwaway volume over it); the `project`-scope TODO and the one-step `gh auth login -s project` are covered by the start-script cases | manual check (b) in `implement.md` |
| `/codeo:doctor` reports ready | not yet checkable — needs a `gh` login. In a fresh container `doctor.sh` prints `ok` for config, schema, codename, suites, deps, overlays and superpowers (`cannot verify`), and `fail` for gh-auth, gh-scopes, board and ruleset, rc 1, only because nothing is logged in | the in-image `doctor.sh` run; manual check (b) |
| The image contains none of the reference-project-specific tools | met | in the image, `command -v` of dotnet, node, npm, terraform, gcloud, psql, kubectl and docker finds nothing (`tools-checked`, no `UNEXPECTED` line; bash 5.2.21, jq 1.7, git 2.43.0, gh 2.103.3, shellcheck 0.9.0, Claude Code 2.1.319, user `dev` UID 1000, `CLAUDE_CONFIG_DIR=/home/dev/.claude`); the Dockerfile test for the excluded tools; no secrets volume, `localEnv` or `.codeo-secrets` in `devcontainer.json` |

**Documentation.** The plan says no page moves, and that holds: nothing under `docs/` or the README describes the repository's own tooling, and the README is out of scope per the issue. The `CHANGELOG.md` line describes the change as it now is (image, `dev` user, `codeo-gh` volume, the start script installing superpowers and codeo at the pin, the config additions, nothing in `scripts/`, `lib/`, `hooks/` or `skills/`) and names no chown. The script headers and the Dockerfile comments were checked against the code; the ones that overstate are N1, N2 and N4 below.

**Independent review.** Dispatched with the criteria and the diff only (code, tests, config, changelog; no dossier). In plain text, its assessment: ready to merge, no Critical or Important findings. It exercised the real Claude CLI, gh, Docker volumes and mountinfo in the image: both plugins install at the pin and a second run changes nothing; a pin moved to `v1.0.2` reinstalls codeo with no tracked file changed; a root-owned clone in a named volume mounted at `/workspaces` is chowned to `dev` with the script exiting 0; a root-owned bind mount gets no `sudo`, only a TODO; mutations (`>=` back to `>`, `pwd -P` back to `pwd`, dropping the `cd "$HOME"` in `claude_out`) each fail a case.

**Findings**

- F1 (blocking in round 1) — fixed by `45c06f0` and verified above: `plugins.sh` runs every `claude plugin …` call from `$HOME`; a pin bump leaves `git status` empty.
- F2 (blocking in round 1) — fixed by `a32340d` and `879701c` and verified above: the clone itself is chowned only on a named volume, never a bind mount, never the parent.
- F3 (non-blocking in round 1) — carried: Claude's own login and plugins are not on a volume; deferred to `/codeo:triage` by the answer to Q6. F4 (non-blocking in round 1) — carried: the `plugin` key is not listed in `lib/env.sh`; deferred to `/codeo:triage`. F5-F11 — folded in and fixed (`/workspaces` line, whole-name match, `/home/${USERNAME}`, one-step `gh auth login -s project`, the F9 cases and the looser pin assertion, `plan.md`'s log and footprint form, `implement.md`'s Deployed-revision line); `dossier-check.sh .codeo/36` prints nothing.
- N1 — non-blocking, implement's. `devcontainer-start.sh:4` says each step checks before it acts, but line 37 runs `git config --global --add safe.directory` on every run, adding a duplicate entry each time (the reviewer saw the path twice after two adds). Harmless; fix with a `--get-all` check or soften the comment.
- N2 — non-blocking, plan's. `plugins.sh:3-4,37-40`: the header says a changed pin replaces codeo and the pin is `plugin.repo` plus `plugin.ref`, but only the ref is compared. A changed `plugin.repo` with the same ref leaves the old repository's codeo installed and the script still prints success. The plan's decision (Round 2 table, and Task 4) compares the ref; no test covers a repo change. The ref is a tag today, so the exposure is small.
- N3 — non-blocking, implement's. `devcontainer-start.sh:72` runs `claude auth status` with the clone as its working directory, while `plugins.sh:16-18` states that `claude` never runs inside a git repository. No tracked file changed in the reviewer's runs and `auth status` is read-only, but nothing pins it. Fix: `(cd "$HOME" && claude auth status)`.
- N4 — non-blocking, implement's. `devcontainer-start.sh:15`: the comment about equal mount points and `>=` sits above the function's description instead of beside the `>=` on line 25 (the re-review noted the same).
- N5 — non-blocking, plan's. `devcontainer-start.sh:43`: for a bind-mounted checkout not owned by `dev`, the TODO suggests `sudo chown -R … if that is what you want`, the very command the script avoids because on a rootless runtime it hands host files to a subordinate UID; and the script then never says `ready` for that setup. Better wording explains the user-namespace mapping (for Podman, `--userns=keep-id`). The wording is the plan's (Task 8, Interfaces).
- N6 — non-blocking, plan's. `devcontainer.json:7`: `--cpus=2` makes Docker refuse to start the container on a host or VM with fewer than 2 CPUs ("range of CPUs is from 0.01 to 1.00"). Low risk; the value was a planner's call.
- N7 — non-blocking, plan's. `overlap.sh --outside 36` prints `.devcontainer/devcontainer.json` and `CHANGELOG.md`: round 2's footprint replaced round 1's and lists only round 2's files, so the other branch files read as outside it. Other workflows were told too little; the footprint should have been the union. The files are the plan's own Task 2 and Task 6 outputs.
- Carried from the reviews of round 2, all non-blocking and fail-safe (recorded in `implement.md`): the unquoted `for word in $list` can glob in the repo root; the `done < "$info" 2>/dev/null` redirect does not silence a missing mountinfo; a bind mount with a space in its path (`\040` in mountinfo) never matches; no test pins optional mountinfo fields or a `/` mount; `ds_safe_dir_set` ends in `| grep -q` under `pipefail`.

No issue filed for this pass.

**Verdict: clear — forward to `/codeo:close`.**

## Log

- 2026-11-07 — round 1: build and suites pass on the host and in the image; two blocking plan-level findings (F1, F2); sent back to /codeo:plan · cost: 8m · opus-5-5 88k in + 1.7M cached / 19k out · sonnet-5-5 29k in + 3.2M cached / 7k out
- 2026-11-07 — round 2: build and suites pass on the host and in the image; both round-1 blocking findings fixed and re-proved; no blocking finding; clear · cost: 6m · opus-5-5 343k in + 2.9M cached / 29k out · sonnet-5-5 244k in + 28k cached / 523 out
