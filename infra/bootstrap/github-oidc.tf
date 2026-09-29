locals {
  gha_plan_role_name  = "p06-gha-plan"
  gha_apply_role_name = "p06-gha-apply"
  repo_sub_prefix     = "repo:${var.github_repo}"
  account_id          = data.aws_caller_identity.current.account_id
}

resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]

  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd",
  ]
}

# ---------------------------------------------------------------------------
# Plan role: PRs on the repo and pushes to main. Read-only + write .tflock.
# ---------------------------------------------------------------------------
data "aws_iam_policy_document" "gha_plan_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "${local.repo_sub_prefix}:pull_request",
        "${local.repo_sub_prefix}:ref:refs/heads/main",
      ]
    }
  }
}

resource "aws_iam_role" "gha_plan" {
  name               = local.gha_plan_role_name
  assume_role_policy = data.aws_iam_policy_document.gha_plan_trust.json
}

resource "aws_iam_role_policy_attachment" "gha_plan_readonly" {
  role       = aws_iam_role.gha_plan.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

data "aws_iam_policy_document" "gha_plan_tflock" {
  statement {
    sid     = "S3NativeLockWrite"
    effect  = "Allow"
    actions = ["s3:PutObject", "s3:DeleteObject"]

    resources = ["${aws_s3_bucket.tfstate.arn}/*.tflock"]
  }
}

resource "aws_iam_role_policy" "gha_plan_tflock" {
  name   = "tflock-write"
  role   = aws_iam_role.gha_plan.id
  policy = data.aws_iam_policy_document.gha_plan_tflock.json
}

# ---------------------------------------------------------------------------
# Apply role: only the 'prod' environment. PowerUser + IAM writes scoped to
# p06-* names, with an explicit deny on modifying the CI roles themselves.
# ---------------------------------------------------------------------------
data "aws_iam_policy_document" "gha_apply_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["${local.repo_sub_prefix}:environment:prod"]
    }
  }
}

resource "aws_iam_role" "gha_apply" {
  name               = local.gha_apply_role_name
  assume_role_policy = data.aws_iam_policy_document.gha_apply_trust.json
}

resource "aws_iam_role_policy_attachment" "gha_apply_poweruser" {
  role       = aws_iam_role.gha_apply.name
  policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
}

data "aws_iam_policy_document" "gha_apply_iam_scoped" {
  statement {
    sid    = "AllowScopedIAMWrite"
    effect = "Allow"

    actions = [
      "iam:CreateRole",
      "iam:DeleteRole",
      "iam:UpdateRole",
      "iam:UpdateAssumeRolePolicy",
      "iam:AttachRolePolicy",
      "iam:DetachRolePolicy",
      "iam:PutRolePolicy",
      "iam:DeleteRolePolicy",
      "iam:TagRole",
      "iam:UntagRole",
      "iam:PassRole",
      "iam:CreatePolicy",
      "iam:DeletePolicy",
      "iam:CreatePolicyVersion",
      "iam:DeletePolicyVersion",
      "iam:SetDefaultPolicyVersion",
      "iam:CreateInstanceProfile",
      "iam:DeleteInstanceProfile",
      "iam:AddRoleToInstanceProfile",
      "iam:RemoveRoleFromInstanceProfile",
    ]

    resources = [
      "arn:aws:iam::${local.account_id}:role/p06-*",
      "arn:aws:iam::${local.account_id}:policy/p06-*",
      "arn:aws:iam::${local.account_id}:instance-profile/p06-*",
    ]
  }

  statement {
    sid    = "DenyMutatingCIRoles"
    effect = "Deny"

    actions = [
      "iam:DeleteRole",
      "iam:UpdateRole",
      "iam:UpdateAssumeRolePolicy",
      "iam:AttachRolePolicy",
      "iam:DetachRolePolicy",
      "iam:PutRolePolicy",
      "iam:DeleteRolePolicy",
      "iam:TagRole",
      "iam:UntagRole",
      "iam:PassRole",
    ]

    resources = [
      aws_iam_role.gha_plan.arn,
      aws_iam_role.gha_apply.arn,
    ]
  }
}

resource "aws_iam_role_policy" "gha_apply_iam_scoped" {
  name   = "iam-scoped-p06"
  role   = aws_iam_role.gha_apply.id
  policy = data.aws_iam_policy_document.gha_apply_iam_scoped.json
}
