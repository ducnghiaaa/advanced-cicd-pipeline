# eks:DescribeCluster is what `aws eks update-kubeconfig` calls before kubectl
# can talk to the API. The access entry above says the role is a K8s admin,
# but the initial "which cluster and where" lookup is still an AWS API call.
data "aws_iam_policy_document" "agent_eks_describe" {
  statement {
    sid       = "EksDescribeForKubeconfig"
    effect    = "Allow"
    actions   = ["eks:DescribeCluster", "eks:ListClusters"]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "agent_eks_describe" {
  name   = "eks-describe"
  role   = data.terraform_remote_state.compute.outputs.jenkins_agent_role_name
  policy = data.aws_iam_policy_document.agent_eks_describe.json
}
