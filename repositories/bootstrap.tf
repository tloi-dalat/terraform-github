import {
  for_each = setsubtract(keys(local.repos), ["terraform-tailscale"])
  to       = github_repository_file.dependabot[each.key]
  id       = "${each.key}:.github/dependabot.yaml:main"
}

import {
  to = github_repository_file.pr_check[".github"]
  id = ".github:.github/workflows/pr-check.yaml:main"
}

resource "github_repository_file" "codeowners" {
  for_each = local.repos

  repository          = github_repository.this[each.key].name
  branch              = "main"
  file                = ".github/CODEOWNERS"
  content             = file("${path.module}/bootstrap/CODEOWNERS.${each.value.profile}")
  commit_message      = "chore: add codeowners"
  overwrite_on_create = false

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [content, commit_message, commit_author, commit_email]
  }
}

resource "github_repository_file" "pr_check" {
  for_each = local.title_check_repos

  repository          = github_repository.this[each.key].name
  branch              = "main"
  file                = ".github/workflows/pr-check.yaml"
  content             = file("${path.module}/bootstrap/pr-check.${each.value.profile}.yaml")
  commit_message      = "ci: add pr check"
  overwrite_on_create = false

  depends_on = [github_repository_file.codeowners]

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [content, commit_message, commit_author, commit_email]
  }
}

resource "github_repository_file" "dependabot" {
  for_each = local.repos

  repository          = github_repository.this[each.key].name
  branch              = "main"
  file                = ".github/dependabot.yaml"
  content             = file("${path.module}/bootstrap/dependabot.yaml")
  commit_message      = "ci: add dependabot"
  overwrite_on_create = false

  depends_on = [github_repository_file.pr_check]

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [content, commit_message, commit_author, commit_email]
  }
}

resource "github_branch" "release" {
  for_each = local.service_repos

  repository    = github_repository.this[each.key].name
  branch        = "release"
  source_branch = "main"

  depends_on = [github_repository_file.codeowners, github_repository_file.pr_check, github_repository_file.dependabot]

  lifecycle {
    prevent_destroy = true
    ignore_changes  = all
  }
}
