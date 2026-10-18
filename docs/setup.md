# One-time setup

A pull request gets a plan comment; merging to `main` applies it. `tests/` runs `tofu test` with a mocked
provider on every PR.

1. **GitHub App `tloi-terraform`**: repository permission Administration read/write, webhook off, installable only
   on this account, installed on all repositories. Generate a private key. It is separate from the CI App, whose
   key every repo can use.
2. **This repo's secrets** (not org secrets, so only this repo can change rules): `TERRAFORM_APP_ID`,
   `TERRAFORM_APP_INSTALLATION_ID` (the number at the end of the installation's settings URL),
   `TERRAFORM_APP_PRIVATE_KEY`, `R2_ACCESS_KEY_ID`, `R2_SECRET_ACCESS_KEY` (same state bucket as
   terraform-cloudflare), and the variable `CLOUDFLARE_ACCOUNT_ID`. `CI_APP_ID` comes from the org secret.
3. After the first apply, delete hand-made rulesets and branch protection rules in each repo: they still apply on
   top, and the strictest rule wins.
