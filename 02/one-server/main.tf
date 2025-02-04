terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.85.0"
    }
  }
}

provider "aws" {
  region = "us-east-2"
}

resource "aws_instance" "example" {
  ami           = "ami-0a752653199c4fce6"
  instance_type = "t2.micro"
  tags = {
    Name = "terraform-example"
  }
}
