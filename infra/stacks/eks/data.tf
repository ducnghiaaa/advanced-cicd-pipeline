data "aws_caller_identity" "current" {}

# Read VPC + subnets from the network stack instead of duplicating them here.
data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = var.state_bucket
    key    = "stacks/network/terraform.tfstate"
    region = var.region
  }
}

# Read the Jenkins agent IAM role from the compute stack so we can grant it
# EKS API access (kubectl from the pipeline) via an access entry.
data "terraform_remote_state" "compute" {
  backend = "s3"
  config = {
    bucket = var.state_bucket
    key    = "stacks/compute/terraform.tfstate"
    region = var.region
  }
}
