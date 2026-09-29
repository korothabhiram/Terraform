# Branching and commit rules

This repo follows **trunk-based development**. `main` is the trunk: it is always
releasable, and it is the only long-lived branch.

## One-time setup

```bash
./scripts/install-hooks.sh
```

This points the clone at `.githooks/`, which checks your commit messages before
they are written. CI runs the same checks, so skipping the hook with
`--no-verify` only moves the failure to the pull request.

## The loop

```bash
git switch main && git pull --rebase       # start from current trunk
git switch -c TRY-1                        # branch named after the ticket
# ... work, committing as you go ...
git commit -m 'TRY-1: add ECS task definition for the api service'
git push -u origin TRY-1
# open a PR titled: TRY-1: add ECS task definition for the api service
# squash-merge once commit-lint is green
git switch main && git pull --rebase
git branch -d TRY-1                        # delete the branch, it is done
```

Keep branches short-lived — hours to a couple of days. A branch that lives for a
week is no longer trunk-based development, and it is where painful merges come
from. If a change is too big to land in a day, land it behind a flag or in
vertical slices that each keep `main` green.

## Rules that are enforced

| Rule | Enforced by |
| --- | --- |
| Commit subject matches `TRY-<number>: <description>` | `.githooks/commit-msg` + `commit-lint` CI |
| Branch named `TRY-<number>` | `commit-lint` CI |
| PR title matches `TRY-<number>: <description>` | `commit-lint` CI |
| No direct pushes to `main` | `.githooks/pre-push` + branch ruleset |
| `main` stays linear, squash-merge only | branch ruleset |
| `commit-lint` must pass, branch must be up to date | branch ruleset |
| `main` cannot be deleted or force-pushed | branch ruleset |

### Commit message format

```
TRY-<number>: <description>
```

The number is the ticket. Any `TRY-<number>` is accepted on any branch, so a
commit can be cherry-picked between branches without rewording it.

```
✅ TRY-1: add ECS task definition for the api service
✅ TRY-42: fix null deref in the health check
❌ add ECS task definition          (no prefix)
❌ TRY1: add task definition        (missing hyphen)
❌ try-1: add task definition       (must be uppercase)
❌ TRY-1 add task definition        (missing colon)
```

Exempt, because Git writes or rewrites them for you: `Merge …` commits and
`Revert "…"` commits. `fixup!` / `squash!` commits are fine locally but must be
squashed away before the PR is merged.

Keep the subject at 72 characters or fewer; the hook warns past that. Put
anything longer in the body, after a blank line.

## Fixing a rejected message

```bash
git commit --amend                         # most recent commit
git rebase -i <base-sha>                   # older commits: reword each one
git push --force-with-lease
```

## Branch protection

`.github/rulesets/trunk-protection.json` is the source of truth for the `main`
ruleset. Apply or re-apply it with:

```bash
./scripts/apply-ruleset.sh                 # needs the gh CLI
```

The ruleset has no bypass actors, so it applies to admins too. If you need an
emergency escape hatch, add yourself to `bypass_actors` and re-apply.
