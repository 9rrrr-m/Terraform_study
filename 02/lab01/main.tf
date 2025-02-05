# provider 설정
provider "aws" {
  region = "us-east-2"
}

# -------------------------- #
# Resource 설정
# 작업: VPC + Subnet
# 작업 절차:
# * VPC 생성
# * IGW 생성 및 연결
# * Public Subnet 생성
# * Routing Table 생성 및 연결
# -------------------------- #

# 1) VPC 생성
resource "aws_vpc" "myVPC" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags = {
    Name = "myVPC"
  }
}

# 2) IGW 생성 및 연결
resource "aws_internet_gateway" "myIGW" {
  vpc_id = aws_vpc.myVPC.id

  tags = {
    Name = "myIGW"
  }
}

# 3) Public Subnet 생성
resource "aws_subnet" "myPubSubnet" {
  vpc_id                  = aws_vpc.myVPC.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "myPubSubnet"
  }
}

# 4) Routing Table 생성 및 연결
resource "aws_route_table" "myPubRT" {
  vpc_id = aws_vpc.myVPC.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myIGW.id
  }

  tags = {
    Name = "myPubRT"
  }
}

resource "aws_route_table_association" "myPubRTassoc" {
  subnet_id      = aws_subnet.myPubSubnet.id
  route_table_id = aws_route_table.myPubRT.id
}

# -------------------------- #
# 추가 실습
# 작업: 웹서버 EC2(user_data)
# 작업 절차:
# * SG 생성
# * EC2(user_data)
# -------------------------- #

# 1) SG 생성
resource "aws_security_group" "mySG" {
  name        = "allow_web"
  description = "Allow HTTP inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.myVPC.id

  tags = {
    Name = "mySG"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh" {
  security_group_id = aws_security_group.mySG.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "allow_http" {
  security_group_id = aws_security_group.mySG.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_http" {
  security_group_id = aws_security_group.mySG.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# 2) EC2(user_data)
resource "aws_instance" "myWEB" {
  ami           = "ami-018875e7376831abe"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.myPubSubnet.id
  vpc_security_group_ids = [aws_security_group.mySG.id]

  user_data_replace_on_change = true
  user_data = <<-EOF
    #!/bin/bash
    yum install -y httpd
    echo "MyWEB" > /var/www/html/index.html
    systemctl enable --now httpd
    EOF

  tags = {
    Name = "myWEB"
  }
}
