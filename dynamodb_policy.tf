resource "aws_iam_policy" "dynamodb_policy" {
  name        = var.DynamoDBAccessPolicyName
  description = "IAM policy to allow specific actions on DynamoDB table ."

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "dynamodb:DescribeTable",
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem",
          "dynamodb:DescribeContinuousBackups",
          "dynamodb:DescribeTimeToLive",
          "dynamodb:ListTagsOfResource"
        ],
        Resource = "arn:aws:dynamodb:*:*:table/${var.terraform-state-dynamodb}"
      }
    ]
  })
}