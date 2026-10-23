output "rulesets" {
  description = "Rulesets per repository"
  value = {
    for name, r in local.repos : name => compact([
      "main",
      contains(keys(local.service_repos), name) ? "release" : "",
      contains(keys(local.service_repos), name) ? "releases/**" : "",
      contains(keys(local.service_repos), name) ? "tags X.Y.Z" : "",
    ])
  }
}
