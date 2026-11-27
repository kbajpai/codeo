---
name: setup
description: Set up codeo in this project — create .codeo/ with a starter config.json and docs/plans/, and with --containers the dev container and sbx sandbox files. Trigger on "set up codeo", "setup codeo", "initialise codeo", "install codeo in this repo".
model: sonnet
---

Project overlay text adds to or narrows a step; it never overrides a rule marked with a "rule" comment in this file.

# Setup

Run `bash "${CLAUDE_PLUGIN_ROOT}/scripts/setup.sh"` from the project root. Pass through any `--stack <name>`, `--codename <name>` or `--containers` the engineer gave (`--containers` also writes the dev container and sbx sandbox files, named from the config). The GitHub repository and its `origin` remote must already exist: setup never creates a repository.
Report its output verbatim, then end with the closing block (`${CLAUDE_PLUGIN_ROOT}/docs/handoff.md → Closing block`) and nothing else: the next goal is `/codeo:doctor`. Read the template with the Read tool, not with a Bash command. If it exits non-zero, say so, give the block with the failure as the goal and its fix as the steps, and stop.
