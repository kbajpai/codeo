# Issue #213 — implement

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/213 |
| Branch | `feat/213-release-v1-0-11-main` |
| Updated | 2026-11-27 |

## Where this stands

Round 1 is **waiting on you (Task 7)**: Tasks 1-6 of `docs/plans/2026-11-27-release-v1-0-11.md` are done and reviewed, and the release pull request is open: https://github.com/kbajpai/codeo/pull/214 (`release/v1.0.11` into `main`, head `b277022`). Tasks 8-12 follow your merge. `## Outcome` stays pending until the whole plan is built. Nothing is open (no question), and `overlap.sh 213` printed nothing.

**The release branch** is cut from `origin/main` at `3857710` and changes exactly `.claude-plugin/plugin.json`, `CHANGELOG.md`, `README.md`, `docs/updating.md` and `tests/install.test.sh`:

| Task | Commit(s) | Review |
|---|---|---|
| 1 version moves | `bcc384b` | clean |
| 2 README M1-M4 | `4d062df` | clean |
| 3 README M5, M8 | `0ace6f1` | clean |
| 4 README guard, identity, cleanup, M6, M7 | `2c40f44`, `b04fffa` | one fix round (two Important findings, both addressed and re-reviewed) |
| 5 changelog | `b277022` | clean |
| 6 suite and release PR | pull request #214 | checked by the controller (below) |

**Task 6 checks, on head `b277022`:** `git diff --name-only origin/main` lists exactly the five files; `bash tests/readme.test.sh` and `bash tests/install.test.sh` end `all cases passed`; `bash tests/run.sh` ends `all cases passed` only with this sandbox's global gitignore switched off (`GIT_CONFIG_GLOBAL=/dev/null bash tests/run.sh`): that ignore lists `.sbx`, and `tests/sandbox.test.sh` runs `git add .sbx` in a temporary repository, which it refuses. Without the override only that one file fails, and it fails the same way on `origin/main`. The sandbox also lacked the `hostname` binary (live.test.sh), which was installed with apt. PR checks: `qc-verdict` passed; `tests` was pending when this was written.

**The changelog date** is `2026-11-27`, the UTC date the pull request opened (`2026-11-27T23:47:14Z`). `docs/release-checklist.md` says the heading carries the date the release pull request *opens*, so a merge after midnight UTC does not change it (the plan's Task 7 sentence about correcting it on a later merge day is superseded by the checklist).

**Next, in order:**
1. **You (Task 7):** merge #214 when `tests` and `qc-verdict` are green, then tell me.
2. **Me (Task 8):** read the merge commit SHA, clone, check out that SHA, and run `bash tests/run.sh` (with the same global-ignore caveat if it applies); the result must end `all cases passed`.
3. **You (Task 9):** `git fetch origin`, `git tag v1.0.11 <SHA>`, `git push origin v1.0.11`, one command at a time; then I run `git ls-remote --tags origin v1.0.11`.
4. **Me (Task 10):** `gh release create v1.0.11 --verify-tag --title v1.0.11 --notes-file <the changelog section>`.
5. **Me (Task 11):** set `plugin.ref` to `v1.0.11` in `.codeo/config.json` on this branch (`/codeo:close` opens that pull request).
6. **You (Task 12):** rebuild or restart the dev container, start a new session, and run `claude plugin list`: `codeo@codeo` must show `1.0.11`.

**Deferred Minor review findings, for `/codeo:qc`'s and the final review's triage.** Task 4: (a) the "Writes under `.codeo/` are exempt" sentence is exact for Edit and Write, but for git only when every path is under `.codeo/`; (b) the cleanup placeholder sentence sits at the end of the role-guard *Fix* bullet, though it is not a role-guard refusal; (c) the edit-guard paragraph sits between the entry's bold lead and its Symptom/Cause/Fix bullets, which breaks the entry's shape; (d) the `mismatch` example line holds only for skills that run in an issue's checkout. Task 2: the long step 1 paragraph does not say which `ruleset` message appears when, and its `--containers` sentence omits that a fresh run also writes `codename` and the pin. Task 3: "owns one dossier file" is slightly loose for init. Task 5: the #211 bullet is not in issue order (cosmetic). Task 1's review had none.

## Questions

None.

## Notes

**Deviation from the plan.** The plan's worktree `../codeo-213-release` is not creatable in the sandbox (`/Users/kbajpai/codeo` is root-owned), so Tasks 1-4 ran in `.superpowers/worktrees/release-v1.0.11` inside the checkout (git-ignored). Where the plan says `../codeo-213-release`, any worktree of `release/v1.0.11` serves.

**Rulings made at pre-flight** (the plan's grep expectations that did not match `main`):
- R1: Task 1's `grep -c 'v1.0.9.1\|v1.0.9;x' tests/install.test.sh` is at least 1, not 2 (both strings share a line).
- R2: Task 2's "`ruleset` is skipped" is in two places (Setting a project up step 1, and the Troubleshooting *config* entry); both were rewritten and the count is 0.
- R3, R4: the `--codename` and `intake` proofs are at least 5 and 3, since README already held 4 and 2.
- R5: Task 4's `mismatch` baseline is 2 (the lock text's "branch mismatch"), so the proof is at least 3.

**The plan's loose ends are unchanged** (the three `/codeo:triage` notes in `plan.md`). The review also turned up that `gh auth login` is not a remedy where `gh` authenticates from `GH_TOKEN`; that is the same finding as the doctor note in `plan.md` and adds nothing new.

## Outcome

_Pending — written at the hand-off._

## Log

- 2026-11-27 — round 1 paused after Tasks 1-4 (release branch `release/v1.0.11` pushed at `b04fffa`); Tasks 5-6 not started · cost: unavailable (the invocation spans a stop; the subagents' cost is not summed)
- 2026-11-27 — Tasks 5-6 done: changelog `b277022`; release pull request #214 opened; waiting for the merge (Task 7) · cost: unavailable (the invocation spans several stops; the subagents' cost is not summed)
