output "repository_url" {
  description = "URL used by 'docker push' / 'docker pull' for the sample-app repo."
  value       = aws_ecr_repository.sample_app.repository_url
}

output "repository_arn" {
  description = "ARN of the sample-app ECR repository."
  value       = aws_ecr_repository.sample_app.arn
}
