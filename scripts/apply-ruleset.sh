#!/usr/bin/env bash
# Push this repo's GitHub-side configuration to GitHub.
#
#   ./scripts/apply-ruleset.sh
#
# Two things live on GitHub rather than in the repo, and neither one applies
# itself when the JSON is merged -- this script is what reconciles them:
#
#   .github/rulesets/trunk-protection.json  the branch ruleset (what may reach main)
#   .github/repo-settings.json              merge behaviour (what happens after a merge,
#                                           including deleting the branch)
#
# Requires the GitHub CLI, authenticated with admin rights on the repo:
#   gh auth login
set -euo pipefail

repo_root=$(git rev-parse --show-toplevel)
cd "$repo_root"

ruleset_file=".github/rulesets/trunk-protection.json"
settings_file=".github/repo-settings.json"

if ! command -v gh >/dev/null 2>&1; then
	echo "error: gh CLI not found. Install it from https://cli.github.com/ or apply" >&2
	echo "       these by hand in Settings > Rules and Settings > General." >&2
	exit 1
fi

# korothabhiram/Terraform, derived from the origin remote.
slug=$(gh repo view --json nameWithOwner -q .nameWithOwner)

# --- merge behaviour ----------------------------------------------------
# delete_branch_on_merge is a repo setting, not a ruleset rule; rulesets
# govern what may reach a branch, this governs cleanup once a pull request
# lands. Deliberately absent: allow_merge_commit and allow_rebase_merge.
# The ruleset's allowed_merge_methods already enforces squash-only, and
# turning those flags off also strips options from the "Update branch"
# button, which is how you satisfy the up-to-date requirement.
if [ -f "$settings_file" ]; then
	echo "Applying repo settings to $slug ..."
	gh api --method PATCH "repos/$slug" --input "$settings_file" --jq \
		'"  delete_branch_on_merge=\(.delete_branch_on_merge) squash=\(.allow_squash_merge)"'
fi

# --- branch ruleset -----------------------------------------------------
ruleset_name=$(python3 -c "import json;print(json.load(open('$ruleset_file'))['name'])")

existing_id=$(gh api "repos/$slug/rulesets" --jq \
	".[] | select(.name == \"$ruleset_name\") | .id" 2>/dev/null | head -n 1)

if [ -n "$existing_id" ]; then
	echo "Updating ruleset '$ruleset_name' (id $existing_id) on $slug ..."
	gh api --method PUT "repos/$slug/rulesets/$existing_id" --input "$ruleset_file" >/dev/null
else
	echo "Creating ruleset '$ruleset_name' on $slug ..."
	gh api --method POST "repos/$slug/rulesets" --input "$ruleset_file" >/dev/null
fi

echo
echo "Done. Verify at:"
echo "  https://github.com/$slug/settings/rules"
echo "  https://github.com/$slug/settings   (Pull Requests section)"
