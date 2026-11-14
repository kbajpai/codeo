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
