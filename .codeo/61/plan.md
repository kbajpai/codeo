# Issue #61 — plan

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/61 |
| Branch | `chore/release-v1-0-4-main` |
| Updated | 2026-11-14 |

## Where this stands

Q1-Q3 raised, waiting for answers. Nothing is drafted yet.

What exploration found, which shapes the questions:
- **The release change is two files.** `.claude-plugin/plugin.json` `version` `1.0.3` → `1.0.4`, and `CHANGELOG.md`'s `## Unreleased` retitled `## v1.0.4 — <date>`. The v1.0.3 release (PR #33, branch `release/v1.0.3`) changed exactly those two files. No test reads the version or the changelog heading, and `README.md` names no version.
- **The pin change is one line.** `.codeo/config.json` `plugin.ref` `v1.0.3` → `v1.0.4`. `tests/devcontainer.test.sh` checks only that the ref is a well-formed string, so no test edit is needed. `.devcontainer/scripts/plugins.sh` reinstalls codeo when the pin differs from the installed ref, and first checks the pin exists on GitHub, so the tag must exist before the pin moves.
- **This workflow has one branch, and the issue needs two pull requests.** `/codeo:close` opens one pull request per workflow, from this branch. Q1 is how the two map.
- **`main` requires two checks, `tests` and `qc-verdict`.** `qc-verdict` passes a pull request whose diff holds no archived dossier (`no archived dossier in this PR`), which is how #33 and #35 merged. It fails a pull request whose head carries a live dossier, so a release pull request cannot be opened from this branch before `/codeo:close` archives the dossier.
- **Since v1.0.3 the shipped plugin changed in five files:** `scripts/board.sh`, `skills/init/SKILL.md`, `skills/plan/SKILL.md`, `docs/dossier.md`, `docs/handoff.md`. The dossier change is a rule, not a format: a footprint written after a send-back must cover every file the branch still changes. `overlap.sh --outside` already existed in v1.0.3. Q3 is whether `Shared state: unchanged from v1.0.3.` still holds.
- **The v1.0.3 GitHub Release** is titled `release: v1.0.3`; its body is the changelog section followed by GitHub's generated notes.
- **This container runs codeo 1.0.3** (`claude plugin list`). No other workflow is in flight, so there is no footprint overlap to raise.

Decisions taken without a question (correct any of them in an answer):
- The release date in the changelog heading is the day the release pull request is opened. If it merges on a later day, the heading is corrected before merge.
- The changelog bullets are released as they stand. #35 and #58 have no bullet because they changed nothing a project installs.
- The tag push and the GitHub Release are the engineer's (intake). The plan gives the exact commands: `git tag v1.0.4 <merged commit> && git push origin v1.0.4`, then `gh release create v1.0.4 --verify-tag --title "release: v1.0.4"` with the changelog section as notes plus generated notes, as v1.0.3 has.
- Criterion 6's check writes the board. It runs on #61 itself: `board.sh set 61 ready`, then `board.sh set 61 inProgress` to put the card back. Both are lowercase keys the old script rejects.
- The container rebuild is the engineer's; the check after it runs in a new session.
- No documentation page moves: the release checklist is out of scope by the issue, and no page names a version.

## Questions

### Q1 — How do the two pull requests map onto this one workflow branch?

**Why it matters:** it decides which change this branch carries, who opens the other pull request, and how many of the six criteria `/codeo:qc` can check before `/codeo:close`.

- **A. Release PR from its own branch, pin PR from this branch.** `/codeo:implement` cuts `release/v1.0.4` from `main` (two files, no dossier, as `release/v1.0.3` was) and opens that pull request itself. The workflow then waits: you merge it, tag, and publish the Release. After that this branch gets the pin change, you rebuild this container, and criterion 6 is checked here. `/codeo:qc` can then check criteria 1-4 and 6 as facts, and `/codeo:close` opens the pin pull request, which carries the plan and the dossier. Cost: `/codeo:implement` opens a pull request (normally `/codeo:close`'s job) and stops mid-plan for your merge and tag.
- **B. Release PR from this branch, pin PR outside the workflow.** This branch carries the two-file release change and `/codeo:close` opens it. Criteria 2-6 can only happen after that merge, so `/codeo:qc` marks them `not yet checkable`, and the pin change, the rebuild and the board check happen after the workflow has closed, with no dossier recording them.
- **C. Something else.**

I recommend A: every criterion gets checked and recorded inside the workflow, and the release pull request stays as small as #33.

**Options:** A · B · C (say what).

**Answer:**
A (engineer, 2026-11-14, in the conversation)

### Q2 — Who runs the clean-clone test of the merged commit?

**Why it matters:** `docs/release-checklist.md` says nothing in it is done by an agent, and the test gates your tag. The answer decides whether the plan has a task that runs it or a step that waits for your output.

- **A. The agent runs it** in a fresh `mktemp -d` clone at the merged commit, records the commit and the last line in `implement.md`, and you tag after reading it. You can still run your own.
- **B. You run it** and paste the last line; the plan waits and records it as your output.

I recommend A: it leaves command and output in the dossier for `/codeo:qc`, and the tag stays yours either way.

**Options:** A · B.

**Answer:**
A (engineer, 2026-11-14, in the conversation)

### Q3 — Does `Shared state: unchanged from v1.0.3.` stay as written?

**Why it matters:** it is the line a project reads before bumping mid-workflow, and the release PR either keeps it or rewrites it. Since v1.0.3 no dossier form changed and no script reads anything new. One rule changed (#39): a `plan.md` footprint written after a send-back must cover every file the branch still changes. A project mid-workflow with a footprint written under the old rule will see `overlap.sh --outside` name the missing paths at its next re-plan, and nowhere else.

- **A. Keep the line.** The third bullet already describes the footprint rule.
- **B. Keep "unchanged" and add a sentence** to the header: `A footprint written after a send-back now covers the whole branch; see the #39 entry.`
- **C. Reword it yourself** (give the text).

I recommend A: the forms are unchanged, which is what the line has meant in every earlier release.

**Options:** A · B · C.

**Answer:**
A (engineer, 2026-11-14, in the conversation)

## Notes

`superpowers:brainstorming` ran before these questions. The plan overlays `plan-shape`, `proof-of-done` and `wiki-rules` are not set (exit 3), so the generic shape and the default proof apply. No invariants document, no shared environment, no `wiki` module and no exclusive resources are configured.

### Footprint

```
files:      .claude-plugin/plugin.json, CHANGELOG.md, .codeo/config.json, docs/plans/2026-11-14-release-v1-0-4.md, .codeo/61/**
wiki:       none
exclusive:  none
```

## Outcome

_Pending — written at the hand-off._

## Log

- 2026-11-14 — Q1-Q3 raised · cost: 2m · fable-5-2 81k in + 614k cached / 6k out
