# Issue #177 — qc

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/177 |
| Branch | `docs/177-close-163-166-168-leftovers` |
| Updated | 2026-11-25 |

## Where this stands

Round 2 is written and the verdict is clear: round 1's conflict (F1) is resolved in `bf71167`, the build and the whole `shell` suite pass, all eight criteria are met, and the independent review found no Critical or Important issue. Six non-blocking findings are recorded for `/codeo:triage`. Nothing is open. Next step: `/codeo:close`.

## Questions

None.

## Notes

None.

## Outcome

### Round 1 — 2026-11-25

**Base.** `sync-main.sh --abort-on-conflict` printed, exit 2:

```
sync-main: conflict: CHANGELOG.md
sync-main: conflict: docs/release-checklist.md
```

`origin/main` moved by one commit, `7d753fc` (#173, "close the #161 leftovers … release-checklist, changelog and README wording"), which changes `CHANGELOG.md` (7 lines) and `docs/release-checklist.md` (21 lines). Both are files this branch also changes: plan.md Q5 and Q7 answered *proceed and coordinate* with #173, so whoever merges second rebases them and keeps both sides. This branch merges second.

`overlap.sh 177` printed nothing (exit 0).

**Not run.** Steps 3-9 did not run: a conflict stops the pass at step 2 (`qc` resolves nothing).

**Criteria**

| # | Criterion | Verdict | Settled by |
|---|---|---|---|
| 1 | `README.md:256` and `:199` hold for a sandbox, and for `/codeo:doctor` and `live-signal.sh` without `jq` | not yet checkable — pass stopped at step 2 | — |
| 2 | `.codeo/overlays/cleanup.md` and `close.md` put the `git status` precondition before the removal commands and state when the row is marked | not yet checkable — pass stopped at step 2 | — |
| 3 | `CHANGELOG.md:20` no longer calls the README example invented; the `(#157)` clause is not repeated under `(#166)` | not yet checkable — pass stopped at step 2 | — |
| 4 | The close overlay's sandbox clause is complete, and `tests/track.test.sh` restores `TMPDIR` | not yet checkable — pass stopped at step 2 | — |
| 5 | `skills/cleanup/SKILL.md` step 4 names the leftover command for a run whose only output is a `failed name` issue | not yet checkable — pass stopped at step 2 | — |
| 6 | `skills/close/SKILL.md` makes the `<machine>` command usable at once, and says the branch stays on `origin` only when a beat pushed | not yet checkable — pass stopped at step 2 | — |
| 7 | The stale `(unstaged)` and `## Unreleased` lines in #168's workflow record are corrected or marked historical | not yet checkable — pass stopped at step 2 | — |
| 8 | The release checklist names the timezone for the changelog date | not yet checkable — pass stopped at step 2 | — |

**Findings**

- F1 — blocking, `/codeo:implement`'s: the branch conflicts with `origin/main` in `CHANGELOG.md` and `docs/release-checklist.md` after #173 merged (`7d753fc`). Resolve by merging `origin/main` (no rebase), keeping both sides: in `CHANGELOG.md`, #173's lines and this branch's `(#177)` bullet and three v1.0.9 corrections; in `docs/release-checklist.md` step 6, #173's wording and this branch's UTC-date sentence, then re-check that the UTC sentence still agrees with whatever #173 says about the date.

No issue was filed by this pass.

**Verdict: back to `/codeo:implement`.**

### Round 2 — 2026-11-25

**Base.** `sync-main.sh --abort-on-conflict` printed `sync-main: the branch already contains origin/main` (exit 0), so there is no `also changed on main` line. `overlap.sh 177` printed nothing (exit 0); `overlap.sh --outside 177` printed nothing (exit 0): every changed path is inside the footprint. Range under review: `7d753fc..8909b24`, 20 files, 556 insertions, 18 deletions; the product files are the two overlays, `CHANGELOG.md`, `docs/home-checkout.md`, `docs/release-checklist.md`, the two skills and five test files, plus the two `.codeo/done/168` notes.

`scope.sh origin/main HEAD` printed:

```
scope: suite shell needed for unclassified paths:
  .codeo/177/implement.md
  .codeo/177/init.md
  .codeo/177/issue.md
  .codeo/177/plan.md
  .codeo/177/qc.md
  .codeo/done/168/init.md
  .codeo/done/168/plan.md
  CHANGELOG.md
suite.shell=true
```

There is no `deploy=` line and no shared environment, so step 9 does not apply.

**Build.** The `shell` suite's build command is `true`: exit 0.

**Suite.** `bash tests/run.sh` (the `shell` suite, whole): `all cases passed`, exit 0.

**Acceptance criteria**

| Criterion | Verdict | Settled by |
|---|---|---|
| `README.md:256` and `:199` hold for a sandbox, and for `/codeo:doctor` and `live-signal.sh` without `jq` | met — the sentences now live in `docs/home-checkout.md:9` and `:66` (the README was restructured after the issue was filed); the reviewer ran `scripts/doctor.sh` with `jq` off `PATH`: `fail config: config.json: invalid JSON` first, `fail deps: missing: jq` ninth; `live.sh:188` reads the base branch as empty, and `track_confirm` (`.sbx/codeo-sandbox.sh:43-51`) passes `--local` | `tests/readme.test.sh` (three `home-checkout` pins; all fail at the base commit) |
| `.codeo/overlays/cleanup.md` and `close.md` put the `git status` precondition before the removal commands and state when the row is marked | met — `cleanup.md:12` (`first run git status … then run docker rm -f`), `close.md:11` (`run git status in that clone first … then docker rm -f`), both say rows are marked after each removal succeeds | `tests/cleanup-skill.test.sh`, `tests/close-removal.test.sh` (the close pin is scoped to the without-`codeo` sentence and fails against the old text) |
| `CHANGELOG.md:20` no longer calls the README example invented; the `(#157)` clause is not repeated under `(#166)` | met — `grep -c 'invented example issue' CHANGELOG.md` prints `0`; the `name`-proof clause appears once, in the `(#166)` bullet | `CHANGELOG.md` (the merge kept #173's text and re-applied the correction, `bf71167`) |
| The close overlay's sandbox clause is complete, and `tests/track.test.sh` restores `TMPDIR` | met — `close.md:11` ("from the folder that holds the script", marks its row itself only when `codeo-track.sh` sits beside it); `tests/track.test.sh` saves and restores `TMPDIR` and asserts it | `tests/close-removal.test.sh`, `tests/track.test.sh` case `no_temp_file_left` |
| `skills/cleanup/SKILL.md` step 4 names the leftover command for a run whose only output is a `failed name` issue | met — step 4: "When something was proven, or a `leftover` line was printed …", and "nothing was proven and no `leftover` line was printed" for `/codeo:triage` | `tests/cleanup-skill.test.sh` (step 4 extract; fails against the old text) |
| `skills/close/SKILL.md` makes the `<machine>` command usable at once, and says the branch stays on `origin` only when a beat pushed | met — step 17 reads `git ls-remote --heads origin 'codeo-live/<issue>/*'`, prints one exact delete per allowlisted branch, and says "only when a beat pushed one" | `tests/close-skill.test.sh` (six step-17 pins; the reviewer ran them against the base text and they fail) |
| The stale `(unstaged)` and `## Unreleased` lines in #168's workflow record are corrected or marked historical | met — dated `(added by #177)` notes in `.codeo/done/168/plan.md:50` and `init.md:19`; nothing already written changed | `bash scripts/dossier-check.sh .codeo/done/168`: the same two `log-cost` FAILs before and after, none new |
| The release checklist names the timezone for the changelog date | met — `docs/release-checklist.md:90-92` names the UTC date the release pull request opens | `docs/release-checklist.md` |

**Documentation check.** The plan named `docs/home-checkout.md`, `docs/release-checklist.md` and `CHANGELOG.md`; the diff changes each, and `docs/skills.md` and `docs/handoff.md` were read by the implementer and by this pass and state nothing the change contradicts. The changed pages and skills are in the present tense with no "now", "no longer" or issue number outside the CHANGELOG (grep over the added lines of `docs/home-checkout.md`, `docs/release-checklist.md`, `skills/` and the overlays: none). The plan names no wiki page and none is configured. No diagram changed.

**Independent review** (opus, `QC review:`; given the acceptance criteria and the range, not the implementer's account). Its assessment, in plain text: ready to merge with fixes; no Critical or Important issue; every criterion met. It checked each new claim against the scripts, ran `scripts/doctor.sh` without `jq`, and copied the four test files to a worktree at the base commit, where they fail (cleanup-skill 7 failures, close-removal 3, close-skill 9, readme 5) and pass at head.

**Findings.** All are `/codeo:implement`'s (the text says something true on one path only), none blocks the merge, and none was fixed here.

- F1 (blocking in round 1) — fixed by `bf71167`: the conflict with `origin/main` in `CHANGELOG.md` and `docs/release-checklist.md`.
- F2 — non-blocking, `/codeo:implement`'s: `docs/release-checklist.md:90-92` says the UTC date "can be the day after the engineer's local date"; that holds west of UTC only, and east of it the UTC date can be the day before. Fix: "can differ by a day from the engineer's local date".
- F3 — non-blocking, `/codeo:implement`'s: `skills/close/SKILL.md:550-552`. `git ls-remote --heads` prints `<sha>` and `refs/heads/codeo-live/…`, but the allowlist is worded on the name `codeo-live/<issue>/…`; a literal reader could skip every line (say to drop the `refs/heads/` prefix first). "print one … per branch it printed" also reads against the next clause, which skips names outside the set (say "per branch that passes").
- F4 — non-blocking, `/codeo:implement`'s: `.codeo/overlays/cleanup.md:12`, `close.md:11` and `docs/home-checkout.md:66` give "only when `codeo-track.sh` sits beside it" as the condition; `CODEO_TRACK` (`.sbx/codeo-sandbox.sh:22`) also supplies the tracker, and the new sandbox sentence in `home-checkout.md` does not say that with no tracker nothing is asked.
- F5 — non-blocking, `/codeo:implement`'s: `docs/home-checkout.md:9` says `live.sh` is "skipping the assignee lookup"; `assignee_label` still runs `gh` and only the `jq` parse fails, so the lookup yields nothing. It matters only for a web session whose `GET /user` failed.
- F6 — non-blocking, `/codeo:implement`'s: `skills/cleanup/SKILL.md:84` says an issue that failed only `name` "gets one" `leftover` line; it gets one only while origin still holds `codeo-live/<N>/*` branches (`scripts/cleanup.sh:13`). Also a stray comma at `CHANGELOG.md:30` ("on record, is listed").

No issue was filed by this pass. F2-F6 stay in this dossier for `/codeo:triage`.

**Verdict: clear — forward to `/codeo:close`.**

## Log

- 2026-11-25 — round 1: stopped at step 2, conflict with origin/main (#173) in CHANGELOG.md and docs/release-checklist.md; back to /codeo:implement · cost: 0m · opus-5-5 267k in + 26k cached / 601 out
- 2026-11-25 — qc round 2: build and suite passed, 8/8 criteria met, round 1's F1 fixed, review no Critical or Important, F2-F6 non-blocking; clear, forward to /codeo:close · cost: 4m · opus-5-5 410k in + 3.6M cached / 15k out · sonnet-5-5 324k in + 1.8M cached / 2k out
