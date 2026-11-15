# Live-session signal Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** While a codeo session is active in a checkout bound to an issue, other clones see that workflow as live, with the engineer and the machine, through `inflight.sh` and so through `/codeo:triage`; a dead session stops reading as live on its own.

**Architecture:** Each session publishes one tiny parentless commit at its own ref, `refs/codeo/live/<issue>/<machine>`, outside `refs/heads/`, so the feature branch, its PR and the branch list never see it. A plugin hook refreshes it at most every 5 minutes and deletes it when the session ends; the reader treats anything older than 15 minutes as gone. `inflight.sh` fetches those refs and prints a `live:` line per live session.

**Tech Stack:** bash, git plumbing, `gh api` through `scripts/github.sh`, the repo's `tests/*.test.sh` harness (`bash tests/run.sh [pattern]`).

**Spec:** `.codeo/104/init.md` (`## Outcome`: the issue and its acceptance criteria) and `.codeo/104/plan.md` (Q1-Q7 answered). No standing reference doc: the behaviour is documented in `docs/handoff.md` (Task 5).

## Context and decisions

The lock `.codeo/active` is local to one checkout and never pushed, so no pushed fact tells a workflow being worked now from one whose checkout was closed days ago. Leases on `codeo/intake` are the only shared pushed state; they change rarely and are taken and released by steps, while a liveness signal is refreshed every few minutes by a process nobody is watching.

| Decision | Chosen | Rejected (why) |
|---|---|---|
| Where it lives (Q1) | A ref per session, `refs/codeo/live/<issue>/<machine>`, force-pushed over itself. One parentless commit: no history, no branch-list entry, no CI run (`ci.yml` runs on `main` pushes and pull requests only), no race with lease or triage pushes. | A file on `codeo/intake`: ~100 commits a day per session on a branch every engineer pushes to, each able to lose a race and retry. A branch per session: shows in the branch list, and every script that walks `refs/remotes/origin` would need an exclusion. |
| Web sessions (Q2) | Push the ref with `git push`; when the push is refused, write it with REST (`github.sh ref put`). A by-hand check in a real web session is recorded for `/codeo:qc` (Task 7). | Assuming pushes to any ref work there: unverified from this checkout. |
| What refreshes it (Q3) | A plugin hook on `UserPromptSubmit` and `PostToolUse`, running only while `.codeo/active` exists, plus a `SessionEnd` hook that deletes the ref. "Live" means a Claude session in a checkout bound to the issue did something in the last 15 minutes. | Skills calling it: five `SKILL.md` files change, and a long `implement` run outlasts the expiry between calls. |
| Expiry (Q4) | Refresh every 300 s, expire after 900 s, fixed. `CODEO_LIVE_REFRESH_SECONDS` and `CODEO_LIVE_TTL_SECONDS` override them (as `CODEO_LEASE_GRACE_SECONDS` does for leases); no config key. | A config key: a `lib/env.sh` entry, a default and its tests, for a number nobody has asked to tune. |
| Who and where (Q5) | User: `github.sh user login`, else `git config user.name`, else `unknown` — never an email address. Machine: `$CODEO_MACHINE`, else by the lock's `host`: `container` → the lock's `volume:` line; `web` → `web-` and the first 8 characters of its `session:`; `local` → `hostname`. The repository is public, so this is all the signal says. | Printing the container's own hostname (a random id); a user email (leases fall back to one; not copied into a public ref). |
| Display (Q6) | `inflight.sh` prints `  live:      <user> on <machine> (<host>), <age> ago` after `changed:`, once per live session, and nothing when there is none; `--live` prints the sessions as TSV. `--tsv`, `--branches` and every existing line are untouched. When the refs cannot be fetched, the block says `  live:      unknown (could not fetch the signals)`. | An always-present `live: no`; a sixth `--tsv` column (#103 also adds facts to `inflight.sh`, so the column order would need agreeing). |
| Triage (Q7) | One sentence in `skills/triage/SKILL.md` and one clause in `docs/skills.md`: a workflow with a `live:` line is quoted as evidence and not asked about as parked. | Leaving triage's reading of the line to #103. |

```mermaid
sequenceDiagram
    participant S as Claude session (checkout bound to #N)
    participant H as hooks/live-signal.sh
    participant O as origin (refs/codeo/live/N/machine)
    participant R as inflight.sh in another clone
    S->>H: UserPromptSubmit / PostToolUse
    H->>H: .codeo/active present? less than 5 min since last beat?
    H-->>O: live.sh beat — force-push one parentless commit (REST if the push is refused)
    R->>O: fetch +refs/codeo/live/*:refs/codeo/live/* (--prune)
    R->>R: beat within 15 min? print "live:" line
    S->>H: SessionEnd
    H->>O: delete the ref
    Note over O,R: a crash deletes nothing; the line stops printing 15 min after the last beat
```

**Not in this plan.** Blocking, locking or waiting on liveness (information only). Dates, what a workflow waits on, and board mismatch (#103). Sweeping refs left by machines that never come back: they are ignored after 15 minutes and overwritten by the next beat of the same issue and machine, and stay on origin otherwise.

## Global Constraints

- No invariants document is configured, so there is no invariant to check. No shared environment: no task carries `Needs lease:`, and every task but Task 7 runs in this checkout. No `wiki` module, no `resources[]`.
- **No commits from the signal.** Neither the feature branch nor its PR gains a commit or a file. The signal is a ref outside `refs/heads/`; `live.sh` never checks anything out, never touches the index (the commit is built with `git commit-tree` on the empty tree) and never writes to the working tree. Its commits carry a fixed identity (`codeo-live <codeo-live@invalid>`), never the engineer's.
- **Never fails or stalls a session.** Every verb of `live.sh` exits 0 whatever happens (except `fetch` and `list`, whose callers need the difference); a push is bounded by `timeout "${CODEO_LIVE_PUSH_TIMEOUT:-8}"`; the hook runs `beat` in the background with its output discarded.
- **Public repository.** The signal carries the issue number, a GitHub login (or `git config user.name`), a machine label and an epoch. Fields are cut to printable characters, at most 64 each, and the machine is restricted to `[A-Za-z0-9._-]` so it cannot leave the ref's namespace.
- **Information only.** No script refuses, waits or changes its answer because a workflow is live.
- **Clocks.** The reader compares the signal's `beat` epoch with its own clock. A writer whose clock is ahead counts as age 0; one that is behind by minutes shifts the window by that much. This is documented, not corrected.
- **Reaches containers on the next plugin pin.** The hook and `live.sh` run from the installed plugin, so a dev container signals only after its `plugin.ref` moves to a release carrying this change (`CHANGELOG.md`, Task 6).
- The `shell` suite has no `filter`, so each task's proof of done is the whole `bash tests/run.sh`; the narrower `bash tests/run.sh <pattern>` is used only for the red and green steps.
- **Documentation moved.** `docs/handoff.md` → *Parallel workflows* (Task 5), `docs/skills.md` → *triage* → *Reads and writes* (Task 5), `CHANGELOG.md` (Task 6). `docs/dossier.md` and `README.md` do not move: no dossier convention changes and the README lists no hook or script. No `wiki` pages.
- **Overlap with #71 (Q8, proceed and coordinate) and #107 (Q9; `CHANGELOG.md` only).** #71 (`feat/file-new-issues-straight-board`, kbajpai, at implement) changes `skills/triage/SKILL.md`, `docs/handoff.md`, `docs/skills.md` and `CHANGELOG.md`, all of which Tasks 5 and 6 edit. `origin/main` has also moved since this branch was cut (#70 merged; it changed `scripts/github.sh`, `skills/triage/SKILL.md`, `docs/handoff.md`, `docs/skills.md`, `CHANGELOG.md` and the test files named in Tasks 1-4): every task starts from a merged `origin/main`, which `/codeo:implement` does each round (`sync-main.sh`), and re-reads the lines it edits before editing them.

## Review Focus

- **Origin unreachable or slow at a beat or a clear.** The session carries on, `live.sh` exits 0 within the push timeout, and one `live:` line on stderr says why (Task 2: `beat_with_an_unreachable_origin_exits_0_once`).
- **A writer's clock ahead of the reader's.** A signal dated in the future is live with age 0, not dropped and not shown as a negative age (Task 2: `list_treats_a_future_beat_as_age_0`).
- **Odd names.** A `user.name` with spaces, a newline or a `/`, and a machine with `/` or `..`, never change the ref path or add a field (Task 2: `fields_are_cut_and_the_machine_stays_in_its_namespace`).
- **Two sessions on one issue.** Two machines show as two lines; two sessions on one machine share one ref and show as one (Task 3: `two_machines_are_two_live_lines`).
- **The signals cannot be read.** A failed fetch prints `live: unknown`, never silence, and never reads a ref left by an earlier fetch (Task 3: `a_failed_fetch_prints_unknown_not_stale_refs`).

---

### Task 1: `github.sh ref put|delete` — the REST fallback for the signal

**Files:**
- Modify: `scripts/github.sh` (two verbs, and the usage lines at the top and bottom)
- Modify: `tests/github.test.sh` (new cases, placed after the `label list` cases)

**Interfaces:**
- Consumes: the test's stub of `gh api` (`write_fixture`, `mark_fail`, `$calls_log`) and its `assert_*` helpers.
- Produces: `github.sh ref put <ref> <message-file>` prints the new commit's sha and exits 0, or one `github:` line on stderr and exit 1; `github.sh ref delete <ref>` prints nothing and exits 0 (also when the ref is already gone), or one `github:` line and exit 1. Both refuse a `<ref>` that does not start with `refs/codeo/live/`.

- [ ] **Step 1: Write the failing tests** — cases named `ref_put_creates_a_parentless_commit_and_moves_the_ref`, `ref_put_creates_the_ref_when_it_does_not_exist`, `ref_put_refuses_other_namespaces`, `ref_delete_removes_the_ref`, `ref_delete_of_a_missing_ref_succeeds`. The first has fixtures for `GET repos/acme/widgets/git/ref/heads/main` (`{"object":{"sha":"b1"}}`), `GET .../git/commits/b1` (`{"tree":{"sha":"t1"}}`), `POST .../git/commits` (`{"sha":"c1"}`) and `PATCH .../git/refs/codeo/live/104/m` (`{}`), runs `github.sh ref put refs/codeo/live/104/m "$msg_file"` and asserts: exit 0, stdout `c1`, and the call log holds `METHOD=POST PATH=repos/acme/widgets/git/commits` with `FIELD=tree=t1` and no `parents` field, then `METHOD=PATCH PATH=repos/acme/widgets/git/refs/codeo/live/104/m` with `FIELD=sha=c1` and `FIELD=force=true`. The second marks the PATCH to fail and asserts a `METHOD=POST PATH=repos/acme/widgets/git/refs` call with `FIELD=ref=refs/codeo/live/104/m`. The third runs `ref put refs/heads/main "$msg_file"`, asserts exit 1, a stderr line containing `refs/codeo/live/` and an empty call log. The fourth asserts `METHOD=DELETE PATH=repos/acme/widgets/git/refs/codeo/live/104/m`; the fifth marks that DELETE failing with the stub's `Reference does not exist` body and asserts exit 0.
- [ ] **Step 2: Run to see them fail.** `bash tests/run.sh github`. Expected: exit 1, the five cases failing with `unknown …` or the usage line from the final `case` arm.
- [ ] **Step 3: Implement the verbs in `scripts/github.sh`.** `ref) sub=${1:?ref subcommand}; shift` with a `put` and a `delete` arm, both beginning `[[ ${1:-} == refs/codeo/live/* ]] || die "ref $sub: only refs/codeo/live/* may be written, got ${1:-nothing}"`. `put`: base head from `git/ref/heads/<baseBranch>` (`codeo_base_branch`), its tree from `git/commits/<sha>`, `POST git/commits` with `-F "message=@$file"` and `-f "tree=$tree"` (no `parents`, so the commit is a root), then `PATCH git/refs/<ref minus refs/>` with `-f sha=… -F force=true`, falling back to `POST git/refs` with `-f ref=… -f sha=…` when the PATCH fails. `delete`: `DELETE git/refs/<ref minus refs/>`; a failure whose output contains `Reference does not exist` or `Not Found` is success. Both capture `gh`'s output first and print only the sha, like every read verb. Add `ref put|delete` to both usage strings.
- [ ] **Step 4: Run to see them pass.** `bash tests/run.sh github` ends `all cases passed`.
- [ ] **Step 5: Proof of done.** `bash tests/run.sh` prints `all cases passed`.
- [ ] **Step 6: Commit** `scripts/github.sh` and `tests/github.test.sh`.

### Task 2: `scripts/live.sh` — publish, clear, fetch, list

**Files:**
- Create: `scripts/live.sh`
- Create: `tests/live.test.sh`

**Interfaces:**
- Consumes: `github.sh user login` and `github.sh ref put|delete` (Task 1); `lib/env.sh` (`CODEO_PROJECT_ROOT`, `CODEO_STATE_DIR`, `codeo_base_branch`); the lock's `issue:`, `host:`, `volume:` and `session:` lines.
- Produces:
  - `live.sh beat [--force]` — exit 0 always. With no `.codeo/active`, or the checked-out branch being the base branch, it does nothing. Without `--force` it does nothing when the stamp `$(git rev-parse --git-path codeo-live-beat)` is younger than `CODEO_LIVE_REFRESH_SECONDS` (default 300); it touches the stamp first, then force-pushes `<sha>:refs/codeo/live/<issue>/<machine>` to `origin`, where `<sha>` is `git commit-tree` on the empty tree with the message below. A refused or failed push is retried once through `github.sh ref put`; if that fails too, one `live: could not publish — <reason>` line on stderr.
  - `live.sh clear` — exit 0 always; deletes that ref with `git push origin --delete`, falling back to `github.sh ref delete`; removes the stamp.
  - `live.sh fetch` — `git fetch -q --prune origin '+refs/codeo/live/*:refs/codeo/live/*'`; exit 0, or exit 1 with one stderr line.
  - `live.sh list [--tsv]` — reads the refs under `refs/codeo/live/` as last fetched (it never fetches); prints only signals whose age is at most `CODEO_LIVE_TTL_SECONDS` (default 900). `--tsv` lines: `issue<TAB>user<TAB>machine<TAB>host<TAB>age-in-seconds`, oldest issue number first; without it one `#<issue>  <user> on <machine> (<host>), <age> ago` line each, the age as `<n>s` under 60 and `<n>m` after. A ref whose message lacks a field or has a non-numeric `beat` is skipped.
  - The message (`%B` of the commit): `codeo live signal`, a blank line, then `issue: <N>`, `user: <u>`, `machine: <m>`, `host: <container|web|local>`, `beat: <epoch seconds>`.

- [ ] **Step 1: Write the failing tests** in `tests/live.test.sh`, modelled on `tests/inflight.test.sh` (scratch repos, `HOME` in scratch, a copy of the plugin's `scripts/` and `lib/` with `github.sh` replaced by a stub that answers `user login` with `alice` and logs `ref put|delete` calls to `$scratch/gh.log`; a bare `origin` and a `clone_with_lock <issue> <host> [volume|session]` helper that writes `.codeo/active` and a `.codeo/config.json`). Cases, each asserting what its name says:
  - `beat_publishes_one_parentless_commit_naming_issue_user_machine` — after `beat --force` from a `container` lock (`volume: codeo-104`, issue 104), `git -C origin log -1 --format=%B refs/codeo/live/104/codeo-104` contains `issue: 104`, `user: alice`, `machine: codeo-104`, `host: container`, and a `beat:` within 5 s of `date +%s`; `git -C origin rev-list --parents -1 <ref>` is one word (no parent); `git -C origin log -1 --format='%ae' <ref>` is `codeo-live@invalid`.
  - `beat_adds_nothing_to_the_branch_or_the_pull_request` — `git -C origin for-each-ref refs/heads` is byte-identical before and after, the clone's `HEAD` and `git status --porcelain` are unchanged, and `git -C origin rev-list --all --not --branches` lists exactly one commit.
  - `beat_is_throttled_and_force_is_not` — a second `beat` right after the first leaves the ref's sha unchanged; `beat --force` changes it; with `CODEO_LIVE_REFRESH_SECONDS=0` a plain `beat` changes it.
  - `beat_replaces_the_signal_it_does_not_accumulate` — after three forced beats `git -C origin rev-list --count <ref>` is 1.
  - `beat_without_a_lock_or_on_the_base_branch_does_nothing` — no ref, no stamp, empty stderr, exit 0, in both cases.
  - `machine_by_host` — `CODEO_MACHINE=laptop` wins; a `web` lock with `session: abcdef0123456789` gives `web-abcdef01`; `local` gives `hostname`'s output with anything outside `[A-Za-z0-9._-]` replaced by `-`; a `container` lock whose `volume:` is `unknown` falls back to `hostname`.
  - `user_falls_back_to_git_user_name_and_never_an_email` — with the stub's `user login` failing, the user is the clone's `user.name`; with `user.name` unset it is `unknown`; the message never contains `@`.
  - `fields_are_cut_and_the_machine_stays_in_its_namespace` — a `user.name` of `Al\nmachine: evil/../x`, 200 characters long, gives one `user:` line of at most 64 printable characters and exactly one `machine:` line; `CODEO_MACHINE='a/b/../c'` gives a ref `refs/codeo/live/104/a-b-..-c`.
  - `beat_falls_back_to_rest_when_the_push_is_refused` — with a `pre-receive` hook on origin that rejects `refs/codeo/*`, `beat --force` exits 0 and `gh.log` holds `ref put refs/codeo/live/104/codeo-104`; when the stub's `ref put` also fails, stderr has one line starting `live: could not publish` and the exit is 0.
  - `beat_with_an_unreachable_origin_exits_0_once` — `git remote set-url origin /nonexistent`: exit 0, one stderr line, finished within `CODEO_LIVE_PUSH_TIMEOUT=2` plus a second.
  - `clear_deletes_the_ref_and_the_stamp` and `clear_of_a_missing_ref_exits_0`.
  - `fetch_then_list_shows_a_live_session_from_another_clone` — clone A beats; clone B `live.sh fetch` then `live.sh list --tsv` prints `104<TAB>alice<TAB>codeo-104<TAB>container<TAB>` and a number ≤ 5.
  - `list_hides_an_expired_signal_and_shows_it_again_inside_the_ttl` — a signal whose `beat` is 901 s old (planted with `git -C origin commit-tree` and `update-ref`) is absent; one 899 s old is present; with `CODEO_LIVE_TTL_SECONDS=60` a 61 s old one is absent.
  - `list_treats_a_future_beat_as_age_0` — a `beat` 120 s ahead prints age `0`.
  - `list_skips_a_malformed_signal` — a ref whose message has no `beat:` line, or `beat: soon`, prints nothing for it and exits 0.
  - `fetch_prunes_a_cleared_signal` — after A `clear`, B `fetch` then `list --tsv` is empty.
- [ ] **Step 2: Run to see them fail.** `bash tests/live.test.sh`. Expected: exit 1, every case failing with `No such file` for `scripts/live.sh`.
- [ ] **Step 3: Implement `scripts/live.sh`** with the interface above. The header comment documents the four verbs, the two environment variables, the message format and what "live" means; style follows `scripts/lock.sh` (sources `lib/env.sh`, `cd "$CODEO_PROJECT_ROOT"`, `say`/`warn` helpers). The identity is passed per command (`GIT_AUTHOR_NAME=codeo-live GIT_AUTHOR_EMAIL=codeo-live@invalid`, and the same for the committer), so no config is read or written. The empty tree is `git hash-object -t tree -w /dev/null`.
- [ ] **Step 4: Run to see them pass.** `bash tests/live.test.sh` ends `all cases passed`.
- [ ] **Step 5: Proof of done.** `bash tests/run.sh` prints `all cases passed`.
- [ ] **Step 6: Commit** `scripts/live.sh` and `tests/live.test.sh`.

### Task 3: `inflight.sh` prints `live:` and `--live`

**Files:**
- Modify: `scripts/inflight.sh` (header comment, argument parsing, the human block, one new listing)
- Modify: `tests/inflight.test.sh` (new cases before the `empty_clone` block)

**Interfaces:**
- Consumes: `live.sh fetch` and `live.sh list --tsv` (Task 2).
- Produces: in the human output, after a workflow's `changed:` line, one `  live:      <user> on <machine> (<host>), <age> ago` line per live session of that issue, or `  live:      unknown (could not fetch the signals)` once when the fetch failed, or nothing. `inflight.sh --live [--except <N>]` prints `live.sh list --tsv`'s lines minus the excepted issue, or nothing; on a failed fetch it exits 1 with the reason on stderr and nothing on stdout. `--live` cannot be combined with `--tsv` or `--branches` (exit 1, the usage line, which gains `--live`). `--tsv` and `--branches` neither fetch nor read the signals, and their output does not change.

- [ ] **Step 1: Write the failing tests**, using the file's `fresh_repo`, `write_dossier`, `clone_of` and `run_inflight`, plus a `plant_signal <origin> <issue> <machine> <user> <age-seconds>` helper that commits the message of Task 2's format with `git commit-tree` on the empty tree and points `refs/codeo/live/<issue>/<machine>` at it in the scratch origin:
  - `human_block_shows_a_live_session` — with a 30 s old signal for issue 7 by `bob` on `codeo-7`, the `#7  feat/a` block holds `  live:      bob on codeo-7 (container), 30s ago` after its `changed:` line, and the blocks of issues 9 and 5 hold no `live:` line.
  - `two_machines_are_two_live_lines` — signals for issue 7 from `codeo-7` and `laptop` give two lines; a second signal for the same machine is the same ref and gives one.
  - `an_expired_signal_prints_nothing` — a 901 s old signal gives no `live:` line anywhere.
  - `a_failed_fetch_prints_unknown_not_stale_refs` — after one good run that fetched a live signal, the plugin copy's `scripts/live.sh` is replaced by a stub whose `fetch` exits 1 and whose `list --tsv` still prints that signal: the block prints `  live:      unknown (could not fetch the signals)` once and never the signal's line.
  - `live_listing` — `inflight.sh --live` prints the TSV lines; `--live --except 7` leaves issue 7's out; nothing in flight and nothing live prints nothing.
  - `live_cannot_be_combined` — `--live --tsv` and `--live --branches` each exit 1 with `usage: inflight.sh` on stderr.
  - `tsv_and_branches_ignore_the_signals` — with a live signal planted, `--tsv` and `--branches` print exactly what the existing cases expect, and the `gh` stub log is unchanged by `--branches`.
- [ ] **Step 2: Run to see them fail.** `bash tests/run.sh inflight`. Expected: exit 1; the `live:` assertions fail with `want substring`, and `--live` with `usage: inflight.sh`.
- [ ] **Step 3: Implement in `scripts/inflight.sh`.** Parse `--live`; for the human output call `live.sh fetch` once before the loop (`live_ok` set from its status) and, per block, filter `live.sh list --tsv` by issue into `live:` lines; `--live` runs `fetch` then `list --tsv` through the same `--except` filter. Update the header comment and both usage strings.
- [ ] **Step 4: Run to see them pass.** `bash tests/run.sh inflight` ends `all cases passed`.
- [ ] **Step 5: Proof of done.** `bash tests/run.sh` prints `all cases passed`.
- [ ] **Step 6: Commit** `scripts/inflight.sh` and `tests/inflight.test.sh`.

### Task 4: the hook — refresh while a session works, clear at its end

**Files:**
- Create: `hooks/live-signal.sh`
- Modify: `hooks/hooks.json` (the `description`, and three event entries beside the existing `PreToolUse`)
- Create: `tests/live-signal.test.sh`

**Interfaces:**
- Consumes: `live.sh beat` and `live.sh clear` (Task 2); the hook JSON on stdin (`.cwd`).
- Produces: `hooks/live-signal.sh beat|clear` — reads the JSON, finds the project from `.cwd` as `hooks/subagent-model.sh` does, exits 0 and prints nothing when it has none or `.codeo/active` is absent; `beat` starts `live.sh beat` in the background with stdin, stdout and stderr closed; `clear` runs `live.sh clear` in the foreground. It always exits 0. `hooks.json` registers `beat` on `UserPromptSubmit` and `PostToolUse` (no matcher, timeout 10) and `clear` on `SessionEnd` (timeout 10).

- [ ] **Step 1: Write the failing tests** in `tests/live-signal.test.sh` (same scaffold as `tests/subagent-model.test.sh`, plus a bare origin as in Task 2): `hooks_json_registers_beat_and_clear` (`jq` finds `live-signal.sh beat` under `.hooks.UserPromptSubmit` and `.hooks.PostToolUse`, `live-signal.sh clear` under `.hooks.SessionEnd`, and the `PreToolUse` entry for `subagent-model.sh` is still there); `beat_publishes_in_the_background` (a lock and `{"cwd": "<clone>"}` on stdin: the hook returns with empty stdout and stderr, then within 10 s `git -C origin rev-parse refs/codeo/live/104/<machine>` resolves — polled every 0.2 s); `beat_judges_the_cwd_not_the_process_directory` (run from another scratch project with no lock: nothing published, and the first project's lock is honoured when named in `cwd`); `no_lock_no_signal` (empty output, exit 0, no ref); `clear_deletes_the_ref` (after a beat, `clear` removes it before the hook returns); `a_broken_environment_never_fails_the_hook` (invalid JSON, a `cwd` that is not a repository and an unreachable origin each exit 0 with empty output).
- [ ] **Step 2: Run to see them fail.** `bash tests/live-signal.test.sh`. Expected: exit 1, `No such file` for the hook and `hooks_json_registers…` failing on a `null`.
- [ ] **Step 3: Implement `hooks/live-signal.sh`** and the three `hooks.json` entries; the description now reads "While a codeo workflow holds .codeo/active, subagents run on the configured models (the QC reviewer on its own) and the session publishes a short-lived live signal".
- [ ] **Step 4: Run to see them pass.** `bash tests/live-signal.test.sh` ends `all cases passed`.
- [ ] **Step 5: Proof of done.** `bash tests/run.sh` prints `all cases passed` (it includes `tests/subagent-model.test.sh`, which pins the existing hook).
- [ ] **Step 6: Commit** `hooks/live-signal.sh`, `hooks/hooks.json` and `tests/live-signal.test.sh`.

### Task 5: documentation and the triage sentence

**Files:**
- Modify: `docs/handoff.md` (*Parallel workflows*)
- Modify: `docs/skills.md` (*triage* → *Reads and writes*)
- Modify: `skills/triage/SKILL.md` (step 2, *Parked work*, the `inflight.sh` bullet)

**Interfaces:**
- Consumes: the behaviour of Tasks 2-4.
- Produces: nothing a later task uses.

- [ ] **Step 1: `docs/handoff.md`.** After the *Who else is in flight* bullet add a bullet **Who is working right now.** that says: while a Claude session runs in a checkout holding `.codeo/active`, a plugin hook publishes `refs/codeo/live/<issue>/<machine>` (one parentless commit, force-pushed over itself) at most every 5 minutes and deletes it when the session ends; `inflight.sh` prints a `live:` line for a workflow with a signal at most 15 minutes old, and `inflight.sh --live` lists them as TSV; a crash needs no cleanup, the line stops after the expiry; the signal adds nothing to the feature branch or its PR; it names the GitHub login and a machine label on a public repository, nothing else; it is information only; `CODEO_LIVE_REFRESH_SECONDS` (300), `CODEO_LIVE_TTL_SECONDS` (900), `CODEO_MACHINE` and `CODEO_LIVE_PUSH_TIMEOUT` (8) are its settings; the reader's own clock judges the age; where a push to that ref is refused it is written through the REST API, and where neither works nothing is published and the session says so once. Put this plan's Mermaid `sequenceDiagram` (under *Context and decisions*), unchanged, in that bullet, indented under it. In the *Who else is in flight* bullet add "and a `live:` line for each live session" after "the files the branch actually changes".
- [ ] **Step 2: `docs/skills.md`.** In *triage* → *Reads and writes*, first bullet, add `inflight.sh`'s `live:` lines to what it reads.
- [ ] **Step 3: `skills/triage/SKILL.md`.** After the sentence ending "…is worth asking about." in the `inflight.sh` bullet add: "A workflow whose block carries a `live:` line has a session working it now: quote the line as evidence and do not ask about it as parked work. `live: unknown` means the signals could not be read; judge that workflow as before and say so in the run's `## Outcome`." No `<!-- rule: -->` marker is added, so `docs/skills-inventory.md` and its fixture do not move.
- [ ] **Step 4: Proof of done.** `bash tests/run.sh` prints `all cases passed` (the skills lint, the inventory and the skills-doc checks read these files), and `grep -c 'refs/codeo/live' docs/handoff.md` prints a number ≥ 2.
- [ ] **Step 5: Commit** the three files.

### Task 6: `CHANGELOG.md`

**Files:**
- Modify: `CHANGELOG.md` (`## Unreleased`)

- [ ] **Step 1:** Replace the `Shared state: unchanged from v1.0.6.` line with `Shared state: adds refs/codeo/live/<issue>/<machine> on origin, an expiring signal written by the new hook and read by inflight.sh; older versions ignore it and no dossier convention changes.` Leave `Safe to bump mid-workflow: yes`. Add one bullet naming #104: the signal and its ref, the 5-minute refresh and 15-minute expiry with the four environment variables, the hook events, `inflight.sh`'s `live:` line and `--live` (the existing lines and `--tsv`/`--branches` unchanged), the REST fallback (`github.sh ref put|delete`), the triage sentence, that nothing is added to the feature branch or its PR, that containers get it on the next plugin pin, and the stated limit that a session idle for 15 minutes stops reading as live.
- [ ] **Step 2: Proof of done.** `bash tests/run.sh` prints `all cases passed`, and `sed -n 3,8p CHANGELOG.md` shows the new `Shared state:` line.
- [ ] **Step 3: Commit** `CHANGELOG.md`.

### Task 7: the web-session check, recorded for `/codeo:qc`

Runs on: the engineer's host
Shell: bash

**Files:** none; the result goes in `.codeo/104/implement.md`.

This is the only way to settle the issue's fourth criterion, which no scratch repository can: whether a hosted web session can write and read the ref.

- [ ] **Step 1:** In a web session whose checkout holds this branch's lock, with the plugin carrying Tasks 1-4, run `bash scripts/live.sh beat --force`. Expected: no `live:` line on stderr (or one naming the fallback), and exit 0.
- [ ] **Step 2:** From another clone, run `bash scripts/inflight.sh --live`. Expected: one line `104`, the login, `web-<8 characters>`, `web`, and an age under a minute.
- [ ] **Step 3:** Run `bash scripts/live.sh clear` in the web session, then `bash scripts/inflight.sh --live` again from the other clone. Expected: no line for issue 104.
- [ ] **Step 4:** Record the three outputs and whether the push or the REST fallback carried the write in `implement.md`. If both were refused, record that: `/codeo:qc` marks the criterion `not met` with that evidence instead of guessing.
- [ ] **Step 5: Proof of done.** The recorded output of Step 2 names the web machine label.
