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

# EC2 인스턴스를 위한 Security Group 생성
resource "aws_security_group" "allow_ssh" {
  name = "allow_ssh"
  description = "Allow SSH inbound traffic and all outbound traffic"

  tags = {
    Name = "allow_ssh"
  }
}

# Security Group ingress (inbound)
## SSH(22/tcp) 허용
resource "aws_vpc_security_group_ingress_rule" "allow_ssh" {
  security_group_id = aws_security_group.allow_ssh.id
  cidr_ipv4 = "0.0.0.0/0"
  from_port = 22
  ip_protocol = "tcp"
  to_port = 22
}

# Security Group egress (outbound)
## 모두 허용
resource "aws_vpc_security_group_egress_rule" "allow_all_traffic" {
  security_group_id = aws_security_group.allow_ssh.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# EC2 생성
resource "aws_instance" "myInstance" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"

  key_name = "mykeypair"
  vpc_security_group_ids = [ aws_security_group.allow_ssh.id ]

  tags = {
    Name = "myInstance"
  }
}

output "ami_id" {
  value = aws_instance.myInstance.ami
  description = "Ubuntu 24.04 LTS AMI ID"
}
