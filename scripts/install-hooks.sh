#!/usr/bin/env bash
# Point this clone at the versioned hooks in .githooks/.
# Run once per clone:  ./scripts/install-hooks.sh
set -euo pipefail

repo_root=$(git rev-parse --show-toplevel)
cd "$repo_root"

git config core.hooksPath .githooks
chmod +x .githooks/* 2>/dev/null || true

echo "Hooks installed (core.hooksPath=.githooks):"
for hook in .githooks/*; do
	[ -f "$hook" ] && echo "  - $(basename "$hook")"
done
echo
echo "Commit subjects must now match:  TRY-<number>: <description>"
