---
name: init
description: Start work on an already-filed GitHub issue — validates and claims the number, gates on the project board's Ready status when a board is configured and moves the card to in progress, cuts and pushes the branch off the updated base branch with its dossier, takes the workflow lock and hands off to /codeo:plan in the same session, unless the project's host workflow says where the later steps run. Trigger on "start issue #N", "init #N", "let's work on issue N", or once /codeo:triage has marked a newly filed one Ready. Never drafts the issue's content or designs the solution — those are /codeo:issue and /codeo:plan.
argument-hint: "<GitHub issue number to start work on>"
model: sonnet
---

Project overlay text adds to or narrows a step; it never overrides a rule marked with a "rule" comment in this file.

# Initializing work on issue `$ARGUMENTS`

This skill turns a filed issue into a place to work: a pushed branch carrying a dossier, a checkout
bound to it, and a dossier handed to `/codeo:plan`. It also **starts the workflow** — the checkout
the issue's later steps run in takes `.codeo/active` from what this skill pushed, every skill after
it reads that lock to learn which issue it is bound to, and it stays bound until `/codeo:close`.
Other workflows, in other checkouts, run alongside it. It authors nothing about the problem itself
— `/codeo:issue` wrote that, and the design is `/codeo:plan`'s. The work here is mechanical and
low-judgment, which is why this skill pins itself to Sonnet.

<!-- rule: init-03 -->
**The create-only push is the claim.** Of two `init`s on one issue exactly one push succeeds, it
runs before the assignee is added, and every check before it — the assignee and in-flight checks
of step 3, the existence check of step 6 — is advisory: a second `init` is refused at the push
whatever it saw earlier.

The repository is read from the project's config, never typed into a command:

```bash
OWNER=$(bash "${CLAUDE_PLUGIN_ROOT}/scripts/config.sh" get .repo.owner)
NAME=$(bash "${CLAUDE_PLUGIN_ROOT}/scripts/config.sh" get .repo.name)
BASE=$(bash "${CLAUDE_PLUGIN_ROOT}/scripts/config.sh" get .baseBranch)
```

`<base>` below is `$BASE`, and `<scratch>` is a scratch directory outside the repository that
exists only while this skill runs, such as `${TMPDIR:-/tmp}/codeo-init-<N>`.

## Workflow

0. **Invoked with no arguments? Stop and ask before doing anything else.** Don't infer the issue
   from recent conversation, open PRs, or "the only open issue." This skill is the one that
   *starts* the workflow, so there is nothing to read a default from.

1. **Read the project's host workflow, then check where this is running.**
   <!-- point: init/host-workflow -->
   Fetch it with `bash "${CLAUDE_PLUGIN_ROOT}/scripts/overlay.sh" init host-workflow`. On exit 0
   the printed text says how the project's host workflow wraps the claim — where
   this skill runs, whether this checkout switches to the branch, where the lock is taken and how
   the hand-off is opened — and it adds to or narrows the steps below, chiefly those marked *default*. On exit 3
   there is none: the default flow runs — this skill validates the issue and the Ready gate, claims
   the branch with the create-only push, writes and pushes the dossier, checks the branch out here,
   takes the lock and hands off to `/codeo:plan` in this same session. On exit 1, 2 or 4 the script
   prints one `codeo:` line: report it to the engineer and use the default.

   *Default:* a `.codeo/active` in this checkout means it is already bound to an issue's workflow
   (`${CLAUDE_PLUGIN_ROOT}/docs/handoff.md → The lock`): stop, name the issue the lock names, and
   say to run `init` in another checkout of the repository (a second clone, or a `git worktree` of
   this one), or to finish this one with `/codeo:close`. Another issue's workflow in its own
   checkout is no obstacle; that is the point.

2. **Resolve and validate the number.** Accept `42`, `#42`, or a full URL; reject a URL pointing
   at another repository than `$OWNER/$NAME` rather than silently renumbering it. Run
   `bash "${CLAUDE_PLUGIN_ROOT}/scripts/github.sh" issue view <N>`.
   <!-- rule: init-01 -->
   **Inspect the returned `html_url`, not the exit code**: issues and pull requests share one
   number sequence, and where PRs outnumber issues a mistyped number most likely lands on a PR,
   which `github.sh issue view` returns happily — its non-zero exit flags a 404, not a PR. If the
   `html_url` path contains `/pull/`, abort and name the PR it hit. Not found → abort and suggest
   `/codeo:issue`.

3. **Check the issue's state and stop if it is closed.**
   <!-- rule: init-02 -->
   Don't refuse outright and don't reopen it — ask whether to reopen (the user's action, not
   yours), re-target another number, or proceed knowingly.

   **Check nobody else has it.** An `assignees` entry other than
   `bash "${CLAUDE_PLUGIN_ROOT}/scripts/github.sh" user login` is someone else's claim, and
   `bash "${CLAUDE_PLUGIN_ROOT}/scripts/inflight.sh"` listing this issue on a pushed branch is
   someone's workflow already under way. Either one stops the skill, naming the person and branch,
   with one exception: `inflight.sh` listing this issue as `(working)` on the very branch
   `bash "${CLAUDE_PLUGIN_ROOT}/scripts/branch-name.sh" <N>` derives is not a second start but the
   resume step 6 classifies, so that listing alone does not stop the skill. Another assignee stops
   it regardless. So does a `(PR open)` listing on that branch — the workflow is waiting on its
   pull request: finish it with `/codeo:close` in its checkout — and so does this issue's dossier
   on a branch of any other name, a workflow under way that is never started a second time (the
   issue was retitled after its `init`: restore the title, then run `init` again — step 6 finds
   the branch by its derived name and makes the resume claim). Taking over someone else's claim
   needs the engineer to say so in so many words, and that override goes under `## Notes` in
   `init.md` verbatim — one line, `- <date> — override: "<the engineer's words>"` — in the
   dossier's first commit at step 9, or the resume's commit at step 6.
   `${CLAUDE_PLUGIN_ROOT}/docs/handoff.md → Parallel workflows`.
   When `github.sh user login` prints nothing (no token, no `$CODEO_GITHUB_LOGIN`), the assignee
   comparison cannot run — say so and continue rather than stopping, since there is nothing to
   compare against; the `inflight.sh` check still applies. `overlap.sh` has nothing to compare
   yet — no branch, no footprint — so `init`'s check is `inflight.sh` alone, deliberately.

   **Check the board says it is Ready — when there is a board.** Whether one is configured is
   `bash "${CLAUDE_PLUGIN_ROOT}/scripts/config.sh" get .board`: exit 1 with nothing printed means
   the project has none. Then say once, in this turn's output, that no board is configured, so the
   Ready gate and the move to in progress are both skipped; record `Board | not configured` in the
   `## Outcome`, and make no `board.sh` call anywhere in this run (every verb would only print
   `board: not configured` and exit 3; treat that exit the same way if it is what you meet first).
   That is the one case in which the gate does not run, and it is stated, not silent.

   With a board, the statuses are the board's own option names, as `board.statuses` maps them —
   the conventional names only when the map leaves a key out:

   ```bash
   READY=$(bash "${CLAUDE_PLUGIN_ROOT}/scripts/config.sh" get '.board.statuses.ready // "Ready"')
   IN_PROGRESS=$(bash "${CLAUDE_PLUGIN_ROOT}/scripts/config.sh" get '.board.statuses.inProgress // "In progress"')
   ```

   `bash "${CLAUDE_PLUGIN_ROOT}/scripts/board.sh" status <N>` must print `$READY` — the Status on
   the board's gate project that `/codeo:triage` sets when the engineer calls an issue workable.
   Anything else stops the skill, naming what it printed: `none` (not on the board), `unset`, or a
   column before `$READY` means nobody has said it is workable yet, so name `/codeo:triage` or
   moving the card by hand; `$IN_PROGRESS` with no branch found at step 6 is a claim with no
   workflow behind it, for the engineer to sort out. The one exception is a resume: when the
   status is not `$READY`, look for step 6's resume case first — the branch already on origin
   carrying this issue's `init.md` — and if it is there, skip this check and go on, because a
   resumed card may sit anywhere a stash, an abandon or a lost checkout left it.
   <!-- rule: init-06 -->
   A script failure — the likely one is the gh token lacking the `project` scope, and the script
   names the fix — stops the skill too; the Ready check is never skipped because it could not run.
   The one exception is `unavailable` (a hosted web session — Projects v2 is GraphQL-only and the
   session's proxy refuses it): that is not a script failure, so note it in `init.md`'s
   `## Outcome` and continue as if the check passed, rather than stopping. Every other outcome —
   `none`, `unset`, a column before `$READY`, or a real script failure — still stops the skill.

4. **Read the whole issue and restate it in 3-5 lines** — problem, acceptance criteria,
   out-of-scope, unresolved questions. This is the heart of the `## Outcome` below, written once.

5. **Preflight.** `git fetch origin`. Base off `origin/<base>` as of this fetch, never off whatever
   happens to be checked out. The branch is cut in a scratch worktree at step 9, so nothing is
   switched in this checkout before the push.

   *Default:* this checkout is switched to the issue's branch at step 11, and uncommitted changes
   to tracked files would travel with that switch into the workflow. When
   `git status --porcelain --untracked-files=no` prints anything, stop and name the files: they
   are the engineer's to commit or stash first — never stash or discard them yourself.

6. **Derive the branch name and check for collision.** The name comes from
   `bash "${CLAUDE_PLUGIN_ROOT}/scripts/branch-name.sh" <N>` — never chosen by the agent, so two
   `init`s on one issue derive one name, and `init` never picks a different one itself. There is
   no issue number in it. After the `git fetch origin` of step 5, in this order:

   - `git ls-remote --exit-code --heads origin <branch>`. Exit 2, absent: nothing has the name,
     so go on to steps 7–11, a fresh claim (the push at step 9 is what settles a race).
   - Exit 0, present: `bash "${CLAUDE_PLUGIN_ROOT}/scripts/claim.sh" --carries <N> <branch> .`.
     Exit 2 is a collision, not a resume — the branch carries another issue's dossier, no dossier,
     or only this issue's own archived dossier (`.codeo/done/<N>/`: #N has already been through
     `close`), or was merged into `<base>` and left behind, or is bare — cut from `<base>` with
     nothing of its own, for an issue `<base>` has archived: stop and quote both of its lines (the
     engineer retitles the issue or waits for the other to close; an own archived dossier means
     the pull request is open, was closed unmerged, or was squash- or rebase-merged and its branch
     left — step 3 has already stopped the open case — so finish or verify it with `/codeo:close`
     in its checkout; a branch merged into `<base>` and left behind, or bare, is deleted, as
     `close` normally does; retitle only for an issue reopened after its merge).
     Exit 1 means the ref is missing: stop. Exit 0 means the branch carries this issue's
     `init.md`: it is a resume, and
     `bash "${CLAUDE_PLUGIN_ROOT}/scripts/claim.sh" --stash-live <N> <branch> .` *always* runs
     next: a stash or an abandon is live while its `close.md` has more `### Round <n> — stashed`
     or `— abandoned` headings than its `init.md` has `resumed: … after the stash of` or
     `after the abandon of` lines. Exit 0 is a resume of a stash. Exit 4 is an abandoned workflow
     (`claim: #<N> was abandoned on <date> (close.md round <n>)`): `close` abandoned it and
     normally removed its assignee and moved its card to the backlog — `close.md`'s log line says
     whether it did — and `/codeo:triage` may have moved it since, which is why step 3 read the
     board rather than this line. Stop and quote the line. There are two ways on. The engineer
     takes the work up again, saying so in so many words — recorded under `## Notes` in `init.md`
     as step 3's override is, in the resume's commit (sub-step 4 below) — and then it is a resume
     like exit 0 and the sub-steps below run. Or the engineer deletes the old branch on origin and
     runs `init` again for a fresh start; step 3's Ready gate applies then, and its resume
     exception is gone with the branch, so the card has to be Ready first — move it through
     `/codeo:triage`, or by hand, if it is not.
     Exit 3 has two readings, each quoted from the script's line, and both are a lost-checkout
     resume only when the issue's assignee is
     `bash "${CLAUDE_PLUGIN_ROOT}/scripts/github.sh" user login`: `has no stash` means no stash or
     abandon is live, and `already resumed — …` means the last stash or abandon was already
     resumed — by this engineer, when the assignee is them, whose checkout was then lost (the
     state `claim.sh --resume-line` writes as `after a lost container`). Any other assignee makes
     either reading someone's running workflow: stop and quote the line. With no login there is no
     assignee to compare, so stop and say so. Exit 1 means the branch or ref is missing: stop.
   - Any other exit (128, typically): origin did not answer. Stop and quote git's message. Step 5's
     `git fetch origin` normally fails first, so this is rare.

   Origin is the claim, not a local branch list. A leftover from an interrupted run is refused by
   step 9's `git worktree add … -b <branch>`; remove it with `git worktree remove --force
   <scratch>` and `git branch -D <branch>`, then run `init` again.

   On a resume the branch and its dossier already exist, so steps 7–9 are skipped, but **the
   claim is not**: a stash or an abandon removed the assignee, and step 3 already checked that
   nobody else has taken the issue since.
   <!-- rule: init-04 -->
   A resume is claimed the way a fresh `init` is, by a push, pushed against the tip it saw, so
   that of two resumes exactly one succeeds.

   <!-- rule: init-07 -->
   Never merge, rebase or reset a checkout's unpushed commits; they are the engineer's to
   reconcile. So first, when a local `<branch>` exists in this checkout
   (`git rev-parse -q --verify refs/heads/<branch>`; the check is skipped otherwise), one that
   holds commits origin lacks (`git log --oneline origin/<branch>..<branch>` prints any) is work a
   checkout never pushed: stop and name them — the worktree below would move the branch off them. When `<branch>`
   is what this checkout has checked out, git refuses a second worktree of it: detach this
   checkout first (`git switch --detach origin/<base>`; step 5 made sure nothing uncommitted
   travels). Then:

   1. Record `seen=$(git rev-parse origin/<branch>)`.
   2. `git worktree add -B <branch> <scratch> origin/<branch>`.
   3. Append to `<scratch>/.codeo/<N>/init.md`'s `## Log` the line
      `bash "${CLAUDE_PLUGIN_ROOT}/scripts/claim.sh" --resume-line <N> <branch> . <login>` prints,
      followed by ` · cost: ` and `bash "${CLAUDE_PLUGIN_ROOT}/scripts/usage.sh" init`'s output
      (or `cost: unavailable` when it cannot run).
      <!-- rule: init-05 -->
      Write nothing else on that line: the script chose its wording, `--stash-live` counts it, and
      an engineer's override goes under `## Notes`, never on that line. `<login>` is what step 3's
      `github.sh user login` printed; pass it empty when that printed nothing.
   4. Commit that file alone, staged by name, with the subject
      `docs(codeo): init dossier for #<N> — resumed` — on an exit-4 takeover the same commit also
      carries the engineer's override line under `## Notes`. Its log line is also what spends the
      stash or the abandon: each `after the stash of` or `after the abandon of` line answers one
      such heading, so it cannot be resumed again until `close` writes another.
   5. `bash "${CLAUDE_PLUGIN_ROOT}/scripts/claim.sh" --resume <N> <branch> <scratch> "$seen"` — a
      push that origin accepts only while the branch tip is still `$seen`.

   Exit 2 means someone else's resume (or other push) got there first: stop, naming the winner
   from the script's line, run `git worktree remove --force <scratch>` and `git branch -D
   <branch>`, and write nothing else — no assignee, no card move. Exit 1 is a push failure of
   another kind; report git's message and stop. On exit 0, `git worktree remove <scratch>`, then
   run `bash "${CLAUDE_PLUGIN_ROOT}/scripts/github.sh" issue assignee-add <N>` and, with a board,
   `bash "${CLAUDE_PLUGIN_ROOT}/scripts/board.sh" set <N> "$IN_PROGRESS"` (a stash normally moved
   it back to Ready and an abandon to the backlog, but a failed move or a lost checkout may have
   left it anywhere). Quote the line(s) it prints in this turn's output. A failure moving the card
   (refused in a web session, or a missing `project` scope) is reported — say to move `#<N>` to
   `$IN_PROGRESS` by hand — and the claim still stands; go on to step 10 regardless. When
   `github.sh user login` printed nothing at step 3, there is no login to add — skip the assignee
   call and say so in this turn's output rather than stopping the skill. Any other checkout of
   this branch the engineer still has open needs `git pull --ff-only` there, because the resume
   pushed a commit it does not have. If the pull is refused, that checkout has commits it never
   pushed: stop and name them (`git log origin/<branch>..`), and leave them to the engineer as
   above. The claim already stands — the resume line is pushed, and the assignee and the card
   followed it where a login and the board allowed — so do not re-run `init`: reconcile that
   checkout's commits, then `git pull --ff-only` there. Then go on to step 10.

7. **Draft the dossier.** Write `.codeo/<N>/init.md` in this checkout for the gate — the proposed
   `## Outcome` (below), the exact branch name, and the base SHA.
   **Adopt the issue's dossier** if `/codeo:issue` wrote one:
   `bash "${CLAUDE_PLUGIN_ROOT}/scripts/intake.sh" restore <N>` brings it from the `codeo/intake`
   branch when this clone lacks it (an error saying there is no intake branch, or that it has no
   such directory, just means the issue was filed without the skill and is harmless here), then copy `.codeo/intake/<N>/issue.md` to
   `.codeo/<N>/issue.md`. `${CLAUDE_PLUGIN_ROOT}/docs/dossier.md` is the format, and
   `${CLAUDE_PLUGIN_ROOT}/docs/dossier.md → Intake` says why the two paths differ.

8. **Review gate — do not skip or shortcut this.** Point at `.codeo/<N>/init.md` and ask for
   explicit approval, requested changes, or rejection. Nothing below this line runs before it, and
   nothing below it runs while a question in that file is still open. Most runs of this skill have
   nothing to ask — a closed issue is a pick-one, so put it to the engineer in the conversation and
   record the answer in the file.

9. **Cut the branch, commit the dossier onto it, push, and claim the issue.** The branch is cut in
   a scratch worktree that exists only for this step:
   `git worktree add --no-track <scratch> -b <branch> origin/<base>`, then move `.codeo/<N>/`
   there. Create `<scratch>/.codeo/.gitignore` with the lines `active` and `intake/` if the base
   branch does not have it: the lock and `/codeo:issue`'s working copies are the two things under
   `.codeo/` that no feature branch sees. Fill in `## Where this stands` with the branch and base
   SHA, and append the first `## Log` line —
   `- <date> — initialized: branch <branch> off <base> at <sha> · cost: <output of bash "${CLAUDE_PLUGIN_ROOT}/scripts/usage.sh" init>`
   (or `cost: unavailable`). When `github.sh user login` printed nothing back at step 3, there is
   no login to add as assignee — add the **Claim** line to `## Outcome` now (below), since this
   commit is the one place that fact can still be recorded.
   <!-- rule: init-09 -->
   Commit `.codeo/.gitignore`, `.codeo/<N>/init.md`, and any adopted `issue.md` there, staged by
   name (`${CLAUDE_PLUGIN_ROOT}/docs/dossier.md → Durability` has the convention), with the subject
   `docs(codeo): init dossier for #<N>`; the `.gitignore` especially, because untracked it does
   not reach the next clone and the lock stops being ignored there. Then claim it with the push:
   `bash "${CLAUDE_PLUGIN_ROOT}/scripts/claim.sh" <N> <branch> <scratch>`, which prints
   `claim: #<N> claimed <branch>`. The push is create-only, so of two `init`s on one issue exactly
   one succeeds, and it runs **before** the assignee is added. Exit 2 means the branch already
   exists on origin: stop the skill naming the claimant from the script's line, move `.codeo/<N>/`
   back to this checkout (the draft is left for the engineer to delete), run `git worktree remove
   --force <scratch>`, delete the local branch (`git branch -D <branch>`), and write nothing else —
   no assignee, no card move, no `init.md` on origin. Exit 1 is a push failure of another kind;
   report git's message and stop.

   Then `git worktree remove <scratch>` — the local `<branch>` stays, tracking `origin/<branch>`
   (the push set its upstream) — and, only when a login was available at step 3, now that the push
   has claimed the branch, `bash "${CLAUDE_PLUGIN_ROOT}/scripts/github.sh" issue assignee-add <N>`
   — when it was not, the `## Outcome` already says so and there is nothing left to call. Finally,
   with a board, `bash "${CLAUDE_PLUGIN_ROOT}/scripts/board.sh" set <N> "$IN_PROGRESS"` — the card
   move is the claim as the board shows it, as the assignee is on the issue. It adds the issue to
   every project in `board.projects` it is missing from, and sets the Status on every project it
   is on that has the option, printing one `board.sh: #<N> <old> → <new> on #<project> <title>`
   line per project written. Quote those lines in this turn's output. The dossier is pushed by
   now, so the outcome (those lines, or the failure the script reports) is reported here and at
   step 10, not in the `## Log` line. A failure here (refused in a web session, or a missing
   `project` scope) is reported and the claim still stands — say to move `#<N>` to `$IN_PROGRESS`
   by hand, and continue rather than stopping; the branch, dossier and lock never wait on the
   board. With no board there is no call to make.

   The push is what everything after this hangs on: the checkout the issue's later steps run in
   takes its lock from the `init.md` on it, and every skill commits its dossier onto it as it goes.

10. **Verify the push.** `git ls-remote --exit-code --heads origin <branch>` exits 0 and shows the
    branch, and `git show origin/<branch>:.codeo/<N>/init.md` shows the dossier. A checkout of a
    branch without it comes up with no lock, and every later skill in it refuses to start. With a
    board, `bash "${CLAUDE_PLUGIN_ROOT}/scripts/board.sh" status <N>` prints `$IN_PROGRESS` — or
    `unavailable` in a web session, the exception step 3 names, where the card was moved by hand
    at step 9 or is still to be.

11. **Take the lock and hand off** to `/codeo:plan`. With a host workflow, do as its text says —
    where the lock is taken and how that checkout is opened — and say so here.

    *Default:* bind this checkout to the issue. `git checkout <branch>` unless it is already the
    branch checked out here, then
    `bash "${CLAUDE_PLUGIN_ROOT}/scripts/lock.sh" take local`, which reads the `init.md` on the
    checked-out branch that names it and writes `.codeo/active`
    (`${CLAUDE_PLUGIN_ROOT}/docs/handoff.md → The lock`). It prints
    `lock: took the lock for #<N> on <branch>`; quote that line. It never fails its caller: what
    it could not do it prints on stderr as a `lock: TODO — …` line, and then there is no lock —
    quote the line and stop rather than hand off, because `plan` would refuse to start. With the
    lock taken, `/codeo:plan` runs next in this same session.


## The outcome

`init.md`'s `## Outcome` is what every later step reads first, so it is the issue made
workable — no design, no status field, with one exception: a trailing **Claim** line, written
only when step 9 could not add the assignee for lack of a login. That is a fact recorded once,
the way the table above it is, not a status the reader tracks across rounds.

<!-- rule: init-08 -->
Acceptance criteria are copied verbatim and never reworded: they are the standard `/codeo:qc`
judges against.

```markdown
## Outcome

| | |
|---|---|
| Issue | <html_url> — <title> |
| State | open · labels `<label>` |
| Branch | `<branch>` off `<base>` at `<sha>` |
| Board | <ready status> → <in-progress status> (or `not configured`, or `unavailable`) |

**Problem.** Three to five lines, restated from the issue.

**Acceptance criteria** — verbatim from the issue, unchecked:
- [ ] …

**Out of scope.** What the issue excludes.

**Open at intake.** What the issue itself left unresolved — history, frozen; see
`${CLAUDE_PLUGIN_ROOT}/docs/dossier.md → Intake questions are not dossier questions`.

**Claim.** Present only when step 9 skipped the assignee call: "Skipped — no GitHub login
available; run `github.sh issue assignee-add <N>` once one is present."
```

The branch is what finds everything again after a lost context window, and after a lost machine
too: it is pushed and the dossier is committed onto it, so a new checkout of it — on this machine
or any other — takes the same lock and recovers the rest. Say so in the hand-off.

## Hand-off

`${CLAUDE_PLUGIN_ROOT}/docs/handoff.md` is the protocol; this is this skill's half of it.

- **Reads** the GitHub issue, its board Status (`board.sh status`, when a board is configured),
  `.codeo/intake/<N>/issue.md` when there is one, `inflight.sh`'s list of workflows already under
  way, and the project's `init/host-workflow` overlay section when there is one.
- **Writes** the branch, and pushes it create-only through `claim.sh`, which is the claim — on a
  resume, one `resumed:` log line in `init.md`, pushed against the tip it saw; the issue's
  assignee; its board Status, Ready → in progress, through `board.sh`, when a board is
  configured; and `.codeo/<N>/init.md`, the adopted `.codeo/<N>/issue.md`, and, when it is the
  first to need it, `.codeo/.gitignore`, all committed onto the branch. The lock is its too: by
  default written in this checkout by `lock.sh take local` from the pushed `init.md`; with a host
  workflow, wherever that workflow says.
- **Never touches** the issue's text, the project's docs or wiki, any code, or another skill's
  dossier file.
- **Hands off to** `/codeo:plan`, naming `.codeo/<N>/init.md` as the thing to read first — and
  only once nothing in that file is still open. Say explicitly that `plan` should read it rather
  than re-fetching the issue or re-asking the engineer what it already answers.
- **Spins out subagents** on the configured subagent model (`models.subagent`, sonnet when unset),
  passed explicitly, and prefers a direct `grep`/`Read` over an agent when the target is already
  known — see `${CLAUDE_PLUGIN_ROOT}/docs/handoff.md → Spinning out subagents`.

## Non-goals

- Doesn't draft, refine, or re-scope the issue's content — that's `/codeo:issue`'s purview;
  this skill only reads it.
- Doesn't design anything or write a plan doc — that's `/codeo:plan`'s purview; this skill
  hands it the dossier and stops.
- Doesn't write code, documentation, or open a PR — those are `/codeo:implement`'s and
  `/codeo:close`'s. It does commit and push, but only the dossier and only onto the branch it
  just created or is resuming.
- Doesn't touch the project's wiki. The wiki documents the application, not the work, and it
  changes only when merged code does.
- Doesn't release the lock it takes, and doesn't stash or close someone else's — a workflow
  already running on this issue stops this skill rather than being overwritten by it. Workflows
  on *other* issues, in other checkouts, are none of its business.
- Doesn't switch branches before the push. The branch exists only in the scratch worktree of
  step 9 until it is on origin; by default this checkout is switched to it only at step 11.

## Tips

- Validate before you narrate. Everything in steps 1 and 2 is cheap and answers "is this the
  number the user meant?", which is the only question that matters before a branch exists.
- Resuming is the normal case after any failure, but the push decides, on both paths: `claim.sh`
  is create-only for a fresh `init`, so the existence check at step 6 (`git ls-remote --exit-code`
  and `claim.sh --carries`) and the assignee and `inflight.sh` check at step 3 are advisory and a
  second `init` on the same issue is refused at step 9 whatever it saw earlier; a resume is pushed
  against the tip it saw, so it is refused at step 6 when someone else's resume got there first.
