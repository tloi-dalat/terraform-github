locals {
  profiles = ["library", "gitops", "app"]

  repos = {
    for name, r in yamldecode(file("${path.module}/repositories.yaml")) : name => {
      profile           = r.profile
      approvals         = try(r.approvals, 0)
      code_owner_review = try(r.code_owner_review, false)
      checks_main       = flatten(try(r.checks.main, []))
      checks_release    = flatten(try(r.checks.release, []))
    }
  }

  app_repos = { for name, r in local.repos : name => r if r.profile == "app" }

  admin_bypass = [{ actor_type = "OrganizationAdmin", actor_id = 1, bypass_mode = "pull_request" }]

  ci_app_bypass = [{ actor_type = "Integration", actor_id = var.ci_app_id, bypass_mode = "always" }]
}
