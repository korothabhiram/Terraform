#!/usr/bin/env bash
# Apply .github/rulesets/trunk-protection.json to this repo on GitHub.
#
#   ./scripts/apply-ruleset.sh          # create, or update if it already exists
#
# Requires the GitHub CLI, authenticated with the "repo" scope:
#   gh auth login
set -euo pipefail

repo_root=$(git rev-parse --show-toplevel)
cd "$repo_root"

ruleset_file=".github/rulesets/trunk-protection.json"
ruleset_name=$(python3 -c "import json;print(json.load(open('$ruleset_file'))['name'])")

if ! command -v gh >/dev/null 2>&1; then
	echo "error: gh CLI not found. Install it from https://cli.github.com/ or apply" >&2
	echo "       the ruleset by hand: Settings > Rules > Rulesets > New ruleset." >&2
	exit 1
fi

# korothabhiram/Terraform, derived from the origin remote.
slug=$(gh repo view --json nameWithOwner -q .nameWithOwner)

existing_id=$(gh api "repos/$slug/rulesets" --jq \
	".[] | select(.name == \"$ruleset_name\") | .id" 2>/dev/null | head -n 1)

if [ -n "$existing_id" ]; then
	echo "Updating ruleset '$ruleset_name' (id $existing_id) on $slug ..."
	gh api --method PUT "repos/$slug/rulesets/$existing_id" --input "$ruleset_file" >/dev/null
else
	echo "Creating ruleset '$ruleset_name' on $slug ..."
	gh api --method POST "repos/$slug/rulesets" --input "$ruleset_file" >/dev/null
fi

echo "Done. Verify at: https://github.com/$slug/settings/rules"
