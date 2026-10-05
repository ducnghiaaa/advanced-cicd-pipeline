output "cluster_name" {
  description = "Name of the EKS cluster - feed this into `aws eks update-kubeconfig --name`."
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Kubernetes API endpoint."
  value       = module.eks.cluster_endpoint
}

output "cluster_oidc_provider_arn" {
  description = "OIDC provider ARN (needed later for IRSA / pod-level IAM)."
  value       = module.eks.oidc_provider_arn
}

output "kubeconfig_command" {
  description = "One-liner to write kubeconfig for this cluster."
  value       = "aws eks update-kubeconfig --region ${var.region} --name ${module.eks.cluster_name}"
}
