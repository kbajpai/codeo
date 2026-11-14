# Issue #75 — plan

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/75 |
| Branch | `chore/release-v1-0-6-main` |
| Updated | 2026-11-14 |

## Where this stands

Q1-Q4 answered (engineer accepted every recommendation, 2026-11-14). Draft written to `.codeo/75/plan-draft.md` and presented for approval; the plan file under `docs/plans/` is written only after it.

What exploration found, which shapes the questions:
- **The release change is two files**, as in #62 and #65: `.claude-plugin/plugin.json` `version` `1.0.5` → `1.0.6`, and `CHANGELOG.md:3` `## Unreleased` → `## v1.0.6 — <date>`. `origin/main` is at `2a86915`; `## Unreleased` holds two bullets (#67, #69).
- **The pin change is one line**: `.codeo/config.json` `plugin.ref` `v1.0.5` → `v1.0.6`.
- **Two other workflows declare `CHANGELOG.md`**: #51 (at `qc`) and #52 (at `plan`, sequenced after #51). #51's branch already adds a third bullet under `## Unreleased`. Q1 and Q2.
- **v1.0.5 differs from v1.0.3 and v1.0.4 in two ways.** Its tag is lightweight (`git ls-remote --tags origin` shows no `v1.0.5^{}` line), which is what `docs/release-checklist.md` step 7 writes. And it has no GitHub Release: `gh release list` shows v1.0.4, v1.0.3, v1.0.2 and v1.0.0 only, and `gh release view v1.0.5` prints `release not found`. Q3 and Q4.
- **This container runs codeo 1.0.5** for both the user-scope and the project-scope entry of `claude plugin list`. The lock says `host: container`.
- **Since v1.0.5 no dossier form changed**: `docs/dossier.md` is untouched, and the new `Runs on: the engineer's host` line (#69) is written in plan documents, which no script reads back.

Decisions taken without a question (correct any of them in an answer):
- Two pull requests, mapped as #61 did (intake Q3 names it): the release PR comes from its own branch `release/v1.0.6`, cut from `origin/main` in a git worktree and opened by `/codeo:implement`, because the required `qc-verdict` check fails a head that carries a live dossier. This branch carries the pin, the plan and the dossier, and `/codeo:close` opens its PR after the tag exists.
- The agent runs the clean-clone test at the merge commit and records it in `implement.md` (as #61 Q2).
- `Config schema: 1`, `Shared state: unchanged from v1.0.5.` and `Safe to bump mid-workflow: yes` stay as written. The bullets are released as they stand.
- The changelog date is the day the release PR is opened, corrected before merge if it merges on a later day.
- The tag is lightweight, `git tag v1.0.6 <merge commit>`, as the checklist writes it and as v1.0.5 is. Criterion 3 then reads directly off `git ls-remote --tags origin`. (#61 used an annotated tag; say so if you want that again.)
- Both merges, the tag push and the container rebuild are yours. The plan has wait tasks for them. The agent never merges or tags.
- Criterion 6 is checked with `claude plugin list` in a session started after the rebuild.
- No documentation page moves: no page names a version, and changing the release checklist is out of scope by the issue.

## Questions

### Q1 — #51 also changes `CHANGELOG.md`. Release now, or after #51 merges?

**Why it matters:** #51 (`feat/seed-dev-container-git-identity`, assignee kbajpai, step `qc`) adds a third bullet under `## Unreleased` in `CHANGELOG.md`. The release PR retitles that heading on line 3. The two edits are far enough apart that git merges them without a conflict, so if the release merges first and #51 then merges `main`, #51's bullet lands silently under `## v1.0.6`, a version that does not contain it. The answer decides whether the plan waits for #51 or carries a step that tells you what #51 must do.

- **Proceed and coordinate.** Release `main` as it is when the release PR is opened (intake Q2). If #51 has not merged by then, #51 must move its bullet into a new `## Unreleased` block above `## v1.0.6` when it next takes `main`. This plan cannot edit #51's branch; it records the note in its outcome and in the release PR body, and the move is yours or #51's `/codeo:qc`.
- **Sequence after #51.** The release PR is not opened until #51 has merged. Its bullet ships in v1.0.6 and nothing needs moving. This waits for open work, which intake Q2 chose not to do.
- **Re-scope.** Something else (say what).

I recommend *proceed and coordinate* if #51 still has review rounds ahead of it, and *sequence after #51* if its merge is minutes away: the second removes the silent-merge risk entirely.

**Options:** proceed and coordinate · sequence after #51 · re-scope.

**Answer:**
Proceed and coordinate (engineer: "accept all your recommendations", 2026-11-14). #51's latest QC verdict is back to `/codeo:implement` with no PR open, so its merge is not minutes away.

### Q2 — #52 also declares `CHANGELOG.md`. Same treatment?

**Why it matters:** #52 (`feat/run-codeo-latest-claude-models`, assignee kbajpai, step `plan`) lists `CHANGELOG.md` in its footprint and is already sequenced after #51. Its branch has not changed the file yet, so there is nothing to mis-merge today. If the release merges first, #52 must write its bullet under a new `## Unreleased`, not under `## v1.0.6`. The answer decides whether this release waits for #52 as well.

- **Proceed and coordinate.** Do not wait. #52 adds its bullet to whatever `## Unreleased` exists when it gets there, creating the block if the release removed it.
- **Sequence after #52.** Hold the release until #52 has merged, which also means after #51.
- **Re-scope.** Something else (say what).

I recommend *proceed and coordinate*: #52 is only at `plan`, and waiting for it would hold the release for its whole build.

**Options:** proceed and coordinate · sequence after #52 · re-scope.

**Answer:**
Proceed and coordinate (engineer: "accept all your recommendations", 2026-11-14).

### Q3 — Who publishes the GitHub Release, and where do you run the tag commands?

**Why it matters:** it decides the form of the tag-and-release task. The Release was a manual step after v1.0.5's tag and it did not happen. The lock says this checkout is a container, and the plan rule shipping in this release (#69) says commands you run on your own machine must be single commands that any shell passes through unchanged. Building the release notes from the changelog needs `awk` and a redirect, which is not that.

- **A. You tag, the agent publishes the Release.** You run two one-line commands, in any shell and from any clone: `git tag v1.0.6 <merge commit>` and `git push origin v1.0.6`. Once you say it is done, the agent verifies the tag names the merge commit, extracts the `## v1.0.6` changelog section and runs `gh release create v1.0.6 --verify-tag --title "release: v1.0.6" --notes-file <section> --generate-notes`, as v1.0.4's Release was built. The agent publishes something public on your say-so here.
- **B. You do both in this container's terminal (bash)**, as in #61. The plan gives the bash commands, `awk` included, and the agent only verifies afterwards.
- **C. You do both on your own machine.** Say which shell. The Release then uses `--generate-notes` alone, or a notes file you paste, because the agent's file is inside the container.

I recommend A: the tag stays yours, as the issue requires, and the step that was missed last time no longer depends on memory.

**Options:** A · B · C (name the shell).

**Answer:**
A — you tag, the agent publishes the Release (engineer: "accept all your recommendations", 2026-11-14).

### Q4 — v1.0.5 has no GitHub Release. What should happen to that?

**Why it matters:** the issue asks for a Release "as for earlier releases", and v1.0.5 is the one earlier release without one. It is outside this issue's six criteria. The answer decides whether the plan gains a step, a new issue gets filed, or nothing changes.

- **A. Add it to this plan** as one more step in the tag-and-release task: `gh release create v1.0.5 --verify-tag --title "release: v1.0.5"` with the `## v1.0.5` changelog section as notes, run by whoever Q3 names. It widens the issue's scope by one command.
- **B. File it as its own issue** through `/codeo:issue`, and leave this plan alone.
- **C. Leave it.** v1.0.5 stays without a Release.

I recommend A: it is one command, in the same task and by the same hand, and a separate issue costs more than the fix.

**Options:** A · B · C.

**Answer:**
A — add v1.0.5's Release to this plan (engineer: "accept all your recommendations", 2026-11-14).

## Notes

`superpowers:brainstorming` ran before these questions. The plan overlays `plan-shape`, `proof-of-done` and `wiki-rules` are not set (exit 3), so the generic shape and the default proof apply. No invariants document, no shared environment, no `wiki` module and no exclusive resources are configured.

`inflight.sh --except 75` printed two workflows, #51 and #52. The only path shared with either is `CHANGELOG.md`.

### Footprint

```
files:      .claude-plugin/plugin.json, CHANGELOG.md, .codeo/config.json, docs/plans/2026-11-14-release-v1-0-6.md, .codeo/75/**
wiki:       none
exclusive:  none
sequenced:  none (CHANGELOG.md shared with #51 and #52: proceed and coordinate, Q1-Q2)
```

## Outcome

_Pending — written at the hand-off._

## Log

- 2026-11-14 — Q1-Q4 raised · cost: 2m · fable-5-2 78k in + 316k cached / 8k out
- 2026-11-14 — Q1-Q4 answered, draft presented for review · cost: 1m · sonnet-5-5 7k in + 344k cached / 8k out
