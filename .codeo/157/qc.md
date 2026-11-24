# Issue #157 — qc

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/157 |
| Branch | `fix/live-session-signal-leftovers-138` |
| Updated | 2026-11-24 |

## Where this stands

Round 3 is written and the verdict is clear: round 2's F6, F7 and F9 are fixed, all four criteria are met, and the review found two non-blocking gaps (F12, F13) in how `/codeo:close` reports and describes the web-session case. Nothing is open. Next step: `/codeo:close`.

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

### Round 2 — 2026-11-24

**Sync and scope.** `sync-main.sh --abort-on-conflict`: `the branch already contains origin/main`, exit 0. `overlap.sh 157` and `overlap.sh --outside 157` printed nothing. `git diff origin/main...HEAD --stat`: 20 files, 943 insertions, 48 deletions. `scope.sh origin/main HEAD`: `suite.shell=true` (`suite shell needed for unclassified paths: .codeo/157/*, CHANGELOG.md`). No `deploy=` line: no environment is configured.

**Build.** Suite `shell`, build `true`: exit 0.

**Suites.** `bash tests/run.sh`: `all cases passed`.

**Acceptance criteria**

| # | Criterion | Verdict | Settled by |
|---|---|---|---|
| 1 | Both refs on origin: `live.sh fetch` exits 0, no `live: unknown` for that cause, a test reproduces it | met | `tests/live.test.sh` `fetch_survives_a_web_and_a_container_signal_with_equal_labels`; `tests/inflight.test.sh` `live_survives_a_web_and_a_container_signal_with_equal_labels` runs `inflight.sh --live` with the real `live.sh` (exit 0, two rows, no `live:`) and failed with the old refspec |
| 2 | After close no `codeo-live/<issue>/*` remains, or the docs say how to remove one | met | `live.sh sweep` in `/codeo:close` step 16; `docs/handoff.md:173` gives `git push origin --delete codeo-live/<issue>/<machine>` |
| 3 | The web-signal docs name the CI trigger on every beat | met | `docs/handoff.md:173` names `on: push`, `[skip ci]`, the `create` event and excluding `codeo-live/**`; pinned in `tests/live-signal.test.sh` |
| 4 | A session whose id changes between two beats shows as one row, or the docs say it can show twice for up to the TTL | met | `tests/live.test.sh` `web_label_stays_when_the_session_id_changes` and `web_clear_keeps_the_label` (a `SessionEnd` between the beats); `docs/handoff.md:209` states the new-checkout case |

**Documentation.** Round 1's gaps are closed: the label sentence, the `create` event, the `cleanup` entry in `docs/skills.md` and the CHANGELOG header lines. New gaps: F6, F7, F9.

**Independent review** (Opus, given the criteria only): no Critical, one Important, five Minor; it found sound the fetch split and `--prune`, the sweep and `leftover_proof` input handling, the `[skip ci]` claims and every caller of `live.sh clear`.

**Findings**

- F1 (blocking in round 1) — fixed by `c6da81d`: `clear` keeps the saved web label; the test and the docs say so.
- F2 (non-blocking in round 1) — fixed by `4396240`: the CHANGELOG `Shared state` and `Safe to bump` lines.
- F3 (non-blocking in round 1) — fixed by `63eb330`: `inflight.sh --live` is tested against the collision.
- F4 (non-blocking in round 1) — fixed by `4396240`: the `cleanup` entry in `docs/skills.md`.
- F5 (non-blocking in round 1) — fixed by `4396240`: the `create` event.
- F6 — blocking, `/codeo:plan`'s: step 16 of `skills/close/SKILL.md:515` runs `live.sh sweep`, which deletes the issue's `codeo-live/<issue>/*` branches without asking, yet the skill's own **Deletes** bullet (`:723-725`), its Non-goals (`:753-756`: "Doesn't delete a branch without GitHub's merged state, a tip that matches the pull request's head and the engineer's yes") and its frontmatter description (`:3`, "delete the remote branch on the engineer's yes") still say it deletes only the merged branch, on a yes. An agent checking close against its own non-goals will flag or refuse the sweep. I confirmed the three passages. The code does what the plan says; the plan named step 16 and its sentences but not these three passages, so the correction is a plan decision: the sweep's exception stated in each.
- F7 — non-blocking, plan's: `scripts/cleanup.sh:7` and `skills/cleanup/SKILL.md:44-45` say "one tab-separated line per issue", but a proven issue with leftovers prints a `proven` and a `leftover` line; the header's own `:12` row contradicts `:7`.
- F8 — non-blocking, plan's: `scripts/cleanup.sh:133` withholds the leftover command when only the `name` proof failed, although the branches' deletability does not depend on the container name; with a misconfigured overlay no leftover command is ever printed.
- F9 — non-blocking, plan's: `CHANGELOG.md:6` says `/codeo:close` deletes the issue's `codeo-live/<issue>/*` branches with no qualifier; in a hosted web session the sweep is a no-op (`scripts/live.sh:240`), which `docs/handoff.md:173` and `skills/close/SKILL.md:518-519` state.
- F10 — non-blocking, plan's: `scripts/live.sh:130-147,198-201` saves whatever label the first beat computed, including the `hostname` or `unknown` fallback; two web VMs on one issue that both fell back to one hostname then publish to one branch and show as one row. A hosted session sets `CLAUDE_CODE_REMOTE_SESSION_ID`, so the fallback is unlikely.
- F11 — non-blocking, plan's: `sweep` (`scripts/live.sh:250`) and `leftover_proof` (`scripts/cleanup.sh:117`) skip names such as `codeo-live/<N>/a/b`; the documented manual command covers them.

No issue was filed from this pass.

**Verdict: back to `/codeo:plan`.**

### Round 3 — 2026-11-24

**Sync and scope.** `sync-main.sh --abort-on-conflict`: `the branch already contains origin/main`, exit 0. `overlap.sh 157` and `overlap.sh --outside 157` printed nothing, exit 0. `git diff origin/main...HEAD --stat`: 21 files changed, 1157 insertions, 57 deletions. `scope.sh origin/main HEAD`: `suite.shell=true` (`suite shell needed for unclassified paths: .codeo/157/*, CHANGELOG.md`, among others). No `deploy=` line: no environment is configured.

**Build.** Suite `shell`, build `true`: exit 0.

**Suites.** `bash tests/run.sh`: `all cases passed`, exit 0.

**Acceptance criteria**

| # | Criterion | Verdict | Settled by |
|---|---|---|---|
| 1 | Both refs on origin: `live.sh fetch` exits 0, no `live: unknown` for that cause, a test reproduces it | met | `tests/live.test.sh` `fetch_survives_a_web_and_a_container_signal_with_equal_labels` (the web branches fetch into `refs/codeo/live-web/*`, `scripts/live.sh:259`); `tests/inflight.test.sh` `live_survives_a_web_and_a_container_signal_with_equal_labels` runs `inflight.sh --live` with the real `live.sh` |
| 2 | After close no `codeo-live/<issue>/*` remains, or the docs say how to remove one | met | `live.sh sweep` in `/codeo:close` step 16 (outside a web session); `docs/handoff.md:173` gives `git push origin --delete codeo-live/<issue>/<machine>`; `/codeo:cleanup` prints it for a proven issue |
| 3 | The web-signal docs name the CI trigger on every beat | met | `docs/handoff.md:173` names `on: push`, `[skip ci]`, the `create` event and excluding `codeo-live/**`; pinned in `tests/live-signal.test.sh` |
| 4 | A session whose id changes shows as one row, or the docs say it can show twice for up to the TTL | met | `tests/live.test.sh` `web_label_stays_when_the_session_id_changes` and `web_clear_keeps_the_label`; `docs/handoff.md:209` states the new-checkout case |

**Documentation.** Round 2's gaps are closed: `skills/close/SKILL.md` names the sweep in its description (`:3`), its Deletes bullet (`:724-728`) and its Non-goals (`:756-759`), and `docs/skills.md` in the `close` purpose and non-goal lines; the `scripts/cleanup.sh` header (`:6-7`), `skills/cleanup/SKILL.md` step 1 and the CHANGELOG `Shared state` line say what the code does. I searched `skills/close/SKILL.md`, `docs/skills.md` and `docs/handoff.md` for a remaining "deletes only the merged branch" sentence and found none that contradicts the sweep. New gaps: F12, F13, both non-blocking.

**Independent review** (Opus, given the criteria only): no Critical, one Important (F12), four Minor; it ran the six affected test files and they pass, and it found sound the fetch split and prune, `sweep`'s scope and exit-0 behaviour, the `leftover` line's use of pruned refs, the saved label and the CI wording. Its Minor items are F13, F8 again, a missing sweep entry in step 17's evidence sentence (not a defect: `sweep` only warns on failure) and the round-1 test adaptation `two_web_sessions_on_one_issue_publish_two_branches`, which `implement.md` round 1 records as a deliberate deviation.

**Findings**

- F6 (blocking in round 2) — fixed by `072024d`: the three passages of `skills/close/SKILL.md` and the two of `docs/skills.md` state the sweep and its reason.
- F7 (non-blocking in round 2) — fixed by `fee6ba3`: the script header and the skill say a proven issue can print a second `leftover` line.
- F9 (non-blocking in round 2) — fixed by `fee6ba3`: the CHANGELOG says a hosted web session's close deletes none.
- F12 — non-blocking, `/codeo:plan`'s: `skills/close/SKILL.md:537` (step 17, `host: web`) tells the engineer "nothing to remove: the hosted session is done once the engineer closes it". In a hosted web session step 16's `sweep` does nothing, so the session's `codeo-live/<N>/<machine>` branch stays on origin, and the report neither says so nor names the delete command; the same holds for `host: local` with `CLAUDE_CODE_REMOTE=true`. I confirmed the line and that no plan task named step 17. The sentence is about the checkout, criterion 2 stays met through `docs/handoff.md:173` and `/codeo:cleanup`, and nothing is lost, so it does not block the merge.
- F13 — non-blocking, plan's: `skills/close/SKILL.md:3` and `docs/skills.md:185` say close "sweeps the issue's leftover live-signal branches" without the web-session exception that step 16, `docs/handoff.md:173` and the CHANGELOG state; `docs/skills.md:193` carries it.
- F8, F10, F11 — non-blocking, carried from round 2 and unchanged (the plan left them on purpose): `scripts/cleanup.sh:134` prints no leftover command when only the `name` proof failed; the saved label can lock in a `hostname` fallback; branch names with more path segments are skipped by `sweep` and `cleanup.sh`, which the manual command covers.

No issue was filed from this pass. F8, F10, F11, F12 and F13 stay in this dossier for `/codeo:triage`.

**Verdict: clear — forward to `/codeo:close`.**

## Log

- 2026-11-23 — Round 1: build ok; shell suite passed; criteria 1-4 met with F1 against 4's docs; review one Important, four Minor; verdict back to plan · cost: 9m · opus-5-5 75k in + 417k cached / 9k out · sonnet-5-5 96k in + 798k cached / 2k out
- 2026-11-24 — Round 2: build ok; shell suite passed; criteria 1-4 met; round 1's F1-F5 fixed; review one Important (F6) and five Minor; verdict back to plan · cost: 12m · opus-5-5 99k in + 1.4M cached / 18k out · sonnet-5-5 181k in + 1M cached / 5k out
- 2026-11-24 — Round 3: build ok; shell suite passed; criteria 1-4 met; round 2's F6, F7, F9 fixed; review one Important (F12, non-blocking) and four Minor; verdict clear · cost: 14m · opus-5-5 271k in + 1.8M cached / 14k out · sonnet-5-5 31k in + 1M cached / 5k out
