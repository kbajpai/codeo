# codeo

codeo is an agent-workflow plugin for Claude Code: it carries a piece of work from issue to merged pull request through plan, implement and QC steps. It is unrelated to SYSGO's CODEO IDE and to GoCodeo.

## Tests

```bash
bash tests/run.sh [pattern]   # runs tests/*.test.sh whose name contains the pattern
```

## Requirements

bash 4.3 or later, jq, git and gh. Board access uses `gh project`, which needs GraphQL access to GitHub.

## Status

v0.1.0 is a testing tag, not for projects to adopt. The design is in [docs/plans/2026-10-18-workflow-plugin-extraction-design.md](docs/plans/2026-10-18-workflow-plugin-extraction-design.md).
