mock_provider "github" {
  mock_data "github_app" {
    defaults = { id = "777" }
  }
}

variables {
  github_app_id              = "1"
  github_app_installation_id = "1"
  github_app_private_key     = "mock"
  ci_app_id                  = 42
  import_repositories        = false
}

run "every_repo_gets_its_rulesets" {
  command = plan

  assert {
    condition     = length(github_repository_ruleset.main) == length(local.repos)
    error_message = "Every repository needs a main ruleset."
  }

  assert {
    condition = alltrue([
      for kind in [github_repository_ruleset.release, github_repository_ruleset.hotfix, github_repository_ruleset.tags] :
      length(kind) == length(local.app_repos)
    ])
    error_message = "Every app repository needs release, releases/** and tag rulesets."
  }

  assert {
    condition = alltrue([
      for name, r in local.repos : alltrue([for c in concat(r.checks_main, r.checks_release) : can(regex("^\\S.*\\S$", c))])
    ])
    error_message = "Status check names must be non-empty strings without surrounding spaces."
  }
}

run "only_gitops_repos_let_the_ci_app_push" {
  command = plan

  assert {
    condition = alltrue([
      for name, rs in github_repository_ruleset.main :
      contains([for b in rs.bypass_actors : b.actor_type], "Integration") == (local.repos[name].profile == "gitops")
    ])
    error_message = "Only gitops repositories may list the CI App as a bypass actor."
  }
}

run "merge_methods_default_to_squash_on_main_and_merge_on_release" {
  command = plan

  assert {
    condition = alltrue(flatten([
      [for rs in github_repository_ruleset.main : join(",", rs.rules[0].pull_request[0].allowed_merge_methods) == "squash"],
      [for rs in github_repository_ruleset.release : join(",", rs.rules[0].pull_request[0].allowed_merge_methods) == "merge"],
    ]))
    error_message = "main must be squash-only and release merge-commit-only."
  }
}

run "repo_settings" {
  command = plan

  assert {
    condition = alltrue([
      for r in github_repository.this :
      !r.allow_rebase_merge && r.allow_auto_merge && r.delete_branch_on_merge && r.squash_merge_commit_title == "PR_TITLE" && r.merge_commit_title == "PR_TITLE" && r.security_and_analysis[0].secret_scanning_push_protection[0].status == "enabled"
    ])
    error_message = "Every repo: no rebase merge, auto-merge on, head branches deleted, commit titles from the PR title, push protection on."
  }
}

run "every_repo_needs_a_code_owner_approval_and_sre_maintain" {
  command = plan

  assert {
    condition     = alltrue([for name, r in local.repos : r.approvals >= 1 && r.code_owner_review && try(r.teams.sre, "") == "maintain"])
    error_message = "Every repo needs 1 approval, code owner review and sre maintain."
  }
}

run "only_atlantis_merges_atlantis_repos" {
  command = plan

  assert {
    condition     = toset(keys(github_repository_ruleset.merge)) == toset(keys(local.atlantis_repos))
    error_message = "Every atlantis repo needs the merge ruleset, and only those."
  }

  assert {
    condition = alltrue([
      for rs in github_repository_ruleset.merge :
      rs.rules[0].update && length(rs.bypass_actors) == 1 && rs.bypass_actors[0].actor_type == "Integration" && rs.bypass_actors[0].actor_id == 777
    ])
    error_message = "The merge ruleset restricts updates to the Atlantis App alone."
  }
}
