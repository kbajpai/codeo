# Issue #76 — plan

| | |
|---|---|
| Issue | https://github.com/kbajpai/codeo/issues/76 |
| Branch | `feat/trial-doctor-setup-haiku-5` |
| Updated | 2026-11-14 |

## Where this stands

Explored and probed; nothing is drafted. Q1-Q3 decide what the trial runs, what "matched" means and
where the record lives. The plan gets drafted once they are answered.

## Questions

### Q1 — Which cases does each skill run, and how many times per model?

**Why it matters:** both skills have a branch the happy path never reaches: "if it exits non-zero,
say so" and a different closing block. A trial of only the passing run would switch a skill on
evidence that skips half of it. And one run per model is one sample of something that varies run to
run, so the count decides how much the result is worth. Each run costs about $0.16 on Sonnet (see
Notes), less on Haiku.

**Options:**
- **A — two cases per skill, three runs per model each (recommended).** 24 runs, roughly $2-3.
  - `doctor`: every check passes (this checkout) · one check fails (a scratch copy with a broken
    `config.json`).
  - `setup`: a fresh scratch repository, with `--stack node` to exercise the pass-through · a
    scratch repository that already has `.codeo/config.json`, which `setup.sh` refuses with exit 1.
- **B — the same four cases, one run per model each.** 8 runs. Cheapest, and a single lucky or
  unlucky run decides.
- **C — the passing case only, three runs per model.** 12 runs. Leaves the failure branch untried.

**Answer:**

### Q2 — What counts as "matched"?

**Why it matters:** the issue says to switch "only when the Haiku run matches the Sonnet run", but
two runs of the same model never produce the same closing-block wording, so literal equality would
fail Sonnet against itself. The plan needs a check a subagent can apply without judging, and a rule
for a skill whose Haiku runs pass some of the time.

**Options:**
- **A — a fixed checklist per run; Haiku must pass every item on every run (recommended).** The
  items, each one checkable by command or by reading one line:
  1. The script ran exactly once, with the right arguments (`--stack node` passed through).
  2. The script's output appears in the report verbatim, every line, nothing added or dropped.
  3. A non-zero exit is stated; a zero exit is not reported as a failure.
  4. The closing block is present with **Done**, **Next goal** and **Steps**, and nothing follows it.
  5. The next goal is the one the skill names for that exit (`/codeo:doctor` after `setup`;
     `/codeo:issue` or `/codeo:init #<N>` after a green `doctor`; fixing the named failures and
     re-running `/codeo:doctor` after a red one), and the first step is a command that can run.
  6. For `setup`: the files written are the same as the Sonnet run's (`diff -r` of the two scratch
     repositories prints nothing), and nothing else in the repository changed.

  A Sonnet run that fails an item is recorded too, but does not count against Haiku. One Haiku miss
  on any run of a skill keeps that skill on `model: sonnet`.
- **B — the same checklist, but Haiku only has to do as well as Sonnet did.** If Sonnet missed item
  4 once in three, Haiku may too. Fairer as a comparison, weaker as a bar.
- **C — I read the paired reports and judge them equal or not.** No checklist; the record is my
  reading.

**Answer:**

### Q3 — Where is the comparison recorded?

**Why it matters:** criterion 1 says "recorded" and criterion 2 says "the issue says how it
differed". #52 put its alias record in one issue comment and nothing in the repository. Whether the
record is a comment or a file changes the plan's tasks and its footprint.

**Options:**
- **A — one comment on #76, as #52 did (recommended).** The Claude Code version, the exact
  commands, a table of case × model × run × checklist item, and how any failing run differed. The
  raw reports are not kept. `CHANGELOG.md` carries the one-line result.
- **B — the comment, plus the raw reports committed** under `docs/trials/2026-11-14-haiku-doctor-setup/`.
  Anyone can re-read the evidence; adds 24 files and a new directory under `docs/`.
- **C — a page under `docs/` only**, linked from the issue.

**Answer:**

## Notes

**How a run is made — probed, works.** From the project root:
`claude -p --plugin-dir <checkout> --allowedTools Bash --output-format json "/codeo:doctor"`.
`--plugin-dir` loads the skills from the checkout rather than the installed v1.0.6, so the Haiku
runs use a copy of the checkout whose two `model:` lines say `haiku`, and the Sonnet runs use the
checkout as it is. The probe (Claude Code 2.1.325) ran on `claude-sonnet-5-5` only, per
`modelUsage`, cost $0.163, and reported `doctor.sh`'s eleven `ok` lines verbatim followed by the
closing block. `modelUsage` is what proves which model a run used. The JSON is preceded by one
`[mcp-sdk]` warning line on stdout, which the trial's script has to skip.

**`setup` without changing the project** (the question intake left for this step): `setup` runs in
scratch git repositories outside the checkout, each with an `origin` remote and `origin/HEAD` set so
`setup.sh` resolves owner, name and base branch. One fresh repository per run, so the files written
can be compared with `diff -r`. `doctor.sh` writes nothing, so its passing case runs in this
checkout and its failing case in a scratch copy.

**My calls, unless you say otherwise.** One pull request. The trial is a script in the scratchpad,
not in the repository: it is run once and its result is the record. The `model:` change is one line
per skill, and `tests/skills.test.sh` already accepts `haiku`. No page under `docs/` names the model
of `doctor` or `setup`, so the only documentation the change moves is `CHANGELOG.md`.

**Other workflows.** #73 (`docs/evaluate-docker-sandboxes-sbx-against`, kbajpai) is at `init` and
has no footprint yet; its branch has changed nothing. Nothing to compare so far.

## Outcome

_Pending — written at the hand-off._

## Log

- 2026-11-14 — Q1-Q3 raised · cost: 2m · fable-5-2 60k in + 534k cached / 7k out
