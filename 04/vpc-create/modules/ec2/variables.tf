variable "instance_type" {
  default = "t2.micro"
}

variable "instance_tag" {
  default = {
    Name = "myinstance"
  }
}

variable "instance_count" {
  default = 1
}

variable "subnet_id" {}
