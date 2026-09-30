module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  vpc_id     = data.terraform_remote_state.network.outputs.vpc_id
  subnet_ids = data.terraform_remote_state.network.outputs.private_subnet_ids

  # Public + private endpoint so kubectl from the operator laptop works;
  # workers still reach the API over the private ENI.
  cluster_endpoint_public_access       = true
  cluster_endpoint_public_access_cidrs = var.public_access_cidrs
  cluster_endpoint_private_access      = true

  # Whoever runs `terraform apply` becomes cluster-admin automatically -
  # avoids the classic "locked out of my own cluster" foot-gun.
  enable_cluster_creator_admin_permissions = true

  cluster_addons = {
    coredns    = {}
    kube-proxy = {}
    vpc-cni    = {}
  }

  eks_managed_node_group_defaults = {
    ami_type = "AL2023_x86_64_STANDARD"
  }

  eks_managed_node_groups = {
    default = {
      instance_types = var.node_instance_types
      capacity_type  = var.use_spot ? "SPOT" : "ON_DEMAND"

      min_size     = var.node_min
      max_size     = var.node_max
      desired_size = var.node_desired

      # Nodes go in private subnets - reach the internet (image pulls, apt)
      # via the NAT gateway; reach S3 (ECR layer store) via the S3 gateway
      # endpoint provisioned in the network stack.
      subnet_ids = data.terraform_remote_state.network.outputs.private_subnet_ids
    }
  }

  # Grant the Jenkins agent EC2 role EKS API access. `AmazonEKSEditPolicy` is
  # enough to `kubectl apply` app manifests without giving it cluster-admin.
  access_entries = {
    jenkins_agent = {
      principal_arn = data.terraform_remote_state.compute.outputs.jenkins_agent_role_arn

      policy_associations = {
        edit = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSEditPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }
}
