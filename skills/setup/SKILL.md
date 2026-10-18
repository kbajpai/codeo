---
name: setup
description: Set up codeo in this project — create .codeo/ with a starter config.json and docs/plans/. Trigger on "set up codeo", "setup codeo", "initialise codeo", "install codeo in this repo".
model: sonnet
---

# Setup

Run `bash "${CLAUDE_PLUGIN_ROOT}/scripts/setup.sh"` from the project root. Pass through any `--stack <name>` the engineer gave.
Report its output verbatim and add nothing else; if it exits non-zero, say so and stop.
