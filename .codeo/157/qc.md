# Issue #157 — qc

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/157 |
| Branch | `fix/live-session-signal-leftovers-138` |
| Updated | 2026-11-23 |

## Where this stands

Round 1 is written and the verdict is back to `/codeo:plan`: one blocking finding (F1), and the plan's design for the saved label missed that `SessionEnd` runs `clear`. Nothing is open.

## Questions

None.

## Notes

None.

## Outcome

### Round 1 — 2026-11-23

**Sync and scope.** `sync-main.sh --abort-on-conflict`: `the branch already contains origin/main`, exit 0. `overlap.sh 157` and `overlap.sh --outside 157` printed nothing. `git diff origin/main...HEAD --stat`: 17 files, 706 insertions, 45 deletions (scripts, skills, docs, tests, the plan, dossiers). `scope.sh origin/main HEAD`: `suite.shell=true` (`suite shell needed for unclassified paths: .codeo/157/*, CHANGELOG.md`). No `deploy=` line: no environment is configured.

**Build.** Suite `shell`, build `true`: exit 0.

**Suites.** `bash tests/run.sh`: `all cases passed`, exit 0.

**Acceptance criteria**

| # | Criterion | Verdict | Settled by |
|---|---|---|---|
| 1 | Both refs on origin: `live.sh fetch` exits 0, no `live: unknown` for that cause, a test reproduces it | met | `tests/live.test.sh` `fetch_survives_a_web_and_a_container_signal_with_equal_labels` (fetch exit 0, `list` shows two rows); `inflight.sh` turns only a failed `live.sh fetch` into `unknown` (reviewer; not driven end to end by a test, F3) |
| 2 | After close no `codeo-live/<issue>/*` remains, or the docs say how to remove one | met | `live.sh sweep` run by `/codeo:close` step 16 (tests in `tests/live.test.sh`, `tests/close-skill.test.sh`); `docs/handoff.md:173` gives `git push origin --delete codeo-live/<issue>/<machine>`; `/codeo:cleanup` prints it |
| 3 | The web-signal docs name the CI trigger on every beat | met | `docs/handoff.md:173` names `on: push` for all branches, `[skip ci]` and excluding `codeo-live/**`; pinned in `tests/live-signal.test.sh` |
| 4 | A session whose id changes between two beats shows as one row, or the docs say it can show twice for up to the TTL | met — for two beats in one running session (label file, `tests/live.test.sh` label-stability case); the docs overclaim for a session that ends in between (F1) | `scripts/live.sh:139-143`; `docs/handoff.md:209` |

**Documentation.** `docs/handoff.md`, `docs/skills.md` and `CHANGELOG.md` are changed and describe the system in the present tense. Two gaps: F1 (the claim of one row) and F4 below. No wiki module and no documentation-rules overlay.

**Independent review** (Opus, given the criteria only): one Important, four Minor; it found sound the quoting and injection filters in `sweep` and `leftover_proof`, the namespace split with `--prune`, the sweep's lock and web-host guards, and the saved-label validation. Verbatim classification is mine, below.

**Findings**

- F1 — blocking, `/codeo:plan`'s: `scripts/live.sh:228` makes `clear` remove the saved label, and `hooks/live-signal.sh:52-53` runs `clear` on every `SessionEnd`, web included (a web `clear` leaves the branch on origin). A web session that beats as `web-01Sa1Zqc`, ends, and resumes in the same checkout under another id beats as `web-01Sa1Zqb`: two rows for up to the TTL, when the lock's `session` is `unknown` or differs. `docs/handoff.md:209` and the CHANGELOG say such a session "shows as one row" and admit the duplicate only for a new checkout. I confirmed the two lines above; the resume scenario is the reviewer's. The code does what the plan says (the label lives until `clear`), and the plan did not see that `clear` also runs at session end, so the fix is a plan decision: keep the label past `SessionEnd` and drop it only at `/codeo:close`, or leave the code and state the session-end duplicate in the docs.
- F2 — non-blocking, plan's: `CHANGELOG.md` lines 6-7 (`Shared state: … no other state changes`, `Safe to bump mid-workflow: yes`) are untrue now that `/codeo:close` deletes origin branches, readers use `refs/codeo/live-web/`, and a reader on the old plugin keeps the old refspec and still aborts on the collision until it updates.
- F3 — non-blocking, plan's: no test runs `inflight.sh --live` against the collision; the fetch test stands for it.
- F4 — non-blocking, plan's: `docs/skills.md:252-262` still opens `cleanup` as "removes finished issues' dev containers" and its reads-and-writes list omits the `refs/remotes/origin/codeo-live/<N>/*` listing.
- F5 — non-blocking, plan's: `docs/handoff.md:173` does not say that each new web branch also fires a `create` event, which `[skip ci]` does not suppress; excluding `codeo-live/**` is already the sure way it recommends.

No issue was filed from this pass.

**Verdict: back to `/codeo:plan`.**

## Log

- 2026-11-23 — Round 1: build ok; shell suite passed; criteria 1-4 met with F1 against 4's docs; review one Important, four Minor; verdict back to plan · cost: 9m · opus-5-5 75k in + 417k cached / 9k out · sonnet-5-5 96k in + 798k cached / 2k out
