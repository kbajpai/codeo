# Issue #213 — implement

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/213 |
| Branch | `feat/213-release-v1-0-11-main` |
| Updated | 2026-11-27 |

## Where this stands

Round 1 is **paused part-way** so the work can move to another container: Tasks 1-4 of `docs/plans/2026-11-27-release-v1-0-11.md` are done and reviewed, Tasks 5-6 are not started, and `## Outcome` is pending. Nothing is open (no question), and `overlap.sh 213` printed nothing.

**Where the code is.** The release PR's branch is `release/v1.0.11`, pushed to origin at `b04fffa` (no pull request yet). It is cut from `origin/main` at `3857710` and carries five commits, each of one of the plan's tasks, changing exactly `.claude-plugin/plugin.json`, `README.md`, `docs/updating.md` and `tests/install.test.sh`:

| Task | Commit(s) | Review |
|---|---|---|
| 1 version moves | `bcc384b` | clean |
| 2 README M1-M4 | `4d062df` | clean |
| 3 README M5, M8 | `0ace6f1` | clean |
| 4 README guard, identity, cleanup, M6, M7 | `2c40f44`, `b04fffa` | one fix round (two Important findings, both addressed and re-reviewed) |

`bash tests/install.test.sh` and `bash tests/readme.test.sh` ended `all cases passed` on every task's head; `bash tests/run.sh` has not been run on the branch yet (Task 6).

**To carry on from another checkout.** The release branch is an ordinary pushed branch; this feature branch holds only the plan and dossier.
1. Make a worktree of it (the plan's `../codeo-213-release` is not writable in the sandbox; any writable path will do): `git fetch origin`, then `git worktree add <path> release/v1.0.11`.
2. Resume `/codeo:implement` here with the plan's Task 5 (changelog), then Task 6 (`bash tests/run.sh`, `bash tests/readme.test.sh`, `git diff --name-only origin/main` must list exactly the five files, push, open the release PR). Do not redo Tasks 1-4.
3. Tasks 7, 9 and 12 are the engineer's (merge, tag, rebuild); 8, 10 and 11 follow them.

**Deferred Minor review findings (Task 4), for `/codeo:qc`'s and the final review's triage.** (a) The "Writes under `.codeo/` are exempt" sentence is exact for Edit and Write, but for git only when every path is under `.codeo/`. (b) The cleanup placeholder sentence sits at the end of the role-guard *Fix* bullet, though it is not a role-guard refusal. (c) The edit-guard paragraph sits between the entry's bold lead and its Symptom/Cause/Fix bullets, which breaks the entry's shape. (d) The `mismatch` example line holds only for skills that run in an issue's checkout; the home-kind skills print "runs in a home checkout". Task 2's review left two Minor notes (the long step 1 paragraph does not say which `ruleset` message appears when, and its `--containers` sentence omits that a fresh run also writes `codename` and the pin) and Task 3's one ("owns one dossier file" is slightly loose for init); none was acted on. Task 1's review had none.

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
