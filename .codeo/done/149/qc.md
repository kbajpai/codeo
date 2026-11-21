# Issue #149 — qc

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/149 |
| Branch | `fix/close-non-blocking-findings-143` |
| Updated | 2026-11-21 |

## Where this stands

Round 3 done: clear, forward to `/codeo:close`. No blocking finding; every criterion is met on this pass's own output (build exit 0, full suite `all cases passed`). F12-F18 and the earlier F2 and F7 are non-blocking and recorded. Next step: `/codeo:close`.

## Questions

### Q1 — #138 also changes `CHANGELOG.md` (`CHANGELOG.md`, `glob:CHANGELOG.md`): proceed, sequence, or re-scope?

**Why it matters:** `overlap.sh 149` printed `138	CHANGELOG.md` and `138	glob:CHANGELOG.md`. #138 (branch `fix/live-session-signal-does-not`, assignee kbajpai, step `implement`, working; waits on its own `qc.md` Q1-Q3) lists `CHANGELOG.md` in its footprint and has changed it; this branch adds one `## Unreleased` bullet (`fbb7128`). `git merge-tree --write-tree origin/fix/live-session-signal-does-not HEAD` exits 0: the two branches merge today without a conflict. Whichever merges second may still meet a one-hunk conflict if the other's bullet lands next to its own after a later rebase. This is the same kind of overlap `plan.md` Q7 answered for #151.
**Options:** *proceed and coordinate* (my pick: no conflict today, and the second to merge keeps both bullets) · *sequence after #138* · *re-scope*.

**Answer:**
Proceed and coordinate. (Engineer: "go with your picks", 2026-11-21.)

### Q2 — #138 also changes `docs/handoff.md` (`docs/handoff.md`, `glob:docs/handoff.md`): proceed, sequence, or re-scope?

**Why it matters:** `overlap.sh 149` printed `138	docs/handoff.md` and `138	glob:docs/handoff.md`. #138 rewrites the live-signal paragraph (its hunk `@@ -164,29 +164,37 @@`); this branch changes one sentence, the overlap stop rule in the footprint bullet (hunk `@@ -218,7 +218,7 @@`, Task 7, `da6afe8`). Different sections, and `git merge-tree` reports no conflict. This plan's footprint did not list `docs/handoff.md` against #138 because #138 had no footprint at plan time.
**Options:** *proceed and coordinate* (my pick: separate hunks, no conflict) · *sequence after #138* · *re-scope*.

**Answer:**
Proceed and coordinate. (Engineer: "go with your picks", 2026-11-21.)

## Notes

None beyond the round.

## Outcome

### Round 1 — 2026-11-21

Q1-Q2 (overlaps with #138 on `CHANGELOG.md` and `docs/handoff.md`) were answered *proceed and coordinate*; `git merge-tree --write-tree origin/fix/live-session-signal-does-not HEAD` exits 0, so the branches merge without a conflict today.

**Step 2, scope.** `sync-main.sh --abort-on-conflict`: `sync-main: the branch already contains origin/main`. `overlap.sh 149` prints nothing now. `overlap.sh --outside 149` prints nothing (exit 0): every changed path is inside the footprint. `scope.sh origin/main HEAD`: `suite.shell=true` (unclassified paths: the dossiers and `CHANGELOG.md`). Diff `956a86f..e7e88b9`: 22 files, 863 insertions, 63 deletions; `scripts/` unchanged, `.sbx/codeo-sandbox.sh` unchanged. No invariants file, no shared environment, no `wiki` module, no overlay rules (`qc invariants-extra` and `qc wiki-rules` exit 3), so step 9 does not apply.

**Step 3, build.** The `shell` suite's `build` is `true`: exit 0.

**Step 4, suite.** `bash tests/run.sh` (the `shell` suite's `test`, whole): `all cases passed`, `suite-exit=0`. The Opus reviewer briefly mutated `scripts/inflight.sh` and `scripts/qc-verdict.sh` while this run was going and restored both; to rule out a read of a mutated copy, `bash tests/run.sh outcome-heading`, `inflight` and `qc-verdict` were re-run on the clean tree afterwards: each `all cases passed`, and `git status --short` is empty.

**Step 5, criteria** (the test or line that settles each):

| # | Criterion | Verdict | Settled by |
|---|---|---|---|
| 1 | With `--force`, none of the three F13 outputs is followed by the `sbx rm --force` hint; a test fails if it returns | met | `t_rm_sandbox_force_gone` (`tests/codeo-command.test.sh:974`) covers `no sandbox`, both `removed …, but could not … refs` lines and a second-column row; `.devcontainer/codeo:576-580` prints the hint only when `sbx ls` lists the sandbox or cannot list. The reviewer ran the new test file against the base `.devcontainer/codeo` and it failed there. See F2 for the listing-failure case. |
| 2 | `CODEO_HOME=rel codeo rm <N> --sandbox` completes, with a test | met | `.devcontainer/codeo:728` `abs_path_env CODEO_HOME always`; `t_relative_codeo_home_rm` (`:1615`), which failed on the base code with `mktemp … home/home/.rm-err.*` |
| 3 | A `rm` that refuses without `--force` does not run `docker restart` first | met | `.devcontainer/codeo:589-591` and `:516`; `t_rm_inspect_fails_no_restart` (`:1798`) and `t_rm_container_clean`'s call order. The README says the restart can still precede a later refusal (second read, restart failure, `docker rm`). |
| 4 | No README or help sentence about the script's own message, the home-directory stop or the failed-listing exit contradicts the code; the flowchart matches the prose or says it is partial | not met | F1: `.devcontainer/README.md:98` says the stop is "one line", and `codeo issue <N>` with no kind flag prints it twice (reproduced below). F3 and F4 also leave README text out of step with the flowchart and the restart paragraph. The script-message (F12) and failed-listing (F16) sentences are true against the code. |
| 5 | The two skill sentences under #144 F4 sit after "The step stops until it is answered" | met | `skills/implement/SKILL.md:89-93`, `skills/close/SKILL.md:220-225`; `must_precede` at `tests/implement-skill.test.sh:115` and `tests/close-skill.test.sh:443` |
| 6 | `qc-verdict.sh:134` is pinned; each #144 F5 item done or dismissed in writing | met | `qc_verdict_replan` (`tests/outcome-heading.test.sh:192`); F5a `skills/init/SKILL.md:352` pinned at `tests/init-skill.test.sh:54`; F5b seven places, `grep -c 'with or without an'`: plan 2, implement 1, qc 2, close 1, handoff 1, pinned by `tests/overlap-stop.test.sh`; F5c `inflight_send_back` varies `close.md` alone; F5d dismissed in writing in `plan.md` and `implement.md` |
| 7 | `bash tests/run.sh` ends `all cases passed` | met | this pass's run, quoted under step 4 |

**Reproduction of F1** (a `HOME` holding `codeo/.git`, `CODEO_HOME` unset, stubs-free): `codeo issue 5` prints `codeo: ~/codeo is a git checkout; set CODEO_HOME to the directory codeo should keep its files in` twice, exit 1; `codeo issue 5 --container`, `list`, `rm 5 --sandbox`, `shell 5` and `default` print it once. The base code (`956a86f`) prints it twice for `issue 5` too.

**Step 6, documentation.** Pages the diff changes: `.devcontainer/README.md`, `.sbx/README.md`, the `codeo help` text, the five skill pages and `docs/handoff.md`, `CHANGELOG.md`. They are present tense and carry no issue numbers (`grep` for `#14` and `#149` in both READMEs finds nothing). The plan names no page the diff left untouched. Findings F1, F3, F4, F6 and F7 are documentation findings.

**Step 7, independent review** (Opus, given the criteria and the diff only). It ran the new tests against the base code and each new test failed there; it mutated `qc-verdict.sh:134` and `inflight.sh` `close_send_back` and the new pins failed. Its verdict: ready to merge with fixes; its one Critical is F1.

**Findings**

- **F1 — blocking — `/codeo:implement`'s.** `.devcontainer/README.md:98` says `codeo` "stops with one line" when `~/codeo` is a git checkout and `CODEO_HOME` is unset, and criterion 4 requires no sentence about this stop to contradict the code. `codeo issue <N>` without a kind flag prints the line twice: `cmd_issue` (`.devcontainer/codeo`, `kind=${kind_flag:-$(saved_default)}`) runs `saved_default`, whose `home_dir` is inside a command substitution; its `die` ends only the subshell (the comment at `home_dir`, `:53`, says so), and `ensure_home` then dies with the same line. Root cause: callers that assign `$(home_dir)` or `$(saved_default)` do not stop on a refused home directory. It predates this change (the base code prints it twice), but this change rewrote the sentence and the criterion forbids the contradiction. `t_home_checkout_collision` (`tests/codeo-command.test.sh:1557`) matches `issue 5`'s stderr with a prefix glob, so it cannot see a second line. The fix is the implementer's and inside the plan's footprint: stop before `saved_default` (`home_dir >/dev/null` or `ensure_home` first, as `cmd_list` does), and make the test compare the whole stderr; the alternative is to correct the sentence, and the criterion accepts either.
- **F2 — non-blocking — `/codeo:plan`'s.** `.devcontainer/codeo:576-580`: after `no sandbox codeo-<N>` or `removed …, but could not … refs`, the `--force` hint still prints when `sbx ls` cannot be run or fails just after, so criterion 1's "none of the three" holds only while `sbx ls` works. The plan's Q3 (answered A, by the engineer) chose that an unknown state keeps the hint, and the README says "(or cannot list)". Recorded, not a defect of the code against the plan.
- **F3 — non-blocking — `/codeo:implement`'s.** `.devcontainer/README.md` flowchart (*Removing a finished container*) has no failure edges out of the `docker rm -f` / `volume rm` node, while the prose says a failed container or volume removal stops with an error. Plan Q5 chose "complete it", so the chart should show them or the README should say it omits them. Parked since `implement.md`.
- **F4 — non-blocking — `/codeo:implement`'s.** `.devcontainer/README.md:178`: "A container that was running is read a second time" is unqualified, and since this change a running container is read once when `docker inspect` fails without `--force` (the next paragraph says so). Qualify the sentence.
- **F5 — non-blocking — `/codeo:implement`'s.** `.sbx/README.md:78` says the `--force` hint is left out when `sbx ls` no longer lists the sandbox, and does not say it prints when `sbx ls` cannot list, which `.devcontainer/README.md` does.
- **F6 — non-blocking — `/codeo:implement`'s.** `.devcontainer/README.md:215`'s list of refusals that name no command still omits `could not list sandboxes with <sbx>` (`.sbx/codeo-sandbox.sh:59`) and `no sandbox codeo-<N>` (`:380`); the sentence does not claim to be exhaustive, but commit `b2c2d7d`'s subject says it lists every one.
- **F7 — non-blocking — neither's: pre-existing.** With `docker inspect` failing and no `--force`, the refusal is known before the check, yet a stopped container is still started, fetched and read, then left running because `rc` is 0 and `stop_started` does not run. Predates this change; recorded once, not routed.
- **F8 — non-blocking — `/codeo:implement`'s.** Minors already parked in `implement.md`'s `## Outcome`: the flowchart's `H` and edge wording (now fixed by `b2c2d7d`), the new test not asserting the first read ran, `recognised_by_qc_verdict_replan` reading `$crlf` before declaring `local crlf=`, `recognised_by_inflight_send_back` inlining its own `case`.

**Routing.** F1 is blocking and the implementer's; F3-F6 and F8 can ride the same round; F2 is a recorded design choice and F7 is not this change's. Nothing here is the plan's to redo.

**Verdict: back to `/codeo:implement`.**

### Round 2 — 2026-11-21

Whole pass re-run from step 0 on `8f359ae`, after the send-back answered by `implement.md` round 2.

**Step 2, scope.** `sync-main.sh --abort-on-conflict`: `sync-main: the branch already contains origin/main`. `overlap.sh 149` prints nothing; `overlap.sh --outside 149` prints nothing (exit 0). `scope.sh origin/main HEAD`: `suite.shell=true` (unclassified paths: the dossiers and `CHANGELOG.md`). `git diff origin/main...HEAD --stat`: 22 files, 934 insertions, 65 deletions; `scripts/` and `.sbx/codeo-sandbox.sh` unchanged. No invariants file, shared environment, `wiki` module or overlay rules (step 9 does not apply).

**Step 3, build.** The `shell` suite's `build` is `true`: exit 0.

**Step 4, suite.** `bash tests/run.sh`, whole: `all cases passed`, `suite-exit=0`, working tree clean afterwards. The reviewer worked in a separate worktree this time.

**Step 5, criteria**

| # | Criterion | Verdict | Settled by |
|---|---|---|---|
| 1 | With `--force`, none of the three F13 outputs is followed by the `sbx rm --force` hint; a test fails if it returns | met | `t_rm_sandbox_force_gone` (`tests/codeo-command.test.sh`); the reviewer made the hint unconditional in a worktree and the test failed for all three outputs and the second-column case |
| 2 | `CODEO_HOME=rel codeo rm <N> --sandbox` completes, with a test | met | `abs_path_env CODEO_HOME always` in `main`; `t_relative_codeo_home_rm`, which fails when that line is removed (reviewer's worktree run) |
| 3 | A `rm` that refuses without `--force` does not run `docker restart` first | met | `.devcontainer/codeo` `cmd_rm`/`container_check`; `t_rm_inspect_fails_no_restart` fails when `--no-restart` is never chosen (reviewer's worktree run) |
| 4 | No README or help sentence about the script's own message, the home-directory stop or the failed-listing exit contradicts the code; the flowchart matches the prose or says it is partial | not met | F9: `.devcontainer/README.md:98` says "a usage error … never read it, so they go ahead", and `codeo issue 5 --sandbox --rebuild` with a refused home now prints the stop and exits 1 instead of the usage error and exit 2 (reproduced below). The stop itself prints once for every command that reads the home directory (checked below), the failed-listing and script-message sentences match the code, and F10 and F11 are flowchart and prose gaps. |
| 5 | The two skill sentences under #144 F4 sit after "The step stops until it is answered" | met | `skills/implement/SKILL.md:89-93`, `skills/close/SKILL.md:220-225`; `must_precede` at `tests/implement-skill.test.sh:115` and `tests/close-skill.test.sh:443` |
| 6 | `qc-verdict.sh:134` is pinned; each #144 F5 item done or dismissed in writing | met | `qc_verdict_replan` fails under a prefix-match mutation of `qc-verdict.sh:134`; the `inflight_send_back` reader fails under an exact-match mutation of `close_send_back`'s heading (both reviewer worktree runs); F5a pinned at `tests/init-skill.test.sh:54`; F5b: `with or without an` in all seven places, pinned by `tests/overlap-stop.test.sh`; F5d dismissed in writing in `plan.md` and `implement.md` |
| 7 | `bash tests/run.sh` ends `all cases passed` | met | this pass's run, quoted under step 4 |

**Home-directory stop, every command** (a `HOME` holding `codeo/.git`, `CODEO_HOME` unset, `env -i`): `home`, `issue 5`, `issue 5 --sandbox`, `issue 5 --container`, `issue 5 feat/x`, `shell home`, `shell 5`, `shell 5 --container`, `open 5 --sandbox`, `list`, `rm 5 --sandbox`, `default`, `default sandbox` and `update` each print the stop exactly once and exit 1; `help` exits 0; `rm 5`, `open 5` and `rm 5 --container` do not reach the home directory. `~/codeo` holds only `.git` afterwards.

**F9 reproduction:** `env -i HOME=<home with codeo/.git> PATH=/usr/bin:/bin bash .devcontainer/codeo issue 5 --sandbox --rebuild`: at `956a86f` and at `55021e3` it prints `codeo: --rebuild applies only to a container, and the kind here is a sandbox`, exit 2; at `8f359ae` it prints `codeo: ~/codeo is a git checkout; set CODEO_HOME to the directory codeo should keep its files in`, exit 1. With an ordinary home, `8f359ae` still prints the usage error, exit 2.

**Step 6, documentation.** Pages changed since the base: `.devcontainer/README.md`, `.sbx/README.md`, the `codeo help` text, five skill pages, `docs/handoff.md` and `CHANGELOG.md`; present tense, no issue numbers. Findings F9-F11 are documentation or contract findings.

**Step 7, independent review** (Opus, criteria and diff only). It confirmed each new test fails under its mutation, found F9 as its one Critical, and F10, F11 and a restatement of round 1's F7 as Minor. Its verdict: ready to merge with fixes.

**Findings carried from round 1:** F1 (blocking in round 1) — fixed by `fc8a5ac`; F3, F4, F5 and F6 — fixed by `41e9c3d`; F2 stays a recorded design choice (the plan's Q3, answered by the engineer) and F7 (a stopped container started and left running before a refusal known up front) stays pre-existing and unrouted.

**New findings**

- **F9 — blocking — `/codeo:implement`'s.** `.devcontainer/codeo:309` — round 2's fix for F1 — runs `home_dir >/dev/null` before the check `[[ "$kind" == container || -z "$rebuild" ]] || usage …` at `:311`, so with a refused home directory the stop replaces a usage error. That breaks the file header's rule (`:8-9`: every command checks its arguments first and exits 2) and makes `.devcontainer/README.md:98`'s "a usage error … go ahead" untrue for this input, which criterion 4 forbids; the code is what changed, and the base code and the round 1 code both exit 2 here. Root cause: the home check was placed before the one usage test that needs the kind, and that test does not need the home when a kind flag was given (only the saved default needs it). The fix is the implementer's and inside the plan's footprint: when `--container` or `--sandbox` was given, run the `--rebuild` usage test before `home_dir`; when none was given the kind comes from the saved default, so that one usage error may follow the stop, and the README sentence says so. A test covers `issue 5 --sandbox --rebuild` with a refused home (exit 2, the usage message), beside the existing `t_home_checkout_collision` cases.
- **F10 — non-blocking — `/codeo:implement`'s.** `.devcontainer/README.md:182` lists what can refuse after the restart as "the second read, a failed restart or a failed `docker rm`"; `docker volume rm` can also fail there (`could not remove volume codeo-<N>`, `.devcontainer/codeo:654-657`), and the flowchart's error edge label from `G` covers it while the sentence does not. Add it to the sentence.
- **F11 — non-blocking — `/codeo:implement`'s.** The flowchart's error edge leaves only `G`; node `H` ("remove container and image, keep the volume") also runs `docker rm -f` and can stop with `could not remove container`, and the chart neither shows it nor says it is partial. Parked in `implement.md` round 2 as a Minor; add the edge from `H`.

**Routing.** F9 is blocking and the implementer's; F10 and F11 ride the same round. Nothing here is the plan's to redo.

**Verdict: back to `/codeo:implement`.**

### Round 3 — 2026-11-21

Whole pass re-run from step 0 on `1ed2617`, after the send-back answered by `implement.md` round 3.

**Step 2, scope.** `sync-main.sh --abort-on-conflict`: `sync-main: the branch already contains origin/main`. `overlap.sh 149` prints nothing; `overlap.sh --outside 149` prints nothing (exit 0). `scope.sh origin/main HEAD`: `suite.shell=true` (unclassified paths: the dossiers and `CHANGELOG.md`). `git diff origin/main...HEAD --stat`: 22 files, 1017 insertions, 66 deletions; `scripts/` and `.sbx/codeo-sandbox.sh` unchanged. No invariants file, shared environment, `wiki` module or overlay rules (step 9 does not apply, so there is no lease to release).

**Step 3, build.** The `shell` suite's `build` is `true`: exit 0.

**Step 4, suite.** `bash tests/run.sh`, whole: `all cases passed`, `suite-exit=0`, working tree clean afterwards.

**Step 5, criteria**

| # | Criterion | Verdict | Settled by |
|---|---|---|---|
| 1 | With `--force`, none of the three F13 outputs is followed by the `sbx rm --force` hint; a test fails if it returns | met | `t_rm_sandbox_force_gone`; replacing the `sbx_has` guard at `.devcontainer/codeo:591` with `true` fails it on all three outputs (reviewer's worktree run). See F16 for the host with no `sbx`. |
| 2 | `CODEO_HOME=rel codeo rm <N> --sandbox` completes, with a test | met | `abs_path_env CODEO_HOME always` in `main`; `t_relative_codeo_home_rm` fails when it is removed (reviewer's worktree run) |
| 3 | A `rm` that refuses without `--force` does not run `docker restart` first | met | `cmd_rm` and `container_check`'s `--no-restart`; `t_rm_inspect_fails_no_restart` fails when it is dropped (reviewer's worktree run) |
| 4 | No README or help sentence about the script's own message, the home-directory stop or the failed-listing exit contradicts the code; the flowchart matches the prose or says it is partial | met | The home-directory stop (F15): every command and argument combination compared with the base code under a refused home; the stop prints once and exits 1 for every command that reads the home directory, usage errors exit 2 as before (including `issue 5 --sandbox --rebuild`), `rm` of a container and `help` go ahead, nothing is written to `~/codeo`; the README sentence says exactly this. The failed-listing exit (F16): `codeo list` warns on stderr and exits 1, as the help text and both READMEs say. The script-message sentence (F12) lists which refusals name a command and which do not, and that list matches `.sbx/codeo-sandbox.sh`. The flowchart's inspect-first order, no-restart edge, `--force` branches and removal-failure edges match `cmd_rm`; F14 is a qualification it lacks and F12/F16/F17 (below) are remedy and wording gaps in the surrounding prose, all non-blocking. |
| 5 | The two skill sentences under #144 F4 sit after "The step stops until it is answered" | met | `skills/implement/SKILL.md:89-93`, `skills/close/SKILL.md:220-225`; `must_precede` at `tests/implement-skill.test.sh:115` and `tests/close-skill.test.sh:443` (F15: it pins the first of the two sentences only) |
| 6 | `qc-verdict.sh:134` is pinned; each #144 F5 item done or dismissed in writing | met | `qc_verdict_replan` fails under an exact-match and a prefix-match mutation of `qc-verdict.sh:134`; `inflight_send_back` fails under both mutations of `close_send_back`'s heading (reviewer's worktree runs); F5a pinned at `tests/init-skill.test.sh:54`; F5b: `with or without an` in all seven places, pinned by `tests/overlap-stop.test.sh`; F5d dismissed in writing in `plan.md` and `implement.md` |
| 7 | `bash tests/run.sh` ends `all cases passed` | met | this pass's run, quoted under step 4 |

**Home-directory stop and usage errors, base against head** (a `HOME` holding `codeo/.git`, `CODEO_HOME` unset, `env -i`, run here for sixteen argument forms; the reviewer ran about forty-five): every usage error (`issue abc`, `issue 5 a b`, `issue 5 --bogus`, `issue 5 --container --sandbox`, `issue 5 --sandbox --rebuild`, `home --bogus`, `shell`, `rm 5 --bogus`, `rm --force`, `default bogus`, `list x`, `update x`, `open abc`) exits 2 at the base and at head with no stop line; `issue 5` and `issue 5 --rebuild` print the stop twice at the base and once at head; `issue 5 --container --rebuild` prints it once at both.

**Step 6, documentation.** Pages changed since the base: `.devcontainer/README.md`, `.sbx/README.md`, the `codeo help` text, five skill pages, `docs/handoff.md` and `CHANGELOG.md`; present tense, no issue numbers. The plan names no page the diff left untouched.

**Step 7, independent review** (Opus, criteria and diff only). No Critical or Important findings; it mutation-checked each new test in a separate worktree and found each fails when its fix is reverted. Its verdict: ready to merge with fixes, the fixes being README wording (its Minor 1 and 3). It reported eight Minors; they are F12-F18 below and a restatement of F7.

**Findings carried from earlier rounds:** F1 (blocking in round 1) — fixed by `fc8a5ac`; F9 (blocking in round 2) — fixed by `8d2b49e`; F3-F6, F10 and F11 — fixed by `41e9c3d`, `7dd063a` and `5d1fd04`. F2 stays a recorded design choice (the plan's Q3, answered by the engineer). F7 (a stopped container that `codeo` started is left running after a refusal known up front, `.devcontainer/codeo:596-598` and `:629-632`) stays pre-existing and unrouted; the reviewer restated it.

**New findings**, all non-blocking: the change merges as it stands, and each is README wording, a test pin or a recorded limit.

- **F12 — non-blocking — `/codeo:implement`'s.** `.devcontainer/README.md`'s sandbox paragraph says the refusals for `no sandbox codeo-<N>` and a missing clone "name no command: the remedy is to fix what failed and run it again". For `no sandbox` nothing is left to remove or fix; for a missing clone (`.sbx/codeo-sandbox.sh:381`, which dies before `--force` is read) running it again fails the same way, and the only way out is `sbx rm --force codeo-<N>`. Say so for those two refusals.
- **F13 — non-blocking — `/codeo:plan`'s.** The one refusal `--force` passes (the no-branches refusal, `.sbx/codeo-sandbox.sh:390`) names `end <N> --force`, a command a `codeo` user cannot type as it stands, and `codeo rm <N>` adds no `codeo rm <N> --force` line after any `codeo-sandbox:` line. The README describes this accurately; the plan's Q4 (answered A) kept the script's messages, so this is a limit of that choice.
- **F14 — non-blocking — `/codeo:implement`'s.** The flowchart edge `G -- "docker rm -f or volume rm failed" --> Y` is unconditional: the code errors on a failed `docker volume rm` only when `docker volume inspect` shows the volume still exists, and with `--force` a container already gone is no error either (`codeo rm 5 --container --force` with only the image left prints `removed image codeo-dev:codeo-5` and exits 0). Qualify the label or say the chart is partial.
- **F15 — non-blocking — `/codeo:implement`'s.** `must_precede` in `tests/close-skill.test.sh:443` and `tests/implement-skill.test.sh:115` pins only `A non-zero exit, with or without an` after "The step stops until it is answered"; the second F4 sentence (the `overlap: skipping …` warning) could move back before it and both tests would pass. The criterion holds in the text; only the pin is incomplete.
- **F16 — non-blocking — `/codeo:implement`'s.** Both READMEs say the `--force` hint prints when `sbx ls` "cannot list"; it also prints when no `sbx` program is installed (`! sbx=$(sbx_prog)`), after the script's `sbx is not installed` line.
- **F17 — non-blocking — `/codeo:implement`'s.** The README's list of what never reads the home directory names `rm` of a container; `open` of a container also goes ahead and fails with "is a container". With no kind flag, `open` and `rm` also run `docker ps`/`sbx ls` before the stop, which writes nothing.
- **F18 — non-blocking — `/codeo:implement`'s.** The `CHANGELOG.md` entry says `codeo rm` makes a relative `CODEO_HOME` absolute; `main` does it for every command.

**Routing.** No blocking finding: every criterion is met on this pass's own output. F2, F7 and F12-F18 are non-blocking and are recorded for `/codeo:triage` to collect from the archived dossier. Nothing here sends the change back.

**Verdict: clear — forward to `/codeo:close`.**

## Log

- 2026-11-21 — Q1-Q2 raised (overlaps with #138 on CHANGELOG.md and docs/handoff.md) · cost: 1m · opus-5-5 314k in + 693k cached / 1k out
- 2026-11-21 — round 1: Q1-Q2 answered, pass run, back to implement (F1 blocking) · cost: 40m · opus-5-5 415k in + 3.5M cached / 25k out · sonnet-5-5 40k in + 4.8M cached / 10k out
- 2026-11-21 — round 2: pass re-run, back to implement (F9 blocking, regression from round 2's F1 fix) · cost: 9m · opus-5-5 509k in + 3.8M cached / 22k out · sonnet-5-5 28k in + 1.7M cached / 6k out
- 2026-11-21 — round 3: pass re-run, clear verdict, forward to close (F12-F18 non-blocking) · cost: 10m · opus-5-5 585k in + 4.2M cached / 28k out · sonnet-5-5 24k in + 1.4M cached / 6k out
