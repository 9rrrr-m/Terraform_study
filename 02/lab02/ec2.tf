# Provider 설정
provider "aws" {
  region = "us-east-2"
}

# EC2 인스턴스 AMI ID를 위한 Data Source 조회
data "aws_ami" "ubuntu" {
  most_recent      = true
  owners           = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# EC2 생성
resource "aws_instance" "myInstance" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"

  tags = {
    Name = "myInstance"
  }
}

output "ami_id" {
  value = aws_instance.myInstance.ami
  description = "Ubuntu AMI ID"
}
