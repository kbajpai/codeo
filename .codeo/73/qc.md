# Issue #73 — qc

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/73 |
| Branch | `docs/evaluate-docker-sandboxes-sbx-against` |
| Updated | 2026-11-15 |

## Where this stands

Round 2 is written: the build and the suite pass, round 1's three blocking findings are fixed, and the review found three more claims stronger than their evidence (F13 the KVM claim still on #73, F14 the window-title "no equivalent", F15 U6's folder check). The change goes back to `/codeo:implement`.

## Questions

None.

## Notes

- `sync-main.sh --abort-on-conflict` merged `origin/main` (one commit, #82's) cleanly as `0e408ef`, then exited 1 with `comm: file 2 is not in sorted order` while building its `also changed on main:` list, so that list was not printed. The merge itself is complete; `git diff --name-only cfc95ea 0e408ef` shows what main brought: `CHANGELOG.md`, `docs/plans/2026-11-14-trial-doctor-setup-haiku.md` and `.codeo/done/76/*`. None overlaps this branch's files. The script's failure is in the plugin, not in this change.
- The reviewer was given the acceptance criteria, the issue's drivers and requirements, and the git range, and nothing from the implementer's dossier.

## Outcome

### Round 1 — 2026-11-15

**Commands run** (all from the project root, on `0e408ef`, the branch with `origin/main` merged in):
- `overlap.sh 73` and `overlap.sh --outside 73`: no output.
- `git diff origin/main...HEAD --stat`: 6 files, 981 insertions: `.codeo/73/{implement,init,issue,plan}.md`, `docs/dev-environment-sbx-evaluation.md`, `docs/plans/2026-11-14-evaluate-docker-sandboxes-sbx.md`.
- `scope.sh origin/main HEAD`: `scope: suite shell needed for unclassified paths:` the four `.codeo/73/*.md` files, then `suite.shell=true`. No `deploy=` line (no environment is configured).
- Build (`shell`: `true`): exits 0.
- `bash tests/run.sh`: `all cases passed`, exit 0.
- `overlay.sh qc invariants-extra` and `wiki-rules`: exit 3 (none set). No invariants file and no environment resource are configured, so step 9 does not apply.
- `git diff --stat origin/main...HEAD -- .devcontainer skills`: empty.
- `dossier-check.sh .codeo/73`: `FAIL plan.md [footprint] ### Footprint at line 100 lacks: sequenced`; `drift issue.md [header-table]` and `[sections]`.
- Independent review (opus, `QC review:`): given the criteria and the range; verdict "With fixes", no Critical findings, three Important, seven Minor.

**Acceptance criteria**

| # | Criterion | Settled by | Verdict |
|---|---|---|---|
| 1 | A written comparison exists, covering every driver and requirement, each point marked tried or cited | `docs/dev-environment-sbx-evaluation.md`: D1-D10 and U1-U18, every Evidence cell `tried` or `cited`; review confirmed 28 rows (22 tried, 6 cited) | met — but three `tried` claims go beyond their trial output (F1-F3) |
| 2 | Every duty listed under Key Requirements has an equivalent, a workaround or "no equivalent" | U1-U18 cover the home/issue split, one clone per issue, every `devcontainer-start.sh` step, `plugins.sh`, window and session titles, both volumes | met — U3, U4 and U13 describe the finding without the literal word (F5) |
| 3 | States whether sbx runs on Windows + WSL2, with evidence | `## Host`: "yes, partly" with the T1 and T2 output | met for the Windows route; the claim that the Linux-in-WSL2 route is unavailable is not shown (F1) |
| 4 | Ends with one recommendation and its rationale | one `**Recommendation:** hybrid` line, with rationale and the three intake questions answered | met |
| 5 | Follow-up issues filed and linked | #85 and #86 exist and are open; linked in the page's `## Follow-up issues` and in a comment on #73 | met |
| 6 | `.devcontainer/` and the workflow skills unchanged | `git diff --stat origin/main...HEAD -- .devcontainer skills` is empty | met |

**Documentation check.** The only page is the new one; no existing page describes behaviour this change alters, and the plan said so. The reviewer checked the page's account of the current setup against `.devcontainer/` (sudo, `runArgs`, volumes, extensions, the start script's steps, the `REMOTE_CONTAINERS` gate) and found it accurate. No account name, email, token, organisation id or one-time code is in the page.

**Findings**

- **F1 — blocking, `/codeo:implement`'s.** `docs/dev-environment-sbx-evaluation.md` lines 49, 80 (D5), 126, 137, 167: the page concludes the Linux-in-WSL2 route "has no basis" because `lsmod | grep kvm` printed nothing. KVM on the WSL2 kernel is built in, not a module: this machine's own WSL2 kernel (`6.6.87.2-microsoft-standard-WSL2+`) has `CONFIG_KVM=y`, `CONFIG_KVM_INTEL=y`, `CONFIG_KVM_AMD=y` in `/proc/config.gz` (checked this pass), so `lsmod` prints nothing either way and the check cannot show it. Root cause: the plan's T1 used `lsmod`. The page should say the Linux route was not tried, or the engineer should run `ls -l /dev/kvm` in the distribution (and check nested virtualization in `.wslconfig`) and quote that.
- **F2 — blocking, `/codeo:implement`'s.** Lines 76 (D1), 94 (U2), 195, 200: the page says clone mode mounts the host repository read-only, quoting only `/run/sandbox/source (ro)`. T3's create summary also printed the workspace as `\\wsl.localhost\…\codeo-sbx-a → /wsl.localhost/Ubuntu-24.04/home/<user>/Source/codeo-sbx-a (rw)`. The page does not say whether that is the in-sandbox clone at a mirrored path or the host folder mounted read-write, and the recommendation's "isolation gain is for the filesystem and the network" depends on it. Quote the `(rw)` line and say what it is, or mark the read-only claim `cited` and the mapping unresolved.
- **F3 — blocking, `/codeo:implement`'s.** Lines 363 and 424: "the `claude` image moved between creates (T10)". T10 shows the assembled kit digest differed (`0fb3e2c5…` against `4df39400…`); T8's recreate was `assembled kit image ready (cached)`, so the base image changing is not shown, and #86's pinning criterion cites it. Say "the kit digest differed; whether the base image changed was not checked", or compare the image digests.
- **F4 — non-blocking.** Line 434: "Docker Desktop" has no evidence on the page; T1 quotes only `Docker version 29.9.3`. Quote the evidence or drop the words.
- **F5 — non-blocking.** U3, U4, U13: the sbx column describes what happened without saying "equivalent", "workaround" or "no equivalent" (U3: workaround, the per-clone `safe.directory` entry; U4: no repair needed, equivalent in effect; U13: no equivalent).
- **F6 — non-blocking.** Line 424: "`sbx setup` is experimental" has no row or quote on the page; add it to T12's quoted output.
- **F7 — non-blocking.** Line 108 (U16) says logins "do not live in the sandbox", where D7 and U10 say the mechanism "is not shown"; use that wording.
- **F8 — non-blocking.** Lines 79 and 339: "about 23% longer" in parallel is not separated from the run-to-run spread (sequential re-runs took 2m51 and 3m08 against 2m35-2m38 solo).
- **F9 — non-blocking.** Line 21 promises `tried T<n>, <date>`, but D1, U9, U15 and U16 omit the date, and D3 says `sbx prune` is cited without the URL in its Evidence cell.
- **F10 — non-blocking.** Line 114: "unless T1 or T2 shows … and the page says which" is now settled by the sentence before it.
- **F11 — non-blocking.** Line 94: the U2 parenthetical "(so that branch is checked out in the host checkout, not a second one)" does not read clearly.
- **F12 — non-blocking, `/codeo:plan`'s.** `.codeo/73/plan.md`'s `### Footprint` lacks a `sequenced:` key (the dossier checker wants `sequenced:  none`). No CI job runs the checker; it is the plan dossier's, not this change's.
- **F13 — non-blocking, outside this diff.** `sync-main.sh` exited 1 after a successful merge (`comm: file 2 is not in sorted order`); that is the plugin's script, not this change.

Declined by the reviewer, and left to the engineer: whether hybrid is the right choice compared with stay, and whether two follow-up issues is the right grouping; both are recorded as the engineer's choices (Q2).

**Verdict: back to `/codeo:implement`.**

### Round 2 — 2026-11-15

**Commands run** (project root, on `ac548e9`: the round-2 implement commit with `origin/main` merged in again, #84's `.devcontainer/` follow-ups):
- `sync-main.sh --abort-on-conflict`: `merged origin/main (1 commit(s))`, then `comm: file 2 is not in sorted order` and exit 1, as in round 1 (the merge was committed first; the `also changed on main:` list was not printed). Main's commit changed `.devcontainer/README.md`, `codeo-root.sh`, `container-name.sh`, `devcontainer-start.sh`, `folder-check.sh`, `window-title.sh`, `CHANGELOG.md`, `docs/plans/2026-11-14-dev-container-follow-ups.md`, four tests and `.codeo/done/57/*`; the page's account of the start script was re-checked against it (step numbers 1, 2, 2b, 3, 3a, 3a', 3b, 3c, 4-7 unchanged; the new empty-lock handling and folder-name note contradict nothing the page says).
- `overlap.sh 73` and `overlap.sh --outside 73`: no output.
- `git diff origin/main...HEAD --stat`: 7 files, 1072 insertions: `.codeo/73/{implement,init,issue,plan,qc}.md`, `docs/dev-environment-sbx-evaluation.md`, `docs/plans/2026-11-14-evaluate-docker-sandboxes-sbx.md`.
- `scope.sh origin/main HEAD`: `suite shell needed for unclassified paths:` the five `.codeo/73/*.md` files, then `suite.shell=true`; no `deploy=` line (no environment).
- Build (`shell`: `true`): exit 0. `bash tests/run.sh` on `ac548e9`: `all cases passed`, exit 0.
- `overlay.sh qc invariants-extra` and `wiki-rules`: exit 3 (none). `git diff --stat origin/main...HEAD -- .devcontainer skills`: empty.
- `gh issue view 85` and `86`: both `OPEN`. #73's last comment links both.
- Independent review (opus, `QC review:`, given the criteria and the range `aaf4883..ac548e9`): "With fixes", no Critical findings, four Important, six Minor.

**Round 1's blocking findings, rechecked on the page.** F1 (blocking in round 1) — fixed: `lsmod | grep kvm` is recorded as not evidence either way, T1 gained `ls -l /dev/kvm`. F2 (blocking in round 1) — fixed: T3 quotes `(rw)` beside `(ro)`; D1 and U2 are `cited`. F3 (blocking in round 1) — fixed: the page says the printed kit digest differed and the base image was not checked (see F17 on whether that was stricter than the evidence needed). F4-F11 (non-blocking in round 1) — fixed as listed in implement.md round 2.

**Acceptance criteria**

| # | Criterion | Settled by | Verdict |
|---|---|---|---|
| 1 | A written comparison exists, covering every driver and requirement, each point marked tried or cited | `docs/dev-environment-sbx-evaluation.md`: D1-D10, U1-U18, 22 `tried` and 6 `cited`, no blank Evidence cell; reviewer confirmed the rows match the trial records | met, except the two overstatements in F14 and F15 |
| 2 | Every duty has an equivalent, a workaround or "no equivalent" | U1-U18; U3, U4, U13 now begin with the label | not met for U6 (F15: its verdict says "no equivalent needed" while the row describes a workaround) and U13 (F14: "No equivalent" where the mechanism was not tried) |
| 3 | States whether sbx runs on Windows + WSL2, with evidence | `## Host`: `yes, partly`, with the T1-T3 output | met on the page; the same statement on #73 still carries the removed KVM claim (F13) |
| 4 | One recommendation and its rationale | one `**Recommendation:** hybrid` line | met, with the U13 dependency in F14 |
| 5 | Follow-up issues filed and linked | #85 and #86 open; linked in the page and in a comment on #73 | met |
| 6 | `.devcontainer/` and the skills unchanged | `git diff --stat origin/main...HEAD -- .devcontainer skills` empty | met |

**Documentation check.** The only page is the new one; no existing page describes behaviour this change alters, and the plan said so. The reviewer checked the page's account of `.devcontainer/` at HEAD, including main's new changes, and found the step numbering and the chown, empty-lock and base-branch behaviour accurate, apart from U6 (F15). No account name, email, token, organisation id or one-time code is on the page.

**Findings**

- **F13 — blocking, `/codeo:implement`'s.** The comment posted on #73 (`gh issue view 73 --json comments`, the result comment) says "the Linux-in-WSL2 route has no KVM". That is the claim round 1's F1 removed from the page, and it is the issue-side answer to criterion 3. Edit the comment to say the route was not tried and whether `/dev/kvm` exists was not checked.
- **F14 — blocking, `/codeo:implement`'s.** `docs/dev-environment-sbx-evaluation.md` U13 (line ~105) and the Recommendation (~423): the row says "No equivalent" for the window title but admits `window.title` in `.vscode/settings.json` was not tried, and `window-title.sh` only writes a workspace setting into the clone, which nothing in it ties to the dev container. The Recommendation then uses "There is no window title (U13)" as a reason against migrating. Mark U13 untried (the script could be run in the sandbox and the folder opened over Remote-SSH) and say in the Recommendation that the window title is not shown to work.
- **F15 — blocking, `/codeo:implement`'s.** U6 (line ~98): the page says the check is that "the clone folder must equal the container's Docker name" and the verdict is "No equivalent needed: the Docker-name constraint is Docker's rule for container names". At HEAD the folder is the Docker name by construction (`runArgs --name=${containerWorkspaceFolderBasename}`), and `folder-check.sh` checks that the folder names what the lock says (`container-name.sh --docker`: `<codename>-<N>` with a lock, `<codename>-home` on the base branch). The row's own next sentence says the check would compare the sandbox name with the lock, which is what #85 asks for. Describe the real check, and give the verdict as a workaround (untried, #85).
- **F16 — non-blocking.** D7, U9 and the Recommendation (~82, ~101, ~432): "the sandbox has no git identity" rests on `git config user.name` printing nothing (T7); `user.email` was not checked. Say "no `user.name`", or check both.
- **F17 — non-blocking, and one reviewer claim not upheld.** The reviewer said #86's body ("the `docker.io/sbx/claude:latest` image changed digest between two creates the same day (T10)") overstates T10 and dates it wrong. Checked against the recorded output: both creates printed an `Image:` line carrying the same digest as the `Kit:` line (`4df39400…` at T3 and again at T8, `0fb3e2c5…` at T10), and T8 and T10 were both on 2026-11-15, so #86's sentence is supported by the printed `Image:` line and is not a defect. The page's more cautious wording ("the printed kit digest differed; whether the base image changed was not checked") is true and stays; round 1's F3 was stricter than the evidence needed, and nothing is routed for it.
- **F18 — non-blocking.** T4's time: the page has `real 2m37.938s`, the pasted output had `2m37.941s`; use one figure.
- **F19 — non-blocking.** Evidence cells omit a trial they cite: D3 names T3, T5, T8 but the name-reuse error and the per-clone `safe.directory` come from T9; D2 names T12 but `claude` running interactively from WSL bash is T6.
- **F20 — non-blocking.** The Recommendation's "Why not stay" opens with costs "removed by what was tried, not just by what Docker says" and then lists microVM isolation, which is cited, and says the `codeo-<N>` naming cost "goes away" while U1 keeps naming as a convention and #85 needs a name-against-lock check. Separate the tried points from the cited ones and soften the naming claim.
- **F21 — non-blocking.** The code blocks under T3, T7, T8, T9 and T11 are condensed paraphrases, not verbatim output (line ~197 joins two printed lines). Label them "summary of output", or quote the lines as printed.
- **F22 — non-blocking.** Wording leftovers: line ~114 says "run as `sbx.exe` from WSL bash" twice; line ~21 says "later `tried T<n>, <date>`", left from before the trials; U2 repeats "because the clone follows the host's checked-out ref".
- **F12 (carried from round 1) — non-blocking, `/codeo:plan`'s.** `.codeo/73/plan.md`'s `### Footprint` lacks `sequenced:`. **F23 — non-blocking, outside this diff:** `sync-main.sh` exits 1 after a clean merge (`comm … not in sorted order`); the plugin's script.

Declined by the reviewer, left to the engineer: whether hybrid is the right choice, the scope and design of #85 and #86, and re-checking the cited Docker claims against the live pages.

**Verdict: back to `/codeo:implement`.**

## Log

- 2026-11-15 — round 2: build and suite pass, 4 of 6 criteria met, 3 blocking findings, back to implement · cost: 4m · opus-5-5 428k in + 2.9M cached / 15k out · sonnet-5-5 337k in + 1.8M cached / 4k out
- 2026-11-15 — round 1: build and suite pass, 5 of 6 criteria met, 3 blocking findings, back to implement · cost: 4m · opus-5-5 347k in + 3.9M cached / 17k out · sonnet-5-5 270k in + 1.5M cached / 3k out
