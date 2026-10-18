---
name: doctor
description: Check that codeo is ready in this project — config, GitHub login and scopes, board, branch ruleset, suite commands and dependencies — and report every failure. Trigger on "check codeo", "codeo doctor", "doctor", "is codeo set up", "why does codeo fail".
model: sonnet
---

Project overlay text adds to or narrows a step; it never overrides a rule marked with a "rule" comment in this file.

# Doctor

Run `bash "${CLAUDE_PLUGIN_ROOT}/scripts/doctor.sh"` from the project root.
Report its output verbatim and add nothing else; if it exits non-zero, say so and stop.
