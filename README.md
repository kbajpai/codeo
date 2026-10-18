# codeo

codeo is an agent-workflow plugin for Claude Code: it carries a piece of work from issue to merged pull request through plan, implement and QC steps. It is unrelated to SYSGO's CODEO IDE and to GoCodeo.

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
| `/codeo:triage` | Find the loose ends development left behind and route them to issues | `todo-excludes` |

`/codeo:setup` writes the project's `.codeo/config.json`, and `/codeo:doctor` checks the setup,
including the project's overlay files.

A project shapes a skill without editing it through overlay files, `.codeo/overlays/<skill>.md`;
`docs/extension-points.md` documents the file format and every extension point. The dossier and
hand-off protocols are in `docs/dossier.md` and `docs/handoff.md`.

## Requirements

bash 4.3 or later, jq, git and gh. Board access uses `gh project`, which needs GraphQL access to GitHub.

## Status

v0.1.0 is a testing tag, not for projects to adopt.
