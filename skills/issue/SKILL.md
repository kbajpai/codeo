---
name: issue
description: Turn a raw idea, bug report, or out-of-scope finding into a well-formed GitHub issue — problem statement, requirements, and acceptance criteria — through a question-and-answer pass with the engineer, then file it with `gh api`, Issue Type included. Trigger on "file an issue", "draft an issue for X", "turn this into an issue", "write up a bug report", or when /codeo:plan, /codeo:implement or /codeo:triage hits work that belongs in an issue of its own. Standalone — it files the issue and hands off to nobody. Never writes application code or plan docs.
argument-hint: "<idea, bug, or problem to turn into an issue>"
model: opus
---

Project overlay text adds to or narrows a step; it never overrides a rule marked with a "rule" comment in this file.

# Filing an issue for `$ARGUMENTS`

This skill drafts and files a GitHub issue in this project's repository, and that is all it does. It
captures the *what and why* — problem, requirements, acceptance criteria — not the *how*. Contracts,
diagrams, and design belong to `/codeo:plan`; sketching them here duplicates work it will redo
properly with the codebase open in front of it. **It hands off to nobody**: it files the issue,
reports the number, and stops. Don't suggest a next skill and don't cut a branch — the engineer
decides what happens to the issue next.

**Other skills call it.** When `/codeo:plan` or `/codeo:implement` hits work that is real
but out of scope for what it is doing, it delegates here rather than widening its own scope or
dropping the finding on the floor; `/codeo:triage` does the same for every loose end the
engineer chooses to file. The caller passes the finding and the context it already has; it
does *not* answer the questions below on the engineer's behalf. Filing returns control to the
caller with the new issue's number, nothing more.

The repository is read from the project's config, never typed into a command:
`bash "${CLAUDE_PLUGIN_ROOT}/scripts/config.sh" get .repo.owner` and
`bash "${CLAUDE_PLUGIN_ROOT}/scripts/config.sh" get .repo.name`.

## Workflow

0. **Invoked with no arguments? Stop and ask before doing anything else.**
   <!-- rule: issue-01 -->
   Don't infer the idea, bug, or problem to file from conversation context or recent activity —
   ask the engineer what they want turned into an issue. A skill delegating here always passes its
   finding, so an empty argument means a human invoked it bare. This skill is exempt from the lock
   every other skill reads: it runs before a number exists, and filing an issue is not starting work
   on it, so a bare invocation here really is ambiguous. It neither reads nor writes
   `.codeo/active`.

1. **Restate the request** as a one-paragraph problem statement before drafting anything, so
   misunderstandings surface immediately rather than after a draft is written.

2. **Explore just enough to describe the problem accurately, not to design its solution.** Search
   existing issues (`bash "${CLAUDE_PLUGIN_ROOT}/scripts/github.sh" issue search "<words>"`) to
   check this isn't a duplicate. Skim the relevant code only to confirm the problem is real and
   correctly located — don't sketch a fix.
   **For a bug report**, invoke `superpowers:systematic-debugging` and run *Phase 1: Root Cause
   Investigation* only — reproduce it, read the error, note what changed — so the issue carries
   real steps to reproduce and the observed-versus-expected behaviour rather than a description of
   a symptom.
   <!-- rule: issue-02 -->
   Stop at the end of Phase 1: a hypothesis or a fix is `/codeo:plan`'s job, and a root cause you
   suspect but have not shown goes in the draft as an open question, not a claim.

3. **Run the question-and-answer pass in the dossier — this is the skill's core, not a
   formality.** There is no issue number yet, so the file is
   `.codeo/intake/new-<slug>/issue.md`, slugged from the working title and renamed in step 8.
   `intake/` is ignored on every branch; the file's durable copy lives on the intake branch
   instead — see `${CLAUDE_PLUGIN_ROOT}/docs/dossier.md → Intake`. Resuming a dossier this clone
   does not have yet (it was started on another machine), run
   `bash "${CLAUDE_PLUGIN_ROOT}/scripts/intake.sh" restore new-<slug>` first.
   `${CLAUDE_PLUGIN_ROOT}/docs/dossier.md` is the format. Write the questions there as numbered
   entries and cover:
   - The problem as they see it, and where their account and the code disagree — which is right.
   - What is explicitly *out* of scope for this issue versus a follow-up.
   - What "done" looks like, concretely enough to become acceptance criteria.
   - Non-functional constraints worth recording as requirements (perf, auth, backward
     compatibility) — not how they would be satisfied.

   Ask in small batches rather than one interrogation, and only about things whose answer would
   change the issue. Commit the file to the intake branch —
   `bash "${CLAUDE_PLUGIN_ROOT}/scripts/intake.sh" commit new-<slug> "docs: issue dossier for new-<slug>"`
   — then print the path and the numbers still open, end the turn, and resume from the file when
   re-invoked; ask follow-ups as new numbers until the issue's shape stops moving. Every turn that
   writes the file ends with that commit, which is how a question left open survives the machine.

   Distinguish the two kinds of unknown.
   <!-- rule: issue-03 -->
   A question the engineer *can* answer blocks this skill and lives in the dossier. One nobody can
   answer yet is content — it goes verbatim into the draft's own open-questions text and blocks
   nothing. Silently picking an answer is neither.
   <!-- rule: issue-04 -->
   When another skill delegated here, the questions still go to the engineer; the caller supplied
   the finding, not the answers.

4. **Draft the issue body** using this section order. Include only the sections that apply; never
   omit `Description` or `Acceptance Criteria`:

   ```markdown
   ### Description

   ### Motivation / Context

   ### Key Requirements

   ### Acceptance Criteria
   - [ ] ...

   ### Out of Scope

   ### Reference
   <!-- links to related code, docs, or other issues -->
   ```

   <!-- rule: issue-05 -->
   Acceptance criteria are checkable outcomes ("returns 404 when X"), not a contract spec — if a
   requirement implies a specific request/response shape, state the requirement in prose under
   `Key Requirements` and let `/codeo:plan` design the actual contract. When another skill
   delegated this finding, `Reference` names where it surfaced — the plan doc, the PR, or the file
   and line — so the issue can be read without that conversation.

5. **Propose Issue Type and labels** as part of the draft, not a separate question. Look up what's
   available (`bash "${CLAUDE_PLUGIN_ROOT}/scripts/github.sh" issue-types`, and
   `bash "${CLAUDE_PLUGIN_ROOT}/scripts/github.sh" label list`) and pick `Bug` / `Feature` /
   `Task` based on content; propose only labels that already exist and fit.
   <!-- rule: issue-07 -->
   Do not set `Priority` or `Effort` custom fields — that's human triage judgment this skill has
   no basis to make.

6. **Review gate — do not skip or shortcut this:**
   - Present the full drafted title, body, proposed Issue Type, and proposed labels in the
     conversation itself, and record the same draft in the dossier,
     committed to the intake branch as in step 3.
   - Nothing below this line runs while a question in the dossier is still open.
   - Surface any unknown that is going into the issue as its own open question.
   - Ask for explicit approval, requested changes, or rejection.
   - Only create anything on GitHub after approval. This mutates shared state visible to every
     engineer and can't be `git diff`'d away before it lands — this gate matters at least as much
     as `/codeo:plan`'s gate before writing a file.

7. **Create the issue through the REST API.**
   <!-- rule: issue-06 -->
   Use the REST endpoint, not `gh issue create`: `gh issue create` has no flag for the Issue Type
   and the endpoint takes it, and the response's `number` and `html_url` are the issue — take them
   from it, never reconstruct them. Read the owner and name as above, write the body to a file,
   then:

   ```bash
   OWNER=$(bash "${CLAUDE_PLUGIN_ROOT}/scripts/config.sh" get .repo.owner)
   NAME=$(bash "${CLAUDE_PLUGIN_ROOT}/scripts/config.sh" get .repo.name)
   gh api "repos/$OWNER/$NAME/issues" -f title='<title>' -F body=@<body file> \
     -f type=<Bug|Feature|Task> -f 'labels[]=<label>' -f 'labels[]=<label>'
   ```

   This needs nothing but `gh`'s login, so it works the same on any machine; no GitHub MCP server
   is involved anywhere in this skill.

8. **Rename the dossier directory, commit it, report, and stop.** `.codeo/intake/new-<slug>/`
   becomes `.codeo/intake/<N>/` now that the number exists — that is what lets
   `/codeo:init` adopt it and what keeps the reasoning that produced the issue attached to the
   issue. Commit the rename in one step:
   `bash "${CLAUDE_PLUGIN_ROOT}/scripts/intake.sh" commit <N> "docs: issue dossier for #<N> — filed" --drop new-<slug>`.
   Then report the created issue's URL and number. No next step, no suggested skill, no branch. If
   another skill delegated here, hand the number back to it and let it resume what it was doing.

## Hand-off

`${CLAUDE_PLUGIN_ROOT}/docs/handoff.md` is the protocol. This skill sits outside the workflow's
lifecycle — it runs before an issue number or a branch exists, and it hands off to nobody.

- **Reads** existing issues, the relevant code, and whatever context a calling skill passes.
- **Writes** the GitHub issue, and `.codeo/intake/<N>/issue.md` — drafted under
  `new-<slug>/` and renamed once the number exists — committed only to the intake
  branch, through `bash "${CLAUDE_PLUGIN_ROOT}/scripts/intake.sh"`, which never checks that branch
  out. Nothing on the default branch or on a feature branch: no branch cut, no commit where a PR
  could pick it up.
- **Never touches** the project's docs, code, the branch, the lock, or another skill's dossier
  file. When another skill calls it, that caller records the new number in its own outcome and
  log line; this skill does not.
- **Spins out subagents** on Sonnet only, passed explicitly, and prefers a direct
  `grep`/`Read` over an agent when the target is already known — see
  `${CLAUDE_PLUGIN_ROOT}/docs/handoff.md → Spinning out subagents`.

## Non-goals

- Doesn't design a solution, request/response contract, or architecture diagram — that's
  `/codeo:plan`'s purview.
- Doesn't write code or plan docs.
- Doesn't commit to the default branch or to whatever branch is checked out. Its published output
  is the GitHub issue; its dossier goes only to the intake branch, so it never lands in an
  unrelated PR and never shows up in `git status`.
- Doesn't cut a branch, open a dossier on a feature branch, or hand off to another skill —
  `/codeo:init` is a separate thing the engineer runs when they are ready for it.

## Tips

- An issue that reads well to a stranger six months from now has succeeded; one that only makes
  sense with today's context in your head has not.
- Acceptance criteria should be checkable facts, not restatements of the description.
- The questions are the work. One round of guessing costs more to undo later than three rounds of
  asking cost now.
- If drafting starts to feel like designing, stop — that's the signal `/codeo:plan` should be
  doing this part, not this skill.
