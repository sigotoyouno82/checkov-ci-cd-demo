# provider設定
provider "aws" {
  region = "ap-northeast-1"
}

# S3バケットの作成
resource "aws_s3_bucket" "example" {
  bucket = "example-bucket-name"
  acl    = "private"

  # サーバーサイド暗号化設定
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  tags = {
    Name        = "example-bucket"
    Environment = "dev"
  }
}
