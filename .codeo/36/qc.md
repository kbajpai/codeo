# Issue #36 — qc

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/36 |
| Branch | `feat/add-dev-container-so-codeo` |
| Updated | 2026-11-07 |

## Where this stands

Round 1 is written and the change goes back to `/codeo:plan`: two blocking findings, both of which the plan's own text prescribed (F1: the `plugins.sh` body in Task 4; F2: the `chown -R` of the clone's parent in Task 5). The code does what the plan says.

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

## Log

- 2026-11-07 — round 1: build and suites pass on the host and in the image; two blocking plan-level findings (F1, F2); sent back to /codeo:plan · cost: 8m · opus-5-5 88k in + 1.7M cached / 19k out · sonnet-5-5 29k in + 3.2M cached / 7k out
