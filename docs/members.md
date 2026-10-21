# Members

`organization/members.yaml` is the whole list of who is in `tloi-dalat` and in which team. Applying a change
(`atlantis apply -p organization`) invites a new name and removes a deleted one from the organization.

```yaml
owners:
  - kitsunehivern

teams:
  sre:
    name: SRE
    description: Site Reliability Engineer
    maintainers: [kitsunehivern]
    members: [someone]
```

- GitHub usernames, not emails.
- A team's key is its slug (CODEOWNERS, repository access, Atlantis); `name` is the display name (default: the key), which Cloudflare Access matches in `github_teams`.
- Everyone listed anywhere becomes an organization member; `owners` are organization owners.
- `members` of a team is authoritative: people added to a team by hand are removed on the next apply.
- Every team needs a maintainer. List owners under `maintainers`, never `members` (GitHub promotes them anyway).
- Someone added to a team joins it only after accepting the organization invitation.
- Which repositories each team can reach: `repositories/repositories.yaml` (`docs/rules.md`, Teams).
- Teams are visible (`closed`), which CODEOWNERS requires.

Before the first apply, put every current member in `members.yaml`: the plan removes anyone missing.
