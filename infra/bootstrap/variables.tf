variable "region" {
  description = "AWS region used by the bootstrap stack (state bucket, lock table, OIDC role)."
  type        = string
  default     = "ap-southeast-1"
}

variable "github_repo" {
  description = "GitHub repository allowed to assume the OIDC role, in the form 'owner/repo'."
  type        = string
  default     = "ducnghiaaa/advanced-cicd-pipeline"

  validation {
    condition     = can(regex("^[A-Za-z0-9][A-Za-z0-9-]*/[A-Za-z0-9._-]+$", var.github_repo))
    error_message = "github_repo must be in the form 'owner/repo' (e.g. ducnghiaaa/advanced-cicd-pipeline)."
  }
}
