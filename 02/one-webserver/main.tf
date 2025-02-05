# Provider 설정
provider "aws" {
  region = "us-east-2"
}

# -------------------------------#
# Resource 설정
# * SG(8080/tcp)
# * EC2(user_data="WEB 서버 설정")
# -------------------------------#

# 1) SG
resource "aws_security_group" "allow_80" {
  name        = var.security_group_name
  description = "Allow 80 inbound traffic and all outbound traffic"
  tags = {
    Name = "my_allow_80"
  }
}

## SG ingress rule
resource "aws_vpc_security_group_ingress_rule" "allow_http_80" {
  security_group_id = aws_security_group.allow_80.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = var.server_port
  ip_protocol       = "tcp"
  to_port           = var.server_port
}

## SG egress rule
resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.allow_80.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# 2) EC2 생성
resource "aws_instance" "example" {
  ami                    = "ami-0cb91c7de36eed2cb"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.allow_80.id]

  user_data_replace_on_change = true
  user_data                   = <<EOF
#!/bin/bash
apt install -y apache2
echo "Hello, World" > /var/www/html/index.html
systemctl enable --now apache2
EOF

  tags = {
    Name = "myweb"
  }
}
