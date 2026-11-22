# Issue #146 — plan

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/146 |
| Branch | `feat/release-v1-0-8-once` |
| Updated | 2026-11-22 |

## Where this stands

Q1-Q3 are answered: the #118 bullet moves to `## v1.0.8`, the README examples (and the install test stubs they are compared with) move to v1.0.8 in the release PR, and the `Config schema` line names `issue.priority`. The release PR is therefore four files, not two. The draft plan is at `.codeo/146/plan-draft.md`, awaiting the engineer's approval.

What exploration found:
- **The gate is met.** #143, #144, #145, #138, #149 and #151 all read `CLOSED` / `COMPLETED`, and each merged to `main`. `origin/main` is at `6ccd510`, 16 commits past `v1.0.7` (`7b25bc2`).
- **Each gating issue has its bullet under `## Unreleased`** (criterion 2): #151 (line 9), #138 (lines 11 and 21), #145 (line 13), #144 (line 15), #143 (line 23), #149 (line 31). The section holds 12 bullets, which also cover #102, #108, #112, #122, #126, #131 (with #123, #125) and #133.
- **The release change is two files**, as in #100: `.claude-plugin/plugin.json` `version` `1.0.7` → `1.0.8`, and `CHANGELOG.md:3` `## Unreleased` → `## v1.0.8 — <date>`. Q1 and Q2 may each add to that.
- **A bullet is in the wrong section (Q1).** #118 merged after the `v1.0.7` tag (`9f14461`), and its bullet landed under `## v1.0.7` (line 56), the outcome #100's plan warned about. The tag's own `CHANGELOG.md` has 18 bullets in that section; `main` has 19.
- **The README names `v1.0.7` in its recorded installer output (Q2).** #151 added about 25 such lines, a `"ref": "v1.0.7"` JSON snippet (line 130) and a `marketplace add kbajpai/codeo@v1.0.7` example (line 441). `tests/install.test.sh` compares the snippet with what `install.sh` writes for a stubbed `v1.0.7` tag.
- **The header lines (Q3).** `Config schema: 1` is true: the config's `schema` is 1 and `issue.priority` is optional. `Shared state:` names the branch-name shape, the `sandbox:` lock key, the `unassigned:<N>` ledger rows and the `codeo-live/<issue>/<machine>` branches, which is every shared-state change I found in the diff since `v1.0.7` (`scripts/lock.sh`, `scripts/live.sh`, `scripts/inflight.sh`, `scripts/dossier-check.sh`, `docs/dossier.md`). `install.sh` writes only the machine's own Claude settings. `issue.priority` is named in two bullets but not in the header.
- **No other workflow is in flight**: `inflight.sh --except 146` prints `no other workflow in flight`, so there is no overlap question.
- **No test breaks at the retitle**: the changelog tests grep the whole file for bullets by content, and none reads `## Unreleased` or `plugin.json`'s version.
- **The pin change is one line**: `.codeo/config.json` `plugin.ref` `v1.0.7` → `v1.0.8`.

Decisions taken without a question, all as #100 did them (correct any of them in an answer):
- Two pull requests. The release PR comes from its own branch `release/v1.0.8`, cut from `origin/main` in a git worktree and opened by `/codeo:implement`, because the required `qc-verdict` check fails a head that carries a live dossier. This branch carries the pin, the plan and the dossier, and `/codeo:close` opens its PR after the tag exists.
- `main` is released as it stands when the release PR is opened. The release task re-reads `## Unreleased` first, in case `main` moved.
- The changelog date is the day the release PR is opened, corrected before merge if it merges on a later day.
- The agent runs the clean-clone test at the merge commit and records it in `implement.md`.
- You merge both PRs, and you tag and push with single commands; the tag is lightweight, `git tag v1.0.8 <merge commit>`, as v1.0.5 to v1.0.7 are. The agent never merges or tags.
- The agent publishes the GitHub Release once you say the tag is pushed, in the checklist's step 8 form: `gh release create v1.0.8 --verify-tag --title v1.0.8 --notes-file <the section>`, no generated notes.
- Criterion 8 is checked with `claude plugin list` in a session started after you rebuild or restart this container.
- #132 (tests only, merged as `1fc1005`) has no changelog bullet and gets none: it changed two test files and nothing a user of the plugin sees, and it is not a gating issue.
- The blank lines between the `## Unreleased` bullets stay; earlier sections have none, and the difference is cosmetic.

## Questions

### Q1 — #118's bullet sits under `## v1.0.7`, but v1.0.7 does not contain #118. Move it to `## v1.0.8` in the release PR?

**Why it matters:** #118 merged after the `v1.0.7` tag, so its change (live-signal tests and docs) ships first in v1.0.8. On `main` its bullet is the last line of `## v1.0.7` (`CHANGELOG.md:56`, "Leftovers from the live signal work, documentation and tests only…"). The v1.0.7 GitHub Release notes, made from the tag, do not have it. If it moves, the release PR's changelog diff is the retitle plus one bullet moved, the `## v1.0.7` section matches its tag and its Release again, and the v1.0.8 Release notes carry the bullet. If it stays, the release PR is the retitle alone and the changelog goes on crediting #118 to a version that lacks it.

I recommend *move it*: the issue asks for a changelog accurate for everything merged since v1.0.7, and this is one line.

**Options:** move it to `## v1.0.8` · leave it under `## v1.0.7`.

**Answer:**
Move it to `## v1.0.8` (engineer, by the question tool in the conversation, 2026-11-22; recorded here by the skill).

### Q2 — The README's examples say `v1.0.7`. Update them to `v1.0.8` in the release PR, or leave them?

**Why it matters:** `README.md` shows recorded installer output that names the release (`install: release v1.0.7`, `codeo v1.0.6 -> v1.0.7`, about 25 lines), the project settings snippet with `"ref": "v1.0.7"`, and `claude plugin marketplace add kbajpai/codeo@v1.0.7`. Once v1.0.8 is tagged, a first-time reader who runs the install command sees `v1.0.8` where the README shows `v1.0.7`. Updating them adds `README.md` and `tests/install.test.sh` to the release PR (the test compares the snippet with the installer's output for a stubbed `v1.0.7` tag, so the stub or the snippet check changes with it), edits output that was recorded from real runs, and has to be repeated at every release. The issue says the release PR sets the version in `plugin.json` only, and changing the release checklist is out of scope. Leaving them keeps the release PR to the two files and treats the output as an example of a run.

I recommend *leave them*: the lines are examples of what a run prints, the text above them already says the latest release is the highest `vX.Y.Z` tag, and v1.0.7 never contained `install.sh` anyway, so no README version would make every example literally reproducible. If the stale number bothers you, the durable fix is a separate issue (a placeholder version in the examples), which I would file with `/codeo:issue`.

**Options:** leave them · update them to `v1.0.8` in the release PR · leave them and file an issue for placeholder versions.

**Answer:**
Update them to `v1.0.8` in the release PR (engineer, by the question tool in the conversation, 2026-11-22; recorded here by the skill).

### Q3 — Should a header line of the v1.0.8 section name the new optional `issue.priority` key?

**Why it matters:** the issue asks that the `Config schema`, `Shared state` and `Safe to bump mid-workflow` lines stay accurate "including the new optional `issue.priority` key". Today the header reads `Config schema: 1` with nothing after it, as in every earlier release, and the key is described in two bullets (#102, #145). The schema number is still 1 and a config without the key behaves as before, so the line is true as written. Naming the key there means the release PR also edits line 5, to `Config schema: 1 (adds the optional `issue.priority` key; a config without it is unchanged)`. No script or test reads that line.

I recommend *name it on the line*: the issue singles the key out, a reader deciding whether to bump looks at the header first, and it costs one clause.

**Options:** name it on the `Config schema` line · leave `Config schema: 1` as it is, the bullets say it.

**Answer:**
Name it on the `Config schema` line (engineer, by the question tool in the conversation, 2026-11-22; recorded here by the skill).

## Notes

`superpowers:brainstorming` ran before these questions. The plan overlays `plan-shape`, `proof-of-done` and `wiki-rules` are not set (exit 3), so the generic shape and the default proof apply. No invariants document, no shared environment, no `wiki` module and no exclusive resources are configured. The role check (`role.sh --check plan`) exited 0.

Intended shape: one plan under `docs/plans/` (`2026-11-22-release-v1-0-8.md`), modelled on `docs/plans/2026-11-18-release-v1-0-7.md`; no reference doc, since nothing is a standing decision.

### Footprint

```
files:      .claude-plugin/plugin.json, CHANGELOG.md, README.md, tests/install.test.sh, .codeo/config.json, docs/plans/2026-11-22-release-v1-0-8.md, .codeo/146/**
wiki:       none
exclusive:  none
sequenced:  none
```

## Outcome

_Pending — written at the hand-off._

## Log

- 2026-11-22 — Q1-Q3 raised · cost: 2m · fable-5-2 96k in + 1M cached / 8k out
- 2026-11-22 — Q1-Q3 answered; draft written for the review gate · cost: 6m · fable-5-2 119k in + 2.1M cached / 26k out
