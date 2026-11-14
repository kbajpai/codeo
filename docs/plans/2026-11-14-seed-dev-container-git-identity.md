# Seed the Dev Container Git Identity Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** On first start, the dev container fills a missing `user.name` and `user.email` in the `codeo-git` volume's git config from the host `~/.gitconfig`, then from `GIT_AUTHOR_NAME` / `GIT_AUTHOR_EMAIL`, and keeps a TODO that names the sources tried when neither has a value.

**Architecture:** Step 5 of `.devcontainer/scripts/devcontainer-start.sh` is rewritten: for each of the two keys it checks the volume file (`git config --global`), and only when the key is missing takes the first non-empty value from the host file, then the environment, and writes it with `git config --global`. VS Code copies the host `~/.gitconfig` in alongside `postCreateCommand`, so it can arrive after step 5 starts (seen in this container: the file appeared about a second after the lock was taken); step 5 therefore waits up to `CODEO_GITCONFIG_WAIT` seconds (default 10) for the file, and only when a value is missing and the file is absent. The test harness is made hermetic first, then the cases are written red before the code (plan Q1 = A). The last task is the engineer's: a real container is the only place the timing can be proved (plan Q2).

**Tech Stack:** bash, git, `bash tests/run.sh`, VS Code Dev Containers.

**Spec:** `.codeo/51/init.md` (`## Outcome`: the six acceptance criteria); plan Q1-Q3 of `.codeo/51/plan.md`.

## Global Constraints

- Only `user.name` and `user.email` are seeded. No other host setting is copied, and the host file is read key by key with `git config --file "$HOME/.gitconfig" --get <key>`, never copied or included (issue Q4).
- A value already in the volume file is never changed, and each key is judged on its own (issue Q2).
- The sources are tried in this order: `~/.gitconfig`, then `GIT_AUTHOR_NAME` / `GIT_AUTHOR_EMAIL`; a source "has" a value only when it is non-empty (issue Q1).
- The start script still always exits 0. A failed write is reported by the TODO, never by a failure.
- A seeded value is never printed: the report says which key was set and from which source.
- Out of scope: other host git settings, moving the identity out of the volume or changing `GIT_CONFIG_GLOBAL`, the container name (#50), and anything under `scripts/`, `lib/`, `hooks/` or `skills/`. `.devcontainer/devcontainer.json` does not change (a test forbids `localEnv`, so the environment variables arrive only from the engineer's own tooling).
- Documentation: the one page this change moves is `.devcontainer/README.md` (*What the start script does*, Task 4). No page under `docs/` describes the start script's git identity step.
- Ordering: Tasks 1-4 are proved by the `shell` suite in this checkout; Task 5 is the engineer's check in a real container. There is no shared environment, so no task carries `Needs lease:`, and no invariants document is configured. Task 5 is typed in this container's own bash terminal and in VS Code, not on the engineer's host, so it carries no `Runs on:` marker.
- Branch state: this branch was cut at `91894c1`; `main` has since taken #72 (#69), which also edits `CHANGELOG.md` and `.devcontainer/README.md`. Task 1 merges `origin/main` before either file is touched.
- The `shell` suite has no `filter`, so a task's proof is the whole `bash tests/run.sh` (prints `all cases passed`, exit 0); `bash tests/devcontainer.test.sh` is the quick loop for red and green.

## Review Focus

- A host value that is present but empty (`user.name =`) is no value: step 5 falls through to the environment (Task 2, `start_empty_host_value_falls_through_to_the_environment`).
- A malformed host file (`git config --file` exits non-zero) is no value and not a failure: the script still exits 0 and the environment is tried (Task 2, `start_malformed_host_gitconfig_falls_through`).
- A name with a space or an apostrophe survives the round trip into the volume file (Task 2: the host name in the cases is `Ada O'Neil`).
- Step 5 never waits when the volume already holds both values, so only a container's first start can pay the wait (Task 3, `start_does_not_wait_when_the_volume_has_the_identity`).
- The host file's other settings (`init.defaultBranch`, `pull.rebase`, `credential.helper`) stay out of the volume file (Task 2, `start_copies_nothing_but_the_identity`).

---

### Task 1: Merge `main`, and make `ds_run` hermetic for identity

**Files:**
- Modify: `tests/devcontainer.test.sh` (`ds_run`, the comment above `ds_setup`, and the header comment)

**Interfaces:**
- Produces: `ds_run` unsets `GIT_AUTHOR_NAME` / `GIT_AUTHOR_EMAIL` and passes `DS_AUTHOR_NAME` / `DS_AUTHOR_EMAIL` through as them when set; it always sets `CODEO_GITCONFIG_WAIT` to `${DS_GITCONFIG_WAIT:-0}`. Later tasks rely on both. `ds_host_identity` is not defined here.
- The host file of a case is `$ds_dir/home/.gitconfig` (`HOME` is `$ds_dir/home`) and the volume file is `$ds_dir/gitconfig` (`GIT_CONFIG_GLOBAL`).

- [ ] **Step 1: Merge `main`.**
  Run: `git merge origin/main`
  Expected: a clean merge (this branch holds only `.codeo/51/` files), exit 0.

- [ ] **Step 2: Make `ds_run` hermetic.** In `ds_run`, add `-u GIT_AUTHOR_NAME -u GIT_AUTHOR_EMAIL` to the `env -u ...` list, add `${DS_AUTHOR_NAME:+GIT_AUTHOR_NAME="$DS_AUTHOR_NAME"}` and `${DS_AUTHOR_EMAIL:+GIT_AUTHOR_EMAIL="$DS_AUTHOR_EMAIL"}` beside the existing `${DS_SET:+"$DS_SET"}`, and add `CODEO_GITCONFIG_WAIT="${DS_GITCONFIG_WAIT:-0}"` to the variables it sets. Extend the comment above `ds_setup` to name `DS_AUTHOR_NAME`, `DS_AUTHOR_EMAIL` and `DS_GITCONFIG_WAIT`. Without the `-u`, an engineer's own `GIT_AUTHOR_*` would change the results; without the `0`, every case with no identity would wait ten seconds once Task 3 lands.

- [ ] **Step 3: Prove nothing changed.**
  Run: `bash tests/run.sh`
  Expected: `all cases passed`, exit 0.

- [ ] **Step 4: Commit.**

```bash
git add tests/devcontainer.test.sh
git commit -m "test: make the start-script cases hermetic for the git identity (#51)"
```

### Task 2: Seed the identity from the host file, then the environment

**Files:**
- Modify: `tests/devcontainer.test.sh` (new cases beside `start_identity_todo_when_only_one_is_set`, entries in `cases=( ... )`, header comment)
- Modify: `.devcontainer/scripts/devcontainer-start.sh` (step 5, and the header comment's "a git identity")

**Interfaces:**
- Consumes: `ds_setup`, `ds_ready_run`, `ds_todos`, `DS_AUTHOR_NAME`, `DS_AUTHOR_EMAIL` (Task 1).
- Produces: step 5 reports each fill on stdout as `devcontainer-start: git identity: <key> set from <source>`, where `<source>` is `~/.gitconfig` or the variable's name; the TODO is one line that contains `git identity`, the missing key names, `~/.gitconfig`, `GIT_AUTHOR_NAME` and `GIT_AUTHOR_EMAIL`.

- [ ] **Step 1: Write the failing cases.** Add two helpers: `ds_host_identity` (writes `user.name` `Ada O'Neil` and `user.email` `ada@example.com` into `$ds_dir/home/.gitconfig` with `git config --file`) and `ds_global <key>` (prints `git config --file "$ds_dir/gitconfig" --get <key>`, empty when unset). Then these cases, each beginning `ds_setup <name> || return 0` and ending with `ds_ready_run` where it needs a ready baseline, and each listed in `cases=( ... )`:
  - `start_seeds_the_identity_from_the_host_gitconfig` (criterion 1): after `ds_host_identity` and `ds_ready_run`, `ds_global user.name` is `Ada O'Neil` and `ds_global user.email` is `ada@example.com`; stdout contains `user.name set from ~/.gitconfig`; neither `ada@example.com` nor `Neil` appears in stdout or stderr; the last stdout line is `devcontainer-start: ready`.
  - `start_seeds_the_identity_from_the_environment` (criterion 2): with no host file and `DS_AUTHOR_NAME='Grace Hopper'` `DS_AUTHOR_EMAIL=grace@example.com`, both land in the volume file and stdout contains `user.name set from GIT_AUTHOR_NAME`.
  - `start_host_gitconfig_wins_over_the_environment` (criterion 3): host identity and a different environment identity: the volume file holds the host's values.
  - `start_keeps_an_identity_already_in_the_volume` (criterion 4): the volume file has `user.name` `Keep Me`, the host has both; after the run `user.name` is still `Keep Me`, `user.email` is the host's, and a second `ds_ready_run` changes neither.
  - `start_todo_names_the_sources_tried` (criterion 5): with no source, exactly one TODO matches `git identity` and it contains `~/.gitconfig`, `GIT_AUTHOR_NAME` and `GIT_AUTHOR_EMAIL`; with only the host's `user.name` set, the TODO names `user.email` and not `user.name`; the volume file holds the name and no email.
  - `start_copies_nothing_but_the_identity`: the host file also has `init.defaultBranch`, `pull.rebase` and a `credential.helper`; after the run the volume file's key list (`git config --file ... --name-only --list`) holds `user.name`, `user.email` and `safe.directory` only.
  - `start_empty_host_value_falls_through_to_the_environment`: the host file has `user.name =` (empty) and the environment has a name: the environment's name lands.
  - `start_malformed_host_gitconfig_falls_through`: the host file holds `[user` on one line and the environment has both values: the exit is 0 and the environment's values land.

- [ ] **Step 2: Run them to see them fail.**
  Run: `bash tests/devcontainer.test.sh`
  Expected: exit 1, with `FAIL` lines for exactly `start_seeds_the_identity_from_the_host_gitconfig`, `start_seeds_the_identity_from_the_environment`, `start_host_gitconfig_wins_over_the_environment`, `start_keeps_an_identity_already_in_the_volume`, `start_todo_names_the_sources_tried`, `start_empty_host_value_falls_through_to_the_environment` and `start_malformed_host_gitconfig_falls_through`. `start_copies_nothing_but_the_identity` passes already: it guards the rule against a later copy-everything change.

- [ ] **Step 3: Rewrite step 5 of `devcontainer-start.sh`.** Its structure, which the cases above and the Global Constraints determine except the loop:

```bash
# 5. Git identity: fill what the volume's config lacks from the host ~/.gitconfig, then GIT_AUTHOR_*.
identity_missing() { [[ -z $(git config --global --get "$1" 2>/dev/null || true) ]]; }
for pair in user.name:GIT_AUTHOR_NAME user.email:GIT_AUTHOR_EMAIL; do
    key=${pair%%:*} var=${pair#*:}
    identity_missing "$key" || continue
    value=$(git config --file "$HOME/.gitconfig" --get "$key" 2>/dev/null || true) source='~/.gitconfig'
    [[ -n $value ]] || { value=${!var:-} source=$var; }
    [[ -n $value ]] || continue
    if git config --global "$key" "$value"; then say "git identity: $key set from $source"; fi
done
```

  After the loop, the existing test stays the judge: when `git config user.email` or `git config user.name` is still empty, `add_todo` one line of the form `git identity is not set (missing: <the missing keys, comma separated>; tried ~/.gitconfig, then GIT_AUTHOR_NAME / GIT_AUTHOR_EMAIL): run git config --global user.name 'Your Name' and git config --global user.email you@example.com`. Update the header comment: the git identity step now fills the identity as well as reporting it.

- [ ] **Step 4: Run them to see them pass.**
  Run: `bash tests/devcontainer.test.sh`
  Expected: `all cases passed`, exit 0.
  Run: `bash tests/run.sh`
  Expected: `all cases passed`, exit 0.

- [ ] **Step 5: Commit.**

```bash
git add tests/devcontainer.test.sh .devcontainer/scripts/devcontainer-start.sh
git commit -m "feat: seed the dev container git identity from the host config or environment (#51)"
```

### Task 3: Wait for the host file when a value is missing

**Files:**
- Modify: `tests/devcontainer.test.sh` (two cases, `cases=( ... )`)
- Modify: `.devcontainer/scripts/devcontainer-start.sh` (step 5)

**Interfaces:**
- Consumes: `DS_GITCONFIG_WAIT` (Task 1) and the step-5 loop (Task 2).
- Produces: `CODEO_GITCONFIG_WAIT` (seconds, default 10): step 5 waits at most that long, once a second, for `$HOME/.gitconfig` to exist, and only when `user.name` or `user.email` is missing from the volume file.

- [ ] **Step 1: Write the failing cases.**
  - `start_waits_for_the_host_gitconfig_to_arrive`: `ds_setup`, then start a background subshell that sleeps 1 second and writes the host identity into `$ds_dir/home/.gitconfig` (waited on after the run), and run with `DS_GITCONFIG_WAIT=5 ds_ready_run`: the volume file holds the host's values and stdout contains `user.name set from ~/.gitconfig`.
  - `start_does_not_wait_when_the_volume_has_the_identity`: the volume file holds both values, no host file, `DS_GITCONFIG_WAIT=30 ds_ready_run`; `$SECONDS` shows the run took under 5 seconds, and the run is ready with no TODO.

- [ ] **Step 2: Run them to see them fail.**
  Run: `bash tests/devcontainer.test.sh`
  Expected: exit 1, with one `FAIL start_waits_for_the_host_gitconfig_to_arrive` line (the second case passes already, and guards the wait against being unconditional).

- [ ] **Step 3: Add the wait before the Task 2 loop**, inside a guard that runs only when `identity_missing user.name || identity_missing user.email`: poll once a second with `sleep 1` while `[[ ! -e $HOME/.gitconfig ]]` and fewer than `${CODEO_GITCONFIG_WAIT:-10}` seconds have passed. A comment above it says why: VS Code copies the host `~/.gitconfig` in alongside `postCreateCommand`, so it can land after this step starts.

- [ ] **Step 4: Run them to see them pass.**
  Run: `bash tests/devcontainer.test.sh`
  Expected: `all cases passed`, exit 0.
  Run: `bash tests/run.sh`
  Expected: `all cases passed`, exit 0.

- [ ] **Step 5: Commit.**

```bash
git add tests/devcontainer.test.sh .devcontainer/scripts/devcontainer-start.sh
git commit -m "feat: wait briefly for the host git config when the identity is missing (#51)"
```

### Task 4: Document the change

**Files:**
- Modify: `.devcontainer/README.md` (*What the start script does*)
- Modify: `CHANGELOG.md` (*Unreleased*)
- Modify: `tests/devcontainer.test.sh` (header comment: list the new cases)

**Interfaces:**
- Consumes: the report line, the TODO wording and `CODEO_GITCONFIG_WAIT` from Tasks 2-3.

- [ ] **Step 1: Add a bullet to *What the start script does*** in `.devcontainer/README.md`: for a `user.name` or `user.email` the `codeo-git` volume's config lacks, it takes the value from the host's `~/.gitconfig` (which VS Code copies into the container), else from `GIT_AUTHOR_NAME` / `GIT_AUTHOR_EMAIL`; it never changes a value already there and copies nothing else from the host file; on a first start it waits up to 10 seconds (`CODEO_GITCONFIG_WAIT`) for VS Code's copy to arrive; with no source it lists a TODO naming the sources tried. Plain prose, no diagram: the page has none and the step is a lookup order.

- [ ] **Step 2: Add a bullet under *Unreleased*** in `CHANGELOG.md`, in the style of its neighbours: what the start script now does, the two sources and their order, that it fills only what is missing and copies nothing else, the wait and its variable, the new TODO wording, that a container needs no rebuild (the next container start, or `bash .devcontainer/scripts/devcontainer-start.sh`, does it), and `Nothing in scripts/, lib/, hooks/ or skills/ changes (#51).`

- [ ] **Step 3: Update the test file's header comment** with one sentence naming the identity-seeding cases.

- [ ] **Step 4: Prove it.**
  Run: `bash tests/run.sh`
  Expected: `all cases passed`, exit 0.
  Run: `git grep -n -F '(#51)' -- CHANGELOG.md`
  Expected: one line, exit 0.

- [ ] **Step 5: Commit.**

```bash
git add .devcontainer/README.md CHANGELOG.md tests/devcontainer.test.sh
git commit -m "docs: describe the dev container git identity seeding (#51)"
```

### Task 5: The engineer proves it in a real container

This task is yours. It stops and waits: the suite proves the lookup order and the wait against stubs, but only a real container shows that VS Code's copy lands where the script reads it, in time. The identity in the `codeo-git` volume is shared by every container, so this check removes and restores it.

- [ ] **Step 1: Print, then stop.** Print the commands below and the expected output; end the turn and wait for the engineer's pasted output. Nothing else runs until it arrives.

- [ ] **Step 2 (the engineer): the start script seeds a volume with no identity.** In this container's terminal, one command at a time:
  `git config --global --unset user.name`
  `git config --global --unset user.email`
  `bash .devcontainer/scripts/devcontainer-start.sh`
  `git config --global user.name`
  `git config --file /home/dev/.gitconfig user.name`
  Expected: the script prints `devcontainer-start: git identity: user.name set from ~/.gitconfig` and the same for `user.email`, with no `git identity` TODO; the last two commands print the same name.

- [ ] **Step 3 (the engineer): the first start of a new container finds VS Code's copy in time.** Unset both values again as in Step 2, then run **Dev Containers: Rebuild Container** in VS Code. When it has started, run **Dev Containers: Show Container Log**, and then in the new terminal run `git config --global user.email`.
  Expected: the log holds both `git identity: ... set from ~/.gitconfig` lines and no `git identity` TODO; `git config --global user.email` prints the host's email. If the log shows the TODO although the host has an identity, the wait was too short or the copy lands later than the script runs: paste the log and the task goes back to Task 3.

- [ ] **Step 4: Record the output.** The pasted output goes into `.codeo/51/implement.md` as the evidence `/codeo:qc` reads for criterion 1 in a real container. Nothing is committed by this step.
