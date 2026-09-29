output "region" {
  description = "AWS region the bootstrap stack was deployed to."
  value       = var.region
}

output "state_bucket_name" {
  description = "S3 bucket holding the Terraform remote state for every other stack."
  value       = aws_s3_bucket.tfstate.bucket
}

output "state_bucket_arn" {
  description = "ARN of the Terraform state bucket."
  value       = aws_s3_bucket.tfstate.arn
}

output "github_oidc_provider_arn" {
  description = "ARN of the GitHub Actions OIDC provider (reuse in other stacks that add CI roles)."
  value       = aws_iam_openid_connect_provider.github.arn
}

output "gha_plan_role_arn" {
  description = "Assume this from PRs and pushes to main to run 'terraform plan'."
  value       = aws_iam_role.gha_plan.arn
}

output "gha_apply_role_arn" {
  description = "Assume this from the 'prod' GitHub environment to run 'terraform apply'."
  value       = aws_iam_role.gha_apply.arn
}
