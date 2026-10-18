# codeo core extraction — implementation plan (plan 1 of 4)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A new `codeo` repository holds the pipeline's stack-agnostic engine — scripts, hook, config reader, `/codeo:setup` and `/codeo:doctor` — tested and tagged `v0.1.0`, with no RoadMaster name, path or tool in it.

**Architecture:** Every script sources one `lib/env.sh` that resolves the plugin root, the project root and the project's `.codeo/config.json`, so nothing is hard-coded and nothing outside the project (bar `~/.codeo-secrets`) is read. Scripts are ported from `.agentskills/scripts/` and their `*.test.sh` files are ported with them. What differs per project (suites, scopes, locks, board, label map) comes from the config; what differs per environment (activate, schema check) comes from hooks the config names.

**Tech Stack:** bash 4, `jq`, `git`, `gh api` (REST only). Tests are plain `*.test.sh` against scratch git repos, the style of `.agentskills/scripts/tests/lock.test.sh`.

**Spec:** `Docs/plans/2026-10-18-workflow-plugin-extraction-design.md`

**Scope:** This is plan 1. Plan 2 rewrites the `plan`/`implement`/`qc`/`close` prose and adds the golden-dossier replay. Plan 3 is the parallel run on a real RoadMaster issue. Plan 4 migrates RoadMaster (renames, `.agentskills/` removal, CI switch) and tags `v1.0.0`. The skills `issue`, `init`, `plan`, `implement`, `qc`, `close`, `triage` are **not** touched here; they come across in plan 2. `v0.1.0` is therefore a tag for testing, not for projects to adopt.

## Global Constraints

- Plugin name `codeo`; commands `/codeo:*`; state dir `.codeo/`; intake branch `codeo/intake`; env vars `CODEO_*`; secrets dir `~/.codeo-secrets`.
- Config is `.codeo/config.json`, carrying `"schema": 1`. A config whose `schema` exceeds the plugin's is refused with a message naming both numbers. Format is the author's call (design left it to the builder): JSON, because `jq` is already required and no YAML parser may be added.
- Strict paths: `.codeo/`, `docs/`, `docs/plans/`, `wiki/`. Source layout is never assumed; it appears only as globs in the config.
- Base branch comes from `baseBranch` in the config; no script may contain the literal `main`.
- `gh api` REST only, never `gh issue|pr|run`. bash 4 and `jq` are accepted dependencies; nothing else.
- No secret in the repository; scripts read credentials only from `~/.codeo-secrets/`.
- Only the engineer pushes to the repo; release tags are never moved.
- Code comments state their reason; shell files end with a trailing newline (the `.cs` no-newline rule is RoadMaster's, not codeo's).

## Review Focus

- Script run from a subdirectory of the project: `CODEO_PROJECT_ROOT` still resolves to the git top level (Task 2).
- `.codeo/config.json` missing, empty, invalid JSON, or missing a required key: one-line error naming the file and key, non-zero exit, no stack trace (Task 2).
- Config `schema` newer than the plugin: refused, not silently read (Task 2).
- Base branch other than `main` (`develop`): `sync-main.sh`, `overlap.sh`, `qc-verdict.sh` use it (Tasks 3, 5).
- A path in a diff that matches no suite and no skip glob: every suite runs (fail safe, as `changed-scope.sh` does today) (Task 7).
- Two projects pinning different plugin versions on one machine: no script writes outside the project or `~/.codeo-secrets` (Task 2).
- Repo or branch names containing spaces or glob characters: scripts quote them (Task 3).

## File Structure

New repo `codeo` (created locally at `/workspaces/codeo`; the GitHub repo is created by the engineer in Task 10):

```
.claude-plugin/plugin.json, marketplace.json
hooks/hooks.json, hooks/subagent-model.sh
lib/env.sh                 resolves roots, loads and validates the config
scripts/                   one script per concern, ported from .agentskills/scripts/
scripts/doctor.sh          the checks behind /codeo:doctor
scripts/setup.sh           scaffolds a project for /codeo:setup
skills/setup/SKILL.md, skills/doctor/SKILL.md
tests/run.sh               runs every tests/*.test.sh, non-zero on first failure
tests/*.test.sh
docs/                      the plugin's own design reasoning (starts empty but for README)
CHANGELOG.md, README.md
```

## Task 1: Repository scaffold and test runner

**Files:**
- Create: `/workspaces/codeo/.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `tests/run.sh`, `tests/run.test.sh`, `README.md`, `CHANGELOG.md`, `.gitignore`

**Interfaces:**
- Produces: `tests/run.sh [pattern]` — runs `tests/*.test.sh` whose name contains `pattern` (all by default), prints each failing file's output, exits non-zero if any failed, prints `all cases passed` otherwise.

- [ ] **Step 1: Write `tests/run.test.sh`**, which builds a scratch `tests/` dir with one passing and one failing stub and asserts `run.sh` exits 0 for a filter matching only the passing one, exits non-zero for the failing one, and prints `all cases passed` only on success.
- [ ] **Step 2: Run it** — `bash tests/run.test.sh`; expected: FAIL (`run.sh` missing).
- [ ] **Step 3: Implement `tests/run.sh`** per the interface. Write `plugin.json` (`name: codeo`, `version: 0.1.0`) and a `marketplace.json` with `owner.name` set to the engineer's GitHub login (ask once; do not guess). README states in its first paragraph that this is an agent-workflow plugin, unrelated to SYSGO's CODEO IDE or GoCodeo.
- [ ] **Step 4: Run it** — expected: PASS.
- [ ] **Step 5: Commit** — `git init`, `git add -A`, `git commit -m "chore: scaffold codeo and its test runner"`.

## Task 2: Environment library and config

**Files:**
- Create: `lib/env.sh`, `scripts/config.sh`, `tests/env.test.sh`

**Interfaces:**
- Produces, all by sourcing `lib/env.sh`:
  - `CODEO_PLUGIN_ROOT` (dir above `lib/`), `CODEO_PROJECT_ROOT` (`git rev-parse --show-toplevel` of the cwd), `CODEO_STATE_DIR` (`$CODEO_PROJECT_ROOT/.codeo`), `CODEO_SCHEMA=1`.
  - `codeo_die <msg>` — prints `codeo: <msg>` to stderr, exits 1.
  - `codeo_cfg <jq-filter>` — prints the filter's raw result from `.codeo/config.json`; empty output and exit 1 if null/absent.
  - `codeo_cfg_required <jq-filter>` — as above but dies with `config.json: missing <filter>`.
  - `codeo_base_branch` — `baseBranch` (required).
- `scripts/config.sh get <filter>` and `scripts/config.sh validate` — the CLI over the above for skills and `doctor.sh`. `validate` checks `schema` is an integer ≤ `CODEO_SCHEMA` and that `repo.owner`, `repo.name`, `baseBranch` exist.

- [ ] **Step 1: Write `tests/env.test.sh`** with cases `resolves_project_root_from_a_subdirectory`, `missing_config_names_the_file`, `invalid_json_names_the_file`, `newer_schema_is_refused_naming_both_numbers`, `missing_base_branch_names_the_key`, `no_write_outside_project_or_secrets_dir` (runs `validate` under a read-only `HOME` and asserts exit 0).
- [ ] **Step 2: Run it** — expected: FAIL.
- [ ] **Step 3: Implement `lib/env.sh` and `scripts/config.sh`** to the interface. Config keys, all documented in a comment block at the top of `env.sh`: `schema`, `repo{owner,name}`, `baseBranch`, `board{owner,projects[],gateProject,statuses{}}` (optional), `labelTypes{}` (label→branch type), `suites[]{name,paths[],build,test,filter}`, `skipGlobs[]`, `resources[]{name,paths[],parameterised}`, `environment{resource,hooks{activate,revoke,preflight,start,deployed}}` (optional), `invariants` (path), `models{subagent,reviewer}`, `modules[]`.
- [ ] **Step 4: Run it** — expected: PASS.
- [ ] **Step 5: Commit** — `feat: resolve roots and load a versioned project config`.

## Task 3: Lock, claim, sync-main, branch-name

**Files:**
- Create: `scripts/lock.sh`, `scripts/claim.sh`, `scripts/sync-main.sh` (keeps the filename; behaviour is "sync the base branch"), `scripts/branch-name.sh`, and `tests/{lock,claim,sync-main,branch-name}.test.sh`
- Source: the same-named files in `.agentskills/scripts/` and `.agentskills/scripts/tests/`

**Interfaces:**
- Consumes: Task 2's library.
- Produces: the CLIs exactly as documented in the headers of the source files, with these changes only: `.roadmaster/` → `$CODEO_STATE_DIR`; `origin/main` → `origin/$(codeo_base_branch)`; branch types from `labelTypes` in the config (default `enhancement→feat, bug→fix, documentation→docs`, else `chore`); no `/roadmaster:` text.

- [ ] **Step 1: Port the four test files**, replacing the `script=` line with `$CODEO_PLUGIN_ROOT/scripts/…`, `.roadmaster` with `.codeo`, and seeding a `config.json` in each scratch repo. Add `sync_main_follows_a_develop_base_branch` (config `baseBranch: develop`; assert the merge brings in `origin/develop`) and `branch_name_quotes_a_title_with_spaces_and_glob_characters`.
- [ ] **Step 2: Run** `bash tests/run.sh lock claim sync-main branch-name` — expected: FAIL (scripts absent).
- [ ] **Step 3: Port the four scripts** with the changes above. Do not alter behaviour, exit codes or output lines otherwise.
- [ ] **Step 4: Run** the same command — expected: PASS.
- [ ] **Step 5: Commit** — `feat: port lock, claim, sync-main and branch-name`.

## Task 4: Subagent model hook and usage

**Files:**
- Create: `hooks/hooks.json`, `hooks/subagent-model.sh`, `scripts/usage.sh`, `tests/subagent-model.test.sh`, `tests/usage.test.sh`

**Interfaces:**
- `subagent-model.sh`: same stdin JSON contract and deny shape as the source. Active only while `.codeo/active` exists. Allowed model is `models.subagent` from the config (default `sonnet`); the reviewer exception is `models.reviewer` (default `opus`) when the description starts with `QC review:`.
- `usage.sh <skill> [--since <ISO-8601 UTC>]`: as the source, matching invocations of `/codeo:<skill>`.

- [ ] **Step 1: Write tests**: `hook_allows_everything_without_a_lock`, `hook_denies_a_fork_while_locked`, `hook_allows_sonnet_while_locked`, `hook_allows_opus_only_for_a_qc_review_description`, `hook_honours_configured_models`, `usage_matches_codeo_invocations_and_ignores_roadmaster_ones`.
- [ ] **Step 2: Run** `bash tests/run.sh subagent-model usage` — expected: FAIL.
- [ ] **Step 3: Port both**, reading models via `codeo_cfg`; the deny text names `HANDOFF.md → Spinning out subagents` in the plugin's own docs, not `.agentskills/`.
- [ ] **Step 4: Run** — expected: PASS.
- [ ] **Step 5: Commit** — `feat: port the subagent model hook and usage logging`.

## Task 5: Overlap, inflight, qc-verdict

**Files:**
- Create: `scripts/{overlap,inflight,qc-verdict}.sh`, `tests/{overlap,inflight,qc-verdict}.test.sh`

**Interfaces:**
- CLIs unchanged from the sources' headers, with: state dir from `$CODEO_STATE_DIR`; base branch from the config; repo slug from `repo.owner/repo.name`; the `wiki:<Page>` pairing in `overlap.sh` applies only when `wiki` is in `modules`, and maps to `wiki/<Page>.md`; `qc-verdict.sh` reads archived dossiers under `.codeo/done/<N>/` and keeps its `**Verdict:**`/`**Routing:**` pattern byte-for-byte.

- [ ] **Step 1: Port the tests**, adding `overlap_ignores_wiki_pairing_when_the_module_is_off` and `qc_verdict_uses_the_configured_base_branch`.
- [ ] **Step 2: Run** `bash tests/run.sh overlap inflight qc-verdict` — expected: FAIL.
- [ ] **Step 3: Port the scripts.**
- [ ] **Step 4: Run** — expected: PASS.
- [ ] **Step 5: Commit** — `feat: port overlap, inflight and qc-verdict`.

## Task 6: GitHub and board

**Files:**
- Create: `scripts/github.sh`, `scripts/board.sh`, `tests/github.test.sh`, `tests/board.test.sh`

**Interfaces:**
- `github.sh <verb> …`: verbs and output as the source. Owner, repo and head-owner prefix come from the config; `issue-types` is a verb that prints nothing and exits 0 when the owner is a user, not an org (a user-owned repo has none).
- `board.sh status|set …`: as the source; owner, project numbers, the gate project and status names from `board.*`. When `board` is absent from the config every verb prints `board: not configured` and exits 3, so `init` can skip the Ready gate later (the board-less path itself is out of v1; this is only the signal).

- [ ] **Step 1: Port the tests** (they already stub `gh`); add `issue_types_is_empty_for_a_user_owner` and `board_reports_not_configured_with_exit_3`.
- [ ] **Step 2: Run** `bash tests/run.sh github board` — expected: FAIL.
- [ ] **Step 3: Port both scripts.**
- [ ] **Step 4: Run** — expected: PASS.
- [ ] **Step 5: Commit** — `feat: port the GitHub and board scripts with config-driven repo and board`.

## Task 7: Scope detection

**Files:**
- Create: `scripts/scope.sh`, `tests/scope.test.sh`
- Replaces: `.github/scripts/changed-scope.sh` and `dev-scope.sh` (their RoadMaster regexes become RoadMaster's config in plan 4)

**Interfaces:**
- `scope.sh <base> <head>` — run from the project root; diffs `<base>...<head>` with `--no-renames` and prints one `suite.<name>=true|false` line per config suite, plus `deploy=true|false` when `environment` is configured and any changed path matches one of the environment resource's `paths`. Rule, preserved from `changed-scope.sh`: ignore paths matching `skipGlobs`; a suite is true if any remaining path matches its `paths`; a remaining path matching **no** suite's `paths` makes **every** suite true. On stderr, the paths that decided each true.

- [ ] **Step 1: Write tests**: `docs_only_change_runs_no_suite`, `path_in_one_suite_runs_only_that_suite`, `unknown_path_runs_every_suite`, `rename_counts_old_and_new_path`, `deploy_true_only_for_environment_paths`, `no_suites_configured_prints_nothing_and_exits_0`.
- [ ] **Step 2: Run** `bash tests/run.sh scope` — expected: FAIL.
- [ ] **Step 3: Implement `scope.sh`** with bash glob matching (`shopt -s extglob globstar`) over `jq`-emitted globs.
- [ ] **Step 4: Run** — expected: PASS.
- [ ] **Step 5: Commit** — `feat: derive the suites a change needs from config globs`.

## Task 8: Intake and the lease engine

**Files:**
- Create: `scripts/intake.sh`, `tests/intake.test.sh`, `tests/intake-lease.test.sh`
- Source: `.agentskills/scripts/intake.sh` (lines 1–378 and 637–989 are the engine; 380–636 are the `gcp_*`/DEV code that does **not** come across)

**Interfaces:**
- Commands: `commit`, `restore`, `lease take|wait|release|release-all|check|list` exactly as in the source header, minus `gcp`. Branch is `codeo/intake`; leases live under `.codeo/intake/leases/`.
- A resource name must be listed in `resources[]` (a `parameterised` entry accepts `name:<anything>`), else `unknown resource <name>; configured: <list>`.
- Hooks, shell commands run from the project root with `CODEO_ISSUE`, `CODEO_RESOURCE` exported, named under `environment.hooks`: `preflight` (before a take of `environment.resource`; non-zero refuses, even under `--override`), `activate` (after preflight, before publish), `revoke` (on release, or when a take does not end holding the lease), `start` (before `preflight`). `deployed` is read by later plans, not here. Absent hooks are skipped.

- [ ] **Step 1: Port the tests** (`intake-lease.test.sh`; `intake-gcp.test.sh` is **not** ported). Add `unknown_resource_lists_the_configured_ones`, `parameterised_resource_accepts_a_suffix`, `preflight_failure_refuses_even_under_override`, `activate_runs_after_preflight_and_before_publish` (hooks append to a log; assert the order and that nothing is published when preflight fails), `revoke_runs_when_the_take_does_not_end_holding` and `no_environment_configured_runs_no_hook`.
- [ ] **Step 2: Run** `bash tests/run.sh intake` — expected: FAIL.
- [ ] **Step 3: Port the engine**, replacing the DEV-specific code paths with the hook calls above. Keep the queue, grace and right-of-way logic, and the push-as-compare-and-swap, untouched.
- [ ] **Step 4: Run** — expected: PASS.
- [ ] **Step 5: Commit** — `feat: port the intake and lease engine behind environment hooks`.

## Task 9: `/codeo:setup` and `/codeo:doctor`

**Files:**
- Create: `scripts/setup.sh`, `scripts/doctor.sh`, `skills/setup/SKILL.md`, `skills/doctor/SKILL.md`, `tests/setup.test.sh`, `tests/doctor.test.sh`

**Interfaces:**
- `setup.sh [--stack <dotnet|angular|python|xcode|gradle>]…` — run from a project root; creates `.codeo/` with a `.gitignore` ignoring `active` and `intake/`, writes a `config.json` with `schema: 1`, repo and owner from `git remote get-url origin`, `baseBranch` from `git symbolic-ref refs/remotes/origin/HEAD`, and empty `suites`/`resources`; creates `docs/plans/`; refuses (exit 1) if `.codeo/config.json` exists. Stack packs are out of v1: `--stack` is accepted and recorded under `modules`-adjacent key `stacks`, nothing more.
- `doctor.sh` — prints one `ok|fail <check>: <detail>` line per check and exits non-zero if any failed. Checks: `config` (`config.sh validate`), `schema` (not newer than plugin), `gh-auth` (`gh api user` succeeds), `gh-scopes` (the `project` scope when `board` is configured), `board` (each configured project is readable), `ruleset` (the base branch's required checks include the names in `ci.requiredChecks`, default `tests`, `qc-verdict`), `suites` (each suite's `build` and `test` first word resolves via `command -v`), `deps` (`jq`, `git`, bash ≥ 4).
- Both skills are thin: they run the script and report, and say nothing about any stack.

- [ ] **Step 1: Write tests** with `gh` stubbed on `PATH`: `setup_creates_state_dir_and_config`, `setup_refuses_an_existing_config`, `setup_derives_repo_and_base_branch_from_origin`, `doctor_passes_a_healthy_project`, `doctor_fails_when_the_board_scope_is_missing`, `doctor_fails_when_a_suite_command_is_not_installed`, `doctor_reports_every_failure_not_only_the_first`.
- [ ] **Step 2: Run** `bash tests/run.sh setup doctor` — expected: FAIL.
- [ ] **Step 3: Implement the scripts and the two SKILL.md files** (frontmatter: `name`, `description` with trigger phrases, as the existing skills).
- [ ] **Step 4: Run** — expected: PASS.
- [ ] **Step 5: Commit** — `feat: add /codeo:setup and /codeo:doctor`.

## Task 10: Release v0.1.0

**Files:**
- Modify: `README.md`, `CHANGELOG.md`
- Create: `docs/release-checklist.md`

**Interfaces:**
- `CHANGELOG.md` entry format, one per release: `## vX.Y.Z — date`, then `Config schema:`, `Shared state:`, `Safe to bump mid-workflow:` lines, then the changes. The checklist is what the engineer does by hand.

- [ ] **Step 1: Run the whole suite** — `bash tests/run.sh`; expected: `all cases passed`.
- [ ] **Step 2: Grep for leftovers** — `grep -rniE 'roadmaster|sarathi|\bmain\b|\.agentskills|terraform|dotnet' --include='*.sh' --include='*.md' --include='*.json' .`; expected: only the README's disclaimer line and the `dotnet` mentions in test fixtures named as examples. Fix any other hit.
- [ ] **Step 3: Write the `v0.1.0` changelog entry** (schema 1; no shared-state format fixed yet; not safe for projects to adopt) and `docs/release-checklist.md`, which lists the engineer's own actions: create the public GitHub repo, enable secret scanning, set a branch ruleset (changes by PR from the owner only), set tag protection so only the owner can create `v*` tags, then `git tag v0.1.0 && git push origin v0.1.0`.
- [ ] **Step 4: Commit** — `docs: changelog and release checklist for v0.1.0`.
- [ ] **Step 5: Stop and hand the checklist to the engineer.** Creating the public repository and pushing the tag are outward-facing; do not do them.

## Self-review notes

- Spec coverage: strict paths (Tasks 2, 9), config and schema version (2), pinned plugin root (all, via `lib/env.sh`), setup/doctor (9), changelog (10), lease hooks (8), scope globs (7), secrets rule (2, 10), repo protection (10). Deferred to later plans: skill prose, golden replay, parallel run, migration, CI switch, stack packs, wiki and host modules.
- Types consistent: `codeo_cfg`/`codeo_cfg_required`/`codeo_base_branch` and `CODEO_*` variables are defined once in Task 2 and used by name after.
- Proportion: scripts are ported, not re-specified; each task names its source and only the deltas.
