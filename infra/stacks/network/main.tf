data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, 2)
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.0"

  name = "p06-vpc"
  cidr = "10.60.0.0/16"

  azs             = local.azs
  public_subnets  = ["10.60.0.0/24", "10.60.1.0/24"]
  private_subnets = ["10.60.10.0/24", "10.60.11.0/24"]

  enable_nat_gateway = var.enable_nat
  single_nat_gateway = true

  enable_dns_hostnames = true
  enable_dns_support   = true

  public_subnet_tags = {
    Tier                     = "public"
    "kubernetes.io/role/elb" = "1"
  }

  private_subnet_tags = {
    Tier                              = "private"
    "kubernetes.io/role/internal-elb" = "1"
  }
}
