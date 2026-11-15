# Issue #73 — qc

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/73 |
| Branch | `docs/evaluate-docker-sandboxes-sbx-against` |
| Updated | 2026-11-15 |

## Where this stands

Round 1 is written: the build and the suite pass, five of the six criteria are met, and the review found three claims on the page that are stronger than their evidence. The change goes back to `/codeo:implement`.

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

## Log

- 2026-11-15 — round 1: build and suite pass, 5 of 6 criteria met, 3 blocking findings, back to implement · cost: 4m · opus-5-5 347k in + 3.9M cached / 17k out · sonnet-5-5 270k in + 1.5M cached / 3k out
