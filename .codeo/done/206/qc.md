# Issue #206 — qc

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/206 |
| Branch | `fix/206-codeo-cleanup-prints-codeo-rm` |
| Updated | 2026-11-27 |

## Where this stands

Round 2, done: clear, forward to `/codeo:close`. The build and the full `shell` suite pass on the merged tree, all seven criteria are met, F1-F7 of round 1 are closed, and the round's independent review found no blocking defect. Its non-blocking findings are recorded below and routed as follow-ups. Next step: `/codeo:close`.

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
- Follow-up promised, not filed (the role check refuses `/codeo:issue` in this checkout): `docs/dossier.md`'s intake paragraphs (about lines 118-127) and the comment at `scripts/intake.sh:90-91` give "every writer owns a directory no other writer touches" as the reason a rebuilt push is safe, and say nothing of `commit` adding and updating only; the reason is now that `commit` never deletes a file its clone lacks. File it with `/codeo:issue` in the home checkout.
- Follow-up promised, not filed: widen the placeholder pattern in `scripts/cleanup.sh` so a token with `-` or `.` inside the braces (`{issue-number}`) is refused too, without refusing `{a,b}` or `{{.Names}}`, and say how a branch-side delete of a removal record is done (`intake.sh commit cleanup --drop` re-adds a file a clone still holds).

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

### Round 2 — 2026-11-27

**Commands run** (this pass, on the tree after the merge of `origin/main` at `f8aa6f9`; HEAD `ae7608b`):
- `bash .devcontainer/scripts/role.sh --check qc` → exit 0; lock `issue: 206`, branch `fix/206-codeo-cleanup-prints-codeo-rm`; clean tree.
- `bash .../sync-main.sh --abort-on-conflict` → `sync-main: the branch already contains origin/main`.
- `bash .../overlap.sh 206` → nothing (#204's `tests/intake.test.sh` was raised as Q1 of `implement.md` and answered); `bash .../overlap.sh --outside 206` → nothing, so every changed path is in the plan's round-2 footprint.
- `bash .../scope.sh origin/main HEAD` → `suite.shell=true` (unclassified paths: `.codeo/206/*.md`, `CHANGELOG.md`, `README.md`).
- `qc/invariants-extra` and `qc/wiki-rules` overlay points → exit 3 each (none); no invariants file, environment or `wiki` module.
- Build: the `shell` suite's `build` is `true` → exit 0.
- Suite: `bash tests/run.sh` → exit 0, last line `all cases passed`.

**Criteria** (`init.md`):

| Criterion | Verdict | Settled by |
|---|---|---|
| With the project's current overlay, no printed line contains `{` or `}` | met | `tests/cleanup-skill.test.sh` runs the project overlay and the rendered template and requires a `proven` line with no brace; suite passes |
| An overlay whose command keeps a placeholder the script does not expand exits non-zero with a `cleanup:` line, or it is expanded; a test pins it | met | `tests/cleanup.test.sh` cases for `{M}`, `{issue}`, `${HOME}`, `{{N}}` (named `{1}`), `x-{M}` through `{name}`, and `{{.Names}}`/`{a,b}` printed as written; `scripts/cleanup.sh` placeholder block |
| After an issue's removal is recorded, a later run does not list it as proven or not proven | met | `tests/cleanup.test.sh`: `a recorded issue that passes is not listed` (stdout and the stderr note) |
| An issue whose proof fails is listed as not proven whether or not a removal was recorded | met | `tests/cleanup.test.sh`: `a recorded issue whose proof fails …` and `… whose only failure is name …` |
| Two engineers recording removals do not lose each other's entries on merge | met | `tests/cleanup.test.sh` `two engineers keep each other's records` (clone B records before clone A commits; both files on origin) and `a clone that never restored does not delete records`; `tests/intake.test.sh` `commit_keeps_files_the_clone_lacks`; `scripts/intake.sh` `build` adds with `--ignore-removal` |
| `skills/cleanup/SKILL.md`, `docs/skills.md` and the README describe how to record a removal | met | `skills/cleanup/SKILL.md` step 3, `docs/skills.md` `## cleanup`, `README.md` (the `role stale` entry and the skills table row); pinned in `tests/cleanup-skill.test.sh` |
| The full suite passes | met | `bash tests/run.sh` → `all cases passed`, exit 0 |

**Round 1's findings.**
- F1 (blocking in round 1) — fixed by `98e257b` (`intake.sh commit` adds with `--ignore-removal`), `9d0f40d` (the overlapping and never-restored cases are tested; `record` no longer restores).
- F2 (blocking in round 1) — fixed by `b76c549`: `docs/skills.md` says there is no undo command and a clone that still holds the file adds it back.
- F3 (non-blocking in round 1) — fixed by `723abc7`: the check judges the expanded text.
- F4-F7 (non-blocking in round 1) — fixed by `b76c549`, each pinned in `tests/cleanup-skill.test.sh`.

**Documentation check.** The pages the diff changes (`docs/skills.md`, `docs/extension-points.md`, `README.md`, `skills/cleanup/SKILL.md`) describe the new behaviour in present tense; a search of the added lines for "now", "no longer", "used to" and issue numbers found none outside `CHANGELOG.md`, where they are allowed. `CHANGELOG.md`'s `Shared state:` line joins this change's clause with the one `origin/main` brought in. The `docs/dossier.md` gap round 1's `implement.md` reported is G1 below.

**Independent review** (opus, handed the criteria and the diff only), in plain text: no critical finding; "ready to merge: with fixes", its one Important finding being the rationale sentence in G1. Classified here; none blocks the merge.

**Findings**
- **G1 — non-blocking, `/codeo:plan`'s.** `scripts/intake.sh:90-91` and `docs/dossier.md:126-127` give "every writer owns a directory no other writer touches" as the reason a rebuilt push is safe; with several engineers writing `cleanup/` that was never the reason, and the reason is now that `commit` never deletes a file its clone lacks. `docs/dossier.md:118-121` does not say that `commit` only adds and updates. The behaviour is correct and no data is at risk; the statement is a rationale, which is why this does not block. The `docs/dossier.md` half is outside the plan's footprint, so a new plan round would be needed; carried as a follow-up in `## Notes`.
- **G2 — non-blocking, `/codeo:plan`'s.** The placeholder pattern `\{[A-Za-z0-9_]+\}` (`scripts/cleanup.sh`) does not match a token with `-`, `.` or a space inside the braces, so `command: codeo rm {issue-number}` prints unexpanded and exits 0. Round 2 of the plan chose that pattern and the docs state it; follow-up in `## Notes`.
- **G3 — non-blocking, `/codeo:implement`'s.** `docs/extension-points.md` (the `cleanup/removal-command` section) says `{{N}}` "prints as `{1}`"; the run is refused, and `{1}` appears only in the error message because the check expands with sample number 1.
- **G4 — non-blocking, `/codeo:implement`'s.** The README skills-table row says "it stops listing them", and the stderr note says recorded issues "are not listed"; a recorded issue still prints its `leftover` line while branches remain, and one that fails a proof is still listed. `docs/skills.md` and the skill state both correctly.
- **G5 — non-blocking, `/codeo:implement`'s.** The `scripts/intake.sh` header says `commit` puts the directory "as it stands in the working tree" and the next sentence says it only adds and updates; the first sentence needs the same qualifier.
- **G6 — non-blocking, `/codeo:plan`'s.** The documented correction (delete the record from the intake branch and from every clone) names no command for the branch-side delete; `intake.sh commit cleanup --drop <path>` re-adds the file in the same build while a clone still holds it. Follow-up in `## Notes`.
- **Declined by the reviewer, not findings of this change:** two same-day run records overwrite each other (pre-existing); a clone with an older `intake.sh` still deletes (documented in `CHANGELOG.md`); `${HOME}` refused (a documented design choice).

No `/codeo:issue` was filed: the role check refuses it in this checkout, so the two follow-ups are promised under `## Notes`.

**Routing.** No blocking finding. G1-G6 are non-blocking and are carried as follow-ups; none sends the change back.

**Verdict: clear — forward to `/codeo:close`.**

## Log

- 2026-11-27 — round 1 stopped at step 2: Q1-Q2 raised (overlaps with #188 and #195) · cost: 0m · opus-5-5 236k in + 286k cached / 707 out
- 2026-11-27 — round 1: Q1-Q2 answered, build and suite run, 6 of 7 criteria met, independent review; back to /codeo:plan (F1, F2 blocking) · cost: 7m · opus-5-5 315k in + 1.6M cached / 12k out · sonnet-5-5 42k in + 2.8M cached / 5k out
- 2026-11-27 — round 2: build and full suite pass, 7 of 7 criteria met, F1-F7 closed, independent review; clear, forward to /codeo:close (G1-G6 non-blocking follow-ups) · cost: 5m · opus-5-5 479k in + 2.7M cached / 19k out · sonnet-5-5 28k in + 2.1M cached / 4k out
