mock_provider "github" {
  mock_resource "github_team" {
    defaults = { slug = "mock-team" }
  }
}

variables {
  github_app_id              = "1"
  github_app_installation_id = "1"
  github_app_private_key     = "mock"
  import_teams               = false
}

run "everyone_listed_is_a_member" {
  command = plan

  assert {
    condition     = alltrue([for u in local.people : contains(keys(github_membership.this), u)])
    error_message = "Every owner and team user needs an organization membership."
  }

  assert {
    condition     = alltrue([for u in local.owners : github_membership.this[u].role == "admin"])
    error_message = "Owners must have the admin role."
  }

  assert {
    condition     = alltrue([for t in github_team.this : t.privacy == "closed"])
    error_message = "Teams must be visible: CODEOWNERS can't use secret teams."
  }
}
