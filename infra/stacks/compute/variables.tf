variable "region" {
  description = "AWS region."
  type        = string
  default     = "ap-southeast-1"
}

variable "admin_cidrs" {
  description = "CIDRs allowed to SSH into the controller and to open Jenkins UI on port 8080. Use /32 for a single IP."
  type        = list(string)

  validation {
    condition     = length(var.admin_cidrs) > 0
    error_message = "admin_cidrs cannot be empty — leaving it empty means nobody can log in."
  }

  validation {
    condition     = alltrue([for c in var.admin_cidrs : can(cidrhost(c, 0))])
    error_message = "Every entry in admin_cidrs must be a valid IPv4 CIDR (e.g. 1.2.3.4/32)."
  }
}

variable "ssh_public_key" {
  description = "OpenSSH public key content (starts with 'ssh-ed25519' or 'ssh-rsa'). NEVER paste a private key."
  type        = string

  validation {
    condition     = can(regex("^(ssh-ed25519|ssh-rsa|ecdsa-sha2-\\S+)\\s+\\S+", var.ssh_public_key))
    error_message = "ssh_public_key must be an OpenSSH public key (starts with ssh-ed25519 / ssh-rsa / ecdsa-*)."
  }
}

variable "ecr_repository_name" {
  description = "Name of the ECR repo produced by the registry stack."
  type        = string
  default     = "p06/sample-app"
}

variable "ssh_private_key_path" {
  description = "Path to the OpenSSH private key that pairs with ssh_public_key. Used only to scp the generated inventory to the controller."
  type        = string
  default     = "~/.ssh/ducnghiaaa"
}
