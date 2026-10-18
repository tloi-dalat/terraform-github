variable "owner" {
  description = "GitHub organization"
  type        = string
  default     = "tloi-dalat"
}

variable "github_app_id" {
  description = "App ID of the tloi-terraform GitHub App (TF_VAR_github_app_id)"
  type        = string
}

variable "github_app_installation_id" {
  description = "Its installation ID in the org (TF_VAR_github_app_installation_id)"
  type        = string
}

variable "github_app_private_key" {
  description = "Its private key, PEM contents (TF_VAR_github_app_private_key)"
  type        = string
  sensitive   = true
}

variable "ci_app_id" {
  description = "App ID of the CI GitHub App (tloi-ci), the bot allowed to push to gitops repos' main (TF_VAR_ci_app_id)"
  type        = number
}
