# Extension points

A skill's steps are generic. Where a project needs something the generic text cannot know, the
skill names an extension point: a place where it reads a section of the project's own overlay
file and follows it. Every point has a default, so a project with no overlay gets the generic
behaviour.

## Overlay files

An overlay file is `$CODEO_STATE_DIR/overlays/<skill>.md`, which is `.codeo/overlays/<skill>.md`
at the project's root, one file per skill. It is committed with the project.

### The heading grammar

A section starts with a line that is exactly `## ` followed by the point's name, with one space
between them and nothing after the name (trailing blanks and a carriage return are ignored):

```markdown
## todo-excludes

vendor/**
generated/**
```

- A section runs to the next `## ` heading or to the end of the file. Deeper headings (`###`)
  and everything else belong to the section.
- Text before the first `## ` heading is a comment; nothing reads it.
- A `## ` line inside a fenced code block still ends the section, because the reader does not
  parse Markdown. Indent a code sample that needs such a line instead of fencing it.
- A section whose body is empty counts as absent.
- A section name appearing twice in one file is an error, not a merge.

### Precedence

Every skill opens with this sentence:

> Project overlay text adds to or narrows a step; it never overrides a rule marked with a "rule"
> comment in this file.

An overlay can say how a step is done in this project, add a check, or restrict a choice. It
cannot remove or contradict a rule the skill marks with a `<!-- rule: ID -->` comment. If an
overlay's text conflicts with such a rule, the rule wins and the skill says so to the engineer.

### How a skill reads a section

A skill fetches a section with `bash "${CLAUDE_PLUGIN_ROOT}/scripts/overlay.sh" <skill> <point>`,
run at the project's root. The exit code decides what the skill does:

| Exit | Meaning | The skill |
|------|---------|-----------|
| 0 | The section exists; its body is on stdout | Follows the printed text |
| 3 | No overlay file, no such section, or an empty one; nothing printed | Uses the point's default |
| 2 | `<skill>/<point>` is not a registered point | Reports the one `codeo:` line and uses the default |
| 4 | The section appears twice | Reports the one `codeo:` line and uses the default |
| 1 | The overlay or the registry cannot be read | Reports the one `codeo:` line and uses the default |

"Reports" means: `/codeo:triage` puts the line in the run's `## Outcome`, `/codeo:plan` tells the
engineer in the turn.

The registered points are the rows of `lib/extension-points.tsv`: skill, point, and the default,
tab-separated. Exit 2 means a skill names a point that is not registered, which is why it fails
at the call instead of falling back silently.

### Validation

`/codeo:doctor` has an `overlays` check. It reads every `.codeo/overlays/<skill>.md`, reports a
`## ` section whose name is not a registered point of that skill (a typo would otherwise be
ignored forever), reports a section that appears twice, and reports an overlay file named for a skill that has no
extension points.

### Adding a project overlay

1. Find the point below whose step you want to shape.
2. Create `.codeo/overlays/<skill>.md` if it does not exist.
3. Add `## <point>` and write the section's body in plain prose or a list, in the form the point
   expects.
4. Run `/codeo:doctor` to confirm the section name is registered and unique.
5. Commit the file.

## The points

### plan/plan-shape

**Where.** `/codeo:plan`, step 5, "Decide the output's shape, and say so before drafting".

**May rely on.** The issue and its dossier, the exploration done in steps 1 to 4, the answered
questions, and `$DOCS` and `$PLANS` (the documentation and plans directories from the config).

**Expected back.** Prose that adds to or narrows the generic shapes: exemplar plans and reference
documents to match, and the sections the project's documents carry. The skill applies it when
choosing the output's shape and again when drafting.

**Default when absent.** Use the generic plan shape in the skill.

**Example.**

```markdown
## plan-shape

Match docs/plans/example-feature-plan.md. Every plan carries a "Rollout" section after the tasks.
```

### plan/proof-of-done

**Where.** `/codeo:plan`, step 8, "Draft the document", under the rule that every task in a plan
ends with its own proof of done.

**May rely on.** The configured `suites` (their `paths`, `build`, `test` and `filter`) and the
task being written, including the files it touches and the test it writes. A suite's `filter` is
a command template for one test, with `{}` standing for the test's name.

**Expected back.** The form of a task's proof: the command and the result it must give, for the
cases the project cares about. The skill uses it for every task in the plan.

**Default when absent.** The suite's filter with {} replaced by the name of the test the task
writes; a suite without filter has no single-test form and its whole test command is the proof.
A task with no test is proved by the suite's `build`, and a documentation-only task by a check it
names. With no suites configured, the task names its proof command in full.

**Example.**

```markdown
## proof-of-done

Run the suite's single-test form, then the whole suite for the touched paths once per task.
State the expected failing message before the code and "all passed" after it.
```

### plan/environment-lease-notes

**Where.** `/codeo:plan`, step 8, after the paragraph "Mark the tasks that need the shared
environment, and put them last". The skill fetches it only when `$ENV_RESOURCE` is set.

**May rely on.** `$ENV_RESOURCE`, the config's `environment.resource`, and the plan's task order
as it stands.

**Expected back.** What counts as an environment task in this project, and anything the project
says about holding the lease. The skill applies it when marking tasks with `Needs lease:`.

**Default when absent.** None; the plan adds no environment lease notes, and the paragraph above
the point is the whole rule.

**Example.**

```markdown
## environment-lease-notes

A task that only edits configuration files is not an environment task. A task that restarts the
shared environment is, and says so in its first line.
```

### plan/wiki-rules

**Where.** `/codeo:plan`, step 8, in "Name the documentation the change moves", where the
documentation tasks are written.

**May rely on.** `$DOCS`, the pages already under it, the config's `modules` (the `wiki` module
adds wiki pages), and the change being planned.

**Expected back.** How the project's pages are written, linked and indexed, and which diagrams
are drawn with which tool. The skill applies it to every documentation task.

**Default when absent.** Documentation rules are only the project's docsDir conventions: the
conventions the existing pages under it already follow.

**Example.**

```markdown
## wiki-rules

Pages are in the present tense about the system, link to each other by page name, and are listed
in the index page. Flows are Mermaid.
```

### implement/environment-lease-notes

**Where.** `/codeo:implement`, step 5, the lease paragraph. The skill fetches it only when
`$ENV_RESOURCE` is set.

**May rely on.** `$ENV_RESOURCE`, the config's `environment.resource` and `environment.hooks`, and
the task being run.

**Expected back.** What the project does around a deploy that the `deploy` hook does not: waiting
for a rollout, smoke checks, who to tell — and anything about taking and holding the lease. The skill
fetches it before the take and applies it to taking, holding and deploying.

**Default when absent.** None; the lease and deploy paragraphs are the whole rule.

**Example.**

```markdown
## environment-lease-notes

After a deploy, wait for the health endpoint to answer before the next task, and post the revision
in the team channel.
```

### implement/wiki-rules

**Where.** `/codeo:implement`, step 5, in the paragraph on documentation tasks.

**May rely on.** `$DOCS`, the pages already under it, the config's `modules`, and the task being
run.

**Expected back.** How the project's pages are written, linked and indexed, and which diagrams
are drawn with which tool. The skill applies it to every documentation task.

**Default when absent.** Documentation rules are only the project's docsDir conventions: the
conventions the existing pages under it already follow.

**Example.**

```markdown
## wiki-rules

Pages are in the present tense about the system, link to each other by page name, and are listed
in the index page. Flows are Mermaid.
```

### qc/environment-evidence

**Where.** `/codeo:qc`, after the `deployed` hook's rows are read. The skill fetches it only when
`$ENV_RESOURCE` is set.

**May rely on.** `$ENV_RESOURCE`, the config's `environment.resource` and `environment.hooks`, and
the rows the `deployed` hook printed.

**Expected back.** The project's steps beyond the hook: a diagnostic to run, the remedy for an
orphan, how to read a state.

**Default when absent.** None; the evidence is the deployed hook's output and nothing more.

**Example.**

```markdown
## environment-evidence

If a row reports a revision the branch does not contain, treat it as an orphan: tell the engineer to
redeploy rather than judging the environment.
```

### qc/wiki-rules

**Where.** `/codeo:qc`, the documentation check.

**May rely on.** `$DOCS`, the pages already under it, the config's `modules`, and the diff.

**Expected back.** How the project's pages are written, linked and indexed, and how diagrams are
checked, including any render step.

**Default when absent.** Documentation checks are only the project's docsDir conventions.

**Example.**

```markdown
## wiki-rules

Pages are in the present tense about the system, link to each other by page name, and are listed in
the index page. A diagram's rendered image must be regenerated from its source.
```

### qc/invariants-extra

**Where.** `/codeo:qc`, the reviewer feed.

**May rely on.** The issue's criteria, the invariants file, the diff, and the config's `modules`.

**Expected back.** Further rules the reviewer must judge the diff against, as plain prose:
conventions the invariants file does not state.

**Default when absent.** None; the reviewer works from the criteria, the invariants file and the
diff.

**Example.**

```markdown
## invariants-extra

Every public function states its failure mode in a comment, and no module reads another module's
configuration directly.
```

### init/host-workflow

**Where.** `/codeo:init`, step 1, "Read the project's host workflow, then check where this is
running".

**May rely on.** `$OWNER`, `$NAME` and `$BASE` (from the config), the issue number the skill was
invoked with, and the checkout it runs in. Nothing has been claimed yet.

**Expected back.** How the project's container or machine workflow wraps the claim: where the
skill runs, whether this checkout switches to the issue's branch, where the lock is taken and
how the hand-off to `/codeo:plan` is opened. It adds to or narrows the steps marked as the
default.

**Default when absent.** None; the skill hands off to plan in the same session. It validates the
issue and the Ready gate, claims the branch, writes and pushes the dossier, checks the branch
out, takes the lock with `lock.sh take local` and continues into `/codeo:plan`.

**Example.**

```markdown
## host-workflow

Run this in the home checkout only. Do not switch this checkout to the issue's branch; the
issue's own container takes the lock when it starts. Hand off by printing the issue number.
```

### triage/todo-excludes

**Where.** `/codeo:triage`, collecting with `--todos`, "git grep -n -E ... -- <pathspec
exclusions>": "The exclusions are the project's to name".

**May rely on.** The `git grep` command over `origin/<base branch>` and the list of tracked
files it will search.

**Expected back.** Glob patterns, one per line. The skill adds each as `':!<glob>'` to the
pathspec of the scan.

**Default when absent.** Scan tracked files only, with no exclusions.

**Example.**

```markdown
## todo-excludes

vendor/**
third_party/**
*.min.js
```
