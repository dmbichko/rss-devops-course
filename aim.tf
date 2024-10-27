resource "aws_iam_role" "GithubActionsRole" {

  name = var.terraform_github_actions_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRoleWithWebIdentity",
      Effect = "Allow",
      Principal = {
        Federated = "arn:aws:iam::${var.aws_account_id}:oidc-provider/token.actions.githubusercontent.com"
      },
      Condition = {
        "StringLike" : {
          "token.actions.githubusercontent.com:sub" : "repo:dmbichko/rss-devops-course:*"
        },
        "StringEquals" : {
          "token.actions.githubusercontent.com:aud" : "sts.amazonaws.com"
        }
      }
    }]
  })
  tags = merge(
    local.common_tags,
    tomap({ "Name" = "${local.prefix}-GithubActionsRole" })
  )
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_iam_policy" "ssm_policy" {
  name        = "SSMSessionManagerPolicy"
  path        = "/"
  description = "IAM policy for Systems Manager Session Manager and Run Command"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:StartSession",
          "ssm:TerminateSession",
          "ssm:ResumeSession",
          "ssm:DescribeSessions",
          "ssm:SendCommand",
          "ssm:GetCommandInvocation",
          "ssm:ListCommands",
          "ssm:GetConnectionStatus"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ssm:DescribeInstanceInformation",
          "ec2:DescribeInstances"
        ]
        Resource = "*"
      }
    ]
  })
}



resource "aws_iam_role_policy" "pass_role_policy" {
  name = "PassRolePolicy"
  role = aws_iam_role.GithubActionsRole.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "iam:PassRole"
        Resource = "arn:aws:iam::${var.aws_account_id}:role/*"
      }
    ]
  })
}
resource "aws_iam_role" "bastion_role" {
  name = "bastion_ssm_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
  tags = merge(
    local.common_tags,
    tomap({ "Name" = "${local.prefix}-EC2SSMRole" })
  )
}

resource "aws_iam_role_policy_attachment" "bastion_ssm_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.bastion_role.name
}

resource "aws_iam_instance_profile" "bastion_profile" {
  name = "bastion_ssm_profile"
  role = aws_iam_role.bastion_role.name
}

resource "aws_iam_role_policy_attachment" "ssm_policy_attachment" {
  role       = aws_iam_role.GithubActionsRole.name
  policy_arn = aws_iam_policy.ssm_policy.arn
}

resource "aws_iam_role_policy_attachment" "dynamodb_policy_attachment" {
  role       = aws_iam_role.GithubActionsRole.name
  policy_arn = aws_iam_policy.dynamodb_policy.arn
}

resource "aws_iam_role_policy_attachment" "ec2_full_access" {
  role       = aws_iam_role.GithubActionsRole.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}

resource "aws_iam_role_policy_attachment" "route53_full_access" {
  role       = aws_iam_role.GithubActionsRole.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonRoute53FullAccess"
}

resource "aws_iam_role_policy_attachment" "s3_full_access" {
  role       = aws_iam_role.GithubActionsRole.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_role_policy_attachment" "iam_full_access" {
  role       = aws_iam_role.GithubActionsRole.name
  policy_arn = "arn:aws:iam::aws:policy/IAMFullAccess"
}

resource "aws_iam_role_policy_attachment" "vpc_full_access" {
  role       = aws_iam_role.GithubActionsRole.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonVPCFullAccess"
}

resource "aws_iam_role_policy_attachment" "sqs_full_access" {
  role       = aws_iam_role.GithubActionsRole.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSQSFullAccess"
}

resource "aws_iam_role_policy_attachment" "eventbridge_full_access" {
  role       = aws_iam_role.GithubActionsRole.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEventBridgeFullAccess"
}