resource "github_actions_organization_workflow_permissions" "this" {
  organization_slug                = var.owner
  default_workflow_permissions     = "read"
  can_approve_pull_request_reviews = false
}
