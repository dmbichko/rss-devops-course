resource "aws_s3_bucket" "terraform_state" {
  bucket = var.terraform-state-s3-bucket
  tags = merge(
    local.common_tags,
    tomap({ "Name" = "${local.prefix}-s3-terraform-state" })
  )
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}