variable "vpc_cidr" {
  default = "10.0.0.0/16"
  type = string
  description = "VPC CIDR block"
}

variable "vpc_tag" {
  default = {
    Name = "myvpc"
  }
  type = map(string)
  description = "VPC tag"
}

variable "subnet_cidr" {
  default = "10.0.1.0/24"
}

variable "subnet_tag" {
  default = {
    Name = "mysubnet"
  }
}
