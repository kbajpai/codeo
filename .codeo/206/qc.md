# Issue #206 — qc

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/206 |
| Branch | `fix/206-codeo-cleanup-prints-codeo-rm` |
| Updated | 2026-11-27 |

## Where this stands

Round 1, done: back to `/codeo:plan`. Q1 and Q2 are answered (proceed and coordinate). The build and the full suite pass, six of seven criteria are met, and the criterion "two engineers recording removals do not lose each other's entries" is not met: the design the plan chose for it cannot meet it. Next step: `/codeo:plan`.

## Questions

### Q1 — #188 overlaps on `skills/cleanup/SKILL.md`, `tests/cleanup-skill.test.sh` and `CHANGELOG.md`: proceed, sequence, or re-scope?

**Why it matters:** #188 (`docs/188-close-177-qc-leftovers-utc`, assignee kbajpai, step `qc`, sent back to `/codeo:plan` in its round 1) has already changed three files this branch also changes. `overlap.sh` printed `#188` with each of `CHANGELOG.md`, `glob:CHANGELOG.md`, `skills/cleanup/SKILL.md`, `glob:skills/cleanup/SKILL.md`, `tests/cleanup-skill.test.sh` and `glob:tests/cleanup-skill.test.sh`. #188's diff in those files is small (2, 3 and 3 lines), against 17, 19 and 3 lines here. It also changes `.codeo/overlays/cleanup.md` and `templates/containers/.codeo/overlays/cleanup.md`, which this branch does not change, but `tests/cleanup-skill.test.sh` here pins both as brace-free and as printing a `proven` line. Whichever branch merges second runs `sync-main.sh` and resolves a likely conflict in the cleanup skill and its test. If #188's overlay edit adds a brace or an unknown placeholder, this branch's pin fails at that point.

- Proceed and coordinate: both go on. The second to merge resolves the overlap at its sync, and its `/codeo:qc` re-runs the cleanup tests on the merged tree.
- Sequence after #188: this branch waits until #188 merges, then syncs and re-runs `/codeo:qc`. #188 is back at `/codeo:plan`, so the wait is open-ended.
- Re-scope: no part of this change can move out of those files without dropping an acceptance criterion.

I recommend proceeding and coordinating.

**Options:** proceed and coordinate (recommended) · sequence after #188 · re-scope.

**Answer:**
Proceed and coordinate, as recommended. Given in the conversation: "go with your picks".

### Q2 — #195 overlaps on `tests/cleanup-skill.test.sh` and `tests/cleanup.test.sh`: proceed, sequence, or re-scope?

**Why it matters:** #195 (`feat/195-identify-acting-user-strictly-verify`, assignee kbajpai, step `qc`, sent back to `/codeo:plan` in its round 1) declares `tests/**` in its footprint. `overlap.sh` printed `#195` with `tests/cleanup-skill.test.sh` and `tests/cleanup.test.sh`. Neither file is on the list of files #195's branch has changed, so the overlap is its declared glob only. `plan.md` Q7 and Q9 already settled the other paths shared with #195.

**Options:** proceed and coordinate (recommended) · sequence after #195 · re-scope.

**Answer:**
Proceed and coordinate, as recommended. Given in the conversation: "go with your picks".

## Notes

- `scope.sh origin/main HEAD` printed `suite.shell=true`. Its unclassified paths were `.codeo/206/implement.md`, `.codeo/206/init.md`, `.codeo/206/issue.md`, `.codeo/206/plan.md`, `CHANGELOG.md` and `README.md`.
- No environment, invariants file or `wiki` module is configured. `models.reviewer` is unset, so the reviewer runs on opus.

## Outcome

### Round 1 — 2026-11-27

**Commands run** (this pass):
- `bash .../sync-main.sh --abort-on-conflict` → `sync-main: the branch already contains origin/main`.
- `bash .../overlap.sh 206` → no new overlap after Q1-Q2; `overlap.sh --outside 206` → nothing, so every changed path is in the plan's footprint.
- `bash .../scope.sh origin/main HEAD` → `suite.shell=true` (unclassified paths: `.codeo/206/*.md`, `CHANGELOG.md`, `README.md`).
- Build: the `shell` suite's `build` is `true` → exit 0.
- Suite: `bash tests/run.sh` → `all cases passed`, exit 0.
- No environment, invariants file or wiki module is configured; no environment step.

**Criteria** (`init.md`):

| Criterion | Verdict | Settled by |
|---|---|---|
| With the project's current overlay, no printed line contains `{` or `}` | met | `tests/cleanup-skill.test.sh`: the overlay's and the template's printed lines hold no brace and are `proven` lines |
| An overlay whose command keeps a placeholder the script does not expand exits non-zero with a `cleanup:` line, or it is expanded; a test pins it | met, with F3 | `tests/cleanup.test.sh`: `an unexpanded placeholder in the command stops the run`, `… in the fallback …`, `a shell brace and a Go template are not placeholders`; `scripts/cleanup.sh:114-123` |
| After an issue's removal is recorded, a later run does not list it as proven or not proven | met | `tests/cleanup.test.sh`: `a recorded issue that passes is not listed`; `scripts/cleanup.sh:183-198` |
| An issue whose proof fails is listed as not proven whether or not a removal was recorded | met | `tests/cleanup.test.sh`: `a recorded issue whose proof fails …`, `… whose only failure is name …` |
| Two engineers recording removals do not lose each other's entries on merge | not met | F1: the record and the commit overlap case loses a record; `tests/cleanup.test.sh` `two engineers keep each other's records` runs the two clones one after the other only |
| `skills/cleanup/SKILL.md`, `docs/skills.md` and the README describe how to record a removal | met, with F2 | `skills/cleanup/SKILL.md` step 3, `docs/skills.md` `## cleanup`, `README.md`; pinned in `tests/cleanup-skill.test.sh` |
| The full suite passes | met | `bash tests/run.sh` → `all cases passed` |

**Documentation check.** The pages the diff changes describe the new behaviour in present tense with no issue numbers or history words. Two statements are untrue as written (F2 and F3's `docs/extension-points.md:593` overclaim), and the plan file's Q2 premise ("`intake.sh commit` keeps other clones' files") is wrong, as `implement.md` records. Nothing else moves a page: `.devcontainer/README.md` and `docs/container-templates.md` still say what the code does.

**Independent review** (opus, handed the criteria and the diff only): not ready to merge, for F1 and F2 below; quoted in plain text, its findings are classified here.

**Root cause of F1** (`superpowers:systematic-debugging`, Phase 1 only). `scripts/intake.sh` `build` reads origin's tip into a private index and then runs `git add -f -- .codeo/intake/cleanup`; with git 2.x a directory pathspec also stages the deletion of every file under it that this clone's working tree lacks (confirmed on git 2.53.0: a tree with `a/1`, `a/2` and a working tree holding `a/1`, `a/3` stages `D a/2`, `A a/3`). So a commit replaces the directory with the committing clone's working tree. `cleanup.sh record` restores origin's files once, before it writes; a record another engineer pushes between that restore and this clone's commit is deleted, and `intake.sh commit`'s retry after a refused push rebuilds on the newer tip from the same working tree, which deletes it reliably. The skill's run-record commit (step 3) has the same property for every clone that restored only at step 0. The plan chose "one file per issue, no change to `intake.sh`" on the premise that `commit` only adds; that premise is false.

**Findings**

- **F1 — blocking, `/codeo:plan`'s.** Two engineers lose each other's removal records when their commits overlap (`scripts/cleanup.sh:81-94`, `scripts/intake.sh:159-185,280-301`). The code does what the plan says; the plan's design cannot meet the criterion. The fix needs a design decision the plan did not make and a file outside its footprint: `scripts/intake.sh` (and `tests/intake.test.sh`), for example a commit that adds only the files under `removed/` it holds, a union merge on the retry as `merge_ledger` does for triage, or a restore inside `commit`'s retry loop. `scripts/intake.sh:176-177` carries a comment ("a dossier absent from this clone is one it never restored, not one to delete") that the git behaviour above contradicts. The test must run the two commits overlapping, not one after the other.
- **F2 — blocking, `/codeo:plan`'s.** The documented undo is untrue (`docs/skills.md:257`: "delete `.codeo/intake/cleanup/removed/<N>.md` from `codeo/intake` by hand"): any clone that recorded or restored the file still holds it, and its next `intake.sh commit cleanup` (the skill's run-record commit does this every run) adds it back, and `record <N>` there answers `already recorded` (`scripts/cleanup.sh:86`). It follows from the same design as F1; the replan decides how a record is removed, or stops promising an undo.
- **F3 — non-blocking, `/codeo:plan`'s.** The placeholder check and the expansion disagree for unusual overlays (`scripts/cleanup.sh:115-123` against `:160-167`): `command: rm {{N}}` checks as `{}` and prints `rm {12}`; `{{N}name}` prints `{12name}`; `name:` is never checked, so `name: x-{M}` with a permissive `pattern:` puts `{M}` into the printed command. `docs/extension-points.md:593` says any other `{word}` token stops the run, which is too strong. The plan's rule (remove `{N}` and `{name}`, then look for leftovers) is what the code does; checking the expanded text, and `name:` too, is the fix, small enough to ride the re-plan.
- **F4 — non-blocking, `/codeo:implement`'s.** `skills/cleanup/SKILL.md:84` still ends step 3's first paragraph with "Nothing else is written.", and the paragraph after it writes and commits `removed/<N>.md`.
- **F5 — non-blocking, `/codeo:implement`'s.** `scripts/cleanup.sh:13` says a `leftover` line comes "right after a proven line, or a `failed name` line"; for a hidden recorded issue it prints alone (line 30 says so); `skills/cleanup/SKILL.md:47` has the same "right after its own" wording.
- **F6 — non-blocking, `/codeo:implement`'s.** The skill's Hand-off `Reads` list (`skills/cleanup/SKILL.md:107-108`) does not name `origin/codeo/intake`'s `removed/` listing; `docs/skills.md` does.
- **F7 — non-blocking, `/codeo:implement`'s.** `README.md:498`: "so the next run does not list the issue again" omits that a recorded issue that fails a proof is listed.
- **Pre-existing, not a finding of this change:** the dated run records under `.codeo/intake/cleanup/` are deleted by a stale clone's commit by the same mechanism; the plan's replan may fix both with the one `intake.sh` change.
- **Parked from `implement.md`, not blocking:** a failed `restore` ignored silently (subsumed by F1's fix); no test for `record ""` or `record 0`; the refusal test checks only `12.md`; no pin for the restore-first sentence.

No `/codeo:issue` was filed.

**Routing.** F1 is blocking and is the plan's: the design for criterion 5 must change and needs `scripts/intake.sh` in the footprint. F2 goes with it. F3-F7 are non-blocking and are carried by the re-plan's tasks.

**Verdict: back to `/codeo:plan`.**

## Log

- 2026-11-27 — round 1 stopped at step 2: Q1-Q2 raised (overlaps with #188 and #195) · cost: 0m · opus-5-5 236k in + 286k cached / 707 out
- 2026-11-27 — round 1: Q1-Q2 answered, build and suite run, 6 of 7 criteria met, independent review; back to /codeo:plan (F1, F2 blocking) · cost: 7m · opus-5-5 315k in + 1.6M cached / 12k out · sonnet-5-5 42k in + 2.8M cached / 5k out
