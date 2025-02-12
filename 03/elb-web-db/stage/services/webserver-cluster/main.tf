# ------------------------- #
# 0. Provider
# 1. Basic Infra
## 1) default vpc
## 2) default subnet
# 2. ALB - TG(ASG, EC2*2)
## 1) ALB - TG
### - SG 생성
### - TG 생성
### - ALB 생성
### - ALB listener 생성
### - ALB listener rule 생성
## 2) ASG
### - SG 생성
### - LT 생성
### - ASG 생성
# ------------------------- #

# 0. Provider
provider "aws" {
  region = "us-east-2"
}

# 1. Basic Infra
## 1) default vpc
data "aws_vpc" "default" {
  default = true
}

## 2) default subnet
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# 2. ALB - TG(ASG, EC2*2)
## 1) ALB - TG
### - SG 생성
resource "aws_security_group" "myALB_SG" {
  name        = "myALB_SG"
  description = "Allow 80 inbound traffic and all outbound traffic"
  vpc_id      = data.aws_vpc.default.id

  tags = {
    Name = "myALB_SG"
  }
}

resource "aws_vpc_security_group_ingress_rule" "myALB_SG_in_80" {
  security_group_id = aws_security_group.myALB_SG.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_egress_rule" "myALB_SG_out_all" {
  security_group_id = aws_security_group.myALB_SG.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

### - TG 생성
resource "aws_lb_target_group" "myALB_TG" {
  name     = "myALB-TG"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id
}

### - ALB 생성
resource "aws_lb" "myALB" {
  name               = "myALB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.myALB_SG.id]
  subnets            = data.aws_subnets.default.ids
  enable_deletion_protection = false
}

### - ALB listener 생성
resource "aws_lb_listener" "myALB_listener" {
  load_balancer_arn = aws_lb.myALB.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.myALB_TG.arn
  }
}

### - ALB listener rule 생성
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

## 2) ASG
### - SG 생성
resource "aws_security_group" "myASG_SG" {
  name        = "myASG_SG"
  description = "Allow 80 inbound traffic and all outbound traffic"
  vpc_id      = data.aws_vpc.default.id

  tags = {
    Name = "myASG_SG"
  }
}

resource "aws_vpc_security_group_ingress_rule" "myASG_SG_in_80" {
  security_group_id = aws_security_group.myASG_SG.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_egress_rule" "myASG_SG_out_all" {
  security_group_id = aws_security_group.myASG_SG.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

### - LT 생성
data "aws_ami" "myami" {
  most_recent      = true
  owners           = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
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

data "terraform_remote_state" "myTerraformState" {
  backend = "s3"

  config = {
    bucket = "bucket-test-1114"
    key = "global/s3/terraform.tfstate"
    region = "us-east-2"
  }
}

resource "aws_launch_template" "myLT" {
  name = "myLT"

  image_id = data.aws_ami.myami.id

  instance_initiated_shutdown_behavior = "terminate"
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.myASG_SG.id]
  user_data = base64encode(templatefile("user-data.sh", {
    db_address = data.terraform_remote_state.myTerraformState.outputs.address
    db_port = data.terraform_remote_state.myTerraformState.outputs.port
    server_port = 80
  }))
}

### - ASG 생성
resource "aws_autoscaling_group" "myASG" {
  name                      = "myASG"
  max_size                  = 2
  min_size                  = 2
  health_check_type         = "ELB"
  desired_capacity          = 2
  force_delete              = true
  vpc_zone_identifier       = data.aws_subnets.default.ids
  launch_template {
    id = aws_launch_template.myLT.id
    version = "$Latest"
  }

  # 필수 점검
  target_group_arns = [aws_lb_target_group.myALB_TG.arn]

  tag {
    key                 = "Name"
    value               = "myASG"
    propagate_at_launch = true
  }
}


