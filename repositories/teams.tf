resource "github_team_repository" "this" {
  for_each = local.team_access

  team_id    = each.value.team
  repository = each.value.repo
  permission = each.value.permission
}
