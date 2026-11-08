import {
  for_each = var.import_files ? local.repos : {}
  to       = github_repository_file.codeowners[each.key]
  id       = "${each.key}/.github/CODEOWNERS:main"
}

import {
  for_each = var.import_files ? local.title_check_repos : {}
  to       = github_repository_file.pr_check[each.key]
  id       = "${each.key}/.github/workflows/pr-check.yaml:main"
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
  content             = file("${path.module}/bootstrap/pr-check.yaml")
  commit_message      = "ci: add pr check"
  overwrite_on_create = false

  depends_on = [github_repository_file.codeowners]

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [content, commit_message, commit_author, commit_email]
  }
}
