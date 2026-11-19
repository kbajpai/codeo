# Issue #112 — qc

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/112 |
| Branch | `feat/verify-live-session-signal-hosted` |
| Updated | 2026-11-19 |

## Where this stands

Round 1 done, back to `/codeo:implement`: two blocking findings (a changelog sentence that is not true, and the follow-up issues three criteria require are not filed), plus four non-blocking corrections that ride in the same round.

## Questions

None.

## Outcome

### Round 1 — 2026-11-19

**Sync.** `bash scripts/sync-main.sh --abort-on-conflict`: `sync-main: the branch already contains origin/main`, exit 0, so there are no `also changed on main:` lines. `overlap.sh 112` printed nothing; `overlap.sh --outside 112` printed nothing.

**Scope.** `scope.sh origin/main HEAD`: `suite.shell=true` (`docs/**` and the unclassified `.codeo/112/*` and `CHANGELOG.md`). No `deploy=` line: no environment is configured.

**Build.** The `shell` suite's `build` is `true`: `build rc=0`.

**Tests.** `bash tests/run.sh` (the `shell` suite, whole): `all cases passed`, `suite rc=0`.

**Acceptance criteria.** The diff is documentation and dossiers only (`git diff origin/main...HEAD --stat`: `CHANGELOG.md`, `docs/handoff.md`, the plan, `.codeo/112/*`); no script, hook or skill changes, as the plan says. The web-session evidence is the engineer's screenshots, recorded in `implement.md` → Notes → Round 1.

| # | Criterion | Verdict | Settled by |
|---|---|---|---|
| 1 | `beat --force` publishing the signal, and which path | not met — neither path carried it; both refused with HTTP 403 (`git push`; `github.sh ref put`: "Write access to this GitHub API path is not permitted through this proxy (HTTP 403)") | `implement.md` Notes, Task 1 |
| 2 | another clone lists the session and the `live:` line | untestable — nothing was published, so there is nothing to list | `implement.md` Notes, Tasks 2-4 |
| 3 | the user the signal names, or what it named and the follow-up filed | not met — the user is recorded as `Claude`, which is inferred (F3), and the follow-up is not filed (F2) | `implement.md` criteria table, row 3 |
| 4 | branch tip unchanged, and clear removes the session | met for the tip (`4b55d8e97c31…` before and after, in the web session's two `ls-remote` runs); the clear half has nothing to remove | `implement.md` Notes, Task 1 |
| 5 | the hook publishes by itself, or the issue records it does not and files the follow-up | not met — the record says the hook cannot fire (`codeo` is not in `claude plugin list`), and the follow-up is not filed (F2) | `implement.md` Notes, Task 5 |
| 6 | both writes refused: refusal text, #104's criterion stated not met, follow-up filed for the design change | not met — the text and the "not met" statement are recorded and posted on #112, but the follow-up is not filed (F2) | `implement.md` Notes; comment on #112 |

**Documentation check.** `docs/handoff.md` (*Who is working right now*) and `CHANGELOG.md` were checked against `scripts/live.sh`, `scripts/lock.sh` and `scripts/github.sh`. The machine-label sentence matches the code (`live.sh:107-109` treats `session: unknown` as absent and falls back to the hostname). Two statements go beyond the evidence, F4 and F5, and one is untrue, F1. The plan names these two pages and says `README.md`, `docs/dossier.md` and `docs/skills.md` do not move; nothing in the diff changes behaviour they describe.

**Independent review** (opus, given the acceptance criteria and the diff only). Its assessment, quoted: "No. The record of the run is sound. But the changelog claims follow-ups were filed when none were, and criteria 3, 5 and 6 explicitly require those follow-ups. The user label and the proxy's 'development branch only' rule are also stated beyond what the evidence shows." Its findings were each checked here against the files: `CHANGELOG.md:9` and `implement.md` (F1, F2), `scripts/live.sh:114-118` and `scripts/github.sh:31-33` (F3), the screenshots' wording as recorded in `implement.md` (F4, F5). It declined to judge criteria 2 and the clear half of 4, the design change itself, the `CODEO_GITHUB_LOGIN` override, and the Q6/Q7 merge conflicts; none changes anything here.

**Findings.**

- **F1 — blocking, `/codeo:implement`'s.** `CHANGELOG.md:9`: the bullet ends "the follow-ups are filed separately", and `implement.md` says F1-F3 are not filed (`/codeo:issue` refused in that container); the comment on #112 says "to be filed". A changelog is read long after anyone remembers this round, so a sentence that is not true there is wrong whatever happens next. Fix direction: once the issues exist, cite their numbers; until then say they are to be filed.
- **F2 — blocking, `/codeo:implement`'s, after an action only the engineer can take.** Criteria 3, 5 and 6 each accept a negative result only "and files the follow-up"; no issue exists, so each stays `not met`. `/codeo:issue` refuses in this container (role `issue:112`). Fix direction: file F1-F3 with `/codeo:issue` in the home container (their drafts are under `implement.md` → Notes → Later work), then `/codeo:implement` records the three numbers in its criteria table and Outcome, and in the changelog bullet (F1), and replaces the "Later work" lines with them.
- **F3 — non-blocking, `/codeo:implement`'s.** `implement.md` (criteria row 3, Findings) and the comment on #112 say the signal "would have named `Claude`". `beat` calls `user_label` first, which runs `github.sh user login` (`GET /user`) and only falls back to `git config user.name` when that fails (`scripts/live.sh:114-118`). That `GET /user` is refused on a web session is documented in `scripts/github.sh:31-33` but was not seen in this run, and a refused write does not show it. Fix direction: read the user from the `bash -x` trace or the commit the run built, or record it as "not determined; `git config user.name` is `Claude`"; F3's issue draft gets the same wording.
- **F4 — non-blocking, `/codeo:implement`'s.** `docs/handoff.md:184-185`: "its proxy accepts pushes only to the session's own development branch" is the session's own reading of a 403 on one ref; no other push was tried. Fix direction: state what was observed (a push to `refs/codeo/live/…` is refused, and so is the REST write).
- **F5 — non-blocking, `/codeo:implement`'s.** `CHANGELOG.md:9`: "`.claude/settings.json` enabling `codeo@codeo` did not install it" gives a cause nobody examined; the engineer said an environment setup script installs the plugin. Fix direction: say only that the check's session had no `codeo` plugin.
- **F6 — non-blocking, `/codeo:implement`'s.** `docs/handoff.md:183-188` writes one session's proxy behaviour as a permanent property of every hosted session; the hosting product can change it. Say it as an observation, or point at the follow-up. Also, `ref delete` was never run, so `clear`'s REST path in a web session is unverified; one line in F1's issue draft covers it.

Out of scope, recorded once: the `issue.md` dossier-check failures (`## Outcome` missing, two log lines without a cost) are older than this change.

**Verdict: back to `/codeo:implement`.**

## Log

- 2026-11-19 — round 1: back to `/codeo:implement` (2 blocking, 4 non-blocking) · cost: 0m · opus-5-5 209k in + 511k cached / 1k out · sonnet-5-5 3k in + 236k cached / 5k out
