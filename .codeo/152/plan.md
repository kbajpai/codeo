# Issue #152 — plan

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/152 |
| Branch | `feat/run-home-role-host-strict` |
| Updated | 2026-11-23 |

## Where this stands

Round 2, answers in (Q8-Q12 answered "accept all recommendations"). The round 2 plan is drafted in `.codeo/152/plan-draft.md` and awaits approval; nothing is written under `docs/plans/` before that. `/codeo:qc` round 1 sent the change back with three blocking findings that rest on round 1 plan decisions (F1 the printed removal command, F2 the tracker's default repository, F3 what counts as a malformed table) and two non-blocking ones for the plan (F4 the VS Code route, F8 the first removal after an upgrade). Each is a question below with a recommendation. F5-F7 and F9-F12 are `/codeo:implement`'s and need no decision: the round 2 plan lists them as tasks. Round 1's plan and answers (Q1-Q7) stand except where these answers change them.

What exploration settled, so the questions below are only the open ones:

- `role.sh` returns `unguarded` for any checkout with no `/.dockerenv`, so a host clone is unguarded today. `home` today also lets `plan`/`implement`/`qc`/`close` through (they stop at their own step 0); the issue requires them refused in home. `tests/role.test.sh` pins both, so those assertions change.
- `github.sh` has `pr comment` (POST) and `pr comments` (GET, unpaginated), but no way to find a comment by marker or edit one. A new verb for list-with-ids and PATCH is needed. `github.sh` reads owner/repo from `.codeo/config.json`, which `codeo`, `codeo-container.sh` and `codeo-sandbox.sh` do not have when they run from `$CODEO_HOME`.
- `codeo-container.sh` and `codeo-sandbox.sh` are downloaded singly by `curl` and run with no repository; `codeo` exec's them, so it cannot act after them. `codeo-container.sh` is tested with a PATH holding only a stub `docker`, and must stay bash 3.2 and macOS-portable.
- Only `codeo rm` (and `codeo-sandbox.sh end`) is on the host and knows a removal happened. The command `/codeo:cleanup` prints today is the raw `docker rm -f …; docker volume rm …` from `.codeo/overlays/cleanup.md`, which records nothing.
- A container's own hostname is its name (`--hostname codeo-<N>`), so a row's Host must be read from the host side.
- This repository is the plugin source (`skills/`, `scripts/`), so a generic change to `skills/init` ships with a plugin release; project-specific Docker wording belongs in `.codeo/overlays/` and `.devcontainer/`.

## Questions

### Q1 — What does the guard do with a container opened in a folder that is not `<codename>-home` or `<codename>-<N>`?

**Why it matters:** today such a container is `unguarded` and runs every skill (pinned by `other_folders_are_unguarded` in `tests/role.test.sh` and a Review Focus in the #70 plan: "Reopen in Container from a host folder named `codeo`… never refused"). The issue says a host checkout that is neither home nor issue is refused. If containers follow the same rule, that earlier guarantee is reversed and those tests flip; if not, a container in an unshaped folder stays a hole in a "strict" guard.
**Options:** refuse it like a host checkout, with a line that names the folder rule · keep it `unguarded` for containers only, so the break with #70 is avoided (recommended: keep, since the issue's stated rule is about the *host*, and refusing would strand engineers whose container folder is oddly named, with no way forward but renaming) · no preference, you pick.

**Answer:**
Keep it `unguarded` for containers only (recommended option). Relayed from the engineer in the conversation, 2026-11-22: "Accept all recommendations".

### Q2 — On the host, which checkouts count as an issue checkout: any checkout holding the workflow lock, or only a folder named `<codename>-<N>`?

**Why it matters:** the issue calls an issue checkout "a `codeo-<N>` container or sandbox, or any checkout with the workflow lock held". Engineers running the `host: local` flow today work in a clone with an arbitrary folder name and a lock. Requiring the `<codename>-<N>` folder on the host would refuse `/codeo:plan`…`/codeo:close` for them; accepting any lock keeps them working but means a lock in the folder `codeo-home` on the host still reads as `mismatch`.
**Options:** any host checkout with a lock whose issue matches `.codeo/active` is `issue:<N>` regardless of folder, and the folder rule applies only in containers (recommended) · the folder rule applies on the host too, so a host issue checkout must be named `<codename>-<N>`.

**Answer:**
Any host checkout holding a lock that matches `.codeo/active` is `issue:<N>` regardless of folder; the folder rule applies only in containers (recommended option). Relayed from the engineer in the conversation, 2026-11-22: "Accept all recommendations".

### Q3 — Where does the tracking logic live, given the host scripts are downloaded one by one and run with no repository?

**Why it matters:** `/codeo:init` runs in a clone with `gh`, but the rows for container, image, volume and sandbox are written by `codeo-container.sh`, `codeo-sandbox.sh` and `codeo`, which run from `$CODEO_HOME` with no `.codeo/config.json` and no `github.sh`. The choice sets which files change, what `codeo update` downloads, and what `tests/codeo-command.test.sh` must stub.
**Options:**
- **A (recommended).** One new project script, `.devcontainer/codeo-track.sh`, holds the marker, the table format, find-and-edit-or-create, and the "print the row when `gh` fails" fallback. `codeo-container.sh` and `codeo-sandbox.sh` call it when it sits beside them and print the row when it does not. `codeo update` and the download lines in the READMEs fetch it too. Owner/repo come from `CODEO_REPO_URL`. It calls `gh api` directly (REST, as `github.sh` does), since `github.sh` needs a repository checkout. `/codeo:init`'s branch row goes through the same script, called from the `init/host-workflow` overlay, so the generic `skills/init` text does not change.
- **B.** Add find-comment and edit-comment verbs to `scripts/github.sh` and make `skills/init` write the branch row generically; the host scripts embed their own small `gh api` copy. More plugin-side change, and two implementations of the table to keep in step.
- **C.** Put the table logic inline in each of the three host scripts. No new file to download, three copies.

**Answer:**
Option A: one new `.devcontainer/codeo-track.sh`, `gh api` direct, called by the host scripts and by the `init/host-workflow` overlay (recommended option). Relayed from the engineer in the conversation, 2026-11-22: "Accept all recommendations".

### Q4 — How does the removal get recorded, given `/codeo:cleanup` prints raw `docker rm -f …; docker volume rm …` and only `codeo rm` is host-aware?

**Why it matters:** the acceptance criterion is that after the printed removal is run, the rows read `removed`. A raw `docker rm` records nothing, so either the printed command changes or the engineer runs a second command.
**Options:** change the `removal-command` overlay (and the `close/host-workflow` overlay) to print `codeo rm {N}`, which already refuses on unpushed work and would now mark the container, volume, image and sandbox rows `removed` (recommended; it needs `codeo` on the host, which a host home has anyway, and is one command in PowerShell-via-WSL and bash alike) · keep the raw `docker` command and append `; codeo track removed {N}`, which still records but would also run when the removal failed · leave removal unrecorded and document that the rows are updated only by `codeo rm`.
A related call I'm making unless you object: the branch row is marked `deleted` by `/codeo:close` itself right after `git push origin --delete`, through the same tracker script from the issue's container (which has `gh`).

**Answer:**
Print `codeo rm {N}` from the `removal-command` and `close/host-workflow` overlays; `/codeo:close` marks the branch row `deleted` itself (recommended option, and the related call). Relayed from the engineer in the conversation, 2026-11-22: "Accept all recommendations".

### Q5 — Overlap with #146 on `README.md` and `CHANGELOG.md`: how do we handle it?

**Why it matters:** `inflight.sh` shows #146 (`feat/release-v1-0-8-once`, assignee kbajpai, step implement) with `README.md`, `CHANGELOG.md` and `tests/install.test.sh` in its footprint; this plan changes `README.md` (host home, guard, tracking comment, platforms) and `CHANGELOG.md`. Note that `main` already carries `release: v1.0.8 (#158)`, so #146 may be stale rather than live; its last `live:` signal was 6 minutes ago on `codeo-146` though.
**Options:** proceed and coordinate (recommended: both edits are additive sections, and this plan leaves `tests/install.test.sh` alone) · sequence after #146 · re-scope to leave the README and CHANGELOG out until #146 merges.
Overlap tokens, quoted verbatim for `overlap.sh`: `#146` `README.md` `CHANGELOG.md`.

**Answer:**
Proceed and coordinate; leave `tests/install.test.sh` alone (recommended option). Relayed from the engineer in the conversation, 2026-11-22: "Accept all recommendations".

### Q6 — One pull request, or split the guard from the tracking comment?

**Why it matters:** the guard (role.sh, tests, overlays, README guard section) and the tracking comment plus duplicate warning (tracker script, three host scripts, init and close overlays) share no code but share README and CHANGELOG. One PR is a larger review but ships a consistent "host home" story; two PRs let the guard land first, and the tracking work follows #146's README changes cleanly.
**Options:** one PR with the guard tasks first (recommended, matching the issue's single scope and past plans' Q-"one pull request") · two PRs: guard, then tracking, each its own issue/branch (the second would need `/codeo:issue`) · no preference, you pick.

**Answer:**
One pull request, guard tasks first (recommended option). Relayed from the engineer in the conversation, 2026-11-22: "Accept all recommendations".

### Q7 — Overlap with #146, restated as `overlap.sh` prints it: `glob:README.md`, `glob:CHANGELOG.md`

**Why it matters:** the footprint written after approval overlaps #146 (`feat/release-v1-0-8-once`, assignee kbajpai, step implement) on `glob:README.md` and `glob:CHANGELOG.md`; `overlap.sh` only treats a pair as raised when a question quotes these tokens, and Q5 predates the footprint. The footprint now names each test file instead of `tests/**`, so the `tests/install.test.sh` overlap is gone.
**Options:** proceed and coordinate · sequence after #146 · re-scope.

**Answer:**
Proceed and coordinate. Carried over from the engineer's answer to Q5 (same issue, same files); not asked again separately.

### Q8 — What does `/codeo:close` and `/codeo:cleanup` print for an engineer who has no `codeo` command (QC F1)?

**Why it matters:** round 1 made `codeo rm <N>` the only printed removal and said it runs unmodified in PowerShell and bash. It does not: `codeo` is a bash script for Linux, macOS or WSL2, and engineers on the VS Code route or the bare `codeo-container.sh` route never installed it. Before this branch they were given `docker rm -f codeo-<N>; docker volume rm codeo-<N>`, which runs wherever Docker does. The choice also decides whether the tracking comment can go stale: a raw `docker` removal records nothing.
**Options:**
- **A (recommended).** Print `codeo rm <N>` as the command, and beside it one plain sentence: without `codeo` on the host, run `docker rm -f codeo-<N>` then `docker volume rm codeo-<N>`, and the comment's rows then stay `active` until someone runs `bash .devcontainer/codeo-track.sh mark …` from a home checkout. The PowerShell claim is deleted everywhere and replaced by "in a bash shell on the host (Linux, macOS, or WSL2 on Windows)". `scripts/cleanup.sh` gains an optional fourth overlay line, `fallback:`, printed after the command; nothing else about its proofs changes.
- **B.** Keep `codeo rm <N>` as the only printed command, say `codeo` must be installed to remove a container, and delete the PowerShell claim. Smallest change; VS Code-route engineers must install `codeo` (or work the `docker` command out themselves).
- **C.** Go back to printing the raw `docker` commands, and print `codeo-track.sh mark` lines after them for the engineer to run. Works everywhere Docker does, but it is four or five commands, the marks need bash and `gh`, and nothing checks for unpushed work first.

**Answer:**
Option A: print `codeo rm <N>` with one sentence giving the `docker` fallback and saying the rows stay `active`; delete the PowerShell claim; `scripts/cleanup.sh` gains an optional `fallback:` overlay line (recommended option). Relayed from the engineer in the conversation, 2026-11-23: "Accept all recommendations, proceed with plan".

### Q9 — Which repository does the tracker comment on when `CODEO_REPO_URL` is unset (QC F2)?

**Why it matters:** `codeo-track.sh` falls back to `kbajpai/codeo`. The init and close overlays run it inside a checkout where nothing sets `CODEO_REPO_URL`, so in a fork `/codeo:init <N>` would post a comment on the upstream repository's issue `<N>`: a write to someone else's repository.
**Options:**
- **A (recommended).** Order: `CODEO_REPO_URL` when set; else, when the current directory is inside a git checkout, that checkout's `origin` URL; else the upstream default. The overlays run in a checkout, so they follow the fork; `codeo`, `codeo-container.sh` and `codeo-sandbox.sh` run from `~/codeo` (not a checkout) and already clone from `CODEO_REPO_URL` or the same default, so the comment goes to the repository the container was cloned from.
- **B.** As A, but with no default at all: outside a checkout with `CODEO_REPO_URL` unset the tracker records nothing and prints the row. Safest against a wrong-repository write, but upstream users of the downloaded scripts would then get no rows unless they set the variable.
- **C.** Read `repo.owner`/`repo.name` from `.codeo/config.json` in a checkout, in place of `origin`. Matches `github.sh`, but needs `jq` in a script that must stay bash 3.2 with no dependency beyond `gh`.

**Answer:**
Option A: `CODEO_REPO_URL`, else the current checkout's `origin`, else the upstream default (recommended option). Relayed from the engineer in the conversation, 2026-11-23: "Accept all recommendations, proceed with plan".

### Q10 — What makes a tracking table malformed, and how much of the comment is left alone (QC F3)?

**Why it matters:** the issue says a malformed table is reported, not overwritten. Round 1 called a table malformed only when its header was missing, so a hand-edited row with too few or too many cells is silently rewritten (an eight-cell row loses two cells).
**Options:**
- **A (recommended).** A row is well-formed only with exactly six cells, a known kind (`branch`, `container`, `image`, `volume`, `sandbox`) and a known status (`active`, `removed`, `deleted`). One malformed row makes the whole table malformed: `add` and `mark` change nothing, exit 3 and print one `track:` line naming the row's line and the row they would have written; `confirm` still warns from the rows it can read. Strict, simple to reason about; one bad hand-edit stops recording for that issue until it is fixed.
- **B.** Keep malformed rows byte-for-byte and edit only the well-formed ones, printing a `track:` note. Recording carries on, but the tracker then writes to a comment it only partly understands.

**Answer:**
Option A: a row needs exactly six cells, a known kind and a known status; one malformed row makes the table malformed, nothing is written, one `track:` line names it (recommended option). Relayed from the engineer in the conversation, 2026-11-23: "Accept all recommendations, proceed with plan".

### Q11 — Is a container opened through VS Code's "Clone Repository in Named Container Volume" recorded (QC F4)?

**Why it matters:** that route is the first one the init overlay offers, and no host script runs in it, so its container, image and volume never appear in the comment and get no duplicate warning. Inside the container the host's hostname is not known (the container's hostname is its own name), which the Host column needs.
**Options:**
- **A (recommended).** State it: the README, `.devcontainer/README.md` and the init overlay say that only containers and sandboxes made by `codeo`, `codeo-container.sh` or `codeo-sandbox.sh` are recorded, and that the VS Code route records the branch row alone. Add the missing `curl` line for `codeo-track.sh` to the bare-script instructions. No new code.
- **B.** Record it from inside the container at creation (`postCreateCommand`), with the Host cell reading `unknown (VS Code)`. Covers the route, but adds a second writer with a weaker row, needs `gh` logged in before the container is first used, and still cannot mark the removal.

**Answer:**
Option A: document that only the script routes are recorded and the VS Code route records the branch row alone; add the `curl` line for `codeo-track.sh` (recommended option). Relayed from the engineer in the conversation, 2026-11-23: "Accept all recommendations, proceed with plan".

### Q12 — After an upgrade, how does the first `codeo rm <N>` of a container get the tracker (QC F8)?

**Why it matters:** an older installed `codeo` runs `codeo update` and fetches the new `codeo` and two scripts, not `codeo-track.sh`. The new `codeo` downloads a missing script on any command that reads `~/codeo`, but `rm` of a container deliberately never reads it, so that first removal prints a `note:` and marks nothing.
**Options:**
- **A (recommended).** `codeo rm` of a container fetches a missing `codeo-track.sh` before marking, and only that: when `~/codeo` cannot be used (it is a git checkout and `CODEO_HOME` is unset, or the download fails) the removal still goes ahead and prints the `note:` as today. `.devcontainer/README.md`'s sentence that `rm` of a container never reads the home directory is corrected to say it reads it only for the tracker and never stops over it.
- **B.** No code change: the CHANGELOG upgrade step says to run `codeo update` twice (the second run, by the new `codeo`, fetches the tracker).

**Answer:**
Option A: `codeo rm` of a container fetches a missing `codeo-track.sh` and never stops the removal over it (recommended option). Relayed from the engineer in the conversation, 2026-11-23: "Accept all recommendations, proceed with plan".

## Notes

My calls, stated so they can be corrected (none changes scope; they go in the plan as decisions):

- Duplicate-warning confirmation: an interactive prompt on a tty, and a `--yes` flag to go on non-interactively; `codeo issue` passes `--yes` through to the creating script. Opening an existing container (`shell`, `open`) never warns. For a sandbox the warning fires only when the sandbox is about to be created (the current script reuses an existing one silently).
- The row's Host is the host machine's `hostname`; a row on another host is warned about with the line that it is not proof the container still exists.
- A comment whose table is malformed is reported and left untouched; text outside the table is preserved.
- `codeo-container.sh` stays bash 3.2 / macOS portable (`date -u +%Y-%m-%dT%H:%M:%SZ`); tests extend the existing stub-`docker`/`gh` patterns rather than touching real engines.
- One new role name, `stray`, for a host checkout that is neither home nor an issue's (corrects the earlier note that no role names would be added); a host clone named `<codename>-home` with no lock on the base branch and no container markers is `home`; off the base branch it is `stale:?`; any other host checkout without a lock is refused with a line naming the `<codename>-home` rule. `CLAUDE_CODE_REMOTE=true`, `doctor` and `setup` stay exempt.
- The README gets a host-home section (Claude Code, `gh`, the plugin, git identity), the guard, the tracking comment and a Linux/macOS/Windows-WSL note, with `codeo-home` kept documented as supported; `.devcontainer/README.md`'s role table and the `unguarded` paragraph are rewritten.

### Footprint

```
files:      .devcontainer/scripts/role.sh, .devcontainer/codeo-track.sh, .devcontainer/codeo-container.sh, .devcontainer/codeo, .devcontainer/README.md, .sbx/codeo-sandbox.sh, .sbx/README.md, scripts/cleanup.sh, skills/**, .codeo/overlays/**, docs/extension-points.md, docs/plans/2026-11-22-host-home-strict-guard-and-tracking-152.md, README.md, CHANGELOG.md, tests/role.test.sh, tests/role-guard.test.sh, tests/track.test.sh, tests/cmd-mode.test.sh, tests/sandbox.test.sh, tests/codeo-command.test.sh, tests/cleanup.test.sh, tests/cleanup-skill.test.sh, tests/close-removal.test.sh, tests/init-overlay.test.sh, .codeo/152/**
wiki:       none
exclusive:  none
sequenced:  none
```

## Outcome

Plan: `docs/plans/2026-11-22-host-home-strict-guard-and-tracking-152.md` (left unstaged for review).

**Shape.** A scoped, executable plan under `docs/plans/`, seven tasks in one pull request, guard first. No separate reference doc: the standing description lands in `README.md` and `.devcontainer/README.md` (Task 7).

**Decisions.** Q1 a container in an unshaped folder stays `unguarded` · Q2 on the host any checkout holding a lock is `issue:<N>` in any folder · Q3 one new `.devcontainer/codeo-track.sh` (`add`, `mark`, `confirm`), `gh api` direct, called by the host scripts and, through overlays, by init and close · Q4 the overlays print `codeo rm {N}` and `/codeo:close` marks the branch `deleted` · Q5 and Q7 proceed and coordinate with #146 (`README.md`, `CHANGELOG.md`) · Q6 one pull request. Added by the plan: one new role `stray`; `--yes` as the non-interactive flag; `scripts/cleanup.sh` expands `{N}` in `command:`.

**Rejected.** Option B (tracking verbs in `scripts/github.sh`, branch row written by `skills/init`): two implementations of the table, more plugin-side change. Option C (logic inlined in each host script): three copies. Keeping the raw `docker rm` and appending a `track` command: records even when the removal failed. Refusing containers in unshaped folders: strands engineers with oddly named folders.

**Decisions confirmed at the review gate.** Approved as drafted, including: a local `codeo-<N>` container without `--rebuild` stays a refusal with a warning rather than a confirmation; `stray` for an unlocked host `codeo-<N>` clone; `--yes`.

**Documentation moved.** `README.md`, `.devcontainer/README.md`, `.sbx/README.md`, `CHANGELOG.md`, `docs/extension-points.md`; no wiki module.

**Intake questions resolved here.** How a host home is told apart: folder `<codename>-home`, no lock, base branch, no container marker. Where the tracking comment is written from: `codeo-track.sh`, via the host scripts and the init and close overlays. This repository is the plugin source, so the generic skill text was not needed for either.

**Filed:** none. Optional `engineering:*` skills were unavailable; their structure was applied directly.

## Log

- 2026-11-22 — Q1-Q6 raised · cost: 4m · fable-5-2 70k in + 335k cached / 4k out · sonnet-5-5 220k in + 1.1M cached / 29k out
- 2026-11-22 — answers Q1-Q6 recorded, plan drafted for review (engineering skills unavailable: structure applied directly) · cost: 10m · fable-5-2 70k in + 335k cached / 4k out · sonnet-5-5 276k in + 2.1M cached / 60k out
- 2026-11-22 — planned: docs/plans/2026-11-22-host-home-strict-guard-and-tracking-152.md · cost: 14m · fable-5-2 70k in + 335k cached / 4k out · sonnet-5-5 279k in + 2.8M cached / 64k out
- 2026-11-23 — round 2 (send-back from qc.md round 1): Q8-Q12 raised · cost: 0m · fable-5-2 99k in + 234k cached / 3k out
