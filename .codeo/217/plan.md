# Issue #217 — plan

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/217 |
| Branch | `feat/217-add-codeo-go-codeo-done` |
| Updated | 2026-11-28 |

## Where this stands

Round 1. The plan is approved and written to `docs/plans/2026-11-28-codeo-go-done-217.md` (unstaged, for review). `overlap.sh` printed seven overlaps with #207 that Q7 did not quote token by token; Q8 asks to confirm them. The outcome is written once Q8 is answered.

## Questions

### Q1 — `/codeo:init` always stops at its review gate. What counts as the approval when `codeo go` runs it headless?

**Why it matters:** step 8 of the init skill asks for explicit approval of the drafted `init.md` on every run, and nothing after it (the branch, the push, the assignee, the card) runs before the answer. A `claude -p` run cannot be answered, so as the skill stands `codeo go` would fail every time at "init asked a question". The issue's "if init asks a question mid-run, it fails" cannot mean this gate.

- **`codeo go` is the approval.** The init skill gains one documented form, `/codeo:init #<N> --approved`: the engineer has approved the draft in advance, so step 8 is recorded as approved by `codeo go` (one line under `## Notes` in `init.md`) and the run goes on. Every other stop still stops and fails `go`: a closed issue, another assignee, a workflow already in flight, an abandoned branch, a failed script. This changes `skills/init/SKILL.md`, its test and the skills inventory.
- **Two phases.** `codeo go` runs init up to the gate, prints the drafted `## Outcome` in the terminal, asks `approve? [y/N]`, and resumes the same session (`claude -p --resume`) on yes. No skill rule is relaxed, but `go` then needs a terminal, takes two model runs, and has a second failure path (the resume).
- **No skill change; `go` only says so in its prompt** ("the engineer approves the draft"). Cheapest, but it has the model argue past a "do not skip or shortcut this" line on words the skill does not define, which is the kind of gap the inventory's rules exist to close.

I recommend the first.

**Options:** `--approved` form in the skill (recommended) · two phases with a terminal prompt · prompt wording only · no preference, you pick.

**Answer:**
`codeo go` is the approval: the init skill gains `/codeo:init #<N> --approved`. As recommended. Given in the conversation: "Go with your picks".

### Q2 — Where does `codeo go` find the home clone on the host?

**Why it matters:** `go` needs a home checkout three times (the board move, init, and nothing else may be the cwd of `claude -p`), and `done` needs one for the proofs (`cleanup.sh` reads `origin` through a clone that fetches every branch, plus the plugin's scripts and `gh`). `CODEO_HOME` (`~/codeo`) is not it: that directory holds the scripts and sandbox clones and `codeo` refuses it when it is a git checkout. The role check wants a folder named `<codename>-home` on the base branch.

- **`CODEO_HOME_CLONE`, else the current directory.** The variable names the clone; without it, the directory `codeo go` is run from is used when its `role.sh --role` says `home`. Anything else stops with one line naming the variable. Nothing is saved and nothing new is created.
- **A clone codeo makes for itself**, `$CODEO_HOME/<codename>-home`, cloned on first use and pulled before each run (as `.lookup.git` is made today). No setup for the engineer, but a second home clone beside the one they already work in, and the plugin must be installed for it (user scope, or `go` fails at `codeo-root.sh`).
- **The home container.** `docker exec codeo-home claude -p …` in `/workspaces/codeo-home`. No host clone, `jq`, `gh` or plugin needed on the host. But the issue says both commands run on the host where the `claude` login lives; the container has its own login on its volume, and `go` would first have to start `codeo-home`.

I recommend the first, with the variable documented beside `CODEO_HOME`.

**Options:** `CODEO_HOME_CLONE`, else the current directory (recommended) · codeo's own clone under `CODEO_HOME` · the home container · no preference, you pick.

**Answer:**
`CODEO_HOME_CLONE`, else the current directory when it is a home checkout. As recommended. Given in the conversation: "Go with your picks".

### Q3 — Which permissions does the headless init run with?

**Why it matters:** since Claude Code v2.1.302 a `-p` run denies every call that would prompt. Init runs the plugin's scripts, `git worktree`, `git push`, and writes under `.codeo/`; with nothing allowed it fails at the first Bash call. Whatever `go` passes is what an unattended model may do in your home clone.

- **An allow-list:** `--allowedTools` with `Skill`, `Read`, `Glob`, `Grep`, `Write`, `Edit` and `Bash`, and `--permission-prompts none` so `AskUserQuestion` is removed and anything unlisted is denied. The home edit guard (`hooks/home-guard.sh`) still refuses edits outside `.codeo/` and git writes in the home checkout, as in an interactive session. `Bash` unrestricted is still most of the power.
- **Your own settings only.** `go` passes no allow-list; what your user and project settings allow is what runs, and a denied call fails `go` with the denial named (from `permission_denials` in the JSON result). Safest, but `go` works only once you have written allow rules for the init scripts, and the README has to list them.
- **`--dangerously-skip-permissions`.** Simplest and never blocked; the edit guard is then the only limit.

I recommend the allow-list.

**Options:** allow-list plus `--permission-prompts none` (recommended) · your settings only · skip permissions · no preference, you pick.

**Answer:**
An allow-list plus `--permission-prompts none`. As recommended. Given in the conversation: "Go with your picks".

### Q4 — What does `codeo go <N>` do when the issue already has a branch on origin?

**Why it matters:** a branch carrying `.codeo/<N>/init.md` means a stash to resume, a lost container, or someone's running workflow. Init's resume path has stops that need words from you (an abandoned workflow is taken up only "in so many words"), and after a resume an old `codeo-<N>` container has to be removed before `codeo issue` will create one.

- **Fresh starts only.** `go` looks first (the lookup `codeo issue` already does); a branch that holds the dossier stops it with one line naming the two ways on: `codeo issue <N>` for a lost container, `/codeo:init #<N>` in the home checkout for a stash. The acceptance criteria name only Ready and Backlog issues.
- **Resume too.** `go` runs init whatever it finds and lets the skill classify; a stop that needs your words fails `go`. More cases reach the headless run, and each is a new way for it to end somewhere unclear.

I recommend fresh starts only.

**Options:** fresh starts only (recommended) · resume too · no preference, you pick.

**Answer:**
Fresh starts only. As recommended. Given in the conversation: "Go with your picks".

### Q5 — After `codeo done <N>` removes the container, does it also record the removal?

**Why it matters:** `/codeo:cleanup` keeps listing a proven issue until `cleanup.sh record <N>` is committed to the `codeo/intake` branch (#206). Without the record, every issue finished through `codeo done` stays on that list with a `codeo rm` command that removes nothing.

- **Record it.** After a successful removal `done` runs `cleanup.sh record <N>` and `intake.sh commit cleanup` in the home clone. A failure there is one warning line; the removal stands and the exit is still 0. This is a push to a shared branch from a host command.
- **Leave it.** `done` removes and marks the tracking comment (as `codeo rm` does) and nothing else; the record stays a `/codeo:cleanup` step.

I recommend recording it.

**Options:** record it (recommended) · leave it to `/codeo:cleanup` · no preference, you pick.

**Answer:**
Record it. As recommended. Given in the conversation: "Go with your picks".

### Q6 — One pull request, or split?

**Why it matters:** the issue holds four changes. `--version` and the verbose `update` touch only `.devcontainer/codeo`, its template and their tests and can ship alone; `go` and `done` carry the open risk (the headless run, the unverified macOS path) and, with Q1's first option, a skill change.

- **One pull request** for the issue as filed, tasks ordered so `--version` and `update` come first and are provable on their own.
- **Two:** this issue keeps `--version`, `update` and the keychain check; `go` and `done` move to a new issue filed with `/codeo:issue`.

I recommend one.

**Options:** one pull request (recommended) · split in two · no preference, you pick.

**Answer:**
One pull request. As recommended. Given in the conversation: "Go with your picks".

### Q7 — #207 and #213 change files this plan must change. Proceed, sequence, or re-scope?

**Why it matters:** the acceptance criteria require `README.md` and `docs/release-checklist.md`, and every change adds a `CHANGELOG.md` entry; with Q1's first option the plan also changes `skills/init/SKILL.md`, `tests/init-skill.test.sh`, `docs/skills-inventory.md`, `docs/skills.md` and `tests/fixtures/skills-inventory.rules.sha256`.

- `#207`, branch `feat/207-stop-parallel-issues-colliding-shared`, assignee kbajpai, step plan (working): its footprint names `README.md`, `docs/release-checklist.md`, `skills/init/SKILL.md`, `tests/init-skill.test.sh`, `docs/skills-inventory.md`, `docs/skills.md` and `tests/fixtures/skills-inventory.rules.sha256`. It also adds `changelog.d/**`, which may replace direct `CHANGELOG.md` edits.
- `#213`, branch `feat/213-release-v1-0-11-main`, assignee kbajpai, step close (PR open): its footprint names `README.md` and `CHANGELOG.md`. It is the v1.0.11 release and should merge before this work lands; this plan adds its entry under a new `## Unreleased`.

The inventory hash (`tests/fixtures/skills-inventory.rules.sha256`) is one line both branches would rewrite, so it conflicts whichever merges second. I recommend proceeding and coordinating: this branch merges `main` at the start of each round, and whichever of #207 and #217 merges second regenerates the hash and moves its changelog entry to whatever form `main` then has.

**Options:** proceed and coordinate (recommended) · sequence after #207 · sequence after #213 only · re-scope (drop the skill change, Q1) · no preference, you pick.

**Answer:**
Proceed and coordinate. As recommended. Given in the conversation: "Go with your picks".

### Q8 — Confirm the overlap with #207, token by token

**Why it matters:** Q7 answered the overlap in prose, but `overlap.sh` recognises a pair as raised only when a question quotes `#207` and each printed token, and it printed seven: `glob:README.md`, `glob:docs/release-checklist.md`, `glob:docs/skills-inventory.md`, `glob:docs/skills.md`, `glob:skills/init/SKILL.md`, `glob:tests/fixtures/skills-inventory.rules.sha256` and `glob:tests/init-skill.test.sh`. The other workflow is `#207`, branch `feat/207-stop-parallel-issues-colliding-shared`, assignee kbajpai, at `plan` (working), waiting on `/codeo:implement`. Both branches edit the same init skill text and the same pinned inventory hash, so whichever merges second regenerates the hash (`bash tests/inventory.test.sh --update`) and re-reads the skill after a merge of `main`.

**Options:** proceed and coordinate (recommended, as Q7) · sequence after #207 · re-scope.

**Answer:**

## Notes

### Footprint

files: .devcontainer/codeo, templates/containers/.devcontainer/codeo, scripts/cleanup.sh, skills/init/SKILL.md, tests/codeo-command.test.sh, tests/cleanup.test.sh, tests/init-skill.test.sh, tests/readme.test.sh, tests/fixtures/skills-inventory.rules.sha256, docs/skills-inventory.md, docs/skills.md, README.md, .devcontainer/README.md, docs/home-checkout.md, docs/release-checklist.md, CHANGELOG.md, docs/plans/2026-11-28-codeo-go-done-217.md
wiki: none
exclusive: none
sequenced: none

**The two intake questions, looked into.**

- *Does `claude -p` run `/codeo:init` as a slash command?* The current headless docs say yes: "User-invoked skills and custom commands work. Include `/skill-name` in the prompt string and Claude Code expands it before running." (https://code.claude.com/docs/en/headless.md). The plugin form `/codeo:init #<N>` is not shown there literally and was not run; the plan's first `go` task proves it with a harmless skill before anything depends on it. Two things the docs add: an unmatched `/name` does not fail (it goes to the model as plain text and exits 0), and `--bare` loads no plugins, so `go` never passes it. `-p` shows no trust dialog.
- *How does `go` find the home clone?* Nothing on the host records it today. Q2.
- *The keychain.* Claude Code keeps its login in the login keychain on macOS and falls back to `~/.claude/.credentials.json` only on a rejected write; what a read does while the keychain is locked is not documented. The check stays as the issue asks, stubbed in tests and not verified on a Mac.

**My calls, unless corrected.**

- `go` decides success from `origin`, never from the model's words: after the headless run, exactly one branch must hold `.codeo/<N>/init.md` (the lookup `codeo issue` uses). The run's JSON result must also be `subtype: success` with no `permission_denials`. Otherwise `go` prints `codeo: go: init failed: …` with the run's last message beneath it, and runs nothing further.
- `go` moves a card to Ready only from `none`, `unset` or Backlog (`board.sh set <N> ready`); In progress, In review and Done stop it. A project without a board skips the step with one line.
- `go` passes `--container`, `--sandbox` and `--yes` through to `codeo issue`; `done` passes `--container` and `--sandbox` through to the removal.
- `done` gets its proofs from a new `cleanup.sh prove <N>` (the five proofs for one issue, one line, no overlay and no record lookup) rather than from the whole list. An installed plugin too old to have it stops `done` with one line.
- `done` calls `cmd_rm` without `--force`, so unsaved work in the container still refuses. It prints, never runs, the `leftover` branch-delete line.
- The keychain check is `security show-keychain-info ~/Library/Keychains/login.keychain-db`, run only when `uname -s` is `Darwin`; a missing `security` there is treated as unlocked.
- `CODEO_VERSION` goes in both `.devcontainer/codeo` and `templates/containers/.devcontainer/codeo`; the test compares each with `.claude-plugin/plugin.json`. `update` reads the new version from the downloaded file's `CODEO_VERSION=` line, and prints `unknown` for a download from before this release.
- No environment tasks and no lease markers: the project has no shared environment. The lock's `host` is `container`, so any task the engineer runs on their own machine is marked `Runs on: the engineer's host`; I expect one, optional, for the macOS keychain path.
- `engineering:system-design` and `engineering:architecture` are not installed here; their structure is applied directly.

## Outcome

_Pending — written at the hand-off._

## Log

- 2026-11-28 — Q1-Q7 raised · cost: 2m · fable-5-2 142k in + 1.5M cached / 10k out · sonnet-5-5 86k in + 179k cached / 3k out
- 2026-11-28 — Q1-Q7 answered, plan drafted and presented for review · cost: 15m · fable-5-2 151k in + 2M cached / 16k out · sonnet-5-5 269k in + 1.7M cached / 25k out
