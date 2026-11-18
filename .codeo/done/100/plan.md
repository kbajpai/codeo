# Issue #100 — plan

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/100 |
| Branch | `chore/release-v1-0-7-once` |
| Updated | 2026-11-18 |

## Where this stands

Q1 is answered (proceed and coordinate). The draft plan is at `.codeo/100/plan-draft.md`, awaiting the engineer's approval.

What exploration found:
- **The gate is met.** #70, #71, #96, #97, #98 and #99 all read `CLOSED` / `COMPLETED`.
- **The release change is two files**, as in #75: `.claude-plugin/plugin.json` `version` `1.0.6` → `1.0.7`, and `CHANGELOG.md:3` `## Unreleased` → `## v1.0.7 — <date>`. `origin/main` is at `2dabf1f`, 19 commits past `v1.0.6`; `## Unreleased` holds 18 bullets.
- **Each of the five gating issues has its bullet** (criterion 2): #70 (line 18), #71 (line 10), #96 (line 21, which names #96's collected issues #40, #54, #81, #88, #91, and line 22 names "#96's QC"), #97 (line 20), #98 (line 19). #99 has lines 8-9.
- **The three header lines read as accurate.** `Config schema: 1` (the config's `schema` is 1). `Shared state:` names the two additions, `.codeo/intake/cleanup/` and `refs/codeo/live/<issue>/<machine>`, and says no dossier convention changed: `docs/dossier.md`'s only changes since `v1.0.6` are wording, and `dossier-check.sh` at v1.0.6 already required the `sequenced:` key. `Safe to bump mid-workflow: yes`.
- **The pin change is one line**: `.codeo/config.json` `plugin.ref` `v1.0.6` → `v1.0.7`.
- **The release checklist gained step 8 since v1.0.6**: the GitHub Release is titled `vX.Y.Z`, its notes are the changelog section only, and `--generate-notes` is never passed. The five earlier Releases are titled `release: vX.Y.Z`, and v1.0.6's has generated notes appended (#75 QC F1).
- **One other workflow is in flight**: #118, which declares `CHANGELOG.md`. Q1.
- **No test breaks at the retitle**: the changelog tests read the whole file (#107), and `tests/sandbox.test.sh`'s line-9 check is unaffected because the retitle moves no line.

Decisions taken without a question (correct any of them in an answer):
- Two pull requests, as #75: the release PR comes from its own branch `release/v1.0.7`, cut from `origin/main` in a git worktree and opened by `/codeo:implement`, because the required `qc-verdict` check fails a head that carries a live dossier. This branch carries the pin, the plan and the dossier, and `/codeo:close` opens its PR after the tag exists.
- `main` is released as it stands when the release PR is opened, #99 included (init's scope decision). The bullets and the three header lines are released as written; the release task re-reads `## Unreleased` first, in case `main` moved.
- The changelog date is the day the release PR is opened, corrected before merge if it merges on a later day.
- The agent runs the clean-clone test at the merge commit and records it in `implement.md`.
- You tag and push, with single commands; the tag is lightweight, `git tag v1.0.7 <merge commit>`, as v1.0.5 and v1.0.6 are. The agent never merges or tags.
- The agent publishes the GitHub Release once you say the tag is pushed (as #75 Q3 = A), in the checklist's step 8 form: `gh release create v1.0.7 --verify-tag --title v1.0.7 --notes-file <the section>`, no generated notes. The title therefore differs from the earlier `release: vX.Y.Z` ones; the earlier Releases are not retitled.
- Criterion 8 is checked with `claude plugin list` in a session started after you rebuild or restart this container.
- No documentation page moves: the only pages naming `1.0.6` are `docs/dev-environment-sbx-evaluation.md`'s recorded observations, which stay as observed, and changing the release checklist is out of scope by the issue.

## Questions

### Q1 — #118 also changes `CHANGELOG.md`. Release now, or after #118 merges?

**Why it matters:** #118 (branch `feat/live-signal-leftovers-104-refresh`, assignee kbajpai, step `plan (working)`; its plan is written and its build has not started) lists `CHANGELOG.md` in its footprint (`glob:CHANGELOG.md`) and will add one bullet under `## Unreleased`. Its branch has not touched the file yet. The release PR retitles that heading. If the release merges first and #118 then adds its bullet under the first heading it finds, the bullet lands under `## v1.0.7`, a version that does not contain it. The answer decides whether the plan waits for #118 or carries a note saying what #118 must do.

- **Proceed and coordinate.** Do not wait. `main` is released as it stands when the release PR is opened. If #118 happens to merge before that, its bullet ships in v1.0.7 (a merged commit cannot be left out of the tag); otherwise #118 writes its bullet under a new `## Unreleased` above `## v1.0.7`. This plan cannot edit #118's branch: the release PR body and this plan's outcome carry the note, and #118's own changelog task already starts with `sync-main.sh`.
- **Sequence after #118.** The release PR is not opened until #118 has merged, so its bullet ships in v1.0.7 and nothing needs moving. This holds the release for #118's whole build and review, and the issue fixed the list this release waits for.
- **Re-scope.** Something else (say what).

I recommend *proceed and coordinate*: #118 has not started building, and the issue chose not to wait for later work.

**Options:** proceed and coordinate · sequence after #118 · re-scope.

**Answer:**
Proceed and coordinate (engineer, in the conversation, 2026-11-18: "go with the recommended, proceed and coordinate"; recorded here by the skill).

## Notes

`superpowers:brainstorming` ran before this question. The plan overlays `plan-shape`, `proof-of-done` and `wiki-rules` are not set (exit 3), so the generic shape and the default proof apply. No invariants document, no shared environment, no `wiki` module and no exclusive resources are configured.

`inflight.sh --except 100` printed one workflow, #118. The only path shared with it is `CHANGELOG.md`.

Intended shape: one plan under `docs/plans/` (`2026-11-18-release-v1-0-7.md`), modelled on `docs/plans/2026-11-14-release-v1-0-6.md`; no reference doc, since nothing is a standing decision.

## Outcome

| | |
|---|---|
| Plan | `docs/plans/2026-11-18-release-v1-0-7.md` (unstaged, approved 2026-11-18) |
| Shape | Plan under `docs/plans/`; no reference doc, since nothing is a standing decision |

**Decisions.** Two pull requests: the release PR comes from `release/v1.0.7`, cut from `origin/main` in a worktree and opened by `/codeo:implement`, because `qc-verdict` fails a head carrying a live dossier; this branch carries the pin and the dossier. `main` is released as it stands, #99 included (init's scope decision). #118 also changes `CHANGELOG.md` and is not waited for (Q1 = proceed and coordinate): if it merges after the release PR opens, it writes its bullet under a new `## Unreleased` above `## v1.0.7`, which the release PR body says. You merge, tag (lightweight, `git tag v1.0.7 <SHA>`) and push with single commands; the agent runs the clean-clone test, publishes the GitHub Release in checklist step 8 form (title `v1.0.7`, changelog section only, no generated notes) after you say the tag is pushed, and checks the version after your rebuild. The changelog's three header lines stay as written, checked at planning.

**Rejected.** Waiting for #118 (Q1). Re-titling the earlier `release: vX.Y.Z` Releases. Generated release notes.

**Documentation pages the plan changes:** none. `docs/dev-environment-sbx-evaluation.md` names `1.0.6` only as recorded observations.

**Risk for `/codeo:qc`.** Criteria 3-6 and 8 depend on your merge, tag and rebuild; criterion 7 is met when `/codeo:close`'s PR merges. Task 7 records a project-scope `codeo@codeo` entry that does not report 1.0.7 as a finding. Criterion 1 and 2 are re-read at Task 1 in case `main` moved.

### Footprint

```
files:      .claude-plugin/plugin.json, CHANGELOG.md, .codeo/config.json, docs/plans/2026-11-18-release-v1-0-7.md, .codeo/100/**
wiki:       none
exclusive:  none
sequenced:  none
```

## Log

- 2026-11-18 — Q1 raised · cost: 2m · fable-5-2 82k in + 661k cached / 6k out
- 2026-11-18 — Q1 answered, draft approved; planned: docs/plans/2026-11-18-release-v1-0-7.md · cost: 9m · fable-5-2 88k in + 990k cached / 11k out · sonnet-5-5 93k in + 489k cached / 9k out
