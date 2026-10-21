locals {
  config = yamldecode(file("${path.module}/members.yaml"))
  owners = toset(local.config.owners)

  teams = {
    for slug, t in local.config.teams : slug => {
      name        = try(t.name, slug)
      description = try(t.description, "")
      maintainers = toset(try(t.maintainers, []))
      members     = toset(try(t.members, []))
    }
  }

  people = setunion(local.owners, flatten([for t in local.teams : setunion(t.maintainers, t.members)]))
}
