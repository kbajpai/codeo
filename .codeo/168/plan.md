# Issue #168 — plan

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/168 |
| Branch | `feat/release-v1-0-9-once` |
| Updated | 2026-11-25 |

## Where this stands

Q1-Q2 are answered and the plan is approved and written to `docs/plans/2026-11-25-release-v1-0-9.md` (unstaged). The footprint is under `## Notes`; `overlap.sh` runs next, then the outcome.

What exploration found:
- **The gate is met.** #163 and #166 both read `CLOSED`, and each merged to `main` (`24577ac`, `6b3fb6e`). `origin/main` is at `24577ac`, 7 commits past `v1.0.8` (`ee0c020`).
- **Each gating issue has its bullet under `## Unreleased`** (criterion 2). The section holds 12 bullets, which also cover #152, #154 and #157.
- **The release change is four files**, as in #146 and as `docs/release-checklist.md` step 6 now says: `plugin.json`'s `version`, the `CHANGELOG.md` heading, and the version numbers in `README.md` and `tests/install.test.sh`.
- **Two stub tag lists already hold `v1.0.9` (Q1).** `tests/install.test.sh:236` (`t_latest_is_highest_release`) and `:520` (`t_latest_installed_without_version`). A blind `1.0.8` → `1.0.9` makes them list one tag twice.
- **#161 has no bullet (Q2).** It merged after v1.0.8 as #167, documentation only; `init.md` says it sits under `## Unreleased`, and it does not.
- **The header lines stay as written.** The plugin's script diff since `v1.0.8` is `scripts/cleanup.sh`, `scripts/inflight.sh` (6 lines) and `scripts/live.sh`; the `Shared state:` line already names the tracking comment, the `codeo-live` sweep and `refs/codeo/live-web/*`.
- **No other workflow is in flight**: `inflight.sh --except 168` prints `no other workflow in flight`. No pull request is open. #170, #171 and #173 were filed after #168 and ship later.
- **No test breaks at the retitle**: none reads `## Unreleased` or `plugin.json`'s version.
- **Dry-run** on a copy of `24577ac`: the substitution leaves no `1.0.7` in either file and the two stubs unchanged, and `bash tests/install.test.sh` ends `all cases passed`. The whole suite needs a git checkout, so Task 1 runs it in the worktree.

Decisions taken without a question, all as #146 did them: two pull requests, the release PR from `release/v1.0.9` cut from `origin/main` in a worktree; `main` is released as it stands; the date is the day the release PR opens; the tag is lightweight; the engineer merges, tags and rebuilds; the agent runs the clean-clone test and publishes the Release on the engineer's say-so.

## Questions

### Q1 — Two stub tag lists in `tests/install.test.sh` already hold `v1.0.9`. How should the version substitution treat them?

**Why it matters:** the release PR moves `README.md` and `tests/install.test.sh` one version up (`1.0.8` → `1.0.9`, `1.0.7` → `1.0.8`). Lines 236 and 520 list `v1.0.9` beside `v1.0.8`, so a blind substitution leaves line 520 with two identical tags and line 236 with `v1.0.9` twice: both tests pass and check less. Skipping the two functions keeps the lists as they are, which is what #173 says of the ordering stubs. Shifting them too (`1.0.10` → `1.0.11`, `1.0.9` → `1.0.10` first) keeps the tests' meaning and moves the stubs at every release. All three were dry-run and the install test passed.

**Options:** skip the two stubs · shift them too · blind substitution.

**Answer:**
Skip the two stubs (engineer, by the question tool in the conversation, 2026-11-25; recorded here by the skill).

### Q2 — #161 merged after v1.0.8 and has no bullet under `## Unreleased`. Add one to the v1.0.9 section in the release PR?

**Why it matters:** with a bullet the changelog edit is the retitle plus one line and the Release notes carry 13 bullets; without one it is the retitle alone. #161 is not a gating issue and changed no script or skill (the `.devcontainer/README.md` flowchart and wording, the v1.0.8 `Shared state:` line, release checklist step 6). #118 and #112, documentation only, got bullets; #132, tests only, got none. Open issue #173 already owns the missing bullet for the `SessionStart` hook #161 added and the wording fixes to the same text.

**Options:** no bullet · add one short bullet.

**Answer:**
No bullet (engineer, by the question tool in the conversation, 2026-11-25; recorded here by the skill).

## Notes

`superpowers:brainstorming` ran before these questions and `superpowers:writing-plans` before the plan was written. The session was in plan mode, so the questions were asked with the question tool and the draft was reviewed as the plan-mode file, not as `plan-draft.md`; this file was first written after the approval. The plan overlays `plan-shape`, `proof-of-done` and `wiki-rules` are not set (exit 3), so the generic shape and the default proof apply. No invariants document, no shared environment, no `wiki` module and no exclusive resources are configured. The role check (`role.sh --check plan`) exited 0. Steps 6 and 7 of the skill did not apply: no new component and no architectural choice.

### Footprint

```
files:      .claude-plugin/plugin.json, CHANGELOG.md, README.md, tests/install.test.sh, .codeo/config.json, docs/plans/2026-11-25-release-v1-0-9.md, .codeo/168/**
wiki:       none
exclusive:  none
sequenced:  none
```

## Outcome

_Pending — written at the hand-off._

## Log
