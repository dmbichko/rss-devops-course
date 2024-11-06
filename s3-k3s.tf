# S3 bucket for k3s config
resource "aws_s3_bucket" "k3s_config" {
  bucket = "rs-school-${local.prefix}-k3s-config"

  tags = merge(
    local.common_tags,
    tomap({ "Name" = "${local.prefix}-k3s-config" })
  )
}

# Enable versioning
resource "aws_s3_bucket_versioning" "k3s_config" {
  bucket = aws_s3_bucket.k3s_config.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Enable encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "k3s_config" {
  bucket = aws_s3_bucket.k3s_config.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block public access
resource "aws_s3_bucket_public_access_block" "k3s_config" {
  bucket = aws_s3_bucket.k3s_config.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# IAM policy for k3s server to access S3
resource "aws_iam_role_policy" "k3s_server_s3_policy" {
  name = "${local.prefix}-k3s-s3-policy"
  role = aws_iam_role.k3s_server_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.k3s_config.arn,
          "${aws_s3_bucket.k3s_config.arn}/*"
        ]
      }
    ]
  })
}