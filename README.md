# codeo

codeo is an agent-workflow plugin for Claude Code: it carries a piece of work from issue to merged pull request through six steps: issue, init, plan, implement, QC and close. It is unrelated to SYSGO's CODEO IDE and to GoCodeo.

## Tests

```bash
bash tests/run.sh [pattern]   # runs tests/*.test.sh whose name contains the pattern
```

## Skills

The pipeline skills run in this order, each owning one dossier file under `.codeo/<issue>/`:

| Skill | Purpose | Extension points |
|-------|---------|------------------|
| `/codeo:issue` | Turn a raw idea or finding into a well-formed GitHub issue through a question-and-answer pass | none |
| `/codeo:init` | Start work on a Ready issue: claim the branch, write its dossier, take the lock, hand off to plan | `host-workflow` |
| `/codeo:plan` | Explore, ask, and document a change as a reference doc or implementation plan, and check its footprint against every other workflow in flight | `plan-shape`, `proof-of-done`, `environment-lease-notes`, `wiki-rules` |
| `/codeo:implement` | Execute the approved plan task by task through the superpowers execution skills, deploy to a shared environment under its lease when the plan needs it, build, and hand off to QC | `environment-lease-notes`, `wiki-rules` |
| `/codeo:qc` | Check the build, the suites, the criteria, the documentation and an independent review, read what the environment runs, and route forward or back | `environment-evidence`, `wiki-rules`, `invariants-extra` |
| `/codeo:close` | Open the pull request, wait for the merge, route review feedback back, verify the merge, clean up and release the lock; also the way to stash or abandon a workflow | `put-back`, `ci-publish-check`, `host-workflow` |
| `/codeo:triage` | Find the loose ends development left behind and route them to issues | `todo-excludes` |

The whole pipeline ships: every skill from `issue` to `close`, and `triage`, is included.

`/codeo:setup` writes the project's `.codeo/config.json`, and `/codeo:doctor` checks the setup,
including the project's overlay files.

A project shapes a skill without editing it through overlay files, `.codeo/overlays/<skill>.md`;
`docs/extension-points.md` documents the file format and every extension point. The dossier and
hand-off protocols are in `docs/dossier.md` and `docs/handoff.md`.

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

v0.1.0 is a testing tag, not for projects to adopt.
