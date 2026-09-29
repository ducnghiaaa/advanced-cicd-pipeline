data "aws_iam_policy_document" "ec2_trust" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# ---------------------------------------------------------------------------
# Ansible controller — SSM only
# ---------------------------------------------------------------------------
resource "aws_iam_role" "controller" {
  name               = "p06-ansible-controller"
  assume_role_policy = data.aws_iam_policy_document.ec2_trust.json
}

resource "aws_iam_role_policy_attachment" "controller_ssm" {
  role       = aws_iam_role.controller.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

data "aws_iam_policy_document" "controller_ec2_read" {
  statement {
    sid       = "AwsEc2DynamicInventory"
    effect    = "Allow"
    actions   = ["ec2:DescribeInstances", "ec2:DescribeTags", "ec2:DescribeRegions"]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "controller_ec2_read" {
  name   = "aws-ec2-dynamic-inventory"
  role   = aws_iam_role.controller.id
  policy = data.aws_iam_policy_document.controller_ec2_read.json
}

resource "aws_iam_instance_profile" "controller" {
  name = "p06-ansible-controller"
  role = aws_iam_role.controller.name
}

# ---------------------------------------------------------------------------
# Jenkins master — SSM only
# ---------------------------------------------------------------------------
resource "aws_iam_role" "jenkins_master" {
  name               = "p06-jenkins-master"
  assume_role_policy = data.aws_iam_policy_document.ec2_trust.json
}

resource "aws_iam_role_policy_attachment" "master_ssm" {
  role       = aws_iam_role.jenkins_master.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "jenkins_master" {
  name = "p06-jenkins-master"
  role = aws_iam_role.jenkins_master.name
}

# ---------------------------------------------------------------------------
# Jenkins agent — SSM + ECR push (Phase 5 will add eks:DescribeCluster)
# ---------------------------------------------------------------------------
resource "aws_iam_role" "jenkins_agent" {
  name               = "p06-jenkins-agent"
  assume_role_policy = data.aws_iam_policy_document.ec2_trust.json
}

resource "aws_iam_role_policy_attachment" "agent_ssm" {
  role       = aws_iam_role.jenkins_agent.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

data "aws_iam_policy_document" "agent_ecr" {
  statement {
    sid       = "EcrAuthTokenIsAccountWide"
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    sid    = "EcrPushToSampleAppOnly"
    effect = "Allow"

    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:PutImage",
      "ecr:BatchGetImage",
    ]

    resources = [data.aws_ecr_repository.sample_app.arn]
  }
}

resource "aws_iam_role_policy" "agent_ecr" {
  name   = "ecr-push"
  role   = aws_iam_role.jenkins_agent.id
  policy = data.aws_iam_policy_document.agent_ecr.json
}

resource "aws_iam_instance_profile" "jenkins_agent" {
  name = "p06-jenkins-agent"
  role = aws_iam_role.jenkins_agent.name
}
