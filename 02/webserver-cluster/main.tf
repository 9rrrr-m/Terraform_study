# -------------------------------- #
# ALB - TG(AGS)
# -------------------------------- #
# 작업 절차
# 0. 기본 인프라
# 1. ALB
## 1) SG 생성
## 2) TG 생성
## 3) LB 생성
## 4) LB listener 구성
## 5) LB listener rule 구성
# 2. ASG
## 1) SG 생성
## 2) launch template 생성
## 3) ASG 생성
# -------------------------------- #

# 0. 기본 인프라
## VPC, Subnet
### Data Source: aws_vpc
data "aws_vpc" "default" {
  default = true
}

### Data Source: aws_subnets
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# 1. ALB
## 1) SG 생성
### Resource: aws_security_group
resource "aws_security_group" "myALB_SG" {
  name        = "myALB_SG"
  description = "Allow 80/tcp inbound traffic and all outbound traffic"
  vpc_id      = data.aws_vpc.default.id

  tags = {
    Name = "myALB_SG"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_tls_ipv4" {
  security_group_id = aws_security_group.myALB_SG.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.myALB_SG.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

## 2) TG 생성
### Resource: aws_lb_target_group
resource "aws_lb_target_group" "myALB_TG" {
  name     = "myALB-TG"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id
}

## 3) LB 생성
### Resource: aws_lb
resource "aws_lb" "myALB" {
  name               = "myALB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.myALB_SG.id]
  subnets            = data.aws_subnets.default.ids
}

## 4) LB listener 구성
### Resource: aws_lb_listener
resource "aws_lb_listener" "myALB_listener" {
  load_balancer_arn = aws_lb.myALB.arn
  port              = "80"
  protocol          = "HTTP"
  
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.myALB_TG.arn
  }
}

## 5) LB listener rule 구성
### Resource: aws_lb_listener_rule
resource "aws_lb_listener_rule" "myALB_listener_rule" {
  listener_arn = aws_lb_listener.myALB_listener.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.myALB_TG.arn
  }

  condition {
    path_pattern {
      values = ["*"]
    }
  }
}

# 2. ASG
## 1) SG 생성
### Resource: aws_security_group
resource "aws_security_group" "myASG_SG" {
  name        = "myASG_SG"
  description = "Allow 80/tcp inbound traffic and all outbound traffic"
  vpc_id      = data.aws_vpc.default.id

  tags = {
    Name = "myASG_SG"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_80" {
  security_group_id = aws_security_group.myASG_SG.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "allow_22_myASG" {
  security_group_id = aws_security_group.myASG_SG.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic" {
  security_group_id = aws_security_group.myASG_SG.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

## 2) launch template 생성
### Data Source: aws_ami
data "aws_ami" "amazon_linux_2023" {
  most_recent      = true
  owners           = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-kernel-6.1-x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

### Resource: aws_launch_template
resource "aws_launch_template" "myLT" {
  image_id = data.aws_ami.amazon_linux_2023.id
  instance_type = "t2.micro"
  key_name = "mykeypair"
  vpc_security_group_ids = [aws_security_group.myASG_SG.id]
  user_data = filebase64("user_data.sh")
}

## 3) ASG 생성
### Resource: aws_autoscaling_group
resource "aws_autoscaling_group" "bar" {
  name                      = "myASG"
  max_size                  = 2
  min_size                  = 2
  health_check_type         = "ELB"
  vpc_zone_identifier       = data.aws_subnets.default.ids
  
  # 아래 내용은 aws_lb_target_group을 설정한 후 반드시 등록 해 주어야 함.
  target_group_arns = [ aws_lb_target_group.myALB_TG.arn ]
  depends_on = [ aws_lb_target_group.myALB_TG ]  # 생략 가능

  launch_template {
    id      = aws_launch_template.myLT.id
    version = 1
  }

  tag {
    key                 = "Name"
    value               = "myASG"
    propagate_at_launch = true
  }
}
