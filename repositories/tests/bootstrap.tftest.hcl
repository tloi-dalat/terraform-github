mock_provider "github" {
  mock_data "github_app" {
    defaults = { id = "777" }
  }
}

variables {
  github_app_id              = "1"
  github_app_installation_id = "1"
  github_app_private_key     = "mock"
}

run "seeded_files_follow_the_yaml" {
  command = plan

  assert {
    condition     = length(github_repository_file.codeowners) == length(local.repos)
    error_message = "Every repository gets a CODEOWNERS."
  }

  assert {
    condition = alltrue([
      for name, r in local.repos : contains(keys(github_repository_file.pr_check), name) == contains(r.checks_main, "check-title / title")
    ])
    error_message = "pr-check.yaml is seeded exactly in the repositories that require check-title / title."
  }

  assert {
    condition = alltrue([
      for name, f in github_repository_file.codeowners :
      f.content == file("${path.module}/bootstrap/CODEOWNERS.${local.repos[name].profile}")
    ])
    error_message = "A seeded CODEOWNERS must match its profile's template."
  }
}

run "bootstrap_templates_exist_for_every_profile" {
  command = plan

  assert {
    condition     = alltrue([for p in local.profiles : fileexists("${path.module}/bootstrap/CODEOWNERS.${p}") && fileexists("${path.module}/bootstrap/pr-check.${p}.yaml")])
    error_message = "Every profile needs bootstrap/CODEOWNERS.<profile> and bootstrap/pr-check.<profile>.yaml templates."
  }
}

run "service_repos_get_a_release_branch" {
  command = plan

  assert {
    condition     = keys(github_branch.release) == keys(local.service_repos)
    error_message = "Every service repository, and only those, gets a release branch."
  }
}
