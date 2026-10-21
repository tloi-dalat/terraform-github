output "members" {
  description = "Username → organization role"
  value       = { for u, m in github_membership.this : u => m.role }
}
