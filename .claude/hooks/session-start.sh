#!/bin/bash
# Install the codeo and superpowers plugins in a cloud session, so /codeo:* commands load.
# Cloud sessions only; skipped when both plugins are already installed.
set -euo pipefail

if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

cd "${CLAUDE_PROJECT_DIR:-.}"

installed=$(claude plugin list 2>/dev/null || true)
if grep -q 'codeo@codeo' <<<"$installed" && grep -q 'superpowers@superpowers-marketplace' <<<"$installed"; then
  exit 0
fi

# install.sh is idempotent and installs the latest release at user scope.
bash install.sh
