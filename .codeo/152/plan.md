# Issue #152 — plan

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/152 |
| Branch | `feat/run-home-role-host-strict` |
| Updated | 2026-11-22 |

## Where this stands

Round 1, answers in. Q1-Q6 were answered "accept all recommendations" in the conversation and are recorded under each question. The plan is drafted in `.codeo/152/plan-draft.md` and awaits approval; nothing is written under `docs/plans/` before that.

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

## Notes

My calls, stated so they can be corrected (none changes scope; they go in the plan as decisions):

- Duplicate-warning confirmation: an interactive prompt on a tty, and a `--yes` flag to go on non-interactively; `codeo issue` passes `--yes` through to the creating script. Opening an existing container (`shell`, `open`) never warns. For a sandbox the warning fires only when the sandbox is about to be created (the current script reuses an existing one silently).
- The row's Host is the host machine's `hostname`; a row on another host is warned about with the line that it is not proof the container still exists.
- A comment whose table is malformed is reported and left untouched; text outside the table is preserved.
- `codeo-container.sh` stays bash 3.2 / macOS portable (`date -u +%Y-%m-%dT%H:%M:%SZ`); tests extend the existing stub-`docker`/`gh` patterns rather than touching real engines.
- One new role name, `stray`, for a host checkout that is neither home nor an issue's (corrects the earlier note that no role names would be added); a host clone named `<codename>-home` with no lock on the base branch and no container markers is `home`; off the base branch it is `stale:?`; any other host checkout without a lock is refused with a line naming the `<codename>-home` rule. `CLAUDE_CODE_REMOTE=true`, `doctor` and `setup` stay exempt.
- The README gets a host-home section (Claude Code, `gh`, the plugin, git identity), the guard, the tracking comment and a Linux/macOS/Windows-WSL note, with `codeo-home` kept documented as supported; `.devcontainer/README.md`'s role table and the `unguarded` paragraph are rewritten.

## Outcome

_Pending — written at the hand-off._

## Log

- 2026-11-22 — Q1-Q6 raised · cost: 4m · fable-5-2 70k in + 335k cached / 4k out · sonnet-5-5 220k in + 1.1M cached / 29k out
- 2026-11-22 — answers Q1-Q6 recorded, plan drafted for review (engineering skills unavailable: structure applied directly) · cost: 10m · fable-5-2 70k in + 335k cached / 4k out · sonnet-5-5 276k in + 2.1M cached / 60k out
