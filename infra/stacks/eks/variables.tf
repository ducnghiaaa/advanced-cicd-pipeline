variable "region" {
  description = "AWS region for the EKS stack."
  type        = string
  default     = "ap-southeast-1"
}

variable "state_bucket" {
  description = "Name of the S3 bucket holding remote state for the other stacks."
  type        = string
}

variable "cluster_name" {
  description = "Name of the EKS cluster (must satisfy the p06-* naming boundary)."
  type        = string
  default     = "p06-eks"
}

variable "cluster_version" {
  description = "Kubernetes control plane version."
  type        = string
  default     = "1.31"
}

variable "public_access_cidrs" {
  description = "CIDRs allowed to reach the public API endpoint. Keep tight in a lab; 0.0.0.0/0 is only OK because auth still requires IAM."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "node_instance_types" {
  description = "Instance types for the managed node group."
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_desired" {
  description = "Desired size of the managed node group."
  type        = number
  default     = 2
}

variable "node_min" {
  description = "Minimum size of the managed node group."
  type        = number
  default     = 1
}

variable "node_max" {
  description = "Maximum size of the managed node group."
  type        = number
  default     = 3
}

variable "use_spot" {
  description = "Use Spot capacity for the worker nodes (cheap for a lab, ok to be evicted)."
  type        = bool
  default     = true
}
