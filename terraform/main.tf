provider "aws" {
  region = "us-east-1"
}

# IAMロールの作成（レプリケーション用）
resource "aws_iam_role" "s3_replication_role" {
  name = "s3-replication-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "s3_replication_policy" {
  name   = "s3-replication-policy"
  role   = aws_iam_role.s3_replication_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetReplicationConfiguration",
          "s3:ListBucket"
        ]
        Resource = "arn:aws:s3:::example-bucket-name"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ReplicateObject",
          "s3:ReplicateDelete",
          "s3:ReplicateTags"
        ]
        Resource = "arn:aws:s3:::replica-bucket-name/*"
      }
    ]
  })
}

# レプリケーション先バケット
resource "aws_s3_bucket" "replica" {
  bucket = "replica-bucket-name"
  acl    = "private"

  versioning {
    enabled = true
  }
}

# 元バケット
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
    target_bucket = aws_s3_bucket.replica.id
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

  replication_configuration {
    role = aws_iam_role.s3_replication_role.arn

    rules {
      id     = "ReplicationRule"
      status = "Enabled"

      destination {
        bucket        = aws_s3_bucket.replica.arn
        storage_class = "STANDARD"
      }
    }
  }

  tags = {
    Name        = "example-bucket"
    Environment = "production"
  }
}

# パブリックアクセスブロックの設定
resource "aws_s3_bucket_public_access_block" "example" {
  bucket = aws_s3_bucket.example.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
