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
| `merge_methods.main` | `[squash]` | Allowed merge methods into `main` (`merge`, `squash`, `rebase`) |
| `merge_methods.release` | `[merge]` | Allowed merge methods into `release` |
| `checks.main`, `checks.release` | `[]` | Required status checks, named exactly as on a PR: the job's name, or for a reusable workflow `<caller job> / <its job>` (e.g. `check-docker / docker`). YAML anchors can reuse a list |

Always on: PR before merging, stale approvals dismissed on new commits, no force pushes, no deletion.

| Profile | `main` | `release` | `releases/**` | tags `X.Y.Z` |
|---|---|---|---|---|
| `library` | the rules above | | | |
| `gitops` | the rules above; the CI App may push (control-plane's bot commits) | | | |
| `app` | the rules above | PR from `main` only (`check-source / source`), the same PR rules and its own checks | direct pushes allowed (hotfixes), no deletion or force push | can't be moved or deleted |

## Merge methods

- `main`: squash only, so the PR title becomes the commit message.
- `release`: merge commit only. A squash leaves `release` with a commit `main` doesn't have, and every later
  `main` → `release` PR shows old changes again or conflicts.
- Upstream syncs into `main` need a merge commit: an org admin ticks "bypass rules" on the PR and picks
  **Create a merge commit**.

Org admins can merge a PR that fails a rule (`bypass_mode: pull_request`); nobody can push past one. Skipped
required checks count as passing.

## Repository settings

`settings.tf` imports every repo listed in `repositories.yaml` and manages only its pull request settings:

- squash and merge commits on, rebase off;
- auto-merge on;
- head branches deleted after a merge;
- the default commit message for squash and merge commits is the PR title.

The import blocks don't do anything once a repo is in state. Other settings (description, issues, wiki, ...) stay
manual. Removing a repo from `repositories.yaml` fails (`prevent_destroy`); run
`terraform state rm 'github_repository.this["<name>"]'` first.

## Gotchas

- A required check that never runs blocks every PR. Add it here only after its workflow is merged in that repo.
- control-plane's receiver must push with the CI App, or dev deploys are rejected by `main`.
- Tag creation isn't restricted: `release-tag.yaml` creates tags with `GITHUB_TOKEN`. Only moving and deleting are.
