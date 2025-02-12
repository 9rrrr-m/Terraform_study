# ------------------------- #
# 0. Terraform
# 1. Provider
# 2. DB Instance 생성
# ------------------------- #

# 0. Terraform
terraform {
  backend "s3" {
    bucket = "bucket-test-1114"
    key    = "global/s3/terraform.tfstate"
    region = "us-east-2"
    dynamodb_table = "myDyDB"
  }
}

# 1. Provider
provider "aws" {
  region = "us-east-2"
}

# 2. DB Instance 생성
resource "aws_db_instance" "myDB" {
  allocated_storage    = 10
  db_name              = "myDB"
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t3.micro"
  username             = var.dbuser
  password             = var.dbpassword
  parameter_group_name = "default.mysql8.0"
  skip_final_snapshot  = true
}




