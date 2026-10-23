# Rules

`repositories/repositories.yaml` lists every repo; `rulesets.tf` creates the same repository rulesets in each
(org-wide rulesets need GitHub Team or Enterprise; repository rulesets are free for public repos).

```yaml
quiz:
  profile: service
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
| `bypass` | `{}` | Ruleset name (`main`, `release`, `merge`) → GitHub App slugs that may bypass it. See [Bypass](#bypass) |

Always on: PR before merging, stale approvals dismissed on new commits, no force pushes, no deletion.

| Profile | `main` | `release` | `releases/**` | tags `X.Y.Z` |
|---|---|---|---|---|
| `platform` | the rules above | | | |
| `service` | the rules above | PR from `main` only (`check-source / source`), the same PR rules and its own checks | direct pushes allowed (hotfixes), no deletion or force push | can't be moved or deleted |

## Merge methods

- `main`: squash only, so the PR title becomes the commit message.
- `release`: merge commit only. A squash leaves `release` with a commit `main` doesn't have, and every later
  `main` → `release` PR shows old changes again or conflicts.
- Upstream syncs into `main` need a merge commit: an org admin ticks "bypass rules" on the PR and picks
  **Create a merge commit**.

Org admins can merge a PR that fails a rule (`bypass_mode: pull_request`); nobody can push past one. Skipped
required checks count as passing.

## Bypass

`bypass` names, per ruleset, the GitHub Apps allowed past it. Apps are named by slug and resolved to their App ID
at plan time, so adding a bot is one line and the whole org's bypass surface is readable here.

```yaml
control-plane:
  profile: platform
  bypass:
    main: [tloi-ci]        # the bot may push to main

terraform-github:
  profile: platform
  bypass:
    merge: [tloi-atlantis] # only Atlantis may merge
```

Apps bypass in `always` mode (they push directly); org admins keep their `pull_request` bypass on `main` and
`release` on top of whatever is listed. An unknown key (`maim:`) or a `release` list on a non-`service` repo fails the
plan rather than silently doing nothing.

### `merge`

A non-empty `bypass.merge` creates a `merge` ruleset on `main` that only those Apps can update — so a PR merges
only when Atlantis applies it. This ruleset has no admin bypass. A PR without Terraform changes still goes through
Atlantis: `atlantis plan -p <project>`, then `atlantis apply` (no changes) merges it. If Atlantis is down, an org
owner disables the `merge` ruleset in the repo's Settings → Rules; the next apply turns it back on.

## Teams

Each repo lists its teams and their roles (`pull`, `triage`, `push`, `maintain`, `admin`) under `teams:` in
`repositories.yaml`; `sre: maintain` is required. A team left out has no access.

Who must approve is in each repo's `.github/CODEOWNERS`. A code owner needs write access, which this gives.

| Repo | Code owners |
|---|---|
| control-plane | `sre` or `swe`; `.github/` and `bootstrap/` only `sre` |
| charts, reusable-workflow, terraform-*, .github, status | `sre` |
| service repos | `swe`; `.github/` only `sre` |

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
- control-plane's receiver must push with the CI App listed in its `bypass.main`, or dev deploys are rejected by `main`.
- A bypass slug that doesn't resolve fails the plan for every repo, not just its own: the App lookup is one
  `for_each` over the union of all slugs.
- Tag creation isn't restricted: `release-tag.yaml` creates tags with `GITHUB_TOKEN`. Only moving and deleting are.
