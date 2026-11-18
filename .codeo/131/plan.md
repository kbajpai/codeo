# Issue #131 — plan

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/131 |
| Branch | `feat/make-sbx-sandbox-lock-follow` |
| Updated | 2026-11-18 |

## Where this stands

Exploration is done and no plan is drafted yet. Q1-Q5 are open (and the `live.test.sh` failure is a planned task, see `## Notes`); the draft starts once they are answered. The calls I made without asking are listed under `## Notes` so they can be corrected in the same pass.

## Questions

### Q1 — Who decides that the lock is being taken in a sandbox: `lock.sh` itself, or the start script that calls it?

**Why it matters:** `scripts/lock.sh` ships to every project; the marker `~/.codeo-sandbox` and the name `codeo-<N>` are this project's (`.sbx/codeo-sandbox.sh` writes the one and hard-codes the other). The answer decides which files the plan changes and what `lock.sh`'s interface becomes.
**Options:**
- **A — `lock.sh` reads the marker.** With host `container`, when `${CODEO_SANDBOX_MARK:-$HOME/.codeo-sandbox}` exists it writes `sandbox: <codename>-<N>` (the name `container-name.sh --docker` gives) and skips the volume lookup. The start script does not change. The core then knows a marker file name that only this project's `.sbx/` writes, and it guesses the sandbox's name.
- **B — the start script tells it (my pick).** `lock.sh take container --sandbox <name>` writes `sandbox: <name>` and skips the volume lookup; without the flag it behaves as today. `devcontainer-start.sh` reads the marker, as it already does for the folder check, and passes the name. The core gains a general interface and no project convention. An older pinned `lock.sh` ignores the extra arguments and behaves as today, so nothing breaks before the pin moves.
- **C — a new host value, `host: sandbox`.** Rejected unless you want it: the issue keeps `host: container`, and every reader of `host` (`live.sh`, `/codeo:close`, `role.sh`, `docs/handoff.md`) would need the new value.

With A or B, the name comes from somewhere: under B I would have `codeo-sandbox.sh` write the sandbox's name into the marker (`codeo-<N>` in place of an empty file; the readers only test that it exists), and the start script pass that, falling back to `container-name.sh --docker` for an empty marker left by an older run. Say so if the marker should stay empty.

**Answer:**
B, my pick, as the engineer chose in the session ("All Picks", 2026-11-18): the start script passes `--sandbox <name>`; the marker holds the sandbox's name, with `container-name.sh --docker` as the fallback for an empty one. (Transcribed by the skill from the engineer's chat answer.)

### Q2 — The start script runs the installed plugin's `lock.sh` (pinned v1.0.7), not the clone's. Is a run in a real sandbox part of this plan?

**Why it matters:** `devcontainer-start.sh:229-230` takes the lock with `codeo-root.sh`'s plugin, so in this repository a real sandbox keeps printing the volume TODO until a release carries the fix and the pin moves. The tests can prove the first four criteria against the clone's `lock.sh`. A real run needs a task marked `Runs on: the engineer's host`, with `CODEO_ROOT` pointed at the clone inside the sandbox, and (the lock's host is `container`) a question about your shell.
**Options:**
- **Tests only (my pick).** The criteria are proved by `tests/run.sh`; the plan says under Global Constraints that a real sandbox shows the change only after the next release and pin bump, and the release checklist picks it up.
- **Tests and one host task.** The plan ends with a task you run on the host: `issue <N> <branch>` on this branch, then in the sandbox remove `.codeo/active` and re-run the start script with `CODEO_ROOT` set to the clone, and check the lock's `sandbox:` line. I then ask which shell you use.

**Answer:**
Tests only, my pick, as the engineer chose in the session ("All Picks"). (Transcribed.)

### Q3 — When `end` cannot start or fetch the sandbox, should `--force` remove it anyway, or should the message only name the raw command?

**Why it matters:** today both `end <N>` and `end <N> --force` stop at `could not fetch sandbox-codeo-<N> into codeo-<N>, nothing removed` (`.sbx/codeo-sandbox.sh:372-374`). The criterion asks that the output name a way to remove the sandbox, with and without `--force`. The answer decides whether `cmd_end`'s control flow changes or only its messages.
**Options:**
- **Message only (my pick).** Both forms still remove nothing. The line says that nothing in the sandbox could be read, so nothing can be proved or kept, and names `sbx rm --force codeo-<N>` as the way to remove it; with `--force` it adds that `--force` cannot keep commits it could not fetch, so it did not remove the sandbox either. The engineer types the destructive command knowingly.
- **`--force` goes on.** Without `--force` the line names `end <N> --force`; with it, `end` removes the sandbox, keeps whatever refs an earlier fetch left under `refs/codeo/ended/`, and says that what the sandbox held since then is gone. One command, at the cost of `--force` removing work it never saw.

**Answer:**
Message only, my pick, as the engineer chose in the session ("All Picks"). (Transcribed.)

### Q4 — What should `/codeo:close` say for a sandbox after a stash and after an abandon?

**Why it matters:** the criterion covers the finished close only (`codeo-sandbox.sh end <N>`, no Docker line). The overlay's stash and abandon paragraphs (`.codeo/overlays/close.md`) are written for a container: they send the engineer to the home container and say the container must be removed by hand before a resume, because two containers cannot share a name. Neither holds for a sandbox: `issue <N> <branch>` on an existing sandbox reuses it. The answer decides whether the plan adds a sandbox paragraph for each of the three endings or only for the finished one.
**Options:**
- **All three (my pick).** Finished: `bash codeo-sandbox.sh end <N>`, on the host, in the folder that holds `codeo-<N>`; `end` itself refuses while anything is unpushed. Stash: no removal command; the sandbox may stay, and the resume is `/codeo:init #<N>` in the home container, then `bash codeo-sandbox.sh issue <N> <branch>` again. Abandon: no removal command; branch kept, `end <N>` is safe to run; branch deleted, the sandbox holds the only copy, and `end` will refuse without `--force`.
- **Finished only.** Stash and abandon keep the container wording for a sandbox too, and the gap is filed as a follow-up.

The follow-up skills (`/codeo:triage`, `/codeo:cleanup`, `/codeo:init`) are still named as running in the home container `codeo-home` under either option; tell me if the sandbox route has another home.

**Answer:**
All three, my pick, as the engineer chose in the session ("All Picks"); home container `codeo-home` stays the follow-up home. (Transcribed.)

### Q5 — A sandbox created before this change holds a lock with `volume: unknown`. Should close recognise it?

**Why it matters:** a taken lock is never rewritten, so every sandbox already in use keeps `volume: unknown`, and its close would still say to look for a container with `docker ps`. Recognising it means the overlay tells `/codeo:close` to test for `~/.codeo-sandbox` when the lock has no `sandbox:` line, which is one more branch in the overlay text and one more test.
**Options:** leave it: the fix applies to locks taken from now on, and the README says an older sandbox is ended with `end <N>` (my pick) · the overlay also checks the marker for a lock with `volume: unknown`.

**Answer:**
Leave it, my pick, as the engineer chose in the session ("All Picks"). (Transcribed.)

## Notes

Calls made without a question. Each is mine; correct any of them in an answer above or in a line here.

- **One plan, one pull request.** The issue consolidates #123 and #125 so the shared files are edited once.
- **Shape:** an implementation plan under `docs/plans/`, no standing reference doc. The lock's `sandbox:` line is documented where the `volume:` line is today (`docs/handoff.md → The lock`).
- **`/codeo:close` in two layers.** `skills/close/SKILL.md` step 17 stays free of any engine or project command (`tests/close-removal.test.sh` forbids `docker` in it): its `host: container` default learns that a lock may carry `sandbox:` in place of `volume:`, and that either names what the host removes. The command `codeo-sandbox.sh end <N>` goes in this project's `.codeo/overlays/close.md`, keyed on the `sandbox:` line, with `tests/close-removal.test.sh` extended for both lock kinds.
- **`scripts/live.sh`** names the machine from the lock's `volume:` line for `host: container` (`:106`). It will read `sandbox:` when there is no `volume:`, so a sandbox's live signal is named `codeo-<N>` and not after the hostname. This is a consequence of the lock change, not new scope.
- **F19:** when the start script's `exec` fails, `issue` ends with one `codeo-sandbox:` line saying the start script failed in `codeo-<N>`, to fix what it printed and run `issue <N> <branch>` again, or `shell <N>` to look inside. `check_name` and `run -d` do not run after it.
- **F20:** `read_pin` moves into the branch of `ensure_sandbox` that creates, so an existing sandbox needs no pin.
- **Test gaps:** all six are closed, none dropped. The CHANGELOG check stops reading line 9 and instead greps the file for the old clause being absent and the new one present. `required_state` becomes a declared global beside `create_agent`. `sandbox_state` gets a case for a row with fewer than three columns, and `issue` one for a failed `run -d`.
- **The "without the marker" test does not fail today the way #99's review said.** `ds_run` (`tests/devcontainer.test.sh:501-512`) already sets `HOME` to a scratch folder, so the real `$HOME/.codeo-sandbox` is never read: `bash tests/devcontainer.test.sh` with `HOME` pointed at a folder holding `.codeo-sandbox` printed `all cases passed` (run here, 2026-11-18). The criterion still asks for a test that shows it, so the plan adds one that runs the case with the marker present in the outer `HOME`, and pins `CODEO_SANDBOX_MARK` to a missing path in the no-marker half so the case no longer depends on `ds_run`'s `HOME`. A whole `tests/run.sh` under the same `HOME` finished with one failing file, `live.test.sh`, which fails the same way with no marker. **You said to fix it in this plan, so it is a task.** Cause, found by reading: `git -C "$clone" rev-parse --git-path codeo-live-beat` prints a path relative to the clone (`.git/codeo-live-beat`), and three assertions (`tests/live.test.sh:229`, `:236`, `:375`) test it with `-e` from the test's own working directory, which is this repository. Any checkout where the live-signal hook has already fired (this one: `.git/codeo-live-beat`, written 23:18 by this session's hook) holds a real stamp there, so the test reads that one and reports `yes`. Line 371 tries `$clone/$stamp` first, so it passes only by luck. The fix is in the test only: read the path with `git rev-parse --path-format=absolute --git-path` (git 2.31 or later; this host has 2.53), which makes all four checks independent of the working directory. The proof is `bash tests/live.test.sh` printing no failure in this checkout, where the real stamp exists. `scripts/live.sh` is correct and does not change.
- **Documentation the change moves:** `docs/handoff.md` (the lock's `container` bullet, and the live signal's machine name), `docs/extension-points.md` (`close/host-workflow`: *May rely on* gains `sandbox:`), `.sbx/README.md` (the lock line in the `issue` sequence, *Ending a sandbox*, the failed-fetch way out), `.devcontainer/README.md` (where close's removal command is described), and a `CHANGELOG.md` entry.
- **Out of the plan, as the issue says:** `/codeo:cleanup` and `scripts/cleanup.sh` for sandboxes; `role.sh` classifying a sandbox as `unguarded`.

## Outcome

_Pending — written at the hand-off._

## Log
