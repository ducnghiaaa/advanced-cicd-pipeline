output "vpc_id" {
  description = "ID of the p06 VPC."
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of the two public subnets."
  value       = module.vpc.public_subnets
}

output "private_subnet_ids" {
  description = "IDs of the two private subnets."
  value       = module.vpc.private_subnets
}
