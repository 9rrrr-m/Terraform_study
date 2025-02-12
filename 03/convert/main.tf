terraform {
 required_providers {
  aws = {
    source = "hashicorp/aws"
  } 
 } 
}

provider "aws" {
  region = "us-east-2"
}

# Parameters
## KeyName
## LatestAmiId

# Resources
# 1) VPC 생성
## MyVPC
resource "aws_vpc" "MyVPC" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Name = "My-VPC"
  }
}

# 2) IGW 생성 및 붙이기
## MyIGW
## MyIGWAttachment
resource "aws_internet_gateway" "MyIGW" {
  vpc_id = aws_vpc.MyVPC.id

  tags = {
    Name = "My-IGW"
  }
}

# 3) Routing Table 생성 + Route 정보 등록(default route)
## MyPublicRT
## MyDefaultPublicRoute
resource "aws_route_table" "MyPublicRT" {
  vpc_id = aws_vpc.MyVPC.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.MyIGW.id
  }

  tags = {
    Name = "My-Public-RT"
  }
}

# 4) Public Subnet 생성 + 연결
## MyPublicSN1
resource "aws_subnet" "MySubnet1" {
  vpc_id = aws_vpc.MyVPC.id
  availability_zone = "us-east-2a"
  cidr_block = "10.0.0.0/24"

  tags = {
    Name = "My-Public-SN-1"
  }
}

## MyPublicSNRouteTableAssociation
resource "aws_route_table_association" "MyPublicSNRouteTableAssociation" {
  subnet_id = aws_subnet.MySubnet1.id
  route_table_id = aws_route_table.MyPublicRT.id
}

## MyPublicSN2
resource "aws_subnet" "MySubnet2" {
  vpc_id = aws_vpc.MyVPC.id
  availability_zone = "us-east-2b"
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "My-Public-SN-2"
  }
}

## MyPublicSNRouteTableAssociation2
resource "aws_route_table_association" "MyPublicSNRouteTableAssociation2" {
  subnet_id = aws_subnet.MySubnet2.id
  route_table_id = aws_route_table.MyPublicRT.id
}

# 5) Security Group 생성
## WEBSG
resource "aws_security_group" "WEBSG" {
  name = "WEBSG"
  description = "Allow HTTP(80/tcp, 8080/tcp), SSH(22/tcp)"
  vpc_id = aws_vpc.MyVPC.id
  
  tags = {
    Name = "WEBSG"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_HTTP_80" {
  security_group_id = aws_security_group.WEBSG.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "allow_HTTP_8080" {
  security_group_id = aws_security_group.WEBSG.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 8080
  ip_protocol       = "tcp"
  to_port           = 8080
}

resource "aws_vpc_security_group_ingress_rule" "allow_SSH" {
  security_group_id = aws_security_group.WEBSG.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic" {
  security_group_id = aws_security_group.WEBSG.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# 6) EC2 생성
## MYEC21
data "aws_ami" "amazonLinux2023" {
  most_recent = true

  filter {
    name   = "name"
    values = ["al2023-ami-*-kernel-6.1-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["137112412989"]
}

resource "aws_instance" "MYEC21" {
  ami           = data.aws_ami.amazonLinux2023.id
  instance_type = "t2.micro"
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.MySubnet1.id
  security_groups             = [aws_security_group.WEBSG.id]
  user_data                   = <<-EOF
  #!/bin/bash
  exec >/var/log/web.log 2>&1
  echo "[ START ]"
  echo "[ Phase 01 ]"
  hostname EC2-1
  echo "[ Phase 02 ]"
  yum -y install httpd
  echo "[ Phase 03 ]"
  systemctl start httpd && systemctl enable httpd
  echo "[ Phase 04 ]"
  echo "<h1>CloudNet@ EC2-1 Web Server</h1>" > /var/www/html/index.html
  echo "[ END ]"
  EOF
  # user_data_replace_on_change = true

  tags = {
    Name = "EC2-1"
  }
}

## MYEC22
resource "aws_instance" "MYEC22" {
  ami           = data.aws_ami.amazonLinux2023.id
  instance_type               = "t2.micro"
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.MySubnet2.id
  security_groups             = [aws_security_group.WEBSG.id]
  user_data                   = <<-EOF
  #!/bin/bash
  hostname EC2-2
  yum -y install httpd
  systemctl start httpd && systemctl enable httpd
  echo "<h1>CloudNet@ EC2-2 Web Server</h1>" > /var/www/html/index.html
  EOF
  # user_data_replace_on_change = true

  tags = {
    Name = "EC2-2"
  }
}

# 7) EC2에 EIP 할당
## MYEIP1
## MYEIP1Assoc
resource "aws_eip" "MYEIP1" {
  instance = aws_instance.MYEC21.id
  vpc = true
}

## MYEIP2
## MYEIP2Assoc
resource "aws_eip" "MYEIP2" {
  instance = aws_instance.MYEC22.id
  vpc = true
}

# 8) ALB Target Group 생성 및 EC2 인스턴스 연결
## ALBTargetGroup
resource "aws_lb_target_group" "ALBTargetGroup" {
  name = "MY-ALB-TG"
  port = 80
  protocol = "HTTP"
  vpc_id = aws_vpc.MyVPC.id
}

resource "aws_lb_target_group_attachment" "TGAttachement" {
  target_group_arn = aws_lb_target_group.ALBTargetGroup.arn
  target_id = aws_instance.MYEC21.id
  port = 80
}

resource "aws_lb_target_group_attachment" "TGAttachement2" {
  target_group_arn = aws_lb_target_group.ALBTargetGroup.arn
  target_id = aws_instance.MYEC22.id
  port = 80
}

# 9) ALB 생성 & Listener 규칙 생성
## ApplicationLoadBalancer
resource "aws_lb" "ApplicationLoadBalancer" {
  name = "My-ALB"
  load_balancer_type = "application"
  security_groups = [aws_security_group.WEBSG.id]
  subnets = [aws_subnet.MySubnet1.id, aws_subnet.MySubnet2.id]
}

## ALBListener
resource "aws_lb_listener" "ALBListener" {
  load_balancer_arn = aws_lb.ApplicationLoadBalancer.arn
  port = "80"
  protocol = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Fixed response content"
      status_code = "200"
    }
  }
}

resource "aws_lb_listener_rule" "ALBListenerRule" {
  listener_arn = aws_lb_listener.ALBListener.arn
  priority = 100

  condition {
    path_pattern {
      values = ["*"]
    }
  }

  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.ALBTargetGroup.arn
  }
}
