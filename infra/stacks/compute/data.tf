data "aws_caller_identity" "current" {}

data "aws_vpc" "p06" {
  filter {
    name   = "tag:Name"
    values = ["p06-vpc"]
  }
}

data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.p06.id]
  }

  filter {
    name   = "tag:Tier"
    values = ["public"]
  }
}

data "aws_ami" "ubuntu" {
  owners      = ["099720109477"]
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
}

data "aws_ecr_repository" "sample_app" {
  name = var.ecr_repository_name
}

data "http" "github_meta" {
  url = "https://api.github.com/meta"
}

locals {
  github_hook_cidrs = [
    for c in jsondecode(data.http.github_meta.response_body).hooks : c
    if !strcontains(c, ":")
  ]
}
