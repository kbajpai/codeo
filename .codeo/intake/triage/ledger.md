| Fingerprint | Item | Decision | Date |
|---|---|---|---|
| `branch:claude/optimistic-sagan-liihyr` | Pushed, no PR, last commit 2026-11-07 (1c98bdb, skills lint pipe-timing fix; partly overlaps #30) | resume | 2026-11-07 |
| `doc:README.md:six-steps-vs-seven-skills` | fixed on `main` | already #34 | 2026-11-08 |
| `doc:README.md:setup-docs-plans` | fixed on `main` | already #34 | 2026-11-08 |
| `doc:README.md:doctor-checks` | fixed on `main` | already #34 | 2026-11-08 |
| `issue:36` | Open, no branch or PR, not on the board (Status `none`): "Add a dev container so codeo is developed inside its own image" | ready | 2026-11-07 |
| `triage:2026-11-07-4:board-ready-key` | `board.sh set <N> ready` rejects the lowercase key without `board.statuses` | filed #39 | 2026-11-08 |
| `qc:36:N2` | `plugins.sh` compares only `plugin.ref`, not `plugin.repo` | filed #40 | 2026-11-08 |
| `qc:36:N1-N3-N5-N6` | Small `devcontainer-start.sh` / `devcontainer.json` fixes | filed #40 | 2026-11-08 |
| `qc:36:N7` | Re-planned footprint should be the union, not the replacement | filed #39 | 2026-11-08 |
| `qc:36:F4` | `plugin` config key missing from `lib/env.sh` key reference | filed #40 | 2026-11-08 |
| `qc:36:F3` | Claude login and plugins don't survive a container rebuild | filed #40 (optional requirement) | 2026-11-08 |
| `qc:34:F2-F5` | `docs/skills.md` inaccuracies and guard nits | filed #41 | 2026-11-08 |
| `issue:39` | Filed 2026-11-08, no branch, board Status `Ready` | ready | 2026-11-08 |
| `issue:40` | Filed 2026-11-08, no branch, board Status `Backlog` | leave in the backlog | 2026-11-08 |
| `issue:41` | Filed 2026-11-08, no branch, board Status `Backlog` | leave in the backlog | 2026-11-08 |
| `qc:39:F1-F3` | Re-planned footprint rule has no mechanical check; plan skill sub-steps 2/4 contradict | filed #43 | 2026-11-08 |
| `qc:39:F4-F5-F7` | `board.sh set` messages, test gaps, 50-item lookup limit | filed #43 | 2026-11-08 |
| `qc:39:F2-F6-F8` | Stale wording in CHANGELOG, `lib/env.sh`, triage skill, handoff/dossier docs | filed #43 | 2026-11-08 |
| `issue:43` | Filed 2026-11-08, no branch, board Status `Backlog` | leave in the backlog | 2026-11-08 |
| `issue:44` | Filed 2026-11-08, no branch, board Status `none` | ready | 2026-11-08 |
| `issue:45` | Filed 2026-11-08, no branch, board Status `none`; depends on #44 | ready | 2026-11-08 |
| `qc:44:F1-F7` | Misleading `claude auth login` TODO when an auth env var is set; plus six edge cases in `devcontainer-start.sh` / `window-title.sh` | filed #47 | 2026-11-08 |
| `implement:44:left-unfixed-minors` | Temp file mode, stray `.tmp`, missing stdout assertion | filed #47 | 2026-11-08 |
| `issue:47` | Filed 2026-11-08, no branch, board Status `none` | ready | 2026-11-08 |
| `doc:issue-bodies:private-name-44-45` | #44 and #45 bodies still name the private reference project | engineer will edit | 2026-11-08 |
| `qc:45:F1-F2` | Hook command unguarded against a missing `session-title.sh`; changelog says "every" session | folded into #47 | 2026-11-09 |
| `implement:45:test-minors` | `read -r` first line only; `wc -l <<<` assertion cannot fail; relies on jq key order | folded into #47 | 2026-11-09 |
| `implement:45:title-after-lock` | Window and session titles do not follow the lock taken mid-session | folded into #47 | 2026-11-09 |
| `implement:45:filemode` | Container has `core.fileMode=false`, new scripts commit as 100644 | folded into #47 | 2026-11-09 |
| `issue:50` | Filed 2026-11-09, no branch, board Status `unset` | ready | 2026-11-09 |
| `qc:47:F24` | `core.fileMode` flip leaves silent mode changes | filed #54 | 2026-11-10 |
| `qc:47:F25-F29` | Small `window-title.sh` / `devcontainer-start.sh` edges and `implement:47` deferred minors (F26, F20, F21, F23 recorded, not done; F29 left to #40) | filed #54 | 2026-11-10 |
| `qc:50:F1-F2` | Container name from a folder Docker rejects; looser `runArgs` test | filed #54 | 2026-11-10 |
| `issue:51` | Filed 2026-11-09, no branch, board Status `unset` | ready | 2026-11-10 |
| `issue:52` | Filed 2026-11-10, no branch, board Status `none` | ready | 2026-11-10 |
| `issue:54` | Filed 2026-11-10, no branch, board Status `unset` | leave in the backlog | 2026-11-10 |
| `issue:55` | Filed 2026-11-10, no branch, board Status `none` | ready | 2026-11-10 |
| `qc:50:F3` | `tests/devcontainer.test.sh:6-8` header comment leaves "It also checks .devcontainer/Dockerfile" alone on a line (cosmetic) | dismissed — cosmetic, nothing breaks | 2026-11-11 |
| `qc:55:F4` | Two checkouts sharing a folder name cannot run at once | filed #57 | 2026-11-11 |
| `qc:55:F3` | `codeo-root.sh` takes plugin registry entry `[0]` | filed #57 | 2026-11-11 |
| `qc:55:F6` | Empty `.codeo/active` gives neither a lock nor a TODO | filed #57 | 2026-11-11 |
| `qc:55:F2` | `folder-check.sh` hard-codes `main` | filed #57 | 2026-11-11 |
| `qc:55:F5-F7` | Untrue wording in `container-name.sh`, CHANGELOG and the README path | filed #57 | 2026-11-11 |
| `qc:55:F8` | Reworded path `/workspaces/the reference project` in archived records | dismissed — archived records only, harms nothing | 2026-11-11 |
| `implement:55:deferred-minors` | Reviewers' deferred minors (header wording, `2>&1`, bare `-home` test, repeated crash output, weak needle) | filed #57 | 2026-11-11 |
| `qc:55:host-checks` | Docker criteria 1-5, 7 and 8 never run | filed #58 | 2026-11-11 |
| `doc:issue-bodies:private-name-55` | #55's GitHub body still names the private reference project | engineer will edit | 2026-11-11 |
| `issue:57` | Filed 2026-11-11, no branch, board Status `unset` | ready | 2026-11-13 |
| `issue:58` | Filed 2026-11-11, no branch, board Status unset | ready | 2026-11-11 |
| `issue:59` | Throwaway target for #58 host checks; filed 2026-11-11, no branch, board Status unset | ready | 2026-11-11 |
| `qc:58:F1` | Host checks for #55 have attestation only, no captured output for criteria 2-5, 7, 8 | dismissed — engineer accepted attestation at plan Q1 = A | 2026-11-13 |
| `doc:triage-2026-11-11-4:board-ready-name` | `board.sh set <N> ready` rejected the lowercase name | already #39 (fixed on main; installed plugin is pinned at v1.0.3 without it) | 2026-11-13 |
| `qc:58:F8-F10` | Stale and overclaiming lines in archived `.codeo/done/58/plan.md`, small record gaps | dismissed — archived record only, nothing runs from it | 2026-11-13 |
| `issue:61` | Release v1.0.4 from main; filed 2026-11-13, no branch, board Status `none` | ready | 2026-11-13 |
| `issue:67` | Move the dev container image to Ubuntu 26.04 LTS; filed 2026-11-14, no branch, board Status `none` | ready | 2026-11-14 |
| `review:64:4573610395` | `/codeo:close` closing block after a failed cleanup that keeps the lock names checkout removal | filed #69 | 2026-11-14 |
| `review:64:4573610407` | Closing block after an interrupted stash names `/codeo:init`, which stops on the kept lock | filed #69 | 2026-11-14 |
| `review:64:4573610423` | `/codeo:init` closing block names `/codeo:plan` after `lock: TODO` left no lock | filed #69 | 2026-11-14 |
| `review:64:4573610449` | `/codeo:issue` closing block names `/codeo:init` where the board Ready gate refuses a new issue | filed #69 | 2026-11-14 |
| `implement:67:host-commands-shell` | Plan's host-run `docker run` command failed in the engineer's PowerShell | filed #69 | 2026-11-14 |
| `qc:67:F5-F7` | Three wording notes on the #67 changelog entry and dev container README | filed #69 | 2026-11-14 |
| `qc:61:F1-F3` | Stale lines in archived `.codeo/done/61/plan.md`; local-only tag `v1.0.4` | filed #69 — listed there as known and left (out of scope) | 2026-11-14 |
| `issue:69` | Closing blocks, plan host commands and #67 wording; filed 2026-11-14, no branch, board Status `none` | ready | 2026-11-14 |
| `issue:70` | Home-only skill guard, close-time removal commands, print-only /codeo:cleanup; filed 2026-11-14, no branch, board Status `none` | ready | 2026-11-14 |
| `qc:69:G1` | `/codeo:close`'s abandon exit has no closing block and borrows the stash blocks | filed #74 | 2026-11-14 |
| `qc:69:G2` | `tests/closing-exits.test.sh` misses old sentences restored beside the labelled paragraphs | filed #74 | 2026-11-14 |
| `qc:69:G3-G4` | `docs/handoff.md` exceptions table: over-general `init — no lock` row, no "Status unreadable" row | filed #74 | 2026-11-14 |
| `qc:69:G5-G7` | Plan skill host-task paragraph contradictions, incomplete "neutral" list, changelog omits the ask-and-label branch | filed #74 | 2026-11-14 |
| `implement:69:left-minors` | Minors left by the #69 implementers and reviewers | filed #74 | 2026-11-14 |
| `issue:71` | File new issues straight into Backlog; board Status `Backlog` | leave in the backlog | 2026-11-14 |
| `issue:73` | Evaluate Docker Sandboxes; filed 2026-11-14, no branch; left in the backlog in run 6, then moved to Ready by hand by the engineer (board unreadable from the web session) | ready | 2026-11-14 |
| `issue:74` | Follow-ups #69 left; filed 2026-11-14, no branch, board Status `none` | leave in the backlog | 2026-11-14 |
| `issue:75` | Release v1.0.6 from main and pin codeo to it; filed 2026-11-14, no branch, board Status `none` | ready | 2026-11-14 |
| `issue:76` | Trial `doctor` and `setup` on Haiku 5.5; filed 2026-11-14, no branch, board Status `none` | ready | 2026-11-14 |
| `qc:51:F4-F6` | Host `~/.gitconfig` wait stops at existence not content; `[include]` / `[includeIf]` not followed | filed #81 | 2026-11-14 |
| `qc:52:F1-F3` | Plan quotes old model names; changelog clause omits the replay `sed`; plan's `gh --comments --json` command | filed #81 (F2 as a requirement; F1, F3 in Reference only) | 2026-11-14 |
| `qc:75:F1` | v1.0.6 Release body has auto-generated notes appended, unlike v1.0.5's | filed #81 | 2026-11-14 |
| `issue:81` | Small follow-ups from #51, #52 and #75; filed 2026-11-14, no branch, board Status `none` | leave in the backlog | 2026-11-14 |
| `implement:76:haiku-follow-up` | Re-run the Haiku 5.5 trial with the closing-block template read through Read (#76 kept both skills on Sonnet on one item-1 miss) | filed #83 | 2026-11-15 |
| `qc:76:F5-F6` | #76 comment lists three of four scorer corrections; understates one second Bash call | engineer will edit | 2026-11-15 |
| `qc:76:F4` | Plan's `gh issue view --comments --json` command does not run (same command as `qc:52:F1-F3`) | already #81 | 2026-11-15 |
| `issue:83` | Re-run the Haiku trial; filed 2026-11-15, no branch, board Status `none` | leave in the backlog | 2026-11-15 |
| `qc:57:F2` | A `.codeo/active` with content but no `issue:` line still counts as a held lock in the dev container start script | filed #87 | 2026-11-15 |
| `qc:57:F1-F7` | Tests added by #57 that prove less than their names say (stub `lock.sh`, trivially true assertion, loose grep, untested detached-HEAD, failed-`rm` and `window-title.sh` failure paths) | filed #88 | 2026-11-15 |
| `qc:57:F8` | README and CHANGELOG say same-named containers "cannot run at once"; "cannot both exist" is exact | filed #88 | 2026-11-15 |
| `qc:57:F4` | `codeo-root.sh` matches a registry `projectPath` by exact string (symlink, trailing slash, null `installPath`) | filed #88 | 2026-11-15 |
| `qc:57:F5` | One over-long comment line in `devcontainer-start.sh`'s step 3a header | dismissed — cosmetic, nothing breaks | 2026-11-15 |
| `issue:85` | Start an sbx issue sandbox; filed 2026-11-15, no branch, board Status `none`; depends on #73's evaluation | leave in the backlog | 2026-11-15 |
| `issue:86` | Work in and end an sbx issue sandbox; filed 2026-11-15, no branch, board Status `none`; depends on #73's evaluation | leave in the backlog | 2026-11-15 |
| `issue:87` | Dev container start script reports a `.codeo/active` that names no issue; filed 2026-11-15, board Status `none` | ready | 2026-11-15 |
| `issue:88` | Dev container follow-ups from #57; filed 2026-11-15, board Status `none` | leave in the backlog | 2026-11-15 |
| `qc:87:F1` | An unreadable non-empty `.codeo/active` is reported as naming no issue (`grep` exits 2, the `!` fires the TODO) | filed #91 | 2026-11-15 |
| `qc:87:F2-F3` | Step 3a comment misorders "spaces, tabs or `#`"; `start_hash_issue_line_is_a_held_lock` relies on `DS_REPO` and the `-f &&` in the arm are unexplained | filed #91 (one issue for F1-F3, related to #88) | 2026-11-15 |
| `issue:91` | Report an unreadable `.codeo/active` truthfully, and clarify two spots from #87; filed 2026-11-15, board Status `none`; touches the same files as #88 | leave in the backlog | 2026-11-15 |
| `implement:83:sync-main-comm` | `sync-main.sh` exits 1 after a clean merge when `sort` and `comm` order paths differently (`comm: … not in sorted order`) | filed #92 | 2026-11-15 |
| `issue:92` | sync-main.sh exits 1 after a clean merge (sort/comm order); filed 2026-11-15, no branch, board Status `none` | leave in the backlog | 2026-11-15 |
| `qc:73:F32-F36` | sbx evaluation page and #86: image-digest wording (F32), doubled naming sentence (F34), missing follow-up rows and trial range (F35), inferred and leftover wording (F36) | filed #94 | 2026-11-15 |
| `qc:73:F33` | Page cites "credentials stay outside the VM" while T6 shows `GH_TOKEN` in the sandbox; real token or placeholder untested | filed #94 | 2026-11-15 |
| `qc:73:F12` | `/codeo:plan` writes a `### Footprint` with no `sequenced:` line, which `dossier-check.sh` rejects | filed #95 | 2026-11-15 |
| `qc:73:F23` | `sync-main.sh` exits 1 after a clean merge (`comm … not in sorted order`) | already #92 | 2026-11-15 |
| `issue:94` | Correct the sbx evaluation page and #86; filed 2026-11-15, board Status `none` | leave in the backlog | 2026-11-15 |
| `issue:95` | `/codeo:plan` writes `sequenced:  none`; filed 2026-11-15, board Status `none` | leave in the backlog | 2026-11-15 |
| `issue:97` | Docs, skill wording and test-guard follow-ups from #34, #39, #69; filed 2026-11-15, no branch, board Status `Backlog` | leave in the backlog | 2026-11-15 |
| `issue:99` | Make the sbx issue sandbox usable (consolidates #94, #85, #86, #114); board Status `Backlog` | ready | 2026-11-17 |
| `qc:98:F1-F2` | #98 non-blocking minors: "step 10 fills it in" wording at `skills/plan/SKILL.md:232-233` (F1), `comm` shim inert under uutils (F2), ragged wrap at `:275-277` | dismissed — cosmetic, nothing breaks | 2026-11-15 |
| `issue:100` | Release v1.0.7 once #70, #71, #96, #97, #98 close (all closed); board Status `Backlog` | ready | 2026-11-17 |
| `issue:102` | `/codeo:issue` priority labels; marked Ready on the engineer's request to schedule more issues | ready | 2026-11-18 |
| `issue:103` | Let triage judge in-flight workflows from evidence; board Status `Backlog` | ready | 2026-11-17 |
| `issue:104` | Publish a live-session signal for in-flight workflows; filed 2026-11-15, no branch, board Status `none` | leave in the backlog | 2026-11-15 |
| `qc:96:F16` | Changelog docs test reads only `## Unreleased`, so it fails on the release commit | filed #107 | 2026-11-15 |
| `qc:96:F3-F7-F17` | Start-script and `codeo-root.sh` message and edge defects | filed #107 | 2026-11-15 |
| `qc:96:F5-F6-F10-F13-F14-F15-F18` | Test weaknesses, timing, cosmetics and #96's wording gaps (F11-F12) | filed #107 | 2026-11-15 |
| `qc:96:F8` | A folder named `my project` or `_x` still cannot start a dev container | dismissed — the documented limit (plan Q1) is enough | 2026-11-15 |
| `qc:97:F8-F21` | #97's non-blocking findings: `overlap.sh`, `qc-verdict.sh`, test guards, wording | filed #108 | 2026-11-15 |
| `implement:96:login-persistence` | Claude's login does not survive a container rebuild | dismissed — nothing is lost, only a re-login | 2026-11-15 |
| `issue:107` | Dev container follow-ups from #96; filed 2026-11-15, no branch, board Status `none` | leave in the backlog | 2026-11-15 |
| `issue:108` | Follow-ups #97 left; marked Ready on the engineer's request to schedule more issues | ready | 2026-11-18 |
| `qc:70:F9-F11-F12-J8` | #70's findings left for triage: Podman not detected by the role guard, `CODEO_CLEANUP_REMOVAL` in the production path, generic "home container only" wording, cleanup lists every archived issue | filed #116 | 2026-11-16 |
| `qc:104:F10-F13-F14-F15-F16` | #104's findings left for triage (and F5, F7): lock-issue pattern mismatch, push-timeout wording, `ref delete` treats any Not Found as deleted, signal lingers after close, same-volume-name collision, future-dated beat, hook timeout | filed #116 | 2026-11-16 |
| `qc:104:F3` | Web-session live signal's user label is the harness's git identity | filed #116 (referenced to #112; no requirement here) | 2026-11-16 |
| `qc:71:F7-F9` | `board.sh set` prints one line per project; a board with no Backlog option fails every filing with no fix named; CHANGELOG omits the `issue:<N>` fingerprint change | filed #116 | 2026-11-16 |
| `qc:107:F1-F3` | `rm -f -- ""` check unrecorded, CHANGELOG bullet overstates `codeo-root.sh`, weak title test | filed #116 | 2026-11-16 |
| `issue:112` | Verify the live-session signal in a hosted web session; marked Ready (needs a real hosted web session; best after #118 merges) | ready | 2026-11-18 |
| `issue:114` | Dev container trusts the workspace folder in Claude Code; folded into #99 | already #99 — closed as superseded | 2026-11-17 |
| `issue:116` | Follow-ups #70, #71, #104 and #107 left; filed 2026-11-16, board Status `none` | ready | 2026-11-16 |
| `qc:113:G1-G2` | #113's container-first order in `codeo-container.sh` leaves a half-made container after a branch mismatch or failed clone | filed — folded into #99 | 2026-11-17 |
| `qc:113:G3-G7-R7-R8` | #113's remaining wording, documentation and test gaps | filed — folded into #99 with Q1 | 2026-11-17 |
| `implement:104:polish` | #104's refresh label, header line, ref-lock collision and F2 | filed #118 | 2026-11-17 |
| `issue:118` | Live-signal leftovers from #104, now with #116's F8-F9; board Status `Backlog` | ready | 2026-11-18 |
| `qc:116:F7-F10-F11` | #116's leftovers: criterion 13 unchecked on #107, Podman marker test name, stash/abandon pins searching the whole section | filed #121 | 2026-11-18 |
| `qc:116:F8-F9` | `live.sh` timeout comment wording; the 20 s `SessionEnd` figure assumes the default push timeout | folded into #118 | 2026-11-18 |
| `qc:103:F13-F14-F18-F23` | Triage in-flight judging: resume with no step to name, unstable `parked:` fingerprint, resume through Ready, wrong `waits:` for a resumed stash, doc and comment gaps | filed #122 | 2026-11-18 |
| `issue:121` | #116 QC leftovers (tests, criterion 13); consolidated with #130 into #132 | already #132 — consolidated, engineer closes as superseded | 2026-11-18 |
| `issue:122` | Triage in-flight judging leftovers from #103; marked Ready (shares docs/handoff.md with #108: run one at a time) | ready | 2026-11-18 |
| `qc:99:F19-F21` | `.sbx/codeo-sandbox.sh`: no next step after a failed start-script exec, rerun needs a valid pin, `end` fetch failure names no way out | filed #125 | 2026-11-18 |
| `qc:99:F24-minors` | #99's test gaps: devcontainer test fails inside an sbx sandbox, CHANGELOG read by line number, missing `run -d` and short-row tests | filed #125 | 2026-11-18 |
| `qc:99:F17-F18-F22` | #99's evaluation-page wording contradictions | dismissed — the page records trials as they were (accepted recommendation) | 2026-11-18 |
| `issue:123` | sbx lock records a sandbox, not a volume; consolidated with #125 into #131 | already #131 — consolidated, engineer closes as superseded | 2026-11-18 |
| `issue:125` | #99 sbx follow-ups; consolidated with #123 into #131 | already #131 — consolidated, engineer closes as superseded | 2026-11-18 |
| `issue:126` | Issue number in the branch name; filed 2026-11-18, board Status `none` | ready | 2026-11-18 |
| `qc:100:live-test-git-path` | `tests/live.test.sh` tests a relative `--git-path` result against the current directory, so the suite fails in a checkout with its own `.git/codeo-live-beat` | filed #130 | 2026-11-18 |
| `qc:100:F2` | Archived `.codeo/100/plan.md` / `issue.md` stale status lines, two off-by-one changelog line numbers | dismissed — archived record only, nothing runs from it | 2026-11-18 |
| `issue:130` | tests/live.test.sh stamp check against the cwd; consolidated with #121 into #132 | already #132 — consolidated, engineer closes as superseded | 2026-11-18 |
| `issue:131` | sbx lock and #99 follow-ups (consolidates #123, #125); filed 2026-11-18, board Status `Backlog` | ready | 2026-11-18 |
| `issue:132` | Test-suite fixes from #116 and #100 (consolidates #121, #130); board Status `Backlog`, held for #118 which has merged (PR #129) | ready | 2026-11-18 |
| `issue:133` | A `codeo` host command for containers and sandboxes (Linux, bash); filed 2026-11-18, board Status `Backlog` | ready | 2026-11-18 |
| `qc:133:code-leftovers` | #133's `codeo` host command: F19, F25, F29, F30 and the smaller QC findings, with the unresolved PR #136 threads | filed #143 | 2026-11-20 |
| `review:136:4629636234` | PR #136 thread: prune stale origin refs before the volume safety check | filed #143 | 2026-11-20 |
| `review:136:4629636301` | PR #136 thread: request untracked files explicitly in the safety check | filed #143 | 2026-11-20 |
| `review:136:4629636350` | PR #136 thread: refuse an incomplete kind lookup before removal | filed #143 | 2026-11-20 |
| `review:136:4629636391` | PR #136 thread: write between the check and `docker rm -f` | filed #143 | 2026-11-20 |
| `review:136:4629636455` | PR #136 thread: bind-mounted container vs a same-named volume | filed #143 | 2026-11-20 |
| `review:136:4629636491` | PR #136 thread: concurrent first-use commands share one `.part` | filed #143 | 2026-11-20 |
| `review:136:4629636540` | PR #136 thread: concurrent first-time lookups share `.lookup.git.part` | filed #143 | 2026-11-20 |
| `review:136:4629636595` | PR #136 thread: honour `CODEO_REPO_URL` for the lookup cache (appears fixed on main) | filed #143 | 2026-11-20 |
| `review:136:4629636654` | PR #136 thread: resolve the tree entry, not `cat-file -e` (appears fixed on main) | filed #143 | 2026-11-20 |
| `review:136:4629636698` | PR #136 thread: relative `CODEO_CONTEXT` / `CODEO_SBX_IMAGE` overrides | filed #143 | 2026-11-20 |
| `review:136:4629636750` | PR #136 thread: honour `CODEO_SBX` for discovery (appears fixed on main) | filed #143 | 2026-11-20 |
| `qc:133:wording-leftovers` | #133's README, help-text, comment and changelog wording findings; folded into #143 at the engineer's request | filed #143 | 2026-11-20 |
| `qc:108:F4-F6-F10` | #108: overlap.sh failure read as "no overlap", unanchored `## Outcome` heading, init closing block with no next command | filed #144 | 2026-11-20 |
| `qc:108:nits-F2-F3-F5-F8-F9` | #108's test-name, comment and wording nits | dismissed — nits, only F4/F6/F10 were worth an issue (engineer) | 2026-11-20 |
| `issue:138` | Live-session signal in hosted web sessions; filed 2026-11-20, previously left in the backlog; engineer asked about it again | ready | 2026-11-21 |
| `qc:132:F1` | `paragraph_contains_flat` whitespace-only line hardening | dismissed — nothing in today's skill triggers it | 2026-11-20 |
| `qc:112:F7-F12` | #112's approximate refusal texts and one changelog verb | dismissed — #138 carries the substance | 2026-11-20 |
| `qc:102:F1-F2-F5` | #102 priority setting: `"true"` string vs doctor, second priority label, unquoted path | filed #145 | 2026-11-21 |
| `qc:102:F3-F4` | #102 wording findings | filed #145 (F3-F4 listed out of scope) | 2026-11-21 |
| `qc:126:F1-F4` | #126 stale `claim.sh` text; F1-F3 filed, F4 transition gap dismissed | filed #145 | 2026-11-21 |
| `qc:126:F5` | #126 hard-coded `.codeo/<N>` in step 6 | dismissed — cosmetic | 2026-11-21 |
| `qc:122:F1-F5` | #122 triage/inflight wording, `unassigned:<N>` re-asked each run | filed #145 | 2026-11-21 |
| `qc:131:F1-F4` | #131 sandbox-lock leftovers | dismissed — engineer's call, run 11 | 2026-11-21 |
| `unclosed:132` | `fix/fix-test-suite-gaps-left` no longer on origin; close finished | dismissed — branch deleted from origin | 2026-11-21 |
| `issue:143` | `codeo` host command leftovers from #133; filed 2026-11-20 | ready | 2026-11-20 |
| `issue:144` | #108 leftovers (overlap.sh failures, heading rule, init closing block); filed 2026-11-20 | ready | 2026-11-20 |
| `issue:145` | #102, #126 and #122 leftovers; filed 2026-11-21 | ready | 2026-11-21 |
| `qc:143:F12-F16` | #143 non-blocking QC findings: sandbox hint after removal, relative `CODEO_HOME`, README and help wording | filed #149 | 2026-11-21 |
| `qc:143:F6-F9-parked` | #143 round 1 parked: restart before mount check, flowchart gaps | filed #149 | 2026-11-21 |
| `qc:144:F3-F5` | #144 non-blocking QC findings: pronoun in implement/close skills, test pin claim, nits | filed #149 | 2026-11-21 |
| `issue:146` | Release v1.0.8; board Status `Backlog` though ledgered ready 2026-11-21; all six gating issues now closed | ready | 2026-11-22 |
| `issue:149` | #143 and #144 leftovers; filed 2026-11-21 | ready | 2026-11-21 |
| `issue:151` | One-command install and developer README; filed 2026-11-21, board Status `Backlog` | ready | 2026-11-21 |
| `qc:149:F7-F12-F18` | #149 non-blocking QC findings: `codeo rm` remedies, F7 refused `rm` leaves a stopped container running, README/CHANGELOG wording, test pin | filed #154 | 2026-11-21 |
| `qc:145:F1-F3` | #145 non-blocking QC findings: triage step reference, inflight test date, inflight comments | filed #154 | 2026-11-21 |
| `qc:118:F1-F6` | #118 non-blocking QC findings (test label, concurrent-beats case, handoff/live.sh wording) | already #138 | 2026-11-21 |
| `issue:154` | #149 and #145 leftovers; board Status `Backlog` → Ready on the engineer's say-so, run 19 | ready | 2026-11-22 |
| `issue:152` | Run the home role on the host with a strict role guard and issue tracking comment (rewritten 2026-11-22 from an evaluation) | ready | 2026-11-22 |
| `qc:138:F22-F23-F25` | #138's live-signal leftovers: fetch collision on equal labels, leftover `codeo-live/*` branches, label changing with the session id | filed #157 | 2026-11-22 |
| `issue:157` | Live-session signal leftovers from #138; filed 2026-11-22, board Status `Backlog` | leave in the backlog | 2026-11-22 |
| `qc:151:installer-F12-F20-F22-F26-F27` | #151 installer failure-path findings: recovery line names no tag, unusable restore command, undetected dropped installs | dismissed — engineer's call, run 17 | 2026-11-22 |
| `qc:151:nits-F4-F5-F6-F8-F9-F13-F14-F17-F25` | #151 README/CHANGELOG wording and test-strength nits | dismissed — engineer's call, run 17 | 2026-11-22 |
| `qc:151:F7-F15` | "Latest release" is the highest `vX.Y.Z` tag; idempotence compares `plugin.json` with the tag | dismissed — already documented as accepted limits in README Updating/Installing (engineer accepted recommendation) | 2026-11-22 |
| `parked:146:2026-11-22` | #146 In progress, live session on codeo-146; v1.0.8 shipped via release/v1.0.8 (#158), feat/release-v1-0-8-once has no PR | deferred | 2026-11-22 |
