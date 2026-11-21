# Issue #143 — plan

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/143 |
| Branch | `fix/codeo-host-command-close-leftovers` |
| Updated | 2026-11-21 |

## Where this stands

Q1-Q6 answered ("go with my picks"). The plan is drafted at `.codeo/143/plan-draft.md`, but Q7 is open (`CHANGELOG.md` is also in #144's footprint), so the draft is not presented for approval until it is answered.

What I found that shapes the questions (read against `.devcontainer/codeo` at `2e02100`):

- **Much of the list is already fixed on `main`.** #133's rounds 2-5 fixed most of what its own QC called non-blocking, so the work left is smaller than the issue reads. Already fixed, with a test: F19 (`detect_kind` `:244` dies when one listing failed and the other found `codeo-<N>`), F3, F4, F7, F11, F12, F13, F20, F27, F28, F26, F10, F22, F23, F15, F14, and the kind flags in the help text and `.sbx/README.md` (F5, F16). Q5 has the row for each.
- **Still wrong, confirmed by reading:** F29 (`:500-502`), F30 (`:527-533`), the shared `$name.part` (`:98-106`) and `.lookup.git.part` (`:119-124`), `git fetch origin` without `--prune` (`:448`), `git status --porcelain` without an untracked setting (`:452`), the write between check and removal (`:506-527`), the volume removed by name only (`:533`), relative `CODEO_CONTEXT` / `CODEO_SBX_IMAGE` after `cd` (`:150`), and the changelog bullet (`CHANGELOG.md:15`).
- **`codeo-sandbox.sh end` exits 1 for every failure**, so `codeo` cannot tell a refusal over unpushed work from an unreadable sandbox by the exit status. The script already prints `to remove it anyway run: sbx rm --force codeo-<N>` itself in the two cases where nothing could be read (`die_unreadable`). That is what Q3 turns on.
- **Stale refs feed two checks, not one.** `rev-list --not --remotes=origin` (`:461`) and the detached-HEAD check `branch -r --contains HEAD` (`:458`) both read remote-tracking refs, so `--prune` on the first fetch fixes both. The prune also drops `refs/remotes/origin/pr/*`, and the pull-request fetch on the next line brings them back, so the order of the two fetches must stay.
- The `shell` suite has no single-test filter: every task's proof is `bash tests/run.sh codeo-command` followed by the whole `bash tests/run.sh`.
- #144 and #145 are in flight, both at `init` with no footprint and nothing changed yet. All three will add a `CHANGELOG.md` bullet under `## Unreleased`; I compare footprints once this plan has a draft.

## Questions

### Q1 — The write between the safety check and `docker rm -f`: close the window, or record that it stays?

**Why it matters:** this is the one acceptance criterion with an "or". Today a shell or agent attached to a running `codeo-<N>` can commit or save a file after `container_check` has read the repository and before the removal, and that work goes with the volume without `--force`. The choice decides whether `rm` ever interrupts a running session.
**Options:**
- **A — check, restart, check again, remove (my pick).** The check runs as today on the live container, so a dirty container is refused without disturbing anything in it. When it comes back clean and the container was running, `codeo` runs `docker restart codeo-<N>`, which ends every attached shell and agent, then repeats the local reads only (status, stashes, detached HEAD, unpushed commits; no second fetch, since a commit pushed in the window is safe either way) and removes when they are still clean. If the second read finds something, `rm` refuses as usual and the container is left running, restarted. A container `codeo` started itself for the check has no attached session and skips the restart. What stays open: someone who runs `docker exec` into the container in the second or so after the restart. Cost: one `docker restart` (up to 10 seconds on a VS Code-route container, which has no `--init`) and four more `docker exec` calls per clean removal.
- **B — stop the container and check its volume from a helper container.** The reviewer's suggestion: `docker stop`, then run the git checks in a throwaway `docker run` of the issue's image with the same three volumes. Closes the window completely. It rewrites `container_check` and every test stub around it, a refusal leaves the container stopped (or needs it started again), and it interrupts a running session even when the answer is "refused".
- **C — do not prevent it; document it.** The README and the refusal text say to run `codeo rm` only when nothing is working in the container, and the plan records that the window stays. No code.

**Answer:** A — check, restart, check again, remove. (Engineer: "go with my picks", 2026-11-21.)

### Q2 — `~/codeo` is also what `git clone` of this repository makes in `~`: move, detect, or document?

**Why it matters:** an engineer who cloned this repository into `~` and installs `codeo` gets the scripts, `default`, `.lookup.git` and the `codeo-<N>` sandbox clones written into their checkout. Moving the default directory changes every existing install, yours included.
**Options:**
- **A — detect and stop (my pick).** With `CODEO_HOME` unset and `~/codeo/.git` present, `codeo` prints one line (`~/codeo is a git checkout; set CODEO_HOME to the directory codeo should keep its files in`) and exits 1 before writing anything. The directory `codeo` keeps is never a git work tree itself, so nothing that works today breaks. The README gains one sentence. `codeo help` and argument errors still work.
- **B — document only.** One README sentence naming `CODEO_HOME`; no code.
- **C — a new default** (for example `~/.local/share/codeo`), still using `~/codeo` when it already holds `codeo-container.sh`. Avoids the collision for new installs, at the cost of two possible locations, a migration rule and a rewrite of every `~/codeo` in both READMEs.

**Answer:** A — detect and stop: with `CODEO_HOME` unset and `~/codeo/.git` present, one line and exit 1 before anything is written. (Engineer: "go with my picks", 2026-11-21.)

### Q3 — After `codeo-sandbox.sh end` fails, how does `codeo rm` decide which hint to print (F29)?

**Why it matters:** the script cannot change and exits 1 for everything, so `codeo` either goes by whether `--force` was given or reads the script's text.
**Options:**
- **A — by `--force` alone (my pick).** Without `--force`, `codeo` never names `sbx rm --force`; it prints `codeo: codeo rm <N> --force removes it anyway and keeps its commits in ~/codeo/codeo-<N> when it can read them`, which is the route that sets the sandbox's refs aside. With `--force` and a failure, the script has refused for a reason other than unpushed work (no clone, cannot start, cannot fetch), and only then `codeo` prints the `sbx rm --force codeo-<N>` line, worded as discarding whatever the sandbox holds, and not when the script's own message already carries it. Meets the criterion with no dependence on the script's wording. Its flaw: after `no sandbox codeo-<N>` or `no clone codeo-<N> here` without `--force`, the first hint leads to a second failure before the right one shows.
- **B — by the script's text.** `codeo` captures the script's output while still showing it and picks the hint from its phrases (`nothing removed: … or run: codeo-sandbox.sh end`, `no sandbox`, `no clone`, `could not remove`). Exact in every case, but it ties `codeo` to another file's wording; a test would pin each phrase against `.sbx/codeo-sandbox.sh` so a reword fails the suite.

**Answer:** A — by `--force` alone: no `sbx rm --force` hint without `--force`; with it, the hint only when the script's own stderr lacks it. (Engineer: "go with my picks", 2026-11-21.)

### Q4 — A `codeo-<N>` container whose `/workspaces` is not the volume `codeo-<N>` (thread …636455): fix or rule out?

**Why it matters:** `rm` checks the repository the container shows and then deletes the volume `codeo-<N>` by name. If the container was opened from a host folder (a bind mount) while an older volume of that name exists, that volume is deleted unchecked. It needs an unusual setup; the fix is one more `docker` call per removal.
**Options:**
- **A — fix (my pick).** Before removing, `codeo` reads the container's mounts with `docker inspect`. When `/workspaces` is the volume `codeo-<N>`, nothing changes. When it is not, `rm` without `--force` removes the container and its image, leaves the volume and says so in one line naming `docker volume rm codeo-<N>`; `--force` removes the volume too, saying it was not checked. A failed `docker inspect` counts as "could not check".
- **B — rule out.** Reason recorded: both documented routes (`codeo-container.sh` and the VS Code clone-in-volume route) mount the volume `codeo-<N>` on `/workspaces`, so the case needs a container made by hand.

**Answer:** A — fix: read the mounts with `docker inspect` before removal. (Engineer: "go with my picks", 2026-11-21.)

### Q5 — Is this the ruling you want on each remaining item?

**Why it matters:** the issue asks that every listed item is fixed or ruled out with a reason, and that the three "appear fixed" items are confirmed. This table becomes that record and the plan's task list. Line numbers are `.devcontainer/codeo` at `2e02100`.

| Item | What I found | Ruling proposed |
|---|---|---|
| F19, thread …636350 | Fixed: `detect_kind` `:244` dies and asks for a flag; `t_shell_docker_down_sandbox_found` covers `shell` with docker down | No code. Add `rm` tests in both directions (docker down with sbx listing, sbx down with docker listing) asserting nothing runs |
| F29 | Present | Fix per Q3 |
| F30 | Present (`:527-533`) | Fix: `rm` tracks what it removed. With no container the volume message never says a container was removed; with `--force` and neither container nor volume it says `nothing named codeo-<N> to remove` and exits 1; the last line names only what was removed |
| …636234 (prune) | Present (`:448`) | Fix: `git fetch --prune origin`, before the pull-request fetch. Test: a commit held only by a deleted branch's stale ref is refused |
| …636301 (untracked) | Present (`:452`) | Fix: `git status --porcelain --untracked-files=normal` (`normal`, not `all`: a new directory is one line, and the report shows 10 lines) |
| …636391 (write after check) | Present | Per Q1 |
| …636455 (volume by name) | Present | Per Q4 |
| …636491, …636540 (concurrent first use) | Present (`:98-106`, `:119-124`) | Fix: each download goes to its own `mktemp` file in `~/codeo` and is renamed into place; the lookup clone, repoint and fetch run under `flock` on `~/codeo/.lookup.lock`, the clone into its own `mktemp -d` directory. `flock` joins `curl` and `git` as a requirement in the README (it is part of util-linux on every Linux host). Test: two commands started together against slow stubs both exit 0 and leave complete files |
| …636698 (relative overrides) | Present (`:150`) | Fix: `run_script` and the sandbox `rm` path make a relative `CODEO_CONTEXT` or `CODEO_SBX_IMAGE` absolute against the caller's directory before `cd` |
| …636654, F10 | Fixed (`rev-parse`, `:134`), except that `<branch>:path` resolves a same-named tag before the branch | Confirmed; one-line fix of the remainder: `refs/heads/<branch>:…` |
| …636595, F9 | Fixed (`remote set-url`, `:126`; `t_lookup_repoints_clone_at_url`) | Confirmed, dropped |
| F26, …636750 | Fixed (`sbx_prog`, `:189-199`; `t_codeo_sbx_honoured`) | Confirmed, dropped |
| F3 | Fixed (`-q` at `:120`, `:128`; `t_lookup_quiet_git`) | Ruled out: fixed |
| F4 | Fixed (`:156`; `t_home_rebuild_twice_usage`) | Ruled out: fixed |
| F7 | Fixed (`:130-131`; `t_lookup_branch_list_failure`) | Ruled out: fixed |
| F8 | Fixed in `cmd_update` (`:560`) and by `stop_started`; `cmd_default` (`:410`) still prints `mkdir`'s raw error | Fix the one line in `cmd_default` |
| F11 | Fixed (`:517-519`; `t_rm_container_not_found`) | Ruled out: fixed |
| F12 | Fixed (`:446`; `t_rm_unlisted_state_not_stopped_by_us`) | Ruled out: fixed |
| F13 | Fixed (`:367`) | Ruled out: fixed |
| F20 | Fixed (`:458`; `t_rm_container_detached_pushed`) | Ruled out: fixed; the prune above also covers its stale-ref case |
| F27 | Fixed (`:533`; `t_rm_volume_failure_says_container_removed`) | Ruled out: fixed; F30 corrects the case where it overstates |
| F28 | Fixed (`:286-287`; `t_issue_lookup_invalid_branch`) | Ruled out: fixed |
| F5, F16 | Help text and `.sbx/README.md` rows carry the flags. `.devcontainer/README.md`'s first table (`:47`) lacks the flag on `shell`, and its command table has no `open` or `default` row | Fix those rows |
| F14 | Fixed (`.devcontainer/README.md:113`) | Ruled out: fixed |
| F15 | Fixed: neither README says "all or nothing" | Ruled out: fixed |
| F6, F31 | Present (`CHANGELOG.md:15`, still under `## Unreleased`) | Rewrite the bullet in place to describe the command as it is after this change; no second bullet |
| F17 | 14 lines over 120 columns, four of them comments (`:441`, `:445`, `:449-450`, `:497`) | Re-wrap the comments; code lines stay |
| F22 | Fixed (the stub comment says `rev-parse`) | Ruled out: fixed |
| F23 | Fixed (`.devcontainer/README.md:115`) | Ruled out: fixed |
| F21 | Present | Per Q2 |

Not in the issue's list and left alone: F2 (a stopped container's branch is `-`, your #133 Q5 answer) and F32 (unpushed commits listed as bare hashes).

**Options:** as in the table · changes, named by row.

**Answer:** As in the table. (Engineer: "go with my picks", 2026-11-21.)

### Q6 — One run against real Docker on your host before QC, or stubs only?

**Why it matters:** the suite runs `codeo` against stub `docker`, `sbx` and `git`. `--prune` against a real remote, `docker restart` (Q1 A) and the `docker inspect` mount format (Q4 A) are things a stub answers however the test tells it to; #133 needed a reviewer's real-git run to find F24. A host task is one you run, since this container has no Docker.
**Options:**
- **A — one last task marked `Runs on: the engineer's host` (my pick):** a short list of single `codeo` commands on a throwaway issue container (create, leave an untracked file, `codeo rm` refuses, clean it, `codeo rm` removes), with the output each must give.
- **B — stubs only.** The plan says under Global Constraints that real Docker was not exercised.

**Answer:** A — one last task marked `Runs on: the engineer's host`. (Engineer: "go with my picks", 2026-11-21.)

### Q7 — `CHANGELOG.md` is also in #144's footprint: proceed and coordinate, sequence after #144, or re-scope?

**What overlaps:** `CHANGELOG.md`. #144 (`fix/close-108-leftovers-overlap-sh`, assignee kbajpai, at `plan`) lists it in its `files:`; this plan's Task 8 rewrites the `codeo` bullet under `## Unreleased`. Nothing else overlaps: #144 touches `scripts/`, `skills/`, `docs/` and its own tests, none of `.devcontainer/`, `.sbx/` or `tests/codeo-command.test.sh`. #145 (`fix/close-102-126-122-leftovers`, at `plan`, waiting on its own questions) has no footprint yet; it is compared when it has one.
**Why it matters:** both branches edit the same `## Unreleased` section. Different bullets, so the conflict at merge is textual and small, but whichever merges second has to resolve it by hand.
**Options:**
- **A — proceed and coordinate (my pick).** Same agreement as #133's Q6: whichever merges second keeps both entries intact. This plan edits only the `codeo` bullet and leaves every other bullet and the header lines alone, so the second merge is a one-hunk resolution.
- **B — sequence after #144.** This plan waits for #144 to merge; `sequenced:` in the footprint reads `after #144 — both edit CHANGELOG.md (Q7)`. Costs a wait for a one-bullet conflict.
- **C — re-scope.** Move the changelog edit out of this plan and into a follow-up issue. Leaves the #143 acceptance criterion about the changelog unmet.

**Answer:**

## Notes

Calls I made, to correct if wrong:

- **One plan, one pull request.** The fixes share one file and one test file, and the wording fixes describe the same behaviour, so splitting would only create merge conflicts with itself. The output is a plan under `docs/plans/` (`2026-11-21-codeo-host-command-leftovers-143.md`), no separate reference doc: the READMEs are the standing reference.
- `codeo-sandbox.sh` and `codeo-container.sh` do not change, as the issue says.
- No invariants document, no shared environment and no `wiki` module are configured, so there is no invariants check, no lease task and `wiki: none`.

## Outcome

_Pending — written at the hand-off._

## Log
- 2026-11-21 — Q1-Q6 raised · cost: 3m · fable-5-2 137k in + 843k cached / 19k out
- 2026-11-21 — Q1-Q6 answered; plan drafted; Q7 raised (CHANGELOG.md overlap with #144) · cost: 10m · fable-5-2 144k in + 980k cached / 20k out · sonnet-5-5 176k in + 889k cached / 28k out
