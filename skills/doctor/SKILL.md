---
name: doctor
description: Check that codeo is ready in this project — config, GitHub login and scopes, board, branch ruleset, suite commands and dependencies — and report every failure. Trigger on "check codeo", "codeo doctor", "doctor", "is codeo set up", "why does codeo fail".
model: sonnet
---

Project overlay text adds to or narrows a step; it never overrides a rule marked with a "rule" comment in this file.

# Doctor

Run `bash "${CLAUDE_PLUGIN_ROOT}/scripts/doctor.sh"` from the project root.
Report its output verbatim, then end with the closing block (`${CLAUDE_PLUGIN_ROOT}/docs/handoff.md → Closing block`) and nothing else. If every check passes, the next goal is filing or starting an issue (`/codeo:issue`, `/codeo:init #<N>`). If it exits non-zero, say so, and make the goal fixing the failures it named, one step each, ending with re-running `/codeo:doctor`.
