variable "aws_region" {
  default = "us-east-2"
  type = string
  description = "AWS Region"
}

variable "myALB_SG_tag" {
  default = {
    Name = "myALB_SG"
  }
  type = map(string)
  description = "AWS ALB SG tag"
}

variable "web_port" {
  default = 80
  type = number
  description = "HTTP port"
}

variable "ssh_port" {
  default = 22
  type = number
  description = "SSH port"
}

variable "asg_min_size" {
  default = 2
  type = number
  description = "ASG Min size"
}

variable "asg_max_size" {
  default = 2
  type = number
  description = "ASG Max size"
}

variable "lt_version" {
  default = 1
  type = number
  description = "launch template version"
}
