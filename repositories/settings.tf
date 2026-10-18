import {
  for_each = var.import_repositories ? local.repos : {}
  to       = github_repository.this[each.key]
  id       = each.key
}

resource "github_repository" "this" {
  for_each = local.repos

  name = each.key

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
