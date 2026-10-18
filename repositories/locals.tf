locals {
  profiles = ["library", "gitops", "app"]

  repos = {
    for name, r in yamldecode(file("${path.module}/repositories.yaml")) : name => {
      profile           = r.profile
      approvals         = try(r.approvals, 0)
      code_owner_review = try(r.code_owner_review, false)
      up_to_date        = try(r.up_to_date, false)
      linear_history    = try(r.linear_history, false)
      resolve_threads   = try(r.resolve_threads, false)
      last_push_review  = try(r.last_push_review, false)
      checks_main       = flatten(try(r.checks.main, []))
      checks_release    = flatten(try(r.checks.release, []))
    }
  }

  app_repos = { for name, r in local.repos : name => r if r.profile == "app" }

  admin_bypass = [{ actor_type = "OrganizationAdmin", actor_id = 1, bypass_mode = "pull_request" }]

  ci_app_bypass = [{ actor_type = "Integration", actor_id = var.ci_app_id, bypass_mode = "always" }]
}
