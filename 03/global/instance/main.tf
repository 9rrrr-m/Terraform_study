# ---------------- #
# Terraform
# Provider
# ---------------- #

# Terraform
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.86.0"
    }
  }

  backend "s3" {
    bucket = "bucket-test123-dev"
    key = "global/s3/terraform.tfstate"
    dynamodb_table = "terraform_locks"
    region = "us-east-2"
  }
}

# Provider
provider "aws" {
  region = "us-east-2"
}

# Instance
resource "aws_instance" "myEC2" {
  ami = "ami-088b41ffb0933423f"
  instance_type = "t2.micro"

  tags = {
    Name = "myEC2"
  }
}
