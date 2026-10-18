# Rules

`repositories/repositories.yaml` lists every repo; `rulesets.tf` creates the same repository rulesets in each
(org-wide rulesets need GitHub Team or Enterprise; repository rulesets are free for public repos).

```yaml
quiz:
  profile: app
  approvals: 0
  code_owner_review: false
  checks:
    main: [lint, test]
    release: [lint, test, check-source / source]
```

| Profile | `main` | `release` | `releases/**` | tags `X.Y.Z` |
|---|---|---|---|---|
| `library` | PR required, required checks, no deletion or force push | | | |
| `gitops` | same, and the CI App may push (control-plane's bot commits) | | | |
| `app` | same as `library` | PR from `main` only (`check-source / source`), required checks, no deletion or force push | direct pushes allowed (hotfixes), no deletion or force push | can't be moved or deleted |

- `approvals`: required approving reviews (default 0: a PR is required, not a reviewer).
- `code_owner_review`: require a CODEOWNERS approval.
- `checks`: required status checks, named exactly as on a PR: the job's name, or for a reusable workflow
  `<caller job> / <its job>` (e.g. `check-docker / docker`). YAML anchors can reuse a list.

Org admins can merge a PR that fails a rule (`bypass_mode: pull_request`); nobody can push past one. Skipped
required checks count as passing.

## Gotchas

- A required check that never runs blocks every PR. Add it here only after its workflow is merged in that repo.
- control-plane's receiver must push with the CI App, or dev deploys are rejected by `main`.
- Tag creation isn't restricted: `release-tag.yaml` creates tags with `GITHUB_TOKEN`. Only moving and deleting are.
