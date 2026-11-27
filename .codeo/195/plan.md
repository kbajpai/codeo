# Issue #195 — plan

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/195 |
| Branch | `feat/195-identify-acting-user-strictly-verify` |
| Updated | 2026-11-27 |

## Where this stands

Round 2, after a send-back from `/codeo:qc` (`qc.md` round 1). Q9-Q11 answered (recommendations accepted) and the round-2 plan approved and written to `docs/plans/2026-11-27-identify-acting-user-195-round-2.md` (unstaged). The footprint is committed; `overlap.sh` then printed four paths for #204, raised as Q12. The outcome waits for Q12. QC's blocking finding F1 is this
plan's: decision Q2 (a hosted web session's `unverified` login is compared only with the lock's own
`user:` line) makes the ownership checks pass for everyone on web, because `take web` writes that
line from the same variable. Two acceptance criteria are unmet there. Q9-Q11 re-decide it, with the
two plan-owned side findings (F2, F3). Nothing is drafted until they are answered. The round also
carries the implement-owned fixes F4-F8 as tasks (listed under `## Notes`, no question needed).

## Questions

### Q1 — Make `user login` strict, or add a new strict verb beside it?

**Why it matters:** `user login` is also read by `intake.sh` (lease `by:` lines, with an email
fallback) and, indirectly, `live.sh`. Making it refuse Bots and ignore the variable outside web
sessions changes all of them; a new verb leaves them alone but leaves two ways to ask "who am I".
**Options:** (a) new verb `github.sh user whoami` printing `login` and `type`, strict, and
`user login` left as the lenient best-effort label · (b) tighten `user login` itself and fix the
callers that relied on the leniency · (c) no preference, you pick.
**Recommendation:** (a). The strict path is what `init`, `lock take`, claim and `lock.sh verify`
call; the lenient one stays for labels (live signal, lease `by:`) where a wrong name is harmless.

**Answer:**
(a) A new strict verb `github.sh user whoami` printing login and type; `user login` stays the lenient best-effort label. (Engineer: "go with your recommendations on all of them", 2026-11-27.)

### Q2 — In a hosted web session with only `$CODEO_GITHUB_LOGIN`, what may the session do?

**Why it matters:** the issue lets the variable stand in for the login only where `GET /user`
cannot work (web), but forbids using it for an ownership check. So in web, `init` can record the
variable, while `lock.sh verify` cannot rely on it. Something has to decide what verify does there.
**Options:** (a) web verify compares the variable only against the lock's own recorded `user:`
(proving "same session as the one that started it") and never against assignees, with a one-line
note that ownership was not independently verified · (b) web verify is skipped entirely with that
note · (c) web verify refuses unless a real login resolves, which today means it always refuses.
**Recommendation:** (a): it still catches a stale checkout, and it never lets the variable name
someone else as the owner.

**Answer:**
(a) Web verify compares the variable only against the lock's own recorded `user:`, never against assignees, and says ownership was not independently verified. (Engineer: go with recommendations.)

### Q3 — How is "Bot" decided, and what is refused?

**Why it matters:** `GET /user` returns `.type`. A shared bot token reports `Bot`; a user-owned PAT
reports `User`; a GitHub App installation token cannot call `/user` at all and falls into the
"unresolved" case. The issue refuses both unresolved and Bot outside web.
**Options:** (a) refuse when `.type != User` (so `Organization`/anything unexpected also refuses) ·
(b) refuse only on `.type == Bot` or a login ending `[bot]`.
**Recommendation:** (a), the stricter form; the whole point is one real person per login.

**Answer:**
(a) Refuse when `.type != User`. (Engineer: go with recommendations.)

### Q4 — Where and in what form is the login recorded?

**Why it matters:** the issue says the plan decides the file format, and `lock.sh`, the live signal
and `init.md` are all read by scripts, so the format is a convention to pin in `docs/handoff.md`
and `docs/dossier.md`. Existing locks and dossiers have none of it.
**Proposal:** `init.md`'s header table gets a row `| Owner | alice |` written at step 9 (fresh) and
on resume; the lock gets a line `user:    alice` after `host:`; the live signal keeps its existing
`user:` field but is fed from the strict resolver. A lock with no `user:` line (written before this
change) is treated as legacy: `verify` falls back to assignees and the resume line, and says so.
The resume line stays in its current form (login after `by`), so the three copies of the regex
need no change.
**Options:** accept the proposal · change the row/line names · record somewhere else.

**Answer:**
Accept the proposal: `| Owner |` row in `init.md`, `user:` line in the lock, live signal fed from the strict resolver, a lock without `user:` is legacy. (Engineer: go with recommendations.)

### Q5 — What defines the owner that `lock.sh verify` compares against?

**Why it matters:** this is the heart of "A's stale checkout after B resumed is refused", and the
checkout cannot tell from its own files that B resumed; B's resume line is on the pushed branch.
**Proposal:** `verify <issue>` resolves the current login (Q1), then fetches `origin/<branch>` and
reads, in order: the latest `resumed: by <login>` line in the pushed `init.md`, else the pushed
`init.md`'s Owner row; and the issue's assignees. The caller passes only if it is the owner and an
assignee, **and** the local lock's `user:` equals the owner (that last comparison is what refuses
A's stale checkout). Refusal is one line: `codeo: #195 belongs to <owner> (last resumed <date>)…`.
**Open sub-question — fetch fails (offline, or the branch is not pushed yet, as at `init`
before the first push):** (a) fail closed with a line saying ownership could not be checked ·
(b) fall back to the local files and say so. **Recommendation:** (b) only when the branch has no
`origin` ref at all; (a) when the fetch itself errors.
**Options:** accept the proposal and the recommendation · different owner rule · different
offline behaviour.

**Answer:**
Accept the proposal. Fetch error fails closed; no `origin` ref at all falls back to local files and says so. (Engineer: go with recommendations.)

### Q6 — What is the override, how does it work "once", and where is it recorded?

**Why it matters:** the issue wants an explicit, recorded override that works once. Existing
patterns differ: `init`'s takeover is a prose line under `## Notes`; `intake.sh lease take
--override <text>` is script-written; `CODEO_HOME_EDITS=allow` (#192) is an environment variable
that records nothing. Role-guard refusals deliberately have none, and that stays.
**Proposal:** `lock.sh verify <issue> --override "<the engineer's words>"`. It passes that one
call and appends `- <date> — override: <login> over <owner>: "<words>"` to `init.md`'s `## Notes`
(never the resume line), printing the line so the skill commits it with its next dossier commit.
"Once" means: the next step's `verify` is judged again, so a second step needs its own override —
**unless** the engineer wants a takeover to transfer ownership. For a real takeover the engineer
goes through `/codeo:init`'s existing resume path, which writes the resume line that makes them
the owner.
**Options:** accept (per-call override, takeover is `init`'s resume path) · override transfers
ownership by writing a resume-style line itself · the override is an environment variable like #192.

**Answer:**
Accept: per-call `--override "<words>"` recorded under `## Notes`; a real takeover goes through `init`'s resume path. (Engineer: go with recommendations.)

### Q7 — Stash/abandon by a non-owner, and the `assignee-remove` default

**Why it matters:** B4: `assignee-remove <N>` defaults to the current login, so B's stash leaves A
assigned and moves the card. Acceptance requires that a non-owner's stash changes neither.
**Proposal:** close's stash/abandon step calls `lock.sh verify` first (refuses a non-owner without
the override); on success it removes the *recorded owner* explicitly (`assignee-remove <N>
<owner>`), not the caller. `github.sh issue assignee-remove` stops defaulting to the current login
and requires the login argument (a missing one is an error), so the defect cannot recur from any
caller. `tests/github.test.sh` and `tests/close-skill.test.sh` update accordingly.
**Options:** accept · keep the default but only change close's call (smaller, leaves the trap).

**Answer:**
Accept: stash/abandon verify first and remove the recorded owner explicitly; `assignee-remove` requires the login argument. (Engineer: go with recommendations.)

### Q8 — One pull request or two?

**Why it matters:** the issue merges identity and ownership, and says ownership depends on
identity. Identity (Q1-Q4: strict resolver, `init`/`take`/claim refusals, recorded login) can ship
alone and is safe to merge first; ownership (Q5-Q7: `verify`, step 0 in four skills, close/stash,
new rule ids, hash churn) is the larger and riskier half.
**Options:** one PR, with identity tasks first so a partial build still works · two PRs, filed as
a second issue by `/codeo:issue` and sequenced after this one. **Recommendation:** one PR; the
acceptance criteria are one list, and splitting buys little when the tasks already run in order.

**Answer:**
One pull request, identity tasks first. (Engineer: go with recommendations.)

### Q9 — Web sessions: what does an `unverified` login get compared with? (replaces Q2)

**Why it matters:** today `lock.sh take web` writes `user:` from `$CODEO_GITHUB_LOGIN` and `verify`
compares the same variable with that line (`scripts/lock.sh:95`, and the `unverified` branch of
`verify`), so B on A's branch and A's stale checkout both pass on web. The issue says the variable
is "never used to satisfy an ownership check"; a comparison that can only *refuse* does not satisfy
anything.
**Options:** (a) an `unverified` login is compared exactly like a verified one — pushed owner,
assignees, the lock's `user:` — and a mismatch refuses (overridable like any ownership refusal); a
match passes with the "not independently verified" note. The same rule in `take` (no lock on a
mismatch) and in `init`'s prose (another engineer's assignee or owner stops an unverified login
unless the override is recorded; the lost-checkout resume needs the variable to equal the
assignee). · (b) refuse every ownership-gated step in a web session unless `GET /user` resolves
(today that means web sessions cannot run plan/implement/qc/close at all). · (c) keep the code and
narrow the acceptance criteria to non-web hosts, which needs the issue's text changed.
**Recommendation:** (a). Cost to know: `take web` runs from the live-signal hook under an 8 second
bound and will now make the same network calls as elsewhere (`ls-remote`, `fetch`, `issue view`); a
timeout there means no lock and a TODO, as for any other host.

**Answer:**
(a) An `unverified` login is compared like a verified one (pushed owner, assignees, the lock's `user:`); a mismatch refuses and is overridable; a match passes with the "not independently verified" note; same rule in `take` and in `init`'s prose. (Engineer: "Go with your recommendations", 2026-11-27.)

### Q10 — Stash or abandon of a workflow begun before this change (QC F2)

**Why it matters:** `lock.sh owner` prints nothing for a dossier with no Owner row and old
`by no login` resume lines, so `close-16` skips the removal and the stashed issue stays assigned;
the next `/codeo:init` then stops on "another assignee", and `Safe to bump mid-workflow: yes` is not
quite true.
**Options:** (a) when no owner is recorded and `verify` passed without an override, remove the
caller's login (verify has already established the caller is an assignee whenever there are any) ·
(b) remove every assignee of the issue · (c) leave the behaviour and say in the changelog that a
legacy workflow's stash leaves the assignee to remove by hand.
**Recommendation:** (a): it restores what a stash did before, only for the legacy case, and never
when an override was used.

**Answer:**
(a) When no owner is recorded and `verify` passed without an override, remove the caller's login. (Engineer: go with recommendations.)

### Q11 — A failed `assignee-add` after an `init` takeover locks the new owner out (QC F3)

**Why it matters:** B takes A's workflow over through `init`'s resume path; the resume line makes B
the owner, but if `assignee-add` fails A stays the only assignee and every later `verify` refuses B
with `is assigned to A, not B — … take it over with /codeo:init`, a loop that names the wrong fix.
**Options:** (a) keep the refusal (an owner must be an assignee) but, when the caller *is* the
recorded owner, make the line name the real fix (`github.sh issue assignee-add <N> <login>`), and
have `init` write a failed `assignee-add` as a line under `init.md`'s `## Notes` so the next step
can see why · (b) let the recorded owner pass `verify` with a note even when not an assignee · (c)
leave as is.
**Recommendation:** (a): the assignee rule stays strict and the engineer is told the one command
that clears it.

**Answer:**
(a) Keep the refusal; when the caller is the recorded owner the line names the real fix (`github.sh issue assignee-add <N> <login>`), and `init` writes a failed `assignee-add` under `init.md`'s `## Notes`. (Engineer: go with recommendations.)

### Q12 — New overlap with #204 (`chore/204-fix-codeo-close-opens-pr`): proceed, sequence, or re-scope?

`overlap.sh 195` printed four paths for #204 that no earlier question names: `tests/fixtures/dossiers/good-basic/close.md`, `tests/fixtures/golden/case-a/close.md`, `tests/qc-verdict.test.sh`, `tests/role.test.sh`. #204 (assignee `kbajpai`) is now at `implement (working)`, its `changed:` line lists real files, and it waits on its own `qc.md` Q1 and Q2.

**Why it matters:** this plan's footprint has the `tests/**` glob, and #204 now changes those four test files. This round edits `tests/identity.test.sh` (new), `tests/lock-verify.test.sh`, `tests/lock.test.sh`, `tests/init-skill.test.sh`, `tests/close-skill.test.sh`, `tests/qc-skill.test.sh`, `tests/readme.test.sh` and `tests/skills-doc.test.sh`, none of which is one of the four, so the contact is the glob, not a file. The real contact with #204 is unchanged from `qc.md` Q2 (`skills/close/SKILL.md`, `skills/init/SKILL.md`, the docs pages, the rule inventory and its pinned hash), which this round touches again in Tasks 3, 4 and 6 (`init-11`, `close-16`).
**Options:** proceed and coordinate · sequence after #204 · re-scope.
**Recommendation:** proceed and coordinate, as for `qc.md` Q2: whichever branch merges second regenerates `tests/fixtures/skills-inventory.rules.sha256` and re-checks its `init`/`close` prose against the other's.

**Answer:**

## Notes

Calls made without asking (correct any of them in your answers):

- `lock.sh take` keeps its "never fails the caller" contract: on an unresolved or Bot login
  outside web it takes no lock and prints a `TODO` line, matching how it already reports a
  refused checkout. `init` and the claim path, which are skills, refuse outright with one
  `codeo:` line.
- `scripts/live.sh`'s `user_label` order (variable first) is reconciled with the strict resolver's
  rule: the variable is honoured only in web sessions. `docs/handoff.md` lines 195-206, which
  document the old order, are rewritten in the same task.
- A shared `is_web_session` helper replaces the inline `CLAUDE_CODE_REMOTE == true` tests this
  change touches (`github.sh`, `live.sh`, the new `verify`); the ones it does not touch stay.
- Role-guard refusals keep having no override (`plan-09`, `implement-10`, `qc-14`, `close-14`).
- The issue's out-of-scope line about "comparing the recorded login at later steps" is treated as
  superseded, as `init.md` noted; lease ownership stays out of scope.
- Docs this change will move: `docs/handoff.md` (The lock, the lock sample, step-0 checks, the
  live-signal user chain), `docs/dossier.md` (the Owner row), `docs/skills.md` (init, close),
  `README.md` troubleshooting ("A lock that is stuck or not yours"), `CHANGELOG.md` Unreleased.
- The one subagent report quoted `.claude/settings.json` paths; nothing in it asked for any action.

Round 2 — implement-owned findings from `qc.md` round 1 that this round's plan carries as tasks
(no decision needed; say so in an answer if any should be left out):

- F4: `docs/handoff.md` quotes `(last resumed <date>, or claimed <date>)`; the code prints
  `(claimed)`. The doc follows the code; the resume date is taken only from a line whose login the
  owner regex accepts.
- F5: the pushed dossier is fetched into a private ref (`refs/codeo/verify/<branch>`) and read from
  it, not from `FETCH_HEAD`, which the live-signal beat rewrites concurrently.
- F6: the Owner-row parser accepts a backticked login and flexible whitespace.
- F7: the `verify` flowchart shows the legacy-lock and web paths as built; `README.md` says "when it
  has any" for the assignee rule.
- F8: `tests/lock.test.sh`'s unresolved-login `take` case sets `CODEO_GITHUB_LOGIN`; the
  `--override` pin in `tests/qc-skill.test.sh` also catches a wrapped `lease take` command.
- Also corrected by Q9: `docs/handoff.md`'s "`CODEO_GITHUB_LOGIN` never satisfies `lock.sh verify`"
  passage, `docs/dossier.md`/`docs/skills.md`/`CHANGELOG.md` wording, and `skills/init/SKILL.md`'s
  three `unverified` carve-outs.


### Footprint

```
files:      lib/identity.sh, scripts/github.sh, scripts/claim.sh, scripts/lock.sh, scripts/live.sh, skills/init/**, skills/plan/**, skills/implement/**, skills/qc/**, skills/close/**, docs/handoff.md, docs/dossier.md, docs/skills.md, docs/skills-inventory.md, README.md, CHANGELOG.md, tests/**, docs/plans/2026-11-27-identify-acting-user-195.md, docs/plans/2026-11-27-identify-acting-user-195-round-2.md
wiki:       none
exclusive:  none
sequenced:  none
```

## Outcome

| | |
|---|---|
| Plan | `docs/plans/2026-11-27-identify-acting-user-195.md` (unstaged, awaiting the engineer's commit) |
| Shape | Executable plan under `docs/plans/`, 8 tasks, one PR, identity tasks first; reference-doc changes are in `docs/handoff.md`, `docs/dossier.md`, `docs/skills.md` (no separate `docs/<slug>.md`) |

**Decisions (Q1-Q8, recommendations accepted).** New strict `github.sh user whoami` beside a lenient `user login` (Q1); a web session with only `$CODEO_GITHUB_LOGIN` is compared only against the lock's own `user:` and never against assignees (Q2); refuse any `.type != User` (Q3); `| Owner |` row in `init.md`, `user:` line in the lock, live signal fed by the lenient resolver, a lock without `user:` is legacy (Q4); owner is the last resume line of the pushed `init.md`, else its Owner row, a fetch error fails closed and a branch with no `origin` ref falls back to local files (Q5); per-call `lock.sh verify --override "<words>"` recorded under `## Notes`, a lasting takeover goes through `init`'s resume path (Q6); stash/abandon verify first and remove the recorded owner, `assignee-remove` requires a login (Q7); one PR (Q8).

**Rejected.** Tightening `user login` itself (breaks lease and live-signal labels); skipping ownership in web sessions; ownership-transferring override; offline fallback to local files on a fetch error; two PRs.

**Calls made without asking.** `lock.sh take` keeps its never-fails contract (TODO line, no lock); the live signal's login order is reconciled; role-guard refusals keep no override; the intake's out-of-scope line about later-step comparison is treated as superseded; lease ownership stays out of scope. New logic lives in `lib/identity.sh` so `lock.sh` stays testable without repo config.

**Intake questions resolved.** The "Open at intake" note in `init.md` (Out of Scope line left over from the merged issues): ownership verification is in scope.

**Documentation pages the plan will change.** `docs/handoff.md` (The lock, the user chain, a Mermaid `verify` flowchart), `docs/dossier.md` (Owner row, `override:` line), `docs/skills.md` (init, close), `docs/skills-inventory.md` (rules `init-11`, `plan-10`, `implement-11`, `qc-15`, `close-15`, `close-16`), `README.md`, `CHANGELOG.md`.

**Optional skills.** `engineering:system-design` and `engineering:architecture` were not listed in this session; their structure was applied directly. No `/codeo:issue` filed.

## Log

- 2026-11-27 — Q1-Q8 raised · cost: 3m · fable-5-2 70k in + 382k cached / 4k out · sonnet-5-5 192k in + 1M cached / 22k out
- 2026-11-27 — planned: docs/plans/2026-11-27-identify-acting-user-195.md · cost: 8m · fable-5-2 70k in + 382k cached / 4k out · sonnet-5-5 235k in + 2.1M cached / 48k out · engineering:system-design and engineering:architecture unavailable, structure applied directly
- 2026-11-27 — round 2 (send-back from qc.md round 1): Q9-Q11 raised · cost: 1m · fable-5-2 380k in + 421k cached / 5k out
- 2026-11-27 — round 2: plan written, footprint committed, Q12 raised (new overlap with #204) · cost: 6m · fable-5-2 384k in + 824k cached / 6k out · sonnet-5-5 42k in + 3.4M cached / 20k out · engineering:system-design and engineering:architecture unavailable, structure applied directly
