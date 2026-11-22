# Issue #146 — qc

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/146 |
| Branch | `feat/release-v1-0-8-once` |
| Updated | 2026-11-22 |

## Where this stands

Round 1 is written under `## Outcome`: the verdict is clear. Nothing is open; the next step is `/codeo:close`, which opens this branch's pull request (the pin) and meets criterion 7 when it merges. Three non-blocking findings are recorded below.

## Questions

None.

## Notes

Later work, not filed because `/codeo:issue` runs only in the home container and the role check refused it here (`/codeo:issue runs in the home container, but this container's role is issue:146`); `/codeo:triage` collects these once the dossier is archived:
- File an issue for the v1.0.8 `Shared state:` line, which omits two dossier-reading changes (F1). The tag is pushed, so the repair is `gh release edit v1.0.8 --notes-file <the section>` for the Release notes and a changelog line on `main` that then differs from the tag's copy; the engineer decides whether either is worth doing.
- File an issue for `docs/release-checklist.md` step 6, which says to set the version "in `.claude-plugin/plugin.json` only" and does not mention that the README's installer examples and `tests/install.test.sh`'s stubs name the latest release and need the same one-version move (F2).

No invariants document, no further rules (`invariants-extra` and `wiki-rules` exit 3), no shared environment, no `wiki` module and no exclusive resources are configured, so steps 6 and 9 had nothing further to apply.

## Outcome

### Round 1 — 2026-11-22

**Sync and scope.** `sync-main.sh --abort-on-conflict`: `sync-main: the branch already contains origin/main`. `overlap.sh 146` printed nothing (exit 0). `overlap.sh --outside 146` printed nothing (exit 0). `git diff origin/main...HEAD --stat`: six files, the dossiers `.codeo/146/{implement,init,issue,plan}.md`, `.codeo/config.json` and `docs/plans/2026-11-22-release-v1-0-8.md`. `scope.sh origin/main HEAD`:

```
scope: suite shell needed for unclassified paths:
  .codeo/146/implement.md
  .codeo/146/init.md
  .codeo/146/issue.md
  .codeo/146/plan.md
  .codeo/config.json
suite.shell=true
```

**Build.** The `shell` suite's build command is `true`; it exited 0.

**Suites.** `bash tests/run.sh` on this branch at `45de9d4ce5672c96baa8e2fe986323d3f3a9a1b8`: `all cases passed`, exit 0, no `FAIL` line. A second run, in a fresh clone of https://github.com/kbajpai/codeo.git checked out at `ee0c02069817ffffde4a884c420ded16b76ee4f2` (`git rev-parse HEAD` prints that SHA, `.claude-plugin/plugin.json` says `1.0.8`): `all cases passed`, exit 0, no `FAIL` line.

**Acceptance criteria.**

| # | Criterion | Verdict | Settled by |
|---|---|---|---|
| 1 | #143, #144, #145, #138, #149, #151 closed before the release PR is opened | met | `gh issue view`: all six `CLOSED`, the last (#151) at 2026-11-22T15:35:58Z; PR #158 was created at 17:21:41Z |
| 2 | `## v1.0.8` has an entry for each gating issue | met | on `origin/main`, `awk` over the `## v1.0.8` section counts bullets mentioning #143=1, #144=1, #145=1, #138=2, #149=1, #151=1; 13 bullets in all |
| 3 | `plugin.json` says `1.0.8`, `## v1.0.8 — <date>` replaces `## Unreleased`, merged through a PR | met | `origin/main`: `plugin.json` `1.0.8`, line 3 `## v1.0.8 — 2026-11-22`, no `## Unreleased`; PR #158 `MERGED` at 17:51:20Z as `ee0c020`, files exactly `.claude-plugin/plugin.json`, `CHANGELOG.md`, `README.md`, `tests/install.test.sh` |
| 4 | `bash tests/run.sh` in a clean clone of the merged commit ends `all cases passed` | met | this pass's clean-clone run above |
| 5 | `git ls-remote --tags origin` lists `v1.0.8` at that commit | met | `ee0c02069817ffffde4a884c420ded16b76ee4f2	refs/tags/v1.0.8`; no `^{}` line; `git cat-file -t v1.0.8` is `commit` |
| 6 | `gh release view v1.0.8` shows a release | met | `v1.0.8	v1.0.8	false	false` (tag, title, draft, prerelease); its body equals the tag's `## v1.0.8` section but for one trailing blank line |
| 7 | `plugin.ref` is `v1.0.8`, merged through its own PR | not yet checkable — the pin is on this branch (`.codeo/config.json` `v1.0.8`; `origin/main` still `v1.0.7`), and its pull request is `/codeo:close`'s to open | `jq -r .plugin.ref .codeo/config.json` |
| 8 | After a rebuild, the installed plugin reports v1.0.8 | met | `claude plugin list`: `codeo@codeo` `Version: 1.0.8` at user scope and at project scope, both enabled |

**Documentation check.** The change moves one page, `README.md`: on `origin/main` its examples name `v1.0.8` as the latest release (27 lines) and `v1.0.7` only as the older version in the downgrade and "no longer installed" examples; `tests/install.test.sh` passes against them. No page under `docs/` (outside `docs/plans/`) names a version or the pin. The plan's claim that no other page moves holds.

**Independent review** (opus, given the criteria only). No critical findings; assessment "Yes, with a fix", the fix being F1. It re-ran the clean-clone suite (`all cases passed`) and re-checked the tag, the Release, the pin and the installed plugin against GitHub and this container. It checked the header lines' claims against the scripts: the `sandbox:` lock key, `unassigned:<N>` rows, the `codeo-live/*` namespace.

**Findings**
- F1 — non-blocking, the plan's: the `Shared state:` line (`CHANGELOG.md:6`) leaves out two things that ship in v1.0.8, both verified here against `v1.0.7..origin/main`. `scripts/dossier-check.sh`, `scripts/inflight.sh` and `scripts/qc-verdict.sh` now match `## Outcome` exactly, so `## Outcomes` and `## Outcome notes` no longer count as an outcome (`docs/dossier.md` says so), and `scripts/lock.sh` gains a reader of the `### Round <n> — stashed|abandoned` headings (`is_parked`, used by the web hook under `CODEO_LOCK_SKIP_PARKED=1`). `docs/release-checklist.md` step 6 says the line must name every dossier convention a script reads back. The plan declared the line checked and left it as written. Not blocking: the skills write `## Outcome` exactly, so `Safe to bump mid-workflow: yes` still holds, and the tag is pushed and never moved, so nothing on this branch can change the line. The Release notes can be repaired with `gh release edit v1.0.8 --notes-file <the section>`, the engineer's call (see Notes).
- F2 — non-blocking, outside this change: `docs/release-checklist.md` step 6 does not mention that a release now also moves the README's and the install test's version examples (see Notes). The issue puts changing the checklist out of scope.
- F3 — non-blocking, the plan's dossier text only: `plan.md`'s exploration notes still say "The release change is two files", which its `## Outcome` corrects to four. Not edited here.

No finding is blocking; no issue was filed for this pass (the role check refused `/codeo:issue`; the later work is in `## Notes`). No shared environment is configured, so there is no lease to check or release.

**Verdict: clear — forward to `/codeo:close`.**

## Log

- 2026-11-22 — Round 1: build ok; shell suite passed on this branch and in a clean clone of the merge commit; criteria 1-6 and 8 met, 7 left to close's PR; review clear with three non-blocking findings; verdict clear · cost: 11m · opus-5-5 401k in + 3.5M cached / 17k out · sonnet-5-5 212k in + 1.7M cached / 4k out
