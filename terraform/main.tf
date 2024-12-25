provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "example" {
  bucket = "example-bucket-name"
  acl    = "private"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm     = "aws:kms"
        kms_master_key_id = "arn:aws:kms:us-east-1:123456789012:key/key-id"
      }
    }
  }

  versioning {
    enabled = true
  }

  logging {
    target_bucket = "logging-bucket-name"
    target_prefix = "log/"
  }

  lifecycle_rule {
    id      = "MoveToIA"
    enabled = true

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    expiration {
      days = 365
    }
  }

  tags = {
    Name        = "example-bucket"
    Environment = "dev"
  }
}

resource "aws_s3_bucket_public_access_block" "example" {
  bucket = aws_s3_bucket.example.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_notification" "example" {
  bucket = aws_s3_bucket.example.id

  lambda_function {
    lambda_function_arn = "arn:aws:lambda:us-east-1:123456789012:function:example-function"
    events              = ["s3:ObjectCreated:*"]
    filter {
      prefix = "uploads/"
      suffix = ".jpg"
    }
  }
}
