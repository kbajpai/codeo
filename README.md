# codeo

codeo is an agent-workflow plugin for Claude Code: it carries a piece of work from issue to merged pull request through six steps: issue, init, plan, implement, QC and close. It is unrelated to SYSGO's CODEO IDE and to GoCodeo.

## Dev container

The home container and the per-issue containers, how to open each and the folder names Docker accepts: [`.devcontainer/README.md`](.devcontainer/README.md).

## Tests

```bash
bash tests/run.sh [pattern]   # runs tests/*.test.sh whose name contains the pattern
```

## Skills

The six pipeline skills run in order inside one workflow, each owning one dossier file under `.codeo/<issue>/`; `triage` runs outside the workflow lock, between workflows; `setup` and `doctor` set a project up and check it. [`docs/skills.md`](docs/skills.md) describes each one: what it does, what it reads and writes, what it hands off to and never does, and its extension points.

| Skill | Purpose |
|-------|---------|
| [`/codeo:issue`](docs/skills.md#issue) | Turn a raw idea or finding into a well-formed GitHub issue through a question-and-answer pass |
| [`/codeo:init`](docs/skills.md#init) | Start work on a Ready issue: claim the branch, write its dossier, take the lock, hand off to plan |
| [`/codeo:plan`](docs/skills.md#plan) | Explore, ask, and document a change as a reference doc or implementation plan, and check its footprint against every other workflow in flight |
| [`/codeo:implement`](docs/skills.md#implement) | Execute the approved plan task by task through the superpowers execution skills, deploy to a shared environment under its lease when the plan needs it, build, and hand off to QC |
| [`/codeo:qc`](docs/skills.md#qc) | Check the build, the suites, the criteria, the documentation and an independent review, read what the environment runs, and route forward or back |
| [`/codeo:close`](docs/skills.md#close) | Open the pull request, wait for the merge, route review feedback back, verify the merge, clean up and release the lock; also the way to stash or abandon a workflow |
| [`/codeo:triage`](docs/skills.md#triage) | Find the loose ends development left behind and route them to issues |

[`/codeo:setup`](docs/skills.md#setup) writes `.codeo/` with a starter `config.json` and creates `docs/plans/`;
[`/codeo:doctor`](docs/skills.md#doctor) checks the whole set-up — config, GitHub login and scopes, board, branch ruleset, suites, dependencies, overlays and superpowers — and reports every failure.

A project shapes a skill without editing it through overlay files, `.codeo/overlays/<skill>.md`.
Each skill's extension points are listed in `docs/skills.md` and documented in
`docs/extension-points.md`, which also gives the file format. The dossier and hand-off protocols are
in `docs/dossier.md` and `docs/handoff.md`.

## Checking a dossier

```bash
bash scripts/dossier-check.sh <dossier-dir>
```

The checker reads one finished or live dossier directory (`.codeo/<issue>/`, an archived copy, or any
other directory holding some of `issue.md`, `init.md`, `plan.md`, `implement.md`, `qc.md` and `close.md`)
and checks its structure against the forms `docs/dossier.md` (see *What a finished dossier looks like*)
and `docs/handoff.md` state, except the date line, which is not checked. It judges shape only, never whether a finding, plan or answer is right. It
prints one line per finding, in file order and then check order, and no summary:

```
<FAIL|drift> <file> [<check-id>] <text>
```

`FAIL` is a promise the protocol documents make about every dossier the skills write; `drift` is a
deviation that is reported but not failed on. A check's severity never depends on its input. Exit codes:
0 when no `FAIL` printed, 1 when any did, 2 on a usage error (no directory, or a directory holding none of
the six files). The header of `scripts/dossier-check.sh` lists every check id and is its documentation.

```
drift init.md [header-table] no "| | |" header table after the title
FAIL plan.md [log-cost] line 42: no " · cost: "
```

## Replaying finished dossiers

`tests/replay.test.sh` runs the checker over a project's finished dossiers and compares what it prints
with the findings the project recorded as expected, so a change to the checker or to the skills' forms
shows up against real dossiers. Point `CODEO_GOLDEN_DIR` at a directory of dossier directories plus an
`expected.tsv`:

```bash
CODEO_GOLDEN_DIR=<the project's golden directory> bash tests/replay.test.sh
```

`expected.tsv` has one finding per row with the tab-separated columns `dossier`, `severity` (`FAIL` or
`drift`), `file` and `check-id`; blank lines and lines starting with `#` are ignored. Free text is never
compared, so rewording a finding breaks nothing, while a new finding, a moved or re-graded one, or a
recorded one that no longer occurs does. The success line counts every `expected.tsv` row, `FAIL` rows
included.

With `CODEO_GOLDEN_DIR` unset (how `tests/run.sh` runs it) the replay prints a skip line for the real data
and still exercises the harness on the synthetic directory `tests/fixtures/golden/`. Exit codes: 0 when all
findings are as expected, 1 on a mismatch, 2 when the replay cannot be judged (the variable set but empty, a
nonexistent or empty directory, the checker exiting 2, or a malformed `expected.tsv` row). The golden data
stays in the project's own repository; codeo carries none.

## Requirements

bash 4.3 or later, jq, git and gh. Board access uses `gh project`, which needs GraphQL access to GitHub.

## Status

codeo is released and ready for projects to adopt. The current version is in `.claude-plugin/plugin.json`,
and `CHANGELOG.md` lists what changed in each release. Every entry states the config schema (currently 1),
whether the shared state changed, and whether it is safe to bump mid-workflow, so read the entries between
your version and the new one before upgrading.
