# Rules

`repositories/repositories.yaml` lists every repo; `rulesets.tf` creates the same repository rulesets in each
(org-wide rulesets need GitHub Team or Enterprise; repository rulesets are free for public repos).

```yaml
quiz:
  profile: app
  checks:
    main: [lint, test]
    release: [lint, test, check-source / source]
```

| Option | Default | Rule |
|---|---|---|
| `approvals` | `0` | Required approving reviews. A PR is always required |
| `code_owner_review` | `false` | Require a CODEOWNERS approval |
| `up_to_date` | `false` | Branch must be up to date with the base before merging |
| `linear_history` | `false` | `main` only: no merge commits |
| `resolve_threads` | `false` | All review conversations resolved before merging |
| `last_push_review` | `false` | The last push must be approved by someone other than its author |
| `checks.main`, `checks.release` | `[]` | Required status checks, named exactly as on a PR: the job's name, or for a reusable workflow `<caller job> / <its job>` (e.g. `check-docker / docker`). YAML anchors can reuse a list |

Always on: PR before merging, stale approvals dismissed on new commits, no force pushes, no deletion.

| Profile | `main` | `release` | `releases/**` | tags `X.Y.Z` |
|---|---|---|---|---|
| `library` | the rules above | | | |
| `gitops` | the rules above; the CI App may push (control-plane's bot commits) | | | |
| `app` | the rules above | PR from `main` only (`check-source / source`), the same PR rules and its own checks | direct pushes allowed (hotfixes), no deletion or force push | can't be moved or deleted |

## Merge methods

Merge methods are repository settings, not rules (the provider can't set them per branch yet). In each repo's
Settings → General → Pull Requests:

- Allow squash merging (PRs into `main`, so the PR title becomes the commit message) and merge commits.
- Merge `main` → `release` with **Create a merge commit**, never squash. A squash leaves `release` with a commit
  `main` doesn't have, and every later `main` → `release` PR shows old changes again or conflicts.
- Turn on "Automatically delete head branches".

Org admins can merge a PR that fails a rule (`bypass_mode: pull_request`); nobody can push past one. Skipped
required checks count as passing.

## Gotchas

- A required check that never runs blocks every PR. Add it here only after its workflow is merged in that repo.
- control-plane's receiver must push with the CI App, or dev deploys are rejected by `main`.
- Tag creation isn't restricted: `release-tag.yaml` creates tags with `GITHUB_TOKEN`. Only moving and deleting are.
