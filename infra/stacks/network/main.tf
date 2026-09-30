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

# ---------------------------------------------------------------------------
# S3 Gateway endpoint - free, keeps ECR image layer pulls (stored in S3) off
# the NAT gateway. Attached to private subnet route tables so private-subnet
# workloads (EKS worker nodes) reach S3 without traversing NAT.
# ---------------------------------------------------------------------------
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = module.vpc.vpc_id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = module.vpc.private_route_table_ids

  tags = {
    Name = "p06-vpce-s3"
  }
}
