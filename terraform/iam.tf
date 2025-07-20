data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "master_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "master_ssm_policy" {
  statement {
    effect = "Allow"

    actions = [
      "ssm:PutParameter"
    ]

    resources = [
      "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/k8s/join-command"
    ]
  }
}

resource "aws_iam_role" "master_ssm_role" {
  name               = "k8s-master-ssm-role"
  assume_role_policy = data.aws_iam_policy_document.master_assume_role.json
}

resource "aws_iam_role_policy" "master_ssm_role_policy" {
  name   = "k8s-master-ssm-policy"
  role   = aws_iam_role.master_ssm_role.id
  policy = data.aws_iam_policy_document.master_ssm_policy.json
}

resource "aws_iam_instance_profile" "master_ssm_profile" {
  name = "k8s-master-ssm-instance-profile"
  role = aws_iam_role.master_ssm_role.name
}
