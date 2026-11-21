# Issue #149 — plan

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/149 |
| Branch | `fix/close-non-blocking-findings-143` |
| Updated | 2026-11-21 |

## Where this stands

Explored, Q1-Q6 raised, nothing drafted yet. The issue leaves an "or" in six places, and each one decides whether a task is code or prose; those are the questions. Every question carries my pick, so "go with your picks" is a full answer.

What I found (read against `.devcontainer/codeo` and `.sbx/codeo-sandbox.sh` at `56598d3`):

- **F14 has one root.** `home_dir` (`codeo:57`) reads a relative `CODEO_HOME` against `$PWD` on every call, and `cmd_rm` calls it again after `cd "$(home_dir)"` (`:551-557`), which doubles the path. `main` already makes `CODEO_CONTEXT`, `CODEO_SBX_IMAGE` and `CODEO_SBX` absolute once, before any `cd` (`abs_path_env`, `:711-713`).
- **F6: the restart is the last step of `container_check`** (`:511`), and `docker inspect` runs after it returns (`:606`). The only refusal that can follow a restart without `--force`, other than a dirty second read and a failed restart, is the failed inspect. `docker inspect` works on a stopped container too, so it can move ahead of the restart.
- **F13: with `--force`, two script lines mean the sandbox is not there:** `codeo-sandbox: no sandbox codeo-<N>` and `codeo-sandbox: removed codeo-<N>, but could not set aside its refs …`. The third line the issue names, `removed … could not delete its refs`, is printed only without `--force`, where `codeo` already prints no hint after a `codeo-sandbox:` line. `codeo` prints the `sbx rm --force` hint today whenever the script's stderr does not already name that command (`:565`).
- **F12: five script refusals name no command:** no clone, `could not fetch origin`, the pull-request heads, `could not list the commits`, `could not check … for uncommitted work`. The comment at `codeo:561-562` ("--force would not get past it") is also wrong for the no-refs refusal, which `--force` passes.
- **F15: the home-directory stop covers every command that reads the home directory:** `home`, `issue`, `shell`, `open`, `list`, `default`, `update`, and `rm` of a sandbox. `rm` of a container, `help` and a usage error never read it. Making `rm` of a container stop too would change what `rm` refuses, which the issue rules out, so this is a README sentence.
- **F16 is prose only:** one sentence in `.sbx/README.md` and one line under the command list in `codeo help` (not in the usage text, whose lines the tests pin as a table).
- **#144 F4** is a move of two sentences in `skills/implement/SKILL.md` and `skills/close/SKILL.md`, to the order `skills/qc/SKILL.md:96-102` has.
- **#144 F5's stop rule is pinned verbatim** by `tests/overlap-stop.test.sh:17` across `plan`, `implement`, `qc` and `close` (six places). Rewording it changes the test and all six.
- The `shell` suite has no single-test filter: each task's proof is `bash tests/run.sh <test>` followed by the whole `bash tests/run.sh`.
- **In flight:** #151 (`docs/install-codeo-one-command-document`) and #138 (`fix/live-session-signal-does-not`), both at `init` with no footprint and nothing changed. #151's title suggests `.devcontainer/README.md` and perhaps `.devcontainer/codeo`; I compare once this plan has a draft footprint. #145, named at intake, is no longer in flight.

My calls, stated so they can be corrected (not questions):

- One plan under `docs/plans/`, one pull request. No reference doc: nothing here is a standing decision.
- F15 and F16 are prose, as above. F4 is the move, as the issue words it.
- One `CHANGELOG.md` bullet under `## Unreleased`.
- The `engineering` plugin is not installed here; no new component or technology choice is involved, so its structure is not needed.

## Questions

### Q1 — F14, a relative `CODEO_HOME`: make it work, or refuse it?

**Why it matters:** the criterion allows either. It decides whether `CODEO_HOME=rel codeo …` is a supported setup or an error on every command.
**Options:**
- **A — make it work (my pick).** `main` makes `CODEO_HOME` absolute against the starting directory once, with the `abs_path_env CODEO_HOME always` line the other three variables already have. Every command then reads the same directory whatever `cd` follows, not only `rm`. One line of code, one README clause beside the other three variables, one test (`CODEO_HOME=rel codeo rm 5 --sandbox` runs the stub script from `<start>/rel`).
- **B — refuse.** `home_dir` dies with `codeo: CODEO_HOME must be an absolute path` for every command. Simpler to reason about, but it breaks a relative value that works today for every command except `rm` of a sandbox (`tests/codeo-command.test.sh:1564` runs one).

**Answer:**

### Q2 — F6, `docker restart` before the mount check: reorder, or document?

**Why it matters:** today a running container's shells and agents are ended, then `docker inspect` fails, and `rm` refuses with nothing removed. The criterion accepts a README sentence instead of a fix.
**Options:**
- **A — reorder (my pick).** `docker inspect` runs before the restart: after the first read is clean and before `docker restart`. A failed inspect without `--force` then refuses with the same message as today and no session is ended. The inspect result is reused for the volume decision, so the call count stays the same. What can still follow a restart without `--force` is only a dirty second read, a failed restart, or a failed `docker rm`; the README says so. The tests' expected call order (`tests/codeo-command.test.sh:1023`) changes, and one new test asserts no `docker restart` in the calls when inspect fails.
- **B — document.** One README sentence: the restart comes first, so a failed mount check refuses after the sessions were ended. No code.

**Answer:**

### Q3 — F13, how `codeo rm --force` knows the sandbox is already gone

**Why it matters:** the hint must not follow the two outputs above, and a test must fail if it comes back. The mechanism decides whether a future script message can bring the false hint back.
**Options:**
- **A — ask `sbx` (my pick).** After a failed `end --force`, `codeo` runs `sbx ls` once more and prints the hint only when `codeo-<N>` is still listed, or when the listing fails (unknown, so the hint stays). True by the sandbox's state, whatever the script printed, including messages added later. One more `sbx ls` on a failure path only.
- **B — match the script's lines.** No hint when the script's stderr holds `codeo-sandbox: no sandbox codeo-<N>` or `codeo-sandbox: removed codeo-<N>`. No extra call, but it ties `codeo` to two more of the script's phrases; a test in `tests/sandbox.test.sh` would pin them so a reword fails the suite.

**Answer:**

### Q4 — F12, refusals that name no remedy: change the script, or the README?

**Why it matters:** `.devcontainer/README.md:202` says the script's own message "says what to do" whenever it could not read or reach the sandbox. It does not for the five refusals above.
**Options:**
- **A — correct the README and the comment (my pick).** The sentence becomes: the script's own message says what went wrong, and names a command where one applies (`sbx rm --force codeo-<N>` when nothing in the sandbox could be read; `end <N> --force` when no branches were found). The comment at `codeo:561-562` is corrected to match. For the five, the remedy is to fix what failed (the network, the missing clone) and run it again, which the messages already imply.
- **B — the script names a remedy in each of the five.** For example `could not fetch origin: … nothing removed; check the network and run it again`. The README claim then holds as written. Five messages reworded, and `tests/sandbox.test.sh` pins some of them.

**Answer:**

### Q5 — F9, the *Removing a finished container* flowchart: complete it, or label it partial?

**Why it matters:** with Q2 A the chart is redrawn anyway, because the inspect moves ahead of the restart.
**Options:**
- **A — complete it (my pick).** The chart gains the no-container case (refuse, or with `--force` remove the volume and image), the restart failure, the `--force` branches at the read, the mount check and the inspect failure, and the final report.
- **B — label it.** One sentence above the chart: it shows the path without `--force`; the prose covers `--force`, a failed restart and a missing container. With Q2 A the existing nodes are still reordered.

**Answer:**

### Q6 — The #144 leftovers: which are done, which are dismissed in writing?

**Why it matters:** the criterion asks that each item is done or dismissed in writing; the plan's outcome is where a dismissal is recorded.
My pick for each:
- **F3, `qc-verdict.sh:134` — do it.** One new case in `tests/outcome-heading.test.sh`: a re-planned archive whose `plan.md` has `### Round 2` under the varied heading, checked through `qc-verdict.sh`'s footprint failure, for the same six variants. The alternative, correcting the claim, can only be a comment in the test's header, since the commit subject cannot change.
- **F5a, `skills/init/SKILL.md` — do it.** The lock-taken TODO block gains its own "end the turn with this block; do not invoke `/codeo:plan` in this turn". This reads the finding as: a TODO in either case ends the turn, and `/codeo:plan` is the engineer's second step. Say so if the lock-taken TODO case was meant to carry on into `/codeo:plan` after the fix.
- **F5b, the stop rule — do it.** The sentence becomes `Any non-zero exit, with or without an overlap: cannot diff … or overlap: cannot resolve … line, is a stop to report, never "no overlap".` in all six places, and `tests/overlap-stop.test.sh` pins the new wording.
- **F5c, `inflight_send_back` and `inflight.sh:209`'s trailing-space direction — do it if a fixture can separate it, else dismiss.** The task first runs the mutation (line 209 tightened to `/^## Outcome$/`) to see whether `outcome-heading` already fails; QC round 2's own mutation runs say it does. If it fails already, the item is dismissed in the plan's outcome with that run as the reason; if not, a variant is added that does.
- **F5d, `CHANGELOG.md` says the no-lock closing block is "unchanged" — dismiss.** The issue does not list it, and the entry describes a released-as-written change; rewording a past entry adds nothing.

**Options:** as picked · name the items to change.

**Answer:**

## Notes

None yet.

## Outcome

_Pending — written at the hand-off._

## Log

- 2026-11-21 — Q1-Q6 raised · cost: 1m · fable-5-2 106k in + 684k cached / 7k out
