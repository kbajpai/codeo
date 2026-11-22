# Issue #154 — plan

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/154 |
| Branch | `fix/close-149-145-leftovers-codeo` |
| Updated | 2026-11-22 |

## Where this stands

Round 1: Q1-Q3 are answered (all picks). The plan is drafted at `.codeo/154/plan-draft.md` and awaits the engineer's approval; the footprint is written after it.

What I found (read against `.devcontainer/codeo`, `.sbx/codeo-sandbox.sh`, `scripts/inflight.sh` and the tests at `de57829`):

- **F7 is reproduced.** A stub `docker` whose `inspect` fails and whose `ps` lists `codeo-5 exited`, then `codeo rm 5 --container`: exit 1 with `could not check what /workspaces of codeo-5 mounts; nothing removed …`, and the calls are `inspect`, `ps`, `start`, two fetches, four reads, and no `docker stop`. The cause: `container_check` stops what it started only when its own result is non-zero (`codeo:526`); here the read is clean (0) and the refusal comes afterwards in `cmd_rm` (`:638`), which no longer knows the container was started. The existing `t_rm_inspect_fails_no_restart` runs only a running container, so nothing catches it.
- **F13: one script refusal names `end <N> --force`** (`codeo-sandbox.sh:390`, no branches after the fetch). `codeo` adds its `codeo rm <N> --force` line only when the script's stderr has no `codeo-sandbox:` line (`codeo:576`), so this refusal gets none, although `--force` does pass it.
- **F12: with `--force` the missing-clone refusal already gets a working remedy.** The script dies at `:381` before `--force` is read, and `codeo rm <N> --force` then adds `sbx rm --force codeo-<N>` when `sbx ls` still lists the sandbox (`codeo:578-583`). Without `--force` nothing names it. For `no sandbox codeo-<N>` there is nothing to remove. So the README can state a remedy that works with no code change.
- **F14, F16, F17, F18 are prose,** and each reads as the QC finding says: the flowchart edge at `.devcontainer/README.md:211`; "cannot list" at `.devcontainer/README.md:217` and `.sbx/README.md:78` (the hint also prints when `sbx_prog` finds no program, `codeo:581`); `cmd_open` dies with "is a container" before `ensure_home` (`codeo:361-363`); `main` makes `CODEO_HOME` absolute for every command (`codeo:732`), and the `CHANGELOG.md:31` sentence says `codeo rm` does.
- **F15:** both `must_precede` calls pin only `A non-zero exit, with or without an`; the second sentence starts ``An `overlap: skipping #<M>'s changed paths` warning`` in both skills (`skills/implement/SKILL.md:91`, `skills/close/SKILL.md:224`).
- **#145 F1-F3 read as the finding says:** `skills/triage/SKILL.md:318` ("the state step 2 read"); `scripts/inflight.sh:25` and `:241` (the fall-through list omits a `--stash-live` check that exits 0 or 4 and prints nothing, `:245`); the #29 case (`tests/inflight.test.sh:991-1010`) commits the dossier with tip date 2026-11-10 against `Updated` 2026-11-15, so the expected line is the same with or without the wrapper.
- The `shell` suite has no single-test filter: each task's proof is `bash tests/run.sh <test>`, then the whole `bash tests/run.sh`.
- **In flight:** #152 (`feat/run-home-role-host-strict`, kbajpai, step `plan`, waits on `/codeo:implement`, nothing changed yet). Its footprint lists most of the files this issue edits: see Q3.

My calls, stated so they can be corrected (not questions):

- One plan under `docs/plans/`, one pull request, no reference doc: nothing here is a standing decision.
- **F12 is README only:** for `no sandbox codeo-<N>` it says there is nothing to remove; for a missing clone it says running it again fails the same way, and that `codeo rm <N> --force` (or `sbx rm --force codeo-<N>` directly) is the way out, discarding whatever the sandbox holds.
- **F14:** the flowchart's edges are qualified (a failed `volume rm` is an error only while the volume still exists; with `--force` a container already gone is not an error), not labelled partial, as #149's Q5 chose.
- **F18:** the sentence at `CHANGELOG.md:31` is corrected in place, although v1.0.8 is released, because the criterion names that sentence. What this issue changes in behaviour (Q1, Q2) gets one new bullet under a new `## Unreleased`.
- **F15's mutation proof** is run and recorded by the task: move the `overlap: skipping` sentence before "The step stops until it is answered" in each skill, see the test fail, revert.
- **#145 F2:** the dossier commit in the #29 case gets tip date 2026-11-16, and the task shows the case fails with the wrapper removed.
- The `engineering` plugin is not installed here; no new component or technology choice is involved, so its structure is not needed.

## Questions

### Q1 — F13, `end <N> --force` in a `codeo rm` refusal: add a `codeo` line, change the script, or only document it?

**Why it matters:** the criterion allows a code fix or a README sentence. It decides whether a `codeo` user who hits the no-branches refusal is told a command they can type, and whether `.sbx/codeo-sandbox.sh` (which #152 also lists) is edited.
**Options:**
- **A — `codeo` adds its own line (my pick).** When the script's stderr holds `end <N> --force removes it anyway`, `codeo rm <N>` adds `codeo: codeo rm <N> --force removes it anyway` after it. The script is not edited; `codeo` matches one more of its phrases, and a test in `tests/sandbox.test.sh` already pins that phrase (`:884`), so a reword fails the suite. One new case in `tests/codeo-command.test.sh`, one README clause in each README.
- **B — change the script's message.** `.sbx/codeo-sandbox.sh:390` names both forms. No phrase matching, but it edits the script the issue puts out of scope "beyond what F13 needs", changes the pinned line in `tests/sandbox.test.sh`, and a user of the bare script reads a `codeo` command they may not have.
- **C — document only.** `.devcontainer/README.md` says the refusal names `end <N> --force` and that the `codeo` form is `codeo rm <N> --force`. No code, and the message stays untypable as printed.

**Answer:**
A — `codeo` adds its own `codeo rm <N> --force removes it anyway` line after the script's no-branches refusal; the script is not edited. (Engineer: "go with your picks", 2026-11-22; given in the conversation, recorded here.)

### Q2 — F7, a refused `rm` that leaves a started container running: stop it again, or do not start it?

**Why it matters:** both leave a stopped container stopped. They differ in what a refusal after a failed `docker inspect` reads and prints, and in how much of the README and flowchart moves.
**Options:**
- **A — stop it again (my pick).** `container_check --no-restart` (passed only when the inspect failed and `--force` was not given, so the refusal is certain) stops a container it started, whatever the read found. Everything else stays: the container is still started, fetched and read once, and a dirty one is still refused with `holds work that exists only there … (codeo rm <N> --force removes it anyway)`. One line of code, one new case beside `t_rm_inspect_fails_no_restart` (a stopped container: `docker stop` in the calls), one README clause.
- **B — do not start it.** With the inspect failed and no `--force`, `cmd_rm` refuses before `container_check`: nothing is started, fetched or read, for a stopped or a running container. Simpler and faster, but every such refusal then prints `could not check what /workspaces of codeo-<N> mounts`, also for a container holding unpushed work, which today is told about that work. The README paragraph at `:178-182`, the flowchart's `inspect failed, no --force` edges and `t_rm_inspect_fails_no_restart` all change.

**Answer:**
A — stop it again: `container_check --no-restart` stops a container it started, whatever the read found. (Engineer: "go with your picks", 2026-11-22; given in the conversation, recorded here.)

### Q3 — #152 lists most of the files this plan edits: proceed, sequence, or re-scope?

**Why it matters:** #152 (branch `feat/run-home-role-host-strict`, assignee kbajpai, step `plan`, working, waits on `/codeo:implement`, nothing changed on its branch yet) has a footprint that covers these files of this plan: `.devcontainer/codeo`, `.devcontainer/README.md`, `.sbx/README.md`, `CHANGELOG.md`, `tests/codeo-command.test.sh`, `tests/sandbox.test.sh` (read-only here unless Q1 is B), `.sbx/codeo-sandbox.sh` (only if Q1 is B), and `glob:skills/**` (here `skills/triage/SKILL.md`). Its plan is about the home role and host tracking, so the edits are in different functions and paragraphs, but the README's sandbox paragraph, `cmd_rm` and the CHANGELOG's top section are places both may touch; the second to merge rebases over the first.
**Options:** *proceed and coordinate* (my pick: this change is small and mostly single sentences; whoever merges second rebases and keeps both sides) · *sequence after #152* (this plan waits for #152 to merge, then is drafted against its code) · *re-scope* (say which files to leave out).

**Answer:**
Proceed and coordinate: whoever merges second rebases over the other. (Engineer: "go with your picks", 2026-11-22; given in the conversation, recorded here.)

## Notes

None.

## Outcome

_Pending — written at the hand-off._

## Log

- 2026-11-22 — Q1-Q3 raised; `engineering` skills unavailable (plugin not installed) · cost: 2m · fable-5-2 113k in + 1.2M cached / 12k out
