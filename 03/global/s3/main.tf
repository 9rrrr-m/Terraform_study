# --------------------- #
# 1. Provider 설정
# 2. S3 bucket 생성
# 3. DynamoDB 생성
# --------------------- #

# 1. Provider 설정
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.86.0"
    }
  }
}

provider "aws" {
  region = "us-east-2"
}

# 2. S3 bucket 생성
resource "aws_s3_bucket" "terraform_state" {
  bucket = "bucket-test123-dev"

  # force_destroy = true

  tags = {
    Name        = "terraform_state"
  }
}

# 버전 관리
# resource "aws_kms_key" "myKMSkey" {
#   description             = "This key is used to encrypt bucket objects"
#   deletion_window_in_days = 10
# }

# resource "aws_s3_bucket_server_side_encryption_configuration" "myS3bucket_env" {
#   bucket = aws_s3_bucket.myTerraform_state.id

#   rule {
#     apply_server_side_encryption_by_default {
#       kms_master_key_id = aws_kms_key.myKMSkey.arn
#       sse_algorithm     = "aws:kms"
#     }
#   }
# }

# resource "aws_s3_bucket_versioning" "myVersioning" {
#   bucket = aws_s3_bucket.myTerraform_state.id
#   versioning_configuration {
#     status = "Enabled"
#   }
# }

# 3. DynamoDB 생성
resource "aws_dynamodb_table" "terraform_locks" {
  name           = "terraform_locks"
  billing_mode   = "PAY_PER_REQUEST"  # PRIVISIONED, PAY_PER_REQUEST
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"  # S(string), N(number), B(binary)
  }
  
  tags = {
    Name        = "terraform_locks"
    Environment = "production"
  }
}
