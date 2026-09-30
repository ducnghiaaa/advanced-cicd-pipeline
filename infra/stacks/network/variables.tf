variable "region" {
  description = "AWS region for the networking stack."
  type        = string
  default     = "ap-southeast-1"
}

variable "enable_nat" {
  description = "Provision a single NAT gateway for the private subnets. Turn on in Phase 5."
  type        = bool
  default     = true
}
