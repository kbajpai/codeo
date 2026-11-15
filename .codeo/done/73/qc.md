# Issue #73 — qc

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/73 |
| Branch | `docs/evaluate-docker-sandboxes-sbx-against` |
| Updated | 2026-11-15 |

## Where this stands

Round 4 is written: the build and the suite pass on the tree merged with `origin/main`, round 3's blocking findings F24 and F25 are fixed, all six criteria are met, and the review found no Critical issue, two Important and six Minor, all non-blocking. The verdict is clear: next is `/codeo:close`.

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

### Round 3 — 2026-11-15

**Commands run** (project root, on `f414f7f`: the round-3 implement commit; the branch already contained `origin/main`):
- `sync-main.sh --abort-on-conflict`: `the branch already contains origin/main`, exit 0. `overlap.sh 73` and `overlap.sh --outside 73`: no output.
- `git diff origin/main...HEAD --stat`: 7 files, 1142 insertions: `.codeo/73/{implement,init,issue,plan,qc}.md`, `docs/dev-environment-sbx-evaluation.md`, `docs/plans/2026-11-14-evaluate-docker-sandboxes-sbx.md`.
- `scope.sh origin/main HEAD`: `suite shell needed for unclassified paths:` the five `.codeo/73/*.md` files, then `suite.shell=true`; no `deploy=` line (no environment).
- Build (`shell`: `true`): exit 0. `bash tests/run.sh`: `all cases passed`, exit 0.
- `overlay.sh qc invariants-extra` and `wiki-rules`: exit 3 (none). `git diff --stat origin/main...HEAD -- .devcontainer skills`: empty.
- Page checks: no blank Evidence cell; 28 rows (22 `tried`, 6 `cited`), each row 7 fields wide; one `**Recommendation:** hybrid` line; no email, token, organisation id or username on the page. `gh issue view 85` and `86`: both `OPEN`. #73's last comment now says the Linux-in-WSL2 route "was not tried" and links #85 and #86.
- Independent review (opus, `QC review:`, given the criteria, the range `aaf4883..f414f7f` and the instruction to compare the #73 comment with the page): "With fixes", no Critical findings, two Important, seven Minor.

**Round 2's blocking findings, rechecked.** F13 (blocking in round 2) — fixed: the #73 comment no longer asserts "no KVM". F14 (blocking in round 2) — fixed: U13 begins `Not tried:` and the Recommendation says the window title is not shown to work. F15 (blocking in round 2) — fixed: U6 describes the real check and is a workaround. F16, F18-F22 (non-blocking in round 2) — fixed.

**Acceptance criteria**

| # | Criterion | Settled by | Verdict |
|---|---|---|---|
| 1 | A written comparison exists, covering every driver and requirement, each point marked tried or cited | `docs/dev-environment-sbx-evaluation.md`: D1-D10, U1-U18, 22 `tried` and 6 `cited`, no blank cell | not met — U8 is marked `tried` for work that was not run (F25), and D3 states a limit that T8 disproves (F24) |
| 2 | Every duty has an equivalent, a workaround or "no equivalent" | U1-U18 each carry a verdict | met — U8's verdict overstates (F25), and U13 and U16 are worded off the three labels (F27, F29), non-blocking |
| 3 | States whether sbx runs on Windows + WSL2, with evidence | `## Host`: `yes, partly`, with the T1-T3 output; the #73 comment agrees | met — "partly" is not defined (F31) |
| 4 | One recommendation and its rationale | one `**Recommendation:** hybrid` line | met |
| 5 | Follow-up issues filed and linked | #85 and #86 open; linked on the page and in a comment on #73 | met — their wording is stronger than the page in two places (F26) |
| 6 | `.devcontainer/` and the skills unchanged | `git diff --stat origin/main...HEAD -- .devcontainer skills` empty | met |

**Documentation check.** The only page is the new one; no existing page describes behaviour this change alters. The reviewer checked the page's account of `.devcontainer/` at HEAD (sudo at `Dockerfile:37`, `runArgs`, the volumes, the three extensions, the step numbering, the `REMOTE_CONTAINERS` gate in `session-title.sh`, the `~/.claude` note in the README) and found it accurate.

**Findings**

- **F24 — blocking, `/codeo:implement`'s.** `docs/dev-environment-sbx-evaluation.md` D3 (line ~78) says "A sandbox name cannot be reused (`sandbox 'codeo-b' already exists`)", and the Recommendation counts it as a cost of `codeo-<N>` naming. T8 removed `codeo-a` and then created `codeo-a` again, which worked (`real 0m13.078s`); T9 shows only that `create` with the name of a sandbox that exists fails. A name is unique among existing sandboxes and free again after `sbx rm`. Fix both places, and the T9 Result sentence if it says the same.
- **F25 — blocking, `/codeo:implement`'s.** U8 (line ~100) is "Equivalent, tried" for a duty that is `gh auth setup-git` followed by a check that the token has the project scope. T6 shows only that `gh auth status` inside the sandbox reports a login with the `project` scope; the row itself says the start script's check was not run, and neither `gh auth setup-git` nor a push or authenticated fetch from inside a sandbox was run. The hybrid depends on getting commits out of a `--clone` sandbox by pushing (D3, T8, #86), so a reader would take "tried" to cover it. Split the verdict: the `gh` login and scope are tried (T6); git-over-HTTPS credential wiring and a push from a sandbox are not tried, and say which issue covers the push check (#85 or #86).
- **F26 — non-blocking.** #86's body says "There is no window title (T12)" and #85's says "so there is no git identity (T7)"; the page was corrected to "not tried" and "no `user.name` was set (`user.email` was not checked)". Bring both issue bodies in line (`gh issue edit`).
- **F27 — non-blocking.** U13 opens "Not tried:", which is none of the three labels the criterion names; the row already describes a candidate, so label it "Workaround, untried:". The clause "the sandbox set no window title" appears nowhere in the T12 record (it says only that `window.title` was not tried); drop it.
- **F28 — non-blocking.** U6 says "otherwise a `todo:` line"; with no lock and off the base branch, `folder-check.sh` leaves a folder shaped `<codename>-<digits>` alone and reports only a folder of neither shape. Add the exception.
- **F29 — non-blocking.** U16 opens "Observed:" rather than a label; its "no equivalent … other than a kit volume or a saved template" is a cited workaround; its `tried T7, T8` Evidence concerns plugins, not git config. State one verdict and say the git-config persistence is cited only.
- **F30 — non-blocking.** U14's workaround needs a change to `session-title.sh`'s `REMOTE_CONTAINERS` test, which neither #85 nor #86 lists (#86 covers window titles, not session titles). Add it to one of them, or say on the page that it is deliberately left out.
- **F31 — non-blocking.** D2 says the container "opens only through" Clone Repository in Named Container Volume and cites the README, which also describes Reopen in Container (README line ~36); say "is opened through … (the README's documented flow)". The Host verdict "yes, partly" never says what "partly" excludes; add one clause naming it, and make the #73 comment say the same.
- **F12 (carried) — non-blocking, `/codeo:plan`'s.** `.codeo/73/plan.md`'s `### Footprint` lacks `sequenced:`. **F23 (carried) — non-blocking, outside this diff:** `sync-main.sh` exits 1 after a clean merge when main has moved.

Declined by the reviewer, left to the engineer: the accuracy of the cited Docker pages, whether hybrid is the right choice, and the dossier and plan files as records.

**Verdict: back to `/codeo:implement`.**

### Round 4 — 2026-11-15

**Commands run** (project root, on `2d66445`, the round-4 implement commit `e1a3cdc` plus the merge of `origin/main`):
- `sync-main.sh --abort-on-conflict`: `merged origin/main (2 commit(s))` (`8842abc` #89, `f9bfa76` #90), then exit 1 with `comm: file 2 is not in sorted order` (F23, carried: the script, not this change); the `also changed on main:` list was not printed. `git diff --name-only e1a3cdc HEAD` shows what main brought: `.codeo/done/83/*`, `.codeo/done/87/*`, `.devcontainer/README.md`, `.devcontainer/scripts/devcontainer-start.sh`, `CHANGELOG.md`, two plans under `docs/plans/`, `skills/doctor/SKILL.md`, `skills/setup/SKILL.md`, `tests/closing-block.test.sh`, `tests/devcontainer.test.sh`. None is a file this branch changed; the page's account of `devcontainer-start.sh` (step numbering, lock step 3a) is unaffected by main's `.codeo/active` change (it adds a TODO for a file naming no issue).
- `overlap.sh 73` and `overlap.sh --outside 73`: no output.
- `git diff origin/main...HEAD --stat`: 7 files, 1201 insertions: `.codeo/73/{implement,init,issue,plan,qc}.md`, `docs/dev-environment-sbx-evaluation.md`, `docs/plans/2026-11-14-evaluate-docker-sandboxes-sbx.md`.
- `scope.sh origin/main HEAD`: `suite shell needed for unclassified paths:` the five `.codeo/73/*.md` files, then `suite.shell=true`; no `deploy=` line (no environment).
- Build (`shell`: `true`): no build command, nothing to run. `bash tests/run.sh` on the merged tree: `all cases passed`, exit 0.
- `overlay.sh qc invariants-extra` and `wiki-rules`: exit 3 (none). `git diff --stat origin/main...HEAD -- .devcontainer skills`: empty.
- Page checks: 28 rows (D1-D10, U1-U18), 21 `tried` and 7 `cited`, each row 7 fields wide, no blank Evidence cell; one `**Recommendation:** hybrid` line; none of `cannot be reused`, `no git identity`, `There is no window title`, an email address or a token on the page. #85 and #86 are `OPEN`; #85 says "no `user.name` was set (`user.email` was not checked)" and lists the push check as requirement and criterion; #86 says no window title was set and setting one was not tried, and lists session titles; #73's last comment says "21 tried, 7 cited", defines "partly" as the page does, and links #85 and #86.
- Independent review (opus, `QC review:`, given the criteria, the range `f9bfa76..2d66445` and the issue numbers, not the dossiers): "With fixes", no Critical findings, two Important, six Minor.

**Round 3's blocking findings, rechecked.** F24 (blocking in round 3) — fixed: D3 and the Recommendation say a name is unique among existing sandboxes (T9) and usable again after `sbx rm` (T8). F25 (blocking in round 3) — fixed: U8 reads "Equivalent for the login (tried), not shown for the git wiring" and names what was not run; #85 carries the push check. F26-F31 (non-blocking in round 3) — fixed as the page, #85 and #86 now read.

**Acceptance criteria**

| # | Criterion | Settled by | Verdict |
|---|---|---|---|
| 1 | A written comparison exists, covering every driver and requirement, each point marked tried or cited | `docs/dev-environment-sbx-evaluation.md`: D1-D10, U1-U18, 21 `tried`, 7 `cited`, no blank Evidence cell | met |
| 2 | Every duty has an equivalent, a workaround or "no equivalent" | U1-U18 each carry a verdict | met |
| 3 | States whether sbx runs on Windows + WSL2, with evidence | `## Host`: `yes, partly`, defined, with T1-T3 output; the #73 comment agrees | met |
| 4 | One recommendation and its rationale | one `**Recommendation:** hybrid` line with "Why not stay" and "Why not migrate everything" | met |
| 5 | Follow-up issues filed and linked | #85 and #86 open; linked on the page and in a comment on #73 | met |
| 6 | `.devcontainer/` and the skills unchanged | `git diff --stat origin/main...HEAD -- .devcontainer skills` empty | met |

**Documentation check.** The only page is the new one; no existing page describes behaviour this change alters, and main's new `.codeo/active` rule in the README and start script does not touch a row. The reviewer found the page's account of `.devcontainer/` accurate.

**Findings** (none blocks the merge)

- **F32 — non-blocking, `/codeo:implement`'s.** The page (T10 Result, line ~371, and the Fragility bullet) says the kit digest differed and "whether the base image changed was not checked", while #86's body states the `docker.io/sbx/claude:latest` image changed digest between two creates (T10). The recorded output has an `Image:` line with the same digest as the `Kit:` line (see F17), so #86 is supported, but the page quotes no `Image:` line, so a reader cannot check it. Quote the `Image:` lines on the page, or soften #86.
- **F33 — non-blocking.** D1 and "Why not stay" cite "credentials stay outside the VM" as Docker's design (`cited`), while T6 shows `gh` inside the sandbox logged in via `GH_TOKEN`, and whether that is the real token or a placeholder was not tested. The label is honest; a sentence naming the tension would stop a reader weighing it as isolation gained.
- **F34 — non-blocking.** The Recommendation's naming sentence says "there is no volume or folder-naming rule" twice and ends "to work around" after saying names must be checked by a start script. Reword.
- **F35 — non-blocking.** The follow-up list maps #85 without U6 and U8 and #86 without U14, though the issue bodies cover them. #86 says "trials T5 to T12" in one place and "T8 to T12" in another.
- **F36 — non-blocking.** D3's "1m47s (image pull)" infers the pull from T8's "(cached)"; U4's "the bit the index records survives" is checked for `tests/run.sh` only; line 49 says the Linux route "was not tried" twice; the Trials introduction still carries planning instructions ("Paste every output…").
- **F12 (carried) — non-blocking, `/codeo:plan`'s.** `.codeo/73/plan.md`'s `### Footprint` lacks `sequenced:`. **F23 (carried) — non-blocking, outside this diff:** `sync-main.sh` exits 1 after a clean merge when main has moved.

Declined by the reviewer, left to the engineer: whether hybrid is the best choice, the accuracy of the cited Docker pages (not fetched), and the plan and dossier files as records. The engineer may file F32-F36 through `/codeo:triage`; no issue was filed in this pass.

**Verdict: clear — forward to `/codeo:close`.**

## Log

- 2026-11-15 — round 4: build and suite pass, 6 of 6 criteria met, no blocking findings, clear · cost: 3m · opus-5-5 197k in + 1.7M cached / 12k out · sonnet-5-5 119k in + 740k cached / 2k out
- 2026-11-15 — round 3: build and suite pass, 5 of 6 criteria met, 2 blocking findings, back to implement · cost: 4m · opus-5-5 482k in + 1.8M cached / 16k out · sonnet-5-5 29k in + 2.1M cached / 3k out
- 2026-11-15 — round 2: build and suite pass, 4 of 6 criteria met, 3 blocking findings, back to implement · cost: 4m · opus-5-5 428k in + 2.9M cached / 15k out · sonnet-5-5 337k in + 1.8M cached / 4k out
- 2026-11-15 — round 1: build and suite pass, 5 of 6 criteria met, 3 blocking findings, back to implement · cost: 4m · opus-5-5 347k in + 3.9M cached / 17k out · sonnet-5-5 270k in + 1.5M cached / 3k out
