# Contributing

## Dev container

The home container and the per-issue containers, how to open each and the folder names Docker accepts: [`.devcontainer/README.md`](.devcontainer/README.md).

## Hosted sessions

This repository's `.claude/settings.json` runs `.claude/hooks/session-start.sh` at `SessionStart`. It runs only in a hosted session (`CLAUDE_CODE_REMOTE=true`) and only when a session starts, resumes or forks, not on `clear` or `compact`.

The hook runs `install.sh` (the latest release, at user scope) unless `codeo@codeo` and a `superpowers` plugin from any marketplace are both installed and enabled at user scope. A disabled one is enabled by `install.sh`.

A failed install does not stop the session (the command ends `|| true`) and is bounded at 300 seconds.

If the `/codeo:*` commands are not listed after the hook ran, start a new session; the [README](README.md#installing) says sessions that are already open need a restart to load the plugins.

`tests/session-start-hook.test.sh` covers the skip rule.

## Tests

```bash
bash tests/run.sh [pattern]   # runs tests/*.test.sh whose name contains the pattern
```

## Changelog entries

An issue's entry is the file `changelog.d/<issue>.md`: optional header lines `Config schema:`, `Shared state:` and `Safe to bump mid-workflow:` before the first blank line, then the bullets. `CHANGELOG.md` is edited only by `tools/changelog.sh assemble`, which folds the fragments into a release section at release time. A test that looks for an entry reads `bash tools/changelog.sh cat`.

In the assembled `Safe to bump mid-workflow:` line a value beginning with the whole word `yes` is a yes and anything else is a caution; any caution beats every yes, and the cautions are joined with `; ` (a leading `no — ` is dropped from each). `Shared state:` values are joined with `; `, and fragments that disagree on `Config schema:` are refused.

A plan's changelog documentation task writes `changelog.d/<issue>.md`, never `CHANGELOG.md`, and its footprint lists `changelog.d/**`.

## The skills inventory pin

`tests/inventory.test.sh` pins `docs/skills-inventory.md` to the rules in the skills, one line per rule, each followed by a blank line. `bash tests/inventory.test.sh --update` overwrites the fixture whole. Rules in the page are separated by a blank line (the test fails a rule that follows another directly), so two changes to different rules merge without a conflict. Two changes to the same rule, or two rules appended after the same rule, conflict in `docs/skills-inventory.md`: resolve the page, run `bash tests/inventory.test.sh --update` and commit the fixture.

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

