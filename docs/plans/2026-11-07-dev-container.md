# Dev Container Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A `.devcontainer/` that builds from a clean machine, runs `bash tests/run.sh` and `/codeo:doctor` as a non-root `dev` user, and keeps the `gh` login across rebuilds, so codeo is developed with codeo in an image of its own.

**Architecture:** One image on `ubuntu:24.04` carrying only what codeo needs (bash, jq, git, gh, shellcheck, Claude Code). `devcontainer.json` mounts one named volume, `codeo-gh`, and caps memory and CPU. Its `postCreateCommand` runs a short start script that installs superpowers and codeo from the pin in `.codeo/config.json` (`plugins.sh`), wires `gh` into git, and lists what is left for the engineer to do by hand. A new `tests/devcontainer.test.sh` pins the files' shape and exercises both scripts against stubbed `claude` and `gh`; the image itself is proved with `docker build` and `docker run`.

**Tech Stack:** bash 4.3+, jq, Docker (Dockerfile, `devcontainer.json`), the test suite's existing conventions.

**Spec:** GitHub issue #36 as restated in `.codeo/36/init.md` → `## Outcome` (acceptance criteria verbatim); decisions in `.codeo/36/plan.md` Q1-Q4.

## Options considered

| Decision | Chosen | Rejected | Why |
|---|---|---|---|
| Where the container is defined | `.devcontainer/` in this repo (Q4) | a separate private repo that clones this one | a per-issue container is a clone of the issue's branch and reads `devcontainer.json` from it |
| Plugin pin (Q1) | codeo at `v1.0.3` in `.codeo/config.json` `plugin{repo,ref}`; superpowers unpinned | codeo on `main`; superpowers pinned | a released codeo is what the container's own tooling should run; superpowers has no version this repo depends on |
| Start script (Q2) | minimal: ownership, `plugins.sh`, `gh` wiring, git identity, to-do list | also take the container lock and name the container; carry over the identity and Claude-login scripts | `lock.sh` already binds locally in any container; the rest is project machinery |
| Proof of the AC that need VS Code and a login (Q3) | `docker build` / `docker run` here, two manual checks by the engineer before close | install the `devcontainer` CLI on the host | no extra host tooling; the manual checks are listed in Task 6 |
| Base image | `ubuntu:24.04` | a language SDK image | the issue asks for Ubuntu 24.04 and none of the SDK tools |
| git | Ubuntu's own (2.43) | the git-core PPA | `git merge-tree --write-tree`, which `/codeo:close` uses, arrived in 2.38 |
| `devcontainer.json` | strict JSON, no comments; the reasons live in the Dockerfile and scripts | commented JSONC | `jq` reads it, so the test can assert on it |
| Container name | Docker's own | `--name` from the folder | `--name` needs clone-in-volume and collides when two containers share a folder name |

## Global Constraints

- bash 4.3+ in every script; each script starts `#!/usr/bin/env bash` and `set -euo pipefail`. No `grep -q` at the end of a pipeline: capture the command's output first, then `grep -q ... <<<"$out"` (codeo fixed this class of bug in v1.0.3, #32).
- `codeo` is a public plugin that serves every project, so no tracked file names a project that uses it. `tests/agnostic.test.sh` enforces this over every tracked file, new ones included. `.devcontainer/` assumes nothing about a project that uses codeo, and `tests/devcontainer.test.sh` assembles any forbidden word from parts if it ever needs one.
- `.devcontainer/` ships inside every installed copy of the plugin (the plugin source is `./`). It is inert there; nothing in `scripts/`, `lib/`, `hooks/` or `skills/` reads it.
- The image holds none of: .NET, Node/npm, Terraform, gcloud/`google-cloud-cli`, PostgreSQL, Docker, `kubectl`. `devcontainer.json` has no bind mount, no `secrets` volume and no `.codeo-secrets` path.
- The only mount is the named volume `codeo-gh` at `/home/dev/.config/gh`. The Dockerfile creates that directory owned by `dev` so the empty volume takes `dev`'s ownership on first mount.
- User `dev`, UID 1000. Ubuntu 24.04's `ubuntu` user holds UID 1000 and is removed first.
- `runArgs` is exactly `["--memory=4g", "--cpus=2"]`.
- The pin is `.codeo/config.json` → `plugin: {"repo": "kbajpai/codeo", "ref": "v1.0.3"}`, and `"codename": "codeo"`. codeo itself reads neither key; `doctor.sh` only validates the codename.
- The `shell` suite's `paths` gains `.devcontainer/**`, so a change there is judged by the suite.
- `.devcontainer/scripts/devcontainer-start.sh` never fails the container's creation: it exits 0 and prints what it could not do as `devcontainer-start: TODO — …` on stderr.
- Documentation moved by this change: none. `README.md` is out of scope (issue), and no page under `docs/` describes the repo's own tooling. The change is recorded in `CHANGELOG.md` (Task 6). No wiki module.
- No shared environment is configured: every task is proved in this checkout, except Tasks 3 and 6, which also need the local `docker` engine.

## Review Focus

1. A first build with no volume and no host folder present must succeed: `devcontainer.json` has no bind mount and the `codeo-gh` volume is created by Docker (Task 2 test `no_bind_mounts`; Task 6 manual check).
2. An empty `codeo-gh` volume must come up owned by `dev`, not root, or `gh auth login` fails with a permission error (Task 3 `docker run` check on `/home/dev/.config/gh`).
3. `plugins.sh` re-run when everything is already installed at the pin must change nothing and exit 0; run with the pin missing from the config it must exit 1 and say so (Task 4 cases `idempotent`, `no_pin`).
4. `plugins.sh` must not remove a working codeo when the pin cannot be fetched (offline): it stays, exits 1, and says which ref it kept (Task 4 case `offline_keeps_codeo`).
5. The start script run with no `gh` login, no git identity and no Claude login still exits 0 and lists all three as TODO, in the order that clears them (Task 5 case `todo_when_nothing_is_set_up`).

---

```mermaid
flowchart TD
    A["VS Code builds the image<br/>(.devcontainer/Dockerfile)"] --> B["postCreateCommand:<br/>devcontainer-start.sh"]
    B --> C["take ownership of a<br/>root-owned clone"]
    C --> D["plugins.sh: superpowers,<br/>then codeo at the pin"]
    D --> E{"gh logged in?"}
    E -- yes --> F["gh auth setup-git;<br/>TODO if no project scope"]
    E -- no --> G["TODO: gh auth login,<br/>gh auth refresh -s project"]
    F --> H["TODOs for git identity<br/>and claude auth login"]
    G --> H
    H --> I["ready, or the ordered<br/>list of what is left"]
```

### Task 1: Config — `codename`, the plugin pin, and the suite path

**Files:**
- Modify: `.codeo/config.json`
- Create: `tests/devcontainer.test.sh`

**Interfaces:**
- Produces: `tests/devcontainer.test.sh` with the helpers every later task adds cases to: `fail <message>` (appends to a failure list and sets a non-zero final exit), `case_name` runner that calls each function named in a final `cases=( … )` array, and `repo_root`. It prints `FAIL <case>: <detail>` per failure and `all cases passed` on success, like the other `tests/*.test.sh`.

- [ ] **Step 1: Write the failing test.** `tests/devcontainer.test.sh` with the helpers above and one case, `config_has_codename_pin_and_suite_path`, asserting with `jq -e` on `.codeo/config.json`: `.codename == "codeo"`; `.plugin.repo == "kbajpai/codeo"`; `.plugin.ref == "v1.0.3"`; and `.suites[] | select(.name == "shell") | .paths | index(".devcontainer/**")` is not null.
- [ ] **Step 2: Run it and see it fail.** `bash tests/devcontainer.test.sh` → `FAIL config_has_codename_pin_and_suite_path`, exit 1.
- [ ] **Step 3: Edit `.codeo/config.json`.** Add `"codename": "codeo"` and `"plugin": {"repo": "kbajpai/codeo", "ref": "v1.0.3"}` as top-level keys, and `".devcontainer/**"` to the `shell` suite's `paths`.
- [ ] **Step 4: Prove it.** `bash tests/devcontainer.test.sh` → `all cases passed`; `bash tests/run.sh` → `all cases passed` (this includes `doctor.test.sh` and `agnostic.test.sh`); `bash scripts/config.sh validate` exits 0.
- [ ] **Step 5: Commit.** `git add .codeo/config.json tests/devcontainer.test.sh && git commit -m "feat(devcontainer): codename, plugin pin and suite path in the config (#36)"`

### Task 2: `devcontainer.json`

**Files:**
- Create: `.devcontainer/devcontainer.json`
- Modify: `tests/devcontainer.test.sh`

**Interfaces:**
- Consumes: Task 1's helpers.
- Produces: `.devcontainer/devcontainer.json` whose `build.dockerfile` is `Dockerfile` (Task 3) and whose `postCreateCommand` is `bash .devcontainer/scripts/devcontainer-start.sh` (Task 5).

- [ ] **Step 1: Write the failing tests**, all reading the file with `jq`:
  - `devcontainer_json_is_valid_and_runs_as_dev`: `jq -e .` succeeds; `.remoteUser == "dev"`; `.build.dockerfile == "Dockerfile"`; `.postCreateCommand == "bash .devcontainer/scripts/devcontainer-start.sh"`.
  - `run_args_cap_memory_and_cpus`: `.runArgs == ["--memory=4g","--cpus=2"]`.
  - `gh_login_is_one_named_volume`: `.mounts == ["source=codeo-gh,target=/home/dev/.config/gh,type=volume"]`.
  - `no_bind_mounts_or_secrets`: the file's text contains none of `type=bind`, `secrets`, `localEnv`.
- [ ] **Step 2: Run and see them fail.** `bash tests/devcontainer.test.sh` → four FAIL lines.
- [ ] **Step 3: Create `.devcontainer/devcontainer.json`** (strict JSON): `name: "codeo"`, the four fields above, and `customizations.vscode.extensions` = `["anthropic.claude-code", "timonwong.shellcheck", "bierner.markdown-mermaid"]` with `settings` = `{"files.insertFinalNewline": true, "files.trimTrailingWhitespace": true, "[markdown]": {"files.trimTrailingWhitespace": false}}`.
- [ ] **Step 4: Prove it.** `bash tests/devcontainer.test.sh` and `bash tests/run.sh` → `all cases passed`.
- [ ] **Step 5: Commit.** `git add .devcontainer/devcontainer.json tests/devcontainer.test.sh && git commit -m "feat(devcontainer): devcontainer.json with one gh volume and a resource ceiling (#36)"`

### Task 3: The image — `Dockerfile`

**Files:**
- Create: `.devcontainer/Dockerfile`
- Modify: `tests/devcontainer.test.sh`

**Interfaces:**
- Consumes: the volume path `/home/dev/.config/gh` from Task 2.
- Produces: an image whose default user is `dev` (UID 1000), with `CLAUDE_CONFIG_DIR=/home/dev/.claude` and `~/.local/bin` on `PATH`.

- [ ] **Step 1: Write the failing tests** over the Dockerfile's non-comment lines:
  - `dockerfile_is_ubuntu_2404_with_the_tools`: first `FROM` is `ubuntu:24.04`; the text names `jq`, `shellcheck`, `git`, `gh` and `https://claude.ai/install.sh`.
  - `dockerfile_creates_dev_uid_1000_and_the_gh_dir`: `ARG USER_UID=1000`, `ARG USERNAME=dev`, a `userdel` of `ubuntu`, and an `install -d -o` that names `.config/gh`.
  - `dockerfile_has_none_of_the_excluded_tools`: no match for `dotnet|nodejs|npm|terraform|google-cloud|gcloud|postgresql|kubectl|docker\.io|docker-ce`, case-insensitively.
- [ ] **Step 2: Run and see them fail.**
- [ ] **Step 3: Create `.devcontainer/Dockerfile`.** Header comment says what the image is for and what is left out on purpose. Then: `FROM ubuntu:24.04`; `ARG USERNAME=dev`, `ARG USER_UID=1000`; `ENV DEBIAN_FRONTEND=noninteractive`; one `RUN` installing `ca-certificates curl git gnupg jq less locales shellcheck sudo` with `--no-install-recommends`, generating `en_US.UTF-8`, and cleaning `/var/lib/apt/lists`; one `RUN` adding GitHub's apt repository (keyring `https://cli.github.com/packages/githubcli-archive-keyring.gpg`, source `https://cli.github.com/packages stable main`) and installing `gh`; one `RUN` that removes the `ubuntu` user, creates `dev` with `--uid ${USER_UID}` and `/bin/bash`, creates `/home/dev/.config/gh` and `/home/dev/.claude` owned by `dev`, creates `/workspaces`, and writes `dev ALL=(root) NOPASSWD:ALL` to `/etc/sudoers.d/dev` mode 0440 (VS Code's clone-in-volume clones as root, so the start script must be able to take ownership); `USER ${USERNAME}`; `ENV CLAUDE_CONFIG_DIR=/home/dev/.claude PATH=/home/dev/.local/bin:${PATH} LANG=en_US.UTF-8`; and a last `RUN curl -fsSL https://claude.ai/install.sh | bash -s latest` followed by removing everything in `${CLAUDE_CONFIG_DIR}` except `settings.json`, so the build's machine id is not baked in. Claude Code is left to update itself in a running container.
- [ ] **Step 4: Prove it.** `bash tests/devcontainer.test.sh` → `all cases passed`. Then, on a machine with `docker`:
  - `docker build -t codeo-dev-test .devcontainer` → exit 0.
  - `docker run --rm codeo-dev-test bash -c 'id -u; id -un; bash --version | head -1; git --version; jq --version; gh --version | head -1; shellcheck --version | head -2; claude --version'` → `1000`, `dev`, bash 5.x, git 2.4x, and a version for each of the rest.
  - `docker run --rm codeo-dev-test bash -c 'stat -c %U /home/dev/.config/gh; for t in dotnet node npm terraform gcloud psql kubectl docker; do command -v $t && echo "UNEXPECTED $t"; done; true'` → `dev` and no `UNEXPECTED` line.
- [ ] **Step 5: Commit.** `git add .devcontainer/Dockerfile tests/devcontainer.test.sh && git commit -m "feat(devcontainer): an Ubuntu 24.04 image with only codeo's tools (#36)"`

### Task 4: `plugins.sh`

**Files:**
- Create: `.devcontainer/scripts/plugins.sh`
- Modify: `tests/devcontainer.test.sh`

**Interfaces:**
- Consumes: `.codeo/config.json` `plugin.repo` / `plugin.ref` (Task 1).
- Produces: `bash .devcontainer/scripts/plugins.sh` — no arguments; exit 0 when superpowers and codeo are installed at the pin, exit 1 with the reason on stderr otherwise; prints `plugins: …` lines on stdout. Safe to re-run. Task 5 calls it.

The test runs the script from a scratch git repo that has the script, a config, and a `bin/claude` stub on `PATH`. The stub keeps its installed set in `$STUB_DIR/installed` and the marketplace ref in `$CLAUDE_CONFIG_DIR/plugins/known_marketplaces.json`, appends every call to `$STUB_DIR/calls`, and answers `plugin list`, `plugin marketplace add|remove`, `plugin install`. A `bin/git` stub answers `ls-remote` with the exit code in `$STUB_LS_REMOTE_RC` and passes everything else to the real git.

- [ ] **Step 1: Write the failing tests:**
  - `fresh_machine_installs_both`: nothing installed → exit 0; `calls` holds `plugin marketplace add obra/superpowers-marketplace`, `plugin install superpowers@superpowers-marketplace --scope user`, `plugin marketplace add kbajpai/codeo@v1.0.3`, `plugin install codeo@codeo --scope user`.
  - `idempotent`: run twice → the second run's calls are only `plugin list` calls; exit 0.
  - `ref_change_reinstalls`: installed at `v1.0.2`, config at `v1.0.3` → `calls` has `plugin marketplace remove codeo` before the add at the new ref.
  - `offline_keeps_codeo`: installed at `v1.0.2`, config at `v1.0.3`, `STUB_LS_REMOTE_RC=2` → exit 1; stderr names `v1.0.2` and says it stays; `calls` has no `marketplace remove`.
  - `no_pin`: config without `plugin` → exit 1; stderr says `.codeo/config.json has no plugin.repo and plugin.ref`.
  - `large_plugin_list_does_not_break_the_pipe`: the stub's `plugin list` prints 20000 lines with the wanted name first → exit 0 (the `grep -q` under `pipefail` regression).
- [ ] **Step 2: Run and see them fail.**
- [ ] **Step 3: Create `.devcontainer/scripts/plugins.sh`**, `chmod +x`. The algorithm the tests do not determine:
  ```bash
  cd "$(git -C "$(dirname "${BASH_SOURCE[0]}")" rev-parse --show-toplevel)"
  config_dir=${CLAUDE_CONFIG_DIR:-$HOME/.claude}
  say() { echo "plugins: $*"; }
  ok=1
  has_plugin() { local list; list=$(claude plugin list 2>/dev/null || true); grep -q "$1" <<<"$list"; }

  has_plugin 'superpowers@superpowers-marketplace' || {
      if claude plugin marketplace add obra/superpowers-marketplace >/dev/null 2>&1 &&
          claude plugin install superpowers@superpowers-marketplace --scope user >/dev/null 2>&1; then
          say "installed superpowers"
      else ok=; echo "plugins: superpowers is not installed: check the network, then re-run this script" >&2; fi
  }

  repo=$(jq -r '.plugin.repo // empty' .codeo/config.json 2>/dev/null || true)
  ref=$(jq -r '.plugin.ref // empty' .codeo/config.json 2>/dev/null || true)
  have_ref=$(jq -r '.codeo.source.ref // empty' "$config_dir/plugins/known_marketplaces.json" 2>/dev/null || true)
  if [[ -z $repo || -z $ref ]]; then
      ok=; echo "plugins: .codeo/config.json has no plugin.repo and plugin.ref, so codeo is not installed" >&2
  elif [[ $have_ref != "$ref" ]] || ! has_plugin 'codeo@codeo'; then
      # An installed codeo is only replaced once the pin is known to exist: `marketplace remove`
      # also uninstalls it, so an add that then fails offline would leave no codeo at all.
      if has_plugin 'codeo@codeo' &&
          ! GIT_TERMINAL_PROMPT=0 timeout 20 git ls-remote --exit-code -q "https://github.com/$repo" "$ref" >/dev/null 2>&1; then
          ok=; echo "plugins: codeo stays at ${have_ref:-its current version}: the pin $ref could not be fetched: check the network and the pin, then re-run this script" >&2
      else
          claude plugin marketplace remove codeo >/dev/null 2>&1 || true
          if claude plugin marketplace add "$repo@$ref" >/dev/null 2>&1 &&
              claude plugin install codeo@codeo --scope user >/dev/null 2>&1; then
              say "installed codeo $ref"
          else ok=; echo "plugins: codeo is not installed at $ref: check the network, then re-run this script" >&2; fi
      fi
  fi
  [[ -n $ok ]] || exit 1
  say "superpowers, codeo ${ref}"
  ```
  The header comment says what it installs, that it is safe to re-run, that Claude loads plugins when a session starts, and that it exits 1 with the reason on stderr.
- [ ] **Step 4: Prove it.** `bash tests/devcontainer.test.sh` → `all cases passed`; `shellcheck .devcontainer/scripts/plugins.sh` → no output (skip when `shellcheck` is not on the host; Task 6 runs it in the image); `bash tests/run.sh` → `all cases passed`.
- [ ] **Step 5: Commit.** `git add .devcontainer/scripts/plugins.sh tests/devcontainer.test.sh && git commit -m "feat(devcontainer): plugins.sh installs superpowers and codeo at the pin (#36)"`

### Task 5: `devcontainer-start.sh`

**Files:**
- Create: `.devcontainer/scripts/devcontainer-start.sh`
- Modify: `tests/devcontainer.test.sh`

**Interfaces:**
- Consumes: `plugins.sh` (Task 4), called as `bash .devcontainer/scripts/plugins.sh`.
- Produces: `bash .devcontainer/scripts/devcontainer-start.sh` — no arguments, always exits 0, safe to re-run. Prints `devcontainer-start: …` lines; each thing left undone is `devcontainer-start: TODO — <text>` on stderr, and when any of the three logins is outstanding it then prints `devcontainer-start: what is left to do, in this order:` followed by numbered commands.

The test runs it from a scratch git repo holding the script, a stub `plugins.sh` that exits `$STUB_PLUGINS_RC`, and `bin/` stubs for `gh` (`auth status` exit and output from `$STUB_GH_*`; `auth setup-git` logged to `calls`), `claude` (`auth status` exit from `$STUB_CLAUDE_RC`) and `sudo` (logs, runs nothing).

- [ ] **Step 1: Write the failing tests:**
  - `todo_when_nothing_is_set_up`: `gh auth status` fails, `claude auth status` fails, no `user.email` → exit 0; stderr has one TODO each for `gh auth login`, git identity, and `claude auth login`; the numbered list is in the order `gh auth login`, `gh auth refresh -s project`, `claude auth login`, `bash .devcontainer/scripts/devcontainer-start.sh`, with git identity not in it.
  - `ready_when_everything_is_set_up`: `gh auth status` succeeds with `'project'` in its output, `claude auth status` succeeds, identity set, plugins stub exits 0 → stdout ends `devcontainer-start: ready`, stderr empty, `calls` has `gh auth setup-git`.
  - `project_scope_missing_is_a_todo`: logged in, no `'project'` scope → TODO names `gh auth refresh -s project`.
  - `plugins_failure_is_a_todo_not_a_failure`: `STUB_PLUGINS_RC=1` → exit 0 and a TODO naming `plugins.sh`.
  - `takes_ownership_of_a_root_owned_clone`: the stub `stat` reports another uid → `calls` shows `sudo chown -R` on the clone's parent directory; when the uid matches, no `sudo` call.
- [ ] **Step 2: Run and see them fail.**
- [ ] **Step 3: Create `.devcontainer/scripts/devcontainer-start.sh`**, `chmod +x`, in this order, each step checking before it acts: (1) find the clone from the script's own location, and `sudo chown -R` its parent directory if `stat -c %u` of the clone is not `id -u` (VS Code's clone-in-volume clones as root, and git then refuses it as dubious ownership); (2) `cd` to `git rev-parse --show-toplevel`; (3) `bash .devcontainer/scripts/plugins.sh || todo+=(…)`; (4) `gh auth status`: on success `gh auth setup-git`, then a TODO if its output lacks `'project'`; on failure a TODO for `gh auth login`; (5) a TODO when `git config user.email` or `user.name` is empty; (6) a TODO when `claude auth status` fails; (7) print TODOs on stderr or `ready`, then the numbered list when a login is outstanding. The header comment says it is the `postCreateCommand`, is safe to re-run, and never fails the container's creation.
- [ ] **Step 4: Prove it.** `bash tests/devcontainer.test.sh` → `all cases passed`; `shellcheck` on both scripts → no output (when available); `bash tests/run.sh` → `all cases passed`.
- [ ] **Step 5: Commit.** `git add .devcontainer/scripts/devcontainer-start.sh tests/devcontainer.test.sh && git commit -m "feat(devcontainer): a start script that never fails and lists what is left (#36)"`

### Task 6: Changelog and the end-to-end proof

**Files:**
- Modify: `CHANGELOG.md`

- [ ] **Step 1: Add the changelog line.** Under `## Unreleased`, after the existing bullet: `` - `.devcontainer/` defines a development container for this repository: an Ubuntu 24.04 image with bash, jq, git, gh, shellcheck and Claude Code, a non-root `dev` user, the `gh` login in the `codeo-gh` volume, and a start script that installs superpowers and codeo at the pin in `.codeo/config.json` (`plugin`). `.codeo/config.json` gains `codename` and `plugin`, and the `shell` suite's paths gain `.devcontainer/**`. Nothing in `scripts/`, `lib/`, `hooks/` or `skills/` changes (#36). ``
- [ ] **Step 2: Prove the docs and the suite.** `bash tests/run.sh` → `all cases passed` (the agnostic test is part of it).
- [ ] **Step 3: Prove the suite inside the image.** `docker build -t codeo-dev-test .devcontainer`, then `docker run --rm -v "$PWD":/work -w /work codeo-dev-test bash -c 'git config --global --add safe.directory /work && bash tests/run.sh'` → `all cases passed`. A failure here is a real gap in the image or in a test that assumes host state; fix it in this task and add a case to `tests/devcontainer.test.sh` for it.
- [ ] **Step 4: Prove the scripts inside the image.** `docker run --rm -v "$PWD":/work -w /work codeo-dev-test bash -c 'git config --global --add safe.directory /work && shellcheck .devcontainer/scripts/*.sh && bash .devcontainer/scripts/devcontainer-start.sh; echo rc=$?'` → no shellcheck output, TODO lines for the logins, and `rc=0`.
- [ ] **Step 5: Manual checks for the engineer, before `/codeo:close`.** (a) On a machine with the Dev Containers extension and no `codeo-gh` volume, run *Dev Containers: Clone Repository in Named Container Volume…* on this branch: the build completes with no folder or volume created beforehand. (b) In that container run `gh auth login`, then `gh auth refresh -s project`, then `gh auth status` (shows `project`); rebuild the container; `gh auth status` still shows it. Then `bash .devcontainer/scripts/devcontainer-start.sh` ends `ready` after `claude auth login`, and `/codeo:doctor` reports every line `ok`.
- [ ] **Step 6: Commit.** `git add CHANGELOG.md && git commit -m "docs: changelog for the dev container (#36)"`

---

## Round 2 — fixes after QC round 1

> **For agentic workers:** Tasks 1-6 above were built and reviewed in round 1 (commits `a5a8742`..`f9af9f6`): **do not redo them.** Round 2 is Tasks 7-10, which amend that code. Run them in order with the same REQUIRED SUB-SKILL as above. (send-back from qc.md round 1)

**Why:** `/codeo:qc` found two blocking defects that this plan's own Task 4 and Task 5 text prescribed — F1: `plugins.sh` runs `claude plugin marketplace remove` from inside the repository, and the CLI then rewrites the tracked `.claude/settings.json` (reproduced: `"enabledPlugins": {}`); F2: `devcontainer-start.sh` runs `sudo chown -R` on the clone's *parent* whenever the owner is not the current user, which on a rootless runtime changes the ownership of a bind-mounted host checkout. Q6 folds in the non-blocking F5-F11; F3 (Claude login not in a volume) and F4 (the `plugin` key is not listed in `lib/env.sh`) go to `/codeo:triage`.

### Round 2 decisions

| Decision | Chosen | Rejected | Why |
|---|---|---|---|
| Where `claude plugin …` runs (F1) | every call in a subshell with `cd "$HOME"`; the config is read from an absolute path, no `cd` into the repo | removing the marketplace first or editing settings after | the CLI writes the *project* settings of whatever repository it runs in; running outside one cannot touch tracked files |
| Root-owned clone (F2, Q5) | always `git config --global --add safe.directory <clone>`; chown **the clone itself** only when its owner is not the current user *and* its mount is a named volume; otherwise a TODO, never a chown | `safe.directory` alone; chown whenever uid is 0; chown of the parent (round 1) | `safe.directory` does not make a root-owned clone writable (checked in the image: `git status` and `touch` still fail); a rootless runtime shows host files as uid 0 too; the parent can hold other projects' volumes |
| Named volume vs bind mount | `/proc/self/mountinfo`: the mount whose mount point (field 5) is the longest prefix of the clone path, and whose root (field 4) matches `/volumes/<name>/_data` | `findmnt`, `docker inspect`, or the folder's name | verified in the image: a named volume's field 4 is `/var/lib/docker/volumes/<name>/_data`, a bind mount's is the host path; no extra tool and no Docker socket |
| `has_plugin` (F6) | equality against whitespace-split words of the captured `plugin list` | an unanchored `grep`, `grep -w` | `grep -w` treats `-` as a boundary, so `codeo@codeo-fork` would still match |
| Pin assertion (F9) | the test asserts `plugin.ref` is a non-empty string with no whitespace | the literal `v1.0.3` | a pin bump then needs no test edit |

### Round 2 Global Constraints (in addition to those above)

- `plugins.sh` never runs `claude` with a git repository as its working directory: it reads `.codeo/config.json` by absolute path, and every `claude plugin …` call (`list`, `marketplace add|remove`, `install`) runs as `(cd "$HOME" && claude …)`.
- `devcontainer-start.sh` never runs `sudo` on the clone's parent directory, and never chowns a path that is not on a named volume. `CODEO_MOUNTINFO` (default `/proc/self/mountinfo`) is a test-only override of the file it reads, as `doctor.sh` has `CODEO_PLUGINS_FILE`.
- The Dockerfile has no `/home/dev` literal in its `ENV` lines (the user comes from `ARG USERNAME`). `devcontainer.json`'s mount target `/home/dev/.config/gh` stays literal: JSON has no variables, and the user is `dev`.
- Nothing under `scripts/`, `lib/`, `hooks/` or `skills/` changes. The `shell` suite is the proof throughout; `bash tests/run.sh` must print `all cases passed` after every task.
- Tests added here must be mutation-resistant: each fails when the line it pins is reverted, shown in a temp copy in the task's report.
- Documentation moved by round 2: none. `CHANGELOG.md`'s existing line still describes the change; Task 10 amends it only if the start script's behavior wording needs it (it does not: the line names no chown).

### Round 2 Review Focus

1. A pin change must leave `git status --porcelain` empty in a repo that tracks `.claude/settings.json` with codeo enabled (Task 7, case `plugins_pin_change_leaves_tracked_files_alone`, whose stub rewrites that file when `marketplace remove` runs inside a repository).
2. A bind-mounted clone owned by someone else must never be chowned, parent or clone (Task 8, case `start_never_chowns_a_bind_mount`: no `sudo` call at all).
3. A clone-in-volume made as root must still become writable by `dev` (Task 8, case `start_chowns_the_clone_on_a_named_volume`: `sudo chown -R <uid>:<gid> <clone>`, argument is the clone, not its parent).
4. The mountinfo parser must pick the *longest* matching mount point, not the first: a clone under `/workspaces/x` where `/workspaces` is a bind mount and `/workspaces/x` a volume (Task 8, case `start_longest_mount_wins`).
5. `codeo@codeo-fork` in the plugin list must not count as codeo installed (Task 7, case `plugins_matches_whole_plugin_names`).

### Task 7: `plugins.sh` runs `claude` outside the repository and matches whole names (F1, F6)

**Files:**
- Modify: `.devcontainer/scripts/plugins.sh`
- Test: `tests/devcontainer.test.sh`

**Interfaces:**
- Consumes: Task 4's scratch fixture (`pl_setup`, `pl_run`, the `claude` and `git` stubs, `pl_calls_have`).
- Produces: same CLI as before. New behavior: every `claude` invocation has a working directory outside the repository; `has_plugin <name>` is true only when `<name>` equals one whitespace-delimited word of the captured `claude plugin list`.

- [ ] **Step 1: Write the failing tests.** The stub `claude` logs `$PWD` beside each call and, on `plugin marketplace remove`, rewrites `<toplevel>/.claude/settings.json` to `{"enabledPlugins": {}}` when `git rev-parse --show-toplevel` succeeds in its working directory (this models the real CLI, reproduced in QC round 1). The scratch repo commits a `.claude/settings.json` that enables `codeo@codeo`.
  - `plugins_pin_change_leaves_tracked_files_alone`: installed at `v1.0.2`, config at `v1.0.3` → exit 0; `git status --porcelain` is empty; no logged call has a `$PWD` inside the scratch repo.
  - `plugins_matches_whole_plugin_names`: the stub's `plugin list` prints only `xcodeo@codeo-fork` and `superpowers-extra@superpowers-marketplace-x` → the script still runs both installs (calls contain `plugin install codeo@codeo` and `plugin install superpowers@superpowers-marketplace`).
- [ ] **Step 2: Run and see them fail.** `bash tests/devcontainer.test.sh` → `FAIL plugins_pin_change_leaves_tracked_files_alone`, `FAIL plugins_matches_whole_plugin_names`, exit 1; the six round-1 plugins cases still pass.
- [ ] **Step 3: Edit `plugins.sh`.** Replace the top-level `cd` with `root=$(git -C "$(dirname "${BASH_SOURCE[0]}")" rev-parse --show-toplevel)` and read the pin with `jq … "$root/.codeo/config.json"`; add `claude_out() { (cd "$HOME" && claude "$@"); }` and use it for every `claude` call; rewrite `has_plugin` as: capture `claude_out plugin list 2>/dev/null || true`, then loop over its whitespace-split words and return 0 on the first word equal to `$1`. Keep the captured-output rule (no `grep -q` at the end of a pipeline).
- [ ] **Step 4: Prove it.** `bash tests/devcontainer.test.sh` → `all cases passed`; `bash tests/run.sh` → `all cases passed`. Mutation (temp copy): restore `cd "$root"` before the `claude` calls → `plugins_pin_change_leaves_tracked_files_alone` fails; restore `grep -q "$1"` → `plugins_matches_whole_plugin_names` fails.
- [ ] **Step 5: Commit.** `git add .devcontainer/scripts/plugins.sh tests/devcontainer.test.sh && git commit -m "fix(devcontainer): plugins.sh runs claude outside the repository and matches whole plugin names (#36)"`

### Task 8: `devcontainer-start.sh` — ownership only on a named volume; one-step `gh` login; identity and `setup-git` cases (F2, F8, F9)

**Files:**
- Modify: `.devcontainer/scripts/devcontainer-start.sh`
- Test: `tests/devcontainer.test.sh`

**Interfaces:**
- Consumes: Task 5's fixture (the stubs for `gh`, `claude`, `sudo`, `stat`, `git`, the `calls` log, `ds_todos`).
- Produces: step 1 of the script becomes: (a) always `git config --global --add safe.directory "$clone"`; (b) when `stat -c %u "$clone"` ≠ `id -u`: if `clone_on_named_volume "$clone"` is true, `sudo chown -R "$(id -u):$(id -g)" "$clone"` (the clone, never its parent) with a TODO if it fails; otherwise a TODO `the clone at <path> is not owned by you and is not on a Docker volume, so it was left alone: run 'sudo chown -R <uid>:<gid> <path>' yourself if that is what you want`. `clone_on_named_volume <path>` reads `${CODEO_MOUNTINFO:-/proc/self/mountinfo}`, selects the line whose field 5 (mount point) is the longest prefix of `<path>` on a path boundary, and succeeds iff its field 4 matches `/volumes/[^/]+/_data$`. The numbered list names `gh auth login -s project` (instead of `gh auth login` then `gh auth refresh -s project`) when `gh` is not logged in; `gh auth refresh -s project` remains when it is logged in without the `project` scope.

- [ ] **Step 1: Write the failing tests** (stub mountinfo files in the scratch dir, `CODEO_MOUNTINFO` pointing at them; update the round-1 `start_todo_when_nothing_is_set_up` and the ownership case to the new behavior):
  - `start_chowns_the_clone_on_a_named_volume`: foreign uid; mountinfo line `… /var/lib/docker/volumes/v1/_data <clone> …` → `calls` has `sudo chown -R <uid>:<gid> <clone>` and no `sudo` call naming the clone's parent; `git config --global --add safe.directory <clone>` took effect.
  - `start_never_chowns_a_bind_mount`: foreign uid; field 4 `/home/u/src/codeo` → no `sudo` call at all; a TODO matching `not on a Docker volume`; exit 0.
  - `start_longest_mount_wins`: mountinfo has `/workspaces` as a bind mount and `<clone>` (under it) as a volume → chown happens; swapped (volume at `/workspaces`, bind at the clone) → no chown.
  - `start_own_clone_runs_nothing_privileged`: matching uid → no `sudo` call; `safe.directory` still set.
  - `start_identity_todo_when_only_one_is_set`: only `user.name` set → TODO; only `user.email` set → TODO.
  - `start_setup_git_failure_is_a_todo`: stub `gh auth setup-git` exits 1 → TODO naming `gh auth setup-git`, exit 0.
  - `start_todo_when_nothing_is_set_up` (updated): the numbered list is `gh auth login -s project`, `claude auth login`, `bash .devcontainer/scripts/devcontainer-start.sh`, in that order; no `gh auth refresh -s project` line.
- [ ] **Step 2: Run and see them fail.** `bash tests/devcontainer.test.sh` → FAIL lines for each new or changed case.
- [ ] **Step 3: Edit `devcontainer-start.sh`** as in Interfaces. Under bash 4.3 `set -u`, test array lengths before expanding, as the script already does.
- [ ] **Step 4: Prove it.** `bash tests/devcontainer.test.sh` → `all cases passed`; shellcheck in the image (`docker run --rm -v "$PWD":/work -w /work codeo-dev-test shellcheck .devcontainer/scripts/*.sh tests/devcontainer.test.sh`) → no output; `bash tests/run.sh` → `all cases passed`. Mutations (temp copy): chown the parent → `start_chowns_the_clone_on_a_named_volume` fails; drop the named-volume test → `start_never_chowns_a_bind_mount` fails; take the first matching mount instead of the longest → `start_longest_mount_wins` fails; `||` → `&&` between the identity checks → `start_identity_todo_when_only_one_is_set` fails.
- [ ] **Step 5: Commit.** `git add .devcontainer/scripts/devcontainer-start.sh tests/devcontainer.test.sh && git commit -m "fix(devcontainer): chown only a clone on a named volume; one-step gh login (#36)"`

### Task 9: Dockerfile and the pin assertion (F5, F7, F9)

**Files:**
- Modify: `.devcontainer/Dockerfile`, `tests/devcontainer.test.sh`

- [ ] **Step 1: Write the failing tests.**
  - `dockerfile_env_uses_the_username_arg`: no non-comment `ENV` line contains `/home/dev`; the `ENV` for `CLAUDE_CONFIG_DIR` contains `/home/${USERNAME}/.claude`.
  - `dockerfile_does_not_create_workspaces`: no non-comment line mentions `/workspaces`.
  - `config_pin_is_a_wellformed_ref` (replaces the literal `plugin.ref == "v1.0.3"` assertion in `config_has_codename_pin_and_suite_path`): `plugin.ref` is a string, non-empty, with no whitespace; `plugin.repo` still equals `kbajpai/codeo`.
- [ ] **Step 2: Run and see them fail** (the first two; the third is a loosening, so it passes — confirm the old literal assertion is gone by `grep -c 'v1.0.3' tests/devcontainer.test.sh` printing only the fixture lines the plugin cases use).
- [ ] **Step 3: Edit the Dockerfile.** `ENV CLAUDE_CONFIG_DIR=/home/${USERNAME}/.claude` and `PATH=/home/${USERNAME}/.local/bin:${PATH}`; remove `/workspaces` from the `install -d` and reword the nearby comment so it does not imply the directory matters. Keep the passwordless-sudo comment (the start script still uses `sudo` for the volume case).
- [ ] **Step 4: Prove it.** `bash tests/devcontainer.test.sh` and `bash tests/run.sh` → `all cases passed`; `docker build -t codeo-dev-test .devcontainer` → exit 0; `docker run --rm codeo-dev-test bash -c 'echo $CLAUDE_CONFIG_DIR; claude --version; stat -c %U /home/dev/.config/gh'` → `/home/dev/.claude`, a Claude Code version, `dev`.
- [ ] **Step 5: Commit.** `git add .devcontainer/Dockerfile tests/devcontainer.test.sh && git commit -m "fix(devcontainer): derive the home from USERNAME, drop /workspaces, loosen the pin assertion (#36)"`

### Task 10: The end-to-end proof, against the real CLI

**Files:** none changed unless the proof finds a gap (then fix it here, with a case that would have caught it).

- [ ] **Step 1: Rebuild and run the suite in the image.** `docker build --no-cache -t codeo-dev-test .devcontainer`, then `docker run --rm -v "$PWD":/work -w /work codeo-dev-test bash -c 'git config --global --add safe.directory /work && bash tests/run.sh'` → `all cases passed`; shellcheck over `.devcontainer/scripts/*.sh tests/devcontainer.test.sh` → no output.
- [ ] **Step 2: Prove F1 against the real CLI.** In the image, in a scratch git repo that commits the same `.claude/settings.json` as this repo and a `.codeo/config.json` copied from it with `plugin.ref` set to `v1.0.2`: copy `plugins.sh` in, run it (installs codeo at `v1.0.2`), change the pin to `v1.0.3`, run it again → both exit 0, `git status --porcelain` prints nothing, `claude plugin list` shows `codeo@codeo`.
- [ ] **Step 3: Prove F2 against real mounts, never the host checkout.** (a) Named-volume case: `docker volume create codeo-p1`, populate it as root with a copy of the repo (`docker run --rm --user root -v codeo-p1:/workspaces/x -v "$PWD":/src:ro codeo-dev-test bash -c 'cp -a /src/. /workspaces/x/ && chown -R root:root /workspaces/x'`), then run the start script from it as `dev` → `stat -c %U /workspaces/x` prints `dev` and `git -C /workspaces/x status` works; `docker volume rm codeo-p1`. (b) Bind-mount case, on a **copy** of the repo in a scratch directory (never `$PWD`): bind-mount the copy, run the start script as `dev` with the copy owned by another uid → no `sudo` runs, the output has the `not on a Docker volume` TODO, and the copy's ownership is unchanged.
- [ ] **Step 4: Run the doctor.** `docker run … bash scripts/doctor.sh` → record the `ok`/`fail` lines (expected: the four gh-dependent checks fail until a login).
- [ ] **Step 5: Manual checks for the engineer** (unchanged from Task 6, step 5): (a) clone-in-volume build on a machine with no `codeo-gh` volume; (b) `gh auth login -s project`, `gh auth status` shows `project`, rebuild, still shows it; then `claude auth login`, the start script ends `ready`, `/codeo:doctor` is all `ok`.
- [ ] **Step 6: Commit** only if a fix was needed: `git add <the files> && git commit -m "fix(devcontainer): <what the proof found> (#36)"`.
