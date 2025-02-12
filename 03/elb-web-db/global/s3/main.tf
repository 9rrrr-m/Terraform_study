# ------------------------- #
# 0. Provider
# 1. S3 bucket 생성
# 2. DynamoDB Table 생성
# ------------------------- #

# 0. Provider
provider "aws" {
  region = "us-east-2"
}

# 1. S3 bucket 생성
## Resource: aws_s3_bucket
resource "aws_s3_bucket" "myBucket" {
  bucket = "bucket-test-1114"
  force_destroy = true

  tags = {
    Name = "myBucket"
  }
}

## Resource: aws_s3_bucket_versioning
# resource "aws_s3_bucket_acl" "myBucket_acl" {
#   bucket = aws_s3_bucket.myBucket.id
#   acl    = "private"
# }

resource "aws_s3_bucket_versioning" "myBucket_versioning" {
  bucket = aws_s3_bucket.myBucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

## Resource: aws_s3_bucket_server_side_encryption_configuration
resource "aws_kms_key" "myKMSkey" {
  description             = "This key is used to encrypt bucket objects"
  deletion_window_in_days = 10
}

resource "aws_s3_bucket_server_side_encryption_configuration" "myBucket_encryption" {
  bucket = aws_s3_bucket.myBucket.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.myKMSkey.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

# 2. DynamoDB Table 생성
## Resource: aws_dynamodb_table
resource "aws_dynamodb_table" "myDyDB" {
  name           = "myDyDB"
  billing_mode   = "PAY_PER_REQUEST"  # PROVISIONED, PAY_PER_REQUEST
  hash_key       = "LockId"

  attribute {
    name = "LockId"
    type = "S"
  }

  tags = {
    Name        = "myDyDB"
  }
}
