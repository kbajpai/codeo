#!/bin/bash
# Install the codeo and superpowers plugins in a cloud session when either is missing or disabled
# at user scope, by running install.sh. Cloud sessions only (CLAUDE_CODE_REMOTE=true); skipped when
# both are installed and enabled, read from `claude plugin list --json` as install.sh reads it.
# What the session then lists is described in CONTRIBUTING.md → Hosted sessions.
set -euo pipefail

if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

cd "${CLAUDE_PROJECT_DIR:-.}"

# Notice lines may surround the array: read the first array from the first line starting with "[".
# A failing claude, a missing jq or unparsable output leaves both counts empty, so it installs.
raw=$(claude plugin list --json 2>/dev/null || true)
ready=$(printf '%s\n' "$raw" | sed -n '/^\[/,$p' | jq -c 'select(type == "array")' 2>/dev/null \
  | head -n 1 | jq -r '
      def ok(f): any(.[]; (f) and .scope == "user" and .enabled != false);
      if ok(.id == "codeo@codeo") and ok(.id | startswith("superpowers@")) then "yes" else empty end' \
  2>/dev/null || true)
if [ "$ready" = "yes" ]; then
  exit 0
fi

# install.sh is idempotent and installs the latest release at user scope.
bash install.sh
