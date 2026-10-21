resource "github_membership" "this" {
  for_each = local.people

  username = each.key
  role     = contains(local.owners, each.key) ? "admin" : "member"

  lifecycle {
    precondition {
      condition     = length(local.owners) > 0
      error_message = "Keep at least one owner, or nobody can administer the organization."
    }
  }
}

import {
  for_each = var.import_teams ? toset([for t in ["sre", "swe"] : t if contains(keys(local.teams), t)]) : toset([])
  to       = github_team.this[each.key]
  id       = each.key
}

resource "github_team" "this" {
  for_each = local.teams

  name        = each.value.name
  description = each.value.description
  privacy     = "closed"
}

resource "github_team_members" "this" {
  for_each = local.teams

  team_slug = github_team.this[each.key].slug

  dynamic "members" {
    for_each = each.value.maintainers
    content {
      username = members.value
      role     = "maintainer"
    }
  }

  dynamic "members" {
    for_each = each.value.members
    content {
      username = members.value
      role     = "member"
    }
  }

  depends_on = [github_membership.this]

  lifecycle {
    precondition {
      condition     = length(each.value.maintainers) > 0
      error_message = "${each.key}: needs a maintainer, or GitHub promotes one and the plan never settles."
    }
    precondition {
      condition     = length(setintersection(each.value.members, local.owners)) == 0
      error_message = "${each.key}: list owners as maintainers; GitHub makes them maintainers anyway."
    }
    precondition {
      condition     = length(setintersection(each.value.members, each.value.maintainers)) == 0
      error_message = "${each.key}: a user is both maintainer and member."
    }
  }
}
