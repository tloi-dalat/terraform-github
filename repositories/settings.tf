resource "github_repository" "this" {
  for_each = local.repos

  name      = each.key
  auto_init = true

  allow_merge_commit     = true
  allow_squash_merge     = true
  allow_rebase_merge     = false
  allow_auto_merge       = true
  delete_branch_on_merge = true

  merge_commit_title          = "PR_TITLE"
  merge_commit_message        = "BLANK"
  squash_merge_commit_title   = "PR_TITLE"
  squash_merge_commit_message = "BLANK"

  security_and_analysis {
    secret_scanning {
      status = "enabled"
    }
    secret_scanning_push_protection {
      status = "enabled"
    }
  }

  archive_on_destroy = true

  lifecycle {
    prevent_destroy = true
    ignore_changes = [
      auto_init,
      description,
      homepage_url,
      has_issues,
      has_wiki,
      has_projects,
      has_discussions,
      is_template,
      allow_update_branch,
      pages,
      template,
    ]
  }
}

removed {
  from = github_repository_dependabot_security_updates.this

  lifecycle {
    destroy = false
  }
}

resource "github_repository_vulnerability_alerts" "this" {
  for_each = local.repos

  repository = github_repository.this[each.key].name
  enabled    = false
}
