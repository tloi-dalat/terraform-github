resource "github_repository_ruleset" "main" {
  for_each = local.repos

  repository  = each.key
  name        = "main"
  target      = "branch"
  enforcement = "active"

  conditions {
    ref_name {
      include = ["~DEFAULT_BRANCH"]
      exclude = []
    }
  }

  dynamic "bypass_actors" {
    for_each = concat(local.admin_bypass, each.value.profile == "gitops" ? local.ci_app_bypass : [])
    content {
      actor_type  = bypass_actors.value.actor_type
      actor_id    = bypass_actors.value.actor_id
      bypass_mode = bypass_actors.value.bypass_mode
    }
  }

  rules {
    deletion                = true
    non_fast_forward        = true
    required_linear_history = each.value.linear_history

    pull_request {
      required_approving_review_count   = each.value.approvals
      require_code_owner_review         = each.value.code_owner_review
      dismiss_stale_reviews_on_push     = true
      require_last_push_approval        = each.value.last_push_review
      required_review_thread_resolution = each.value.resolve_threads
      allowed_merge_methods             = each.value.merge_main
    }

    dynamic "required_status_checks" {
      for_each = length(each.value.checks_main) > 0 ? [1] : []
      content {
        strict_required_status_checks_policy = each.value.up_to_date
        dynamic "required_check" {
          for_each = each.value.checks_main
          content {
            context = required_check.value
          }
        }
      }
    }
  }

  lifecycle {
    precondition {
      condition     = contains(local.profiles, each.value.profile)
      error_message = "${each.key}: profile must be one of ${join(", ", local.profiles)}, got ${each.value.profile}."
    }
  }
}

resource "github_repository_ruleset" "release" {
  for_each = local.app_repos

  repository  = each.key
  name        = "release"
  target      = "branch"
  enforcement = "active"

  conditions {
    ref_name {
      include = ["refs/heads/release"]
      exclude = []
    }
  }

  dynamic "bypass_actors" {
    for_each = local.admin_bypass
    content {
      actor_type  = bypass_actors.value.actor_type
      actor_id    = bypass_actors.value.actor_id
      bypass_mode = bypass_actors.value.bypass_mode
    }
  }

  rules {
    deletion         = true
    non_fast_forward = true

    pull_request {
      required_approving_review_count   = each.value.approvals
      require_code_owner_review         = each.value.code_owner_review
      dismiss_stale_reviews_on_push     = true
      require_last_push_approval        = each.value.last_push_review
      required_review_thread_resolution = each.value.resolve_threads
      allowed_merge_methods             = each.value.merge_release
    }

    dynamic "required_status_checks" {
      for_each = length(each.value.checks_release) > 0 ? [1] : []
      content {
        strict_required_status_checks_policy = each.value.up_to_date
        dynamic "required_check" {
          for_each = each.value.checks_release
          content {
            context = required_check.value
          }
        }
      }
    }
  }
}

resource "github_repository_ruleset" "hotfix" {
  for_each = local.app_repos

  repository  = each.key
  name        = "releases"
  target      = "branch"
  enforcement = "active"

  conditions {
    ref_name {
      include = ["refs/heads/releases/**"]
      exclude = []
    }
  }

  rules {
    deletion         = true
    non_fast_forward = true
  }
}

resource "github_repository_ruleset" "tags" {
  for_each = local.app_repos

  repository  = each.key
  name        = "release tags"
  target      = "tag"
  enforcement = "active"

  conditions {
    ref_name {
      include = ["refs/tags/*.*.*"]
      exclude = []
    }
  }

  rules {
    deletion = true
    update   = true
  }
}

data "github_app" "atlantis" {
  slug = "tloi-atlantis"
}

resource "github_repository_ruleset" "merge" {
  for_each = local.atlantis_repos

  repository  = each.key
  name        = "merge"
  target      = "branch"
  enforcement = "active"

  conditions {
    ref_name {
      include = ["~DEFAULT_BRANCH"]
      exclude = []
    }
  }

  bypass_actors {
    actor_type  = "Integration"
    actor_id    = tonumber(data.github_app.atlantis.id)
    bypass_mode = "always"
  }

  rules {
    update = true
  }
}
