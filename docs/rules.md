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
| `approvals` | `1` | Required approving reviews |
| `code_owner_review` | `true` | One approval must come from a code owner of the changed files |
| `up_to_date` | `false` | Branch must be up to date with the base before merging |
| `linear_history` | `false` | `main` only: no merge commits |
| `resolve_threads` | `false` | All review conversations resolved before merging |
| `last_push_review` | `true` | The last push must be approved by someone other than its author |
| `teams` | by profile | Team → permission (`pull`, `triage`, `push`, `maintain`, `admin`) |
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

## Atlantis repos

`atlantis: true` adds a `merge` ruleset on `main`: only the `tloi-atlantis` App can update it, so a PR merges only
when Atlantis applies it. A PR without Terraform changes still goes through Atlantis: `atlantis plan -p <project>`,
then `atlantis apply` (no changes) merges it. If Atlantis is down, an org owner disables the `merge` ruleset in the
repo's Settings → Rules; the next apply turns it back on.

## Teams

Each repo lists its teams and their roles (`pull`, `triage`, `push`, `maintain`, `admin`) under `teams:` in
`repositories.yaml`; `sre: maintain` is required. A team left out has no access.

Who must approve is in each repo's `.github/CODEOWNERS`. A code owner needs write access, which this gives.

| Repo | Code owners |
|---|---|
| control-plane | `sre` or `swe`; `.github/` and `bootstrap/` only `sre` |
| charts, reusable-workflow, terraform-* | `sre` |
| app repos | `swe`; `.github/` only `sre` |

## Repository settings

`settings.tf` imports every repo listed in `repositories.yaml` and manages only its pull request settings:

- squash and merge commits on, rebase off;
- auto-merge on;
- head branches deleted after a merge;
- the default commit message for squash and merge commits is the PR title;
- secret scanning and push protection on;
- Dependabot alerts off, which also turns off security update PRs (version updates still come from `.github/dependabot.yaml`).

The import blocks don't do anything once a repo is in state. Other settings (description, issues, wiki, ...) stay
manual.

Removing a repo from `repositories.yaml` fails (`prevent_destroy`); run
`terraform state rm 'github_repository.this["<name>"]'` first.

`organization.tf`: `GITHUB_TOKEN` is read-only unless a workflow asks for more (`permissions:`), and Actions can't
approve PRs.

## Gotchas

- A required check that never runs blocks every PR. Add it here only after its workflow is merged in that repo.
- control-plane's receiver must push with the CI App, or dev deploys are rejected by `main`.
- Tag creation isn't restricted: `release-tag.yaml` creates tags with `GITHUB_TOKEN`. Only moving and deleting are.
