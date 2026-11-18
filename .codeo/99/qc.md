# Issue #99 — qc

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/99 |
| Branch | `feat/make-sbx-issue-sandbox-usable` |
| Plan | `docs/plans/2026-11-17-sbx-issue-sandbox.md` |
| Updated | 2026-11-18 |

## Where this stands

Round 2 has started (2026-11-18): step 2 raised Q1, an overlap with #118 on `CHANGELOG.md`. The pass stops until Q1 is answered, then goes on from step 2.

## Questions

### Q1 — #118 also lists `CHANGELOG.md`: proceed and coordinate, sequence after #118, or re-scope?

`overlap.sh 99` printed `118	CHANGELOG.md` and `118	glob:CHANGELOG.md`. #118 (branch `feat/live-signal-leftovers-104-refresh`, assignee kbajpai, step `init (working)`) lists `CHANGELOG.md` in its footprint and has changed no file yet (`changed: none`). This branch adds one bullet and amends another in the same file.

**Why it matters:** QC cannot go past step 2 until this is settled. *Proceed* lets the pass go on now. *Sequence after #118* means #99 waits for #118 to merge before it goes to a pull request. *Re-scope* means this branch drops its `CHANGELOG.md` bullets.

**Options:**
- *Proceed and coordinate* (recommended): both changes add bullets to the changelog's unreleased list. Whichever merges second gets a small conflict and resolves it by keeping both bullets.
- *Sequence after #118*: #99 waits for #118, which has not started work yet.
- *Re-scope*: this branch drops its changelog bullets. Two acceptance criteria ask for `CHANGELOG.md` to describe the change, so this is not a real option.

**Answer:**

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

## Log
- 2026-11-17 — round 1: build and suite pass; 3 blocking findings from the plan's design (pin beside the downloaded script, end vs squash merges, stale clone on rerun); back to /codeo:plan · cost: 7m · opus-5-5 278k in + 5M cached / 38k out
- 2026-11-18 — round 2 started: sync clean; overlap with #118 on CHANGELOG.md raised as Q1; stopped for the answer · cost: 0m · opus-5-5 19k in + 515k cached / 1k out
