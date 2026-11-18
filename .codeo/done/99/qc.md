# Issue #99 — qc

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/99 |
| Branch | `feat/make-sbx-issue-sandbox-usable` |
| Plan | `docs/plans/2026-11-17-sbx-issue-sandbox.md` |
| Updated | 2026-11-18 |

## Where this stands

Round 3 is written below: clear, forward to `/codeo:close`. All 28 criteria are met; F17-F24 are non-blocking.

## Questions

### Q1 — #118 also lists `CHANGELOG.md`: proceed and coordinate, sequence after #118, or re-scope?

`overlap.sh 99` printed `118	CHANGELOG.md` and `118	glob:CHANGELOG.md`. #118 (branch `feat/live-signal-leftovers-104-refresh`, assignee kbajpai, step `init (working)`) lists `CHANGELOG.md` in its footprint and has changed no file yet (`changed: none`). This branch adds one bullet and amends another in the same file.

**Why it matters:** QC cannot go past step 2 until this is settled. *Proceed* lets the pass go on now. *Sequence after #118* means #99 waits for #118 to merge before it goes to a pull request. *Re-scope* means this branch drops its `CHANGELOG.md` bullets.

**Options:**
- *Proceed and coordinate* (recommended): both changes add bullets to the changelog's unreleased list. Whichever merges second gets a small conflict and resolves it by keeping both bullets.
- *Sequence after #118*: #99 waits for #118, which has not started work yet.
- *Re-scope*: this branch drops its changelog bullets. Two acceptance criteria ask for `CHANGELOG.md` to describe the change, so this is not a real option.

**Answer:**
Proceed and coordinate: whichever of #99 and #118 merges second keeps both changelog bullets (engineer, in the conversation, 2026-11-18).

## Notes

None.

## Outcome

### Round 1 — 2026-11-17

Under review: `implement.md`'s round 1, at `5e5fabd`. Base `origin/main` (merge base `0dc7fa5`).

#### Commands and output

- `sync-main.sh --abort-on-conflict` → `sync-main: the branch already contains origin/main` (exit 0).
- `overlap.sh 99` → nothing printed (exit 0). `overlap.sh --outside 99` → nothing printed (exit 0).
- `scope.sh origin/main HEAD` →
  ```
  scope: suite shell needed for unclassified paths:
    .codeo/99/implement.md
    .codeo/99/init.md
    .codeo/99/plan.md
    .codeo/config.json
    CHANGELOG.md
  suite.shell=true
  ```
- Build (`shell`: `true`) → exit 0.
- Test (`shell`: `bash tests/run.sh`) → `all cases passed`, exit 0; no FAIL line in the log.
- Overlays `qc invariants-extra` and `qc wiki-rules` → exit 3 (none). No invariants file, no environment, no wiki module.
- `git show --stat` of the #94 part's commits (`f45a6da`, `279f193`) `-- .devcontainer skills` → 0 lines each. `git diff origin/main...HEAD -- skills` → 0 lines.
- `gh api repos/kbajpai/codeo` → `{"del":false,"merge":true,"rebase":true,"squash":true}`; `git log origin/main -6 --merges` → none (pull requests land squashed).
- Independent review (`QC review:`, opus) on `0dc7fa5..5e5fabd`, given the criteria only: "With fixes", 1 critical, 3 important, 9 minor. It also ran `bash tests/sandbox.test.sh` (all cases passed) and `shellcheck .sbx/codeo-sandbox.sh` (clean).

#### Criteria

| Part | Criterion | Verdict | Settled by |
|---|---|---|---|
| #94 | Image lines quoted, digest change stated, #86 agrees | met | `docs/dev-environment-sbx-evaluation.md:204,321,371,461` quote each create's kit/image line and say the digest changed between T8 and T10; the recorded output survives only shortened, and the page says so |
| #94 | T13 settles the `gh` token; D1, Recommendation, Credentials cite it | met | evaluation page `:424` (T13), `:448`, `:462` (Credentials), D1 row `:76`; matches `implement.md` S2/S4 |
| #94 | Naming sentence no longer repeats or contradicts itself | met | U1 row `:93`; Task 3 review |
| #94 | U6, U8 → #85; U14 → #86; one trial range | met | follow-up section `:477-478` |
| #94 | "1m47s", U4 file mode, "was not tried", Trials intro | met | `grep -o 'was not tried' | wc -l` → 14; D3 row `:78`, U4 row `:96`, Trials intro `:114` gives no instruction |
| #94 | `tests/run.sh` passes; no `.devcontainer`/`skills` diff | met | suite run above; 0-line stats for `f45a6da`, `279f193` |
| #85 | One documented command creates and starts the sandbox, ends with the lock line | not met | F1: the documented download leaves `issue` without its pin file, so it exits 1 before `create` |
| #85 | `user.name`/`user.email` print values; rerun changes neither | not yet checkable — Task 14 step 3 | `issue_runs_the_start_script_with_the_identity`, `issue_rerun_on_an_existing_sandbox_creates_nothing` cover the script's side |
| #85 | `claude plugin list` shows both plugins at the pin | not yet checkable — Task 14 step 4 | start script unchanged (S5 showed it installs both) |
| #85 | Name disagreeing with the lock gets one `todo:` | met | `issue_name_that_disagrees_with_the_lock_is_one_todo` |
| #85 | No `dubious ownership` on first create, or the fix printed | met | `issue_adds_the_windows_trust_line_once`, `issue_without_git_exe_prints_the_trust_command` |
| #85 | `git push` from inside succeeds with no login | not yet checkable — Task 14 step 5 | S4 showed it in the trials |
| #85 | `tests/run.sh` passes; dev container starts as before | met | suite run above; `tests/devcontainer.test.sh` is part of it |
| #86 | One step opens VS Code on the clone with the three extensions | not yet checkable — Task 14 step 6 | `open_writes_the_title_and_opens_the_clone_folder`; README's `remote.SSH.defaultExtensions` line |
| #86 | Two sandboxes show different titles | not yet checkable — Task 14 step 7 | `open_writes_the_title_…` |
| #86 | A session in a sandbox is titled with its issue | not yet checkable — Task 14 step 6 | `issue_writes_the_sandbox_marker`, `session-title.sh` |
| #86 | Unpushed commit is not removed silently; nothing to lose removes it | not met | the first half holds (`end_with_an_unpushed_commit_removes_nothing`); the second fails in the normal case, F2 |
| #86 | Same digest across days until the pin changes | not yet checkable — Task 14 step 10 | `issue_creates_at_the_pinned_image`, `the_pin_file_is_a_digest` |
| #86 | Cause of the stops stated, or shown not to occur in N repeats | not yet checkable — Task 14 step 9 | `.sbx/README.md` "Stopped sandboxes" says the cause is not known |
| #86 | `tests/run.sh` passes; dev container starts as before | met | suite run above |
| #114 | New home container: no trust dialog | not yet checkable — Task 14 step 12 | `start_trusts_the_clone_in_claude` |
| #114 | Same in an issue container and after rebuild | not yet checkable — Task 14 step 12 | `start_trusts_the_clone_once` |
| #114 | `.claude/settings.json` in effect in the first session | not yet checkable — Task 14 step 12 | — |
| #114 | Only the clone folder is trusted | met | `start_trust_uses_the_resolved_top_level` |
| #114 | Other keys kept | met | `start_trust_keeps_other_keys` |
| #114 | Malformed state file left alone, TODO, exit 0 | met | `start_trust_with_projects_not_an_object_is_a_todo` and the malformed-file case in `tests/devcontainer.test.sh` |
| #114 | `tests/devcontainer.test.sh` covers the step | met | the seven `start_trust_*` cases |
| #114 | `.devcontainer/README.md` and `CHANGELOG.md` describe it | met | `docs_readme_describes_folder_trust`, `docs_changelog_names_folder_trust` |

#### Documentation

`.sbx/README.md`, `.devcontainer/README.md`, `.codeo/overlays/init.md`, `CHANGELOG.md` and the evaluation page are all touched as the plan names. Findings: the README's download line is untrue as a way to run `issue` (F1); the evaluation page says the host script "does not exist yet" (`:455`), untrue once this merges (F5).

#### Findings

- **F1 — blocking — `/codeo:plan`'s.** Following `.sbx/README.md:23-29`, `issue` always exits 1. The README downloads only `codeo-sandbox.sh`, and `read_pin` (`.sbx/codeo-sandbox.sh:73-75`) reads `claude-image` beside the script. A pin downloaded once would also never follow a later pin move. Cause: the plan's Task 10 step 3 says "Read the file next to the script" and Task 13 gives one download line. The code does what the plan says, so the plan has to say where the pin comes from. The clone's `codeo-<N>/.sbx/claude-image` after `ensure_host_clone` is one candidate.
- **F2 — blocking — `/codeo:plan`'s.** `end` refuses after every normal close. This repo squash-merges, as `origin/main` has no merge commits, so the branch's own commits are on no origin ref once `/codeo:close` deletes the remote branch. `unpushed_commits` (`rev-list --glob=refs/sandboxes/codeo-N/* --not --remotes=origin`) then lists them, and `end` refuses. That is the step the README says replaces close's `docker rm` line. Passing `--force` in the common case defeats Q5's protection. Cause: Q5 and Task 12 define "pushed" as reachable from `origin` and never consider a squash merge. One route is to treat commits on a branch whose pull request merged as delivered, for example by comparing trees, or by asking `gh` whether the branch's PR is merged. That is a design choice for the plan.
- **F3 — blocking — `/codeo:plan`'s.** Running `issue` again starts from a stale clone. For an existing `./codeo-<N>`, `ensure_host_clone` (`.sbx/codeo-sandbox.sh:89-101`) checks the branch name only and never updates it. `create --clone .` then starts the new sandbox at the clone's old tip. That happens when resuming a stashed workflow or recreating after `end`. The sandbox misses what was pushed, and its next push is rejected. Cause: the plan's error-path list (plan `:70`) specifies only the other-branch and not-a-clone refusals for an existing clone.
- **F4 — non-blocking — `/codeo:plan`'s.** Refs kept by `end --force` keep refusing. `rm` keeps `refs/sandboxes/codeo-<N>/*` (D-rm, S9), so a later sandbox for the same `<N>` inherits the old commits, and its `end` lists them. This compounds F2, and the same re-plan should settle it.
- **F5 — non-blocking — `/codeo:implement`'s (plan Task 6 page).** The evaluation page says the host script "does not exist yet" (`docs/dev-environment-sbx-evaluation.md:455`).
- **F6 — non-blocking — `/codeo:implement`'s.** `.sbx/README.md:11` says the proxy replaces the token. T13 shows a placeholder and a working push. It does not show the mechanism.
- **F7 — non-blocking — `/codeo:implement`'s.** Minors deferred by the task reviews and confirmed by this review: the `ssh` check has no `BatchMode`/`ConnectTimeout` (a prompt would hang); the folder URI is not percent-encoded; `.codeo/overlays/init.md:34` says "Either way" over three routes; the README omits `CODEO_CODE`; README:137 should quote the exact `%(prefix)///wsl.localhost/…` `safe.directory` entry; an empty `.claude.json` gets a "could not write" TODO.
- **F8 — non-blocking — `/codeo:implement`'s.** Test gaps from the review. The identity test never takes the host `~/.gitconfig` source, and the pin docs test greps its two strings independently. The review also reported that with no lock the name todo reads "run issue home <branch>". Not re-verified here.
- **Task 14 — not a finding.** The host acceptance run still owes evidence for the 13 criteria marked `not yet checkable` above, including the stopped-sandbox cause, which the review raised as I3. Run it on the re-planned branch, once F1-F3 are fixed.

The review set aside, with reasons: sbx argument passing over WSL interop, the sbx banner on stdout, the VS Code `remote.SSH.*` behaviour (all host-only), `role.sh` in a sandbox (already recorded in `implement.md`'s Outcome), concurrent `.claude.json` writers (not in the spec), and `end` not seeing uncommitted work (documented). The #94 `.devcontainer` criterion was judged on that part's own commits, as the plan's Global Constraints say.

No issue was filed this pass.

The code does what the plan says for F1-F3. In each case the plan's design is what fails the criteria or a reasonable user, so the route is the plan.

**Verdict: back to `/codeo:plan`.**

### Round 2 — 2026-11-18

Under review: `implement.md`'s round 2 (Tasks 15-21) and Task 22's host acceptance run, at `419ccdf`. Base `origin/main` (merge base `0dc7fa5`).

#### Commands and output

- `sync-main.sh --abort-on-conflict` → `sync-main: the branch already contains origin/main` (exit 0).
- `overlap.sh 99` → `118	CHANGELOG.md` and `118	glob:CHANGELOG.md` (exit 0). Raised as Q1 and answered *proceed and coordinate*. A rerun printed nothing. `overlap.sh --outside 99` → nothing printed (exit 0).
- `scope.sh origin/main HEAD` →
  ```
  scope: suite shell needed for unclassified paths:
    .codeo/99/implement.md
    .codeo/99/init.md
    .codeo/99/plan.md
    .codeo/99/qc.md
    .codeo/config.json
    CHANGELOG.md
  suite.shell=true
  ```
- Build (`shell`: `true`) → exit 0.
- Test (`shell`: `bash tests/run.sh`) → `all cases passed`, exit 0; `grep -c FAIL` on the log → 0.
- Overlays `qc invariants-extra` and `qc wiki-rules` → exit 3 (none). There is no invariants file, no environment and no wiki module.
- `git show --stat` of `f45a6da` and `279f193` `-- .devcontainer skills` → 0 lines each. `git diff origin/main...HEAD -- skills` → 0 lines. `git log origin/main -6 --merges` → none.
- Independent review (`QC review:`, opus) on `0dc7fa5..419ccdf`, given the criteria only: "No", with 1 critical, 2 important and 7 minor findings. It also ran `bash tests/sandbox.test.sh` and `bash tests/devcontainer.test.sh` (all cases passed) and `shellcheck` (clean on the scripts; one SC2016 info at `tests/sandbox.test.sh:430`).
- Host evidence: Task 22, steps 1-12, under `implement.md` `## Acceptance` (2026-11-18, the engineer's output and screenshots, quoted there).

#### Criteria

| Part | Criterion | Verdict | Settled by |
|---|---|---|---|
| #94 | Image lines quoted, digest change stated, #86 agrees | met | round 1's evidence; the page's digest text is unchanged since (`docs/dev-environment-sbx-evaluation.md:461`) |
| #94 | T13 settles the `gh` token; D1, Recommendation, Credentials cite it | met | T13 at `:424`; D1 row `:76`. F15 asks for narrower wording |
| #94 | Naming sentence no longer repeats or contradicts itself | met | U1 row, unchanged since round 1 |
| #94 | U6, U8 → #85; U14 → #86; one trial range | met | `:477-478`. The #86 bullet gives "from trials T8 to T12" as its one range. F14 is the reviewer's objection that the range does not match the trials used |
| #94 | "1m47s", U4 file mode, "was not tried", Trials intro | met | `grep -o 'was not tried' \| wc -l` → 14 |
| #94 | `tests/run.sh` passes; no `.devcontainer`/`skills` diff | met | suite above; 0-line stats for `f45a6da` and `279f193` |
| #85 | One documented command creates and starts the sandbox, ends with the lock line | not met as written | Acceptance step 2: `issue 99 …` created and started the sandbox and printed `lock: took the lock for #99 on feat/make-sbx-issue-sandbox-usable`, but two identity lines and a `scripts/lock.sh` volume TODO follow it (F11) |
| #85 | `user.name`/`user.email` print values; rerun changes neither | met | Acceptance step 3 (values before and after a rerun); `issue_takes_the_identity_from_the_host_gitconfig` |
| #85 | `claude plugin list` shows both plugins at the pin | met | Acceptance step 4: `codeo@codeo` and `superpowers@superpowers-marketplace`, codeo at `v1.0.6` = `.codeo/config.json` `plugin.ref` |
| #85 | Name disagreeing with the lock gets one `todo:` | met | `issue_name_that_disagrees_with_the_lock_is_one_todo`; Acceptance step 7's no-lock `todo:` |
| #85 | No `dubious ownership` on first create, or the fix printed | met | Acceptance step 2 ("No `dubious ownership`"); `issue_adds_the_windows_trust_line_once` |
| #85 | `git push` from inside succeeds with no login | met | Acceptance step 5: `* [new branch] HEAD -> scratch/sbx-99-push`, no prompt |
| #85 | `tests/run.sh` passes; dev container starts as before | met | suite above; Acceptance step 12 built and opened the dev container |
| #86 | One step opens VS Code on the clone with the three extensions | not met | Acceptance step 6: folder and window title are met, but `remote.SSH.defaultExtensions` failed with `Server returned 403` ×3 and stopped the remote extension host (F9) |
| #86 | Two sandboxes show different titles | met | Acceptance step 7: `codeo [#99]` next to `codeo [home]` |
| #86 | A session in a sandbox is titled with its issue | met | Acceptance step 6: terminal title `✳ codeo [#99] · b7178c8d - codeo-99` |
| #86 | Unpushed commit is not removed silently; nothing to lose removes it | met | Acceptance steps 8 and 8a; `end_with_an_unpushed_commit_removes_nothing`, `end_after_a_squash_merge_removes_the_sandbox`. F12 covers uncommitted work, which this criterion does not name |
| #86 | Same digest across days until the pin changes | met | Acceptance steps 2 and 10: `fd56087a…3593332` both times (the kit image was cached; the pin is honoured); `issue_creates_at_the_pinned_image` |
| #86 | Cause of the stops stated, or shown not to occur in N repeats | met | `.sbx/README.md:97` states the cause (idle after `create`/`exec`); Acceptance step 9, 10 of 10 repeats. The behaviour it exposes is F10. The evaluation page still says the cause is unknown (F16) |
| #86 | `tests/run.sh` passes; dev container starts as before | met | suite above; Acceptance step 12 |
| #114 | New home container: no trust dialog | met | Acceptance step 12, folder `codeo-home`, no dialog (the engineer). The clone held the #99 lock; step 3d does not read the role (`devcontainer-start.sh:299-325`) |
| #114 | Same in an issue container and after rebuild | met | Acceptance step 12: that container held the #99 lock, and there was no dialog after **Rebuild Container**. Step 13 (a `codeo-<N>` folder) was not run; the folder name does not enter step 3d, which keys on the resolved top level |
| #114 | `.claude/settings.json` in effect in the first session | met | Acceptance step 12: session title `codeo [#99] · 9bbb522c` from the project hook, codeo enabled; same after the rebuild |
| #114 | Only the clone folder is trusted | met | `start_trust_uses_the_resolved_top_level` |
| #114 | Other keys kept | met | `start_trust_keeps_other_keys` |
| #114 | Malformed state file left alone, TODO, exit 0 | met | `start_trust_with_projects_not_an_object_is_a_todo`, the malformed-file case, and `start_trust_fills_an_empty_state_file` (F7's empty file) |
| #114 | `tests/devcontainer.test.sh` covers the step | met | the `start_trust_*` cases |
| #114 | `.devcontainer/README.md` and `CHANGELOG.md` describe it | met | `docs_readme_describes_folder_trust`, `docs_changelog_names_folder_trust` |

#### Round 1's findings

- F1 (blocking in round 1) — fixed by `b0464c9` (pin from `CODEO_SBX_IMAGE`, the clone, or `origin/HEAD`). Acceptance step 7 showed the one-line refusal with no pin and the override.
- F2 (blocking in round 1) — fixed by `c3ec483` (PR heads count as delivered). Acceptance step 8a: a plain `end` removed the sandbox.
- F3 (blocking in round 1) — fixed by `034a6fc` (fast-forward before create). Acceptance steps 7 and 8a.
- F4, fixed by `cb71ff2`; Acceptance step 11 named `refs/codeo/ended/codeo-<N>/<UTC>/` three times.
- F5-F8, addressed in Tasks 19-21; the review did not raise them again.

#### Documentation

The plan names `.sbx/README.md`, `.devcontainer/README.md`, `.codeo/overlays/init.md`, `CHANGELOG.md` and the evaluation page, and the diff touches all of them. Two problems:
- `.sbx/README.md:13-17` and `CHANGELOG.md:9` give `remote.SSH.defaultExtensions` as the way to get the extensions, which the host run showed is untrue (F9). The test `docs_readme_gives_the_default_extensions_setting` (`tests/sandbox.test.sh:835`) asserts the line stays.
- The evaluation page's D4 row (`:79`) and Fragility bullet (`:461`) still say the cause of the stops is unknown. `.sbx/README.md:97` now states it (F16).

#### Findings

- **F9 — blocking — `/codeo:plan`'s.** The documented extension route does not work under sbx's default network policy.
  - Following `.sbx/README.md:13-17` breaks the VS Code window: the VS Code server inside the sandbox installs `remote.SSH.defaultExtensions` itself. The `balanced` policy answers `*.gallery.vsassets.io` and `*.gallerycdn.vsassets.io` with 403 (Acceptance step 6), and the failed install stops the remote extension host.
  - `remote.downloadExtensionsLocally` does not cover that list. With it set, installing each extension by hand ("Install in SSH") worked.
  - Cause: the plan chose `remote.SSH.defaultExtensions` and never checked it against the policy. The code and docs follow the plan.
  - The re-plan has to choose a route shown to work: a one-time manual install with `remote.downloadExtensionsLocally`, or an `sbx` policy allow for the two hosts. It also has to correct `CHANGELOG.md:9` and the README test.
- **F10 — blocking — `/codeo:plan`'s.** `issue` leaves a sandbox that stops by itself.
  - A sandbox that only `create`/`exec` started stops about a minute after it goes idle, and an open VS Code window loses its host (`.sbx/README.md:97`; Acceptance steps 2a-6 and 9). One started with `sbx run -d` stays `running (detached)`: 10 of 10 repeats.
  - `issue` (`.sbx/codeo-sandbox.sh:142-150`) and `open` (`:236-250`) never run it, so the "one documented step" route leaves a window that drops.
  - Cause: the plan treated the stops as unexplained and gave `issue` no step that keeps the sandbox up.
  - The re-plan should decide where `run -d` goes (`issue`, `open`, or both) and how it combines with an existing sandbox (D3 records that `-d` combines with reattaching by name).
- **F11 — non-blocking — `/codeo:plan`'s.** The lock line is not the last line.
  - `issue` prints `lock: took the lock for #<N> on <branch>`, then the start script's two identity lines, then `scripts/lock.sh:145`'s TODO about a missing `volume:` (a sandbox's workspace is a bind mount, not a volume).
  - The criterion says "ends with". The README (`.sbx/README.md:35`) describes the real order.
  - The re-plan should settle whether the order or the criterion's reading changes. The `lock.sh` TODO is in `scripts/`, outside this issue, and a re-plan that keeps it may file it with `/codeo:issue`.
- **F12 — non-blocking — `/codeo:plan`'s.** A plain `end` removes the sandbox with uncommitted changes, stashes or a detached HEAD inside, and says only `removed codeo-<N>` (`.sbx/codeo-sandbox.sh:305-354`). The README and CHANGELOG document the limit, and round 1 set it aside as documented. The review raises it as Important against the issue's "no lost work" goal. The criterion names only unpushed commits, so this does not block. It is a cheap check (`git status --porcelain`, `git stash list` through `exec`) for the re-plan to take or decline.
- **F13 — non-blocking — `/codeo:implement`'s.** Script edge cases from the review:
  - `sandbox_state` (`.sbx/codeo-sandbox.sh:57-66`) is called inside `$(…)` in `[[ … ]]`, so its `die` exits only the subshell. An `sbx ls` failure then reads as "not missing" and leads to a second, misleading message.
  - `ensure_windows_trust` (`:128`) builds `%(prefix)///wsl.localhost//…` when `WSL_DISTRO_NAME` is unset, and adds it without a message.
  - On a name/lock mismatch, the start script's `folder-check.sh` TODO ("'docker ps' names it wrongly … `.devcontainer/README.md`") gives dev-container advice in a sandbox, next to `check_name`'s `todo:`.
  - `:41` has a stale comment ("read by the sub-commands to come").
  - `tests/sandbox.test.sh:430` gets SC2016 with no directive.
- **F14 — non-blocking — `/codeo:implement`'s.** The #86 follow-up bullet (`docs/dev-environment-sbx-evaluation.md:478`) cites "T9, T10" and "from trials T8 to T12". That range takes in T11, which #86 does not use, and leaves out T3 and T5, which the D3 cited in the same bullet rests on. Judged met above, because the bullet does give one range.
- **F15 — non-blocking — `/codeo:implement`'s.** T13's Result and D1 say the real `gh` token "stays outside the VM". T13 shows only a placeholder in `gh auth token` and `GH_TOKEN` inside, and the page says the swap was not shown.
- **F16 — non-blocking — `/codeo:implement`'s.** The evaluation page's D4 row (`:79`) and Fragility bullet (`:461`) still say the cause of the stops is unknown or not shown, while `.sbx/README.md:97` states it.

The review set these aside, with reasons:
- The consolidated branch's `.devcontainer` diff: judged on the #94 part's own commits, as in round 1.
- `/codeo:close` and `/codeo:cleanup` still print the `docker rm` line: `skills/` is excluded.
- Host-only sbx behaviours: the acceptance run's records are taken as given.
- `cmd.exe` `%name%` expansion in the folder URI: far-fetched for clone paths.
- Stale refs from a sandbox removed by hand: they make `end` stricter.
- Hedged inference in the "Image:" and "1m47s" sentences.

No issue was filed this pass.

F9 and F10 come from the plan's design: the extension setting it chose, and an `issue` with no step that keeps the sandbox up. The code does what the plan says in both cases, so the route is the plan. F11 and F12 go with it, and F13-F16 are implementation fixes for the round that follows.

**Verdict: back to `/codeo:plan`.**

### Round 3 — 2026-11-18

Under review: `implement.md`'s round 3 (Tasks 23-30), at `d962806`. Base `origin/main` (merge base `0dc7fa5`).

#### Commands and output

- `sync-main.sh --abort-on-conflict` → `sync-main: the branch already contains origin/main` (exit 0).
- `overlap.sh 99` → nothing printed (exit 0). `overlap.sh --outside 99` → nothing printed (exit 0).
- `scope.sh origin/main HEAD` →
  ```
  scope: suite shell needed for unclassified paths:
    .codeo/99/implement.md
    .codeo/99/init.md
    .codeo/99/plan.md
    .codeo/99/qc.md
    .codeo/config.json
    CHANGELOG.md
  suite.shell=true
  ```
- Build (`shell`: `true`) → exit 0.
- Test (`shell`: `bash tests/run.sh`) → `all cases passed`, exit 0; `grep -c FAIL` on the log → 0.
- Overlays `qc invariants-extra` and `qc wiki-rules` → exit 3 (none). There is no invariants file, no environment and no wiki module.
- `git show --stat` of `f45a6da` and `279f193` `-- .devcontainer skills` → 0 lines each. `git diff origin/main...HEAD -- skills` → 0 lines.
- Evaluation page:
  - `grep -o 'was not tried' | wc -l` → 14;
  - `grep -c 'stays outside the VM\|never holds the real token'` → 0;
  - `grep -c 'cause unknown\|cause is not shown'` → 0;
  - the #86 bullet (`:478`) cites "from trials T3 to T12".
- Independent review (`QC review:`, opus) on `0dc7fa5..d962806`, given the criteria only: "With fixes", with 0 critical, 0 important and 9 minor.
- Host evidence: Task 23 and Task 30 under `implement.md` `## Acceptance` (2026-11-18), together with round 2's Task 22 steps 1-12 for the criteria this round's code does not move.

#### Criteria

| Part | Criterion | Verdict | Settled by |
|---|---|---|---|
| #94 | Image lines quoted, digest change stated, #86 agrees | met | evaluation page T3/T8/T10 and Fragility quote the shortened digests and say the digest changed; review minor F21 notes the "kit/image line" wording |
| #94 | T13 settles the `gh` token; D1, Recommendation, Credentials cite it | met | T13 (`:424`), D1, Credentials; the wording is now limited to what T13 showed (`grep` → 0) |
| #94 | Naming sentence no longer repeats or contradicts itself | met | U1 row, unchanged since round 1 |
| #94 | U6, U8 → #85; U14 → #86; one trial range | met | `:477-478`; #86 cites "from trials T3 to T12" |
| #94 | "1m47s", U4 file mode, "was not tried", Trials intro | met | `grep … \| wc -l` → 14; review minor F22 notes a second doubled "was not tried" at T12 (`:421`) |
| #94 | `tests/run.sh` passes; no `.devcontainer`/`skills` diff | met | suite above; 0-line stats for the #94 commits `f45a6da` and `279f193` (judged on the part's own commits, as the plan's Global Constraints say; review minor F23) |
| #85 | One documented command creates and starts the sandbox, ends with the lock line | met | Task 30 step 2 and Acceptance step 2: `issue` printed `lock: took the lock for #99 on …`, read as the engineer settled in plan.md Q16 (printed and taken; the start script's output order is unchanged) |
| #85 | `user.name`/`user.email` print values; rerun changes neither | met | Acceptance step 3; `issue_takes_the_identity_from_the_host_gitconfig` |
| #85 | `claude plugin list` shows both plugins at the pin | met | Acceptance step 4; Task 30 step 2 printed `plugins: superpowers, codeo v1.0.6` |
| #85 | Name disagreeing with the lock gets one `todo:` | met | `issue_name_that_disagrees_with_the_lock_is_one_todo`; Task 28 keeps dev-container folder advice out of a sandbox |
| #85 | No `dubious ownership` on first create, or the fix printed | met | Acceptance step 2, Task 30 step 2; `issue_without_wsl_distro_name_prints_the_trust_todo` |
| #85 | `git push` from inside succeeds with no login | met | Acceptance step 5 |
| #85 | `tests/run.sh` passes; dev container starts as before | met | suite above; Acceptance step 12 |
| #86 | One step opens VS Code on the clone with the three extensions | met | Task 30 step 3: `open 99` gave `codeo [#99]` on `SSH: codeo-99.sbx` with Claude Code, Markdown Preview Mermaid and ShellCheck installed by themselves, after the one-time policy rule in `.sbx/README.md:13-23` |
| #86 | Two sandboxes show different titles | met | Acceptance step 7 |
| #86 | A session in a sandbox is titled with its issue | met | Acceptance step 6 |
| #86 | Unpushed commit is not removed silently; nothing to lose removes it | met | Acceptance steps 8 and 8a; Task 30 steps 5 and 6 (uncommitted work is refused too); the `end_*` cases |
| #86 | Same digest across days until the pin changes | met | Acceptance steps 2 and 10, and Task 30 step 2: `fd56087a…3593332` each time |
| #86 | Cause of the stops stated, or shown not to occur in N repeats | met | `.sbx/README.md` Stopped sandboxes; Acceptance step 9 (10 of 10); Task 30 step 2 (`running (detached)` at 11m) |
| #86 | `tests/run.sh` passes; dev container starts as before | met | suite above; Acceptance step 12 |
| #114 | New home container: no trust dialog | met | Acceptance step 12 |
| #114 | Same in an issue container and after rebuild | met | Acceptance step 12 (the #99 lock, and after **Rebuild Container**) |
| #114 | `.claude/settings.json` in effect in the first session | met | Acceptance step 12 |
| #114 | Only the clone folder is trusted | met | `start_trust_uses_the_resolved_top_level` |
| #114 | Other keys kept | met | `start_trust_keeps_other_keys` |
| #114 | Malformed state file left alone, TODO, exit 0 | met | `start_trust_with_projects_not_an_object_is_a_todo`, the malformed-file case, `start_trust_fills_an_empty_state_file` |
| #114 | `tests/devcontainer.test.sh` covers the step | met | the `start_trust_*` cases |
| #114 | `.devcontainer/README.md` and `CHANGELOG.md` describe it | met | `docs_readme_describes_folder_trust`, `docs_changelog_names_folder_trust` |

#### Round 2's findings

- F9 (blocking in round 2) — fixed by `0fc5ca9`: route A (the policy rule plus `remote.SSH.defaultExtensions`), shown by Tasks 23 and 30.
- F10 (blocking in round 2) — fixed by `55b937d`, `4534ffd` and `ab2511f`: `issue` and `open` leave the sandbox `running (detached)`, shown by Task 30 steps 2-4.
- F11 — settled by plan.md Q16. The `lock.sh` volume TODO is #123.
- F12 — fixed by `7540534` and `285e8b2`; Task 30 step 5.
- F13 — fixed by `55b937d` (`sandbox_state`) and `85f6b6e`.
- F14-F16 — fixed by `3a98326` and `8727638`, apart from F17 below.

#### Documentation

The plan names `.sbx/README.md` (Prerequisites, Commands, Ending a sandbox and its flowchart, Stopped sandboxes), `CHANGELOG.md:9` and the evaluation page. The diff touches each of them, and each now says what the code does. The flowchart's Mermaid is not rendered here: no renderer is installed, and the project has no rule that requires one. Findings: F17 and F18 below.

#### Findings

All are non-blocking.

- **F17 — non-blocking — `/codeo:implement`'s.** The evaluation page's T9 result ("the two earlier stops are unexplained") and the #86 bullet ("the unexplained stops") contradict the D4 row and the Fragility bullet, which state the cause.
- **F18 — non-blocking — `/codeo:implement`'s.** The Credentials bullet says `gh auth status` "still listed `delete_repo`" (T6). T6 ran before T13, so "still" overstates it.
- **F19 — non-blocking — `/codeo:plan`'s.** If the start-script `exec` fails, `issue` ends with sbx's own error and no `codeo-sandbox:` line naming the next step (`.sbx/codeo-sandbox.sh:182`).
- **F20 — non-blocking — `/codeo:plan`'s.** Rerunning `issue` on an existing sandbox still needs a valid pin (`read_pin` comes before `ensure_sandbox`, `:214`). This is rare, because the pin is committed.
- **F21 — non-blocking — `/codeo:plan`'s.** When `end`'s sandbox fetch fails, the message names no way out, even with `--force`. A broken sandbox can then be removed only with a raw `sbx rm --force` (`:374`).
- **F22 — non-blocking — `/codeo:implement`'s.** T12 (`:421`) still says "was not tried" twice, and T3, T8 and T10 say "kit/image line" where the criterion says `Image:` lines. The digests were recorded shortened, and the page says so.
- **F23 — non-blocking — note for `/codeo:close`.** The #94 criterion "`git diff --stat main -- .devcontainer skills` is empty" is met on that part's own commits, as the plan's Global Constraints say. On the consolidated branch, `.devcontainer/` has three changed files, which the #85, #86 and #114 parts require. The pull request description should say so.
- **F24 — non-blocking — `/codeo:implement`'s.** Test gaps:
  - `tests/sandbox.test.sh:1014` reads `CHANGELOG.md` line 9 by number;
  - several deferred minors from the task reviews (the SDD ledger, listed in `implement.md` round 3) remain.

  The one most worth doing is Task 28's: the devcontainer test without the marker fails if the suite runs inside an sbx sandbox.

The review set these aside, with reasons:
- the real `sbx` CLI's behaviour (the host trials are the evidence);
- Claude Code's trust handling;
- the README's host numbers;
- clones under `/mnt/c`;
- concurrent `.claude.json` writers;
- stale refs left by a manual `sbx rm`;
- the identity source;
- "Why not migrate" read as the evaluation at its date;
- shellcheck info notes.

No issue was filed this pass. #123 was filed during planning.

Every acceptance criterion is met, and none of F17-F24 blocks a merge. They can go to `/codeo:triage` after the merge, or into a follow-up.

**Verdict: clear — forward to `/codeo:close`.**

## Log
- 2026-11-17 — round 1: build and suite pass; 3 blocking findings from the plan's design (pin beside the downloaded script, end vs squash merges, stale clone on rerun); back to /codeo:plan · cost: 7m · opus-5-5 278k in + 5M cached / 38k out
- 2026-11-18 — round 2 started: sync clean; overlap with #118 on CHANGELOG.md raised as Q1; stopped for the answer · cost: 0m · opus-5-5 19k in + 515k cached / 1k out
- 2026-11-18 — round 2: build and suite pass; Q1 answered (proceed and coordinate with #118); 26 of 28 criteria met on host evidence; 2 blocking findings from the plan (defaultExtensions blocked by the sbx policy, idle sandboxes stop); back to /codeo:plan · cost: 16m · opus-5-5 174k in + 4.9M cached / 32k out
- 2026-11-18 — round 3: build and suite pass; all 28 criteria met (host evidence: Tasks 22, 23, 30); 8 non-blocking findings; clear, forward to /codeo:close · cost: 11m · opus-5-5 149k in + 4.2M cached / 26k out
