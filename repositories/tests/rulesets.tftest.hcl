mock_provider "github" {}

variables {
  github_app_id              = "1"
  github_app_installation_id = "1"
  github_app_private_key     = "mock"
  ci_app_id                  = 42
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
