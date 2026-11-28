# Issue #219 — issue

| | |
|---|---|
| Issue | #219 |
| Step | issue |

## Where this stands

Filed as #219 from triage run 2026-11-28.

## Questions

None.

## Outcome

### Description

Close the non-blocking findings that `/codeo:qc` and `/codeo:implement` left on #204, #206, #195, #181 and #213 and that no issue carries. Each is a small wording, comment, test or script gap; nothing here breaks a run. They are fixed or ruled out in one pull request, as #185, #193 and #205 do for earlier workflows.

### Motivation / Context

`/codeo:triage` collected them on 2026-11-28 (run 1, Q1, Q2, Q3, Q5, Q6), and the engineer chose to file them as one issue. They sit in archived dossiers under `.codeo/done/<N>/` on `main`.

### Key Requirements

From #204 (`.codeo/done/204/implement.md` line 33, `qc.md` G6):
- `scripts/inflight.sh` labels an archive with no pull request `(PR open)`, and its header comment says "a pull request is usually open". Both name the window between close's archive push and `pr create`, in which the `waits:` line should point at `/codeo:close`, not at review.

From #206 (`.codeo/done/206/qc.md` lines 43-44, `implement.md` line 48):
- `docs/dossier.md`'s intake paragraphs (about lines 118-127) and the comment at `scripts/intake.sh:90-91` give "every writer owns a directory no other writer touches" as the reason a rebuilt push is safe. The reason is now that `commit` only adds and updates, never deletes a file its clone lacks (G1).
- The placeholder pattern in `scripts/cleanup.sh` also refuses a token with `-` or `.` inside the braces (`{issue-number}`), and still accepts `{a,b}` and `{{.Names}}` (G2).
- The docs say how a branch-side delete of a removal record is done, given that `intake.sh commit cleanup --drop` re-adds a file a clone still holds (G6).
- A failed `restore` is not ignored silently, and `record ""` and `record 0` have tests.

From #195 (`.codeo/done/195/implement.md` lines 40 and 69):
- A stale `refs/codeo/verify/feat` blocks a fetch into `feat/x` and fails closed with "cannot reach origin". It reports the real cause.
- Tests cover the `take` web-checkout path with an `unverified` login, a live-signal case for web + variable + failing `/user`, and the weak `assert_contains "local" "local"`.
- The `verify` flowchart shows the no-owner pass and the could-not-check refusal in the assignees read; `ls-remote` tail matching is judged; a failed `assignee-add` is read by a later step or the gap is recorded; `close` no longer says "the assignee" in two places where it means the recorded owner.

From #181 (`.codeo/done/181/qc.md` F2-F4, `implement.md` line 39):
- `.devcontainer/README.md:84` and `CHANGELOG.md:9` say the old shape is the fallback only for a session that carries no number of its own (F2).
- `seq_file` in `.devcontainer/scripts/session-title.sh` (lines 31-40) no longer joins the work-tree root to a git-relative path or depends on `--path-format=absolute` (git 2.31) (F3).
- The header at `session-title.sh:22` says the next fresh session follows the last number given out, not the highest, after a wrap (F4).
- Tests cover a `/clear` with an inherited numbered title and a state path that is a directory; `<id8>` is defined in the README and changelog prose.

From #213 (`.codeo/done/213/qc.md` F1, F2, F3, F5), fixed in the next release's README and changelog since the v1.0.11 tag is never moved:
- The `TODO-set-me` sentences in the README say `codename`, `gh-scopes`, `board` and `suites` also fail with `skipped: config is unusable` (`scripts/doctor.sh` 49, 84, 102, 172).
- The `Shared state:` line names #195's owner read of the `resumed: by` line and #204's close phase detection, as `docs/release-checklist.md` step 6 asks.
- The four README sentences that over-generalize are corrected: the stash/abandon assignee removal (the recorded owner, not the caller), the `mismatch` example (plan, implement, qc and close only), the "git writes through Bash are refused" exemption, and the two placement notes.
- `Safe to bump mid-workflow: yes` carries the caveats its #195 bullet states.

### Acceptance Criteria
- [ ] `inflight.sh` and its header comment name the archive-to-`pr create` window, and a test covers it.
- [ ] `scripts/cleanup.sh` refuses `{issue-number}` and `{a.b}` tokens and accepts `{a,b}` and `{{.Names}}`; the dossier and intake comment state the real reason a rebuilt push is safe; the removal-record delete is documented.
- [ ] A stale `refs/codeo/verify/*` ref produces its own message, not "cannot reach origin".
- [ ] The #195 test and doc gaps listed above are covered or recorded as accepted.
- [ ] The README, changelog and header text for #181 matches `session-title.sh`, and `seq_file` no longer needs git 2.31.
- [ ] Every #213 README and changelog item above is corrected under `## Unreleased`, and `bash tests/readme.test.sh` passes.
- [ ] `bash tests/run.sh` passes.

### Out of Scope
- #181's F1: the review's own finding that `source` is `"fork"` for forks, so nothing is wrong.
- #188's `jq` fallback: dismissed in the triage run.
- CI flakes and `tests/sandbox.test.sh`, filed separately.

### Reference
`.codeo/intake/triage/2026-11-28.md` Q1, Q2, Q3, Q5, Q6; `.codeo/done/204/`, `.codeo/done/206/`, `.codeo/done/195/`, `.codeo/done/181/`, `.codeo/done/213/` on `main`. Siblings: #185, #193, #205.

## Log

- 2026-11-28 — filed #219 from triage 2026-11-28
