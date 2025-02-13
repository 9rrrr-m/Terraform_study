# ------------------------- #
# 0. Provider
# 1. Module 사용 Test
# ------------------------- #

# 0. Provider
provider "aws" {
  region = "ap-northeast-2"
}

# 1. Module 사용 Test
## 1) module myvpc
module "my_vpc" {
  source = "../modules/vpc"

  vpc_cidr = "192.168.10.0/24"
  subnet_cidr = "192.168.10.0/25"
}

## 2) module myec2
module "my_ec2" {
  source = "../modules/ec2"
  instance_count = 1
  subnet_id = module.my_vpc.subnet_id
  instance_type = "t2.micro"
}
