mock_provider "github" {
  mock_data "github_app" {
    defaults = { id = "777" }
  }
}

variables {
  github_app_id              = "1"
  github_app_installation_id = "1"
  github_app_private_key     = "mock"
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
      length(kind) == length(local.service_repos)
    ])
    error_message = "Every service repository needs release, releases/** and tag rulesets."
  }

  assert {
    condition = alltrue([
      for name, r in local.repos : alltrue([for c in concat(r.checks_main, r.checks_release) : can(regex("^\\S.*\\S$", c))])
    ])
    error_message = "Status check names must be non-empty strings without surrounding spaces."
  }
}

run "main_bypass_actors_come_from_the_yaml" {
  command = plan

  assert {
    condition = alltrue([
      for name, rs in github_repository_ruleset.main :
      length([for b in rs.bypass_actors : b if b.actor_type == "Integration"]) == length(try(local.repos[name].bypass.main, []))
    ])
    error_message = "A repo's main ruleset must list exactly the apps named by its bypass.main in repositories.yaml."
  }

  assert {
    condition = alltrue([
      for rs in github_repository_ruleset.main :
      length([for b in rs.bypass_actors : b if b.actor_type == "OrganizationAdmin" && b.bypass_mode == "pull_request"]) == 1
    ])
    error_message = "Every main ruleset keeps the org admin pull_request bypass."
  }

  assert {
    condition = alltrue([
      for rs in github_repository_ruleset.main :
      alltrue([for b in rs.bypass_actors : b.bypass_mode == "always" if b.actor_type == "Integration"])
    ])
    error_message = "App bypass actors are granted in always mode."
  }
}

run "every_bypass_slug_resolves_to_an_app" {
  command = plan

  assert {
    condition     = length(data.github_app.bypass) == length(local.bypass_slugs)
    error_message = "Every app slug named under bypass in repositories.yaml must resolve to a GitHub App."
  }

  assert {
    condition = alltrue([
      for name, r in local.repos : alltrue([for ruleset in keys(r.bypass) : contains(local.bypass_rulesets, ruleset)])
    ])
    error_message = "bypass keys must be one of ${join(", ", local.bypass_rulesets)}."
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

run "only_named_apps_merge_their_repos" {
  command = plan

  assert {
    condition     = toset(keys(github_repository_ruleset.merge)) == toset(keys(local.merge_repos))
    error_message = "A repo gets the merge ruleset exactly when it names apps under bypass.merge."
  }

  assert {
    condition = alltrue([
      for name, rs in github_repository_ruleset.merge :
      rs.rules[0].update && length(rs.bypass_actors) == length(local.repos[name].bypass.merge)
    ])
    error_message = "The merge ruleset restricts updates to the apps named by bypass.merge."
  }

  assert {
    condition = alltrue([
      for rs in github_repository_ruleset.merge :
      alltrue([for b in rs.bypass_actors : b.actor_type == "Integration" && b.bypass_mode == "always"])
    ])
    error_message = "Only apps may merge an atlantis repo: no admin bypass on the merge ruleset."
  }
}
