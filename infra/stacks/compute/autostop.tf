locals {
  autostop_instance_ids  = [for i in aws_instance.this : i.id]
  autostop_instance_arns = [for i in aws_instance.this : i.arn]
}

# ---------------------------------------------------------------------------
# IAM role EventBridge Scheduler assumes to call ec2:StopInstances.
# Scoped to the 3 lab instance ARNs only - no wildcards.
# ---------------------------------------------------------------------------
data "aws_iam_policy_document" "autostop_trust" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["scheduler.amazonaws.com"]
    }

    # Prevent confused-deputy: only Scheduler in THIS account can assume.
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

resource "aws_iam_role" "autostop" {
  name               = "p06-lab-autostop"
  assume_role_policy = data.aws_iam_policy_document.autostop_trust.json
}

data "aws_iam_policy_document" "autostop_permissions" {
  statement {
    sid       = "StopLabInstancesOnly"
    effect    = "Allow"
    actions   = ["ec2:StopInstances"]
    resources = local.autostop_instance_arns
  }
}

resource "aws_iam_role_policy" "autostop" {
  name   = "stop-lab-instances"
  role   = aws_iam_role.autostop.id
  policy = data.aws_iam_policy_document.autostop_permissions.json
}

# ---------------------------------------------------------------------------
# Daily 23:30 Asia/Ho_Chi_Minh auto-stop.
# Uses AWS SDK target so no Lambda is needed.
# ---------------------------------------------------------------------------
resource "aws_scheduler_schedule" "autostop" {
  name                         = "p06-lab-autostop"
  schedule_expression          = "cron(24 13 * * ? *)" # TEST: revert to cron(30 23 * * ? *) after test passes
  schedule_expression_timezone = "Asia/Ho_Chi_Minh"

  flexible_time_window {
    mode = "OFF"
  }

  target {
    arn      = "arn:aws:scheduler:::aws-sdk:ec2:stopInstances"
    role_arn = aws_iam_role.autostop.arn

    input = jsonencode({
      InstanceIds = local.autostop_instance_ids
    })
  }
}
