# --------------------------- #
# 1. 인프라 구성
# * VPC 생성
# * IGW 생성 및 연결
# * Public SN 생성
# * Public RT 생성
# * Public RT 연결
# 2. EC2 인스턴스 생성
# * SG 생성
# * AMI Data Source 설정
# * SSH Key 생성
# * EC2 생성
#   - AMI
#   - SSH Key
#   - User Data(docker 설치)
# 3. PC에서 EC2 연결 설정
# --------------------------- #

# 1. 인프라 구성
## 1) VPC 생성
resource "aws_vpc" "myVPC" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support = true

  tags = {
    Name = "myVPC"
  }
}

## 2) IGW 생성 및 연결
resource "aws_internet_gateway" "myIGW" {
  vpc_id = aws_vpc.myVPC.id

  tags = {
    Name = "myIGW"
  }
}

## 3) Public SN 생성
resource "aws_subnet" "myPubSN" {
  vpc_id     = aws_vpc.myVPC.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-2a"
  map_public_ip_on_launch = true    # 공인ip 할당

  tags = {
    Name = "myPubSN"
  }
}

## 4) Public RT 생성
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

## 5) Public RT 연결
resource "aws_route_table_association" "myPubRT_assoc" {
  subnet_id      = aws_subnet.myPubSN.id
  route_table_id = aws_route_table.myPubRT.id
}

# 2. EC2 인스턴스 생성
## 1) SG 생성
resource "aws_security_group" "mySG" {
  name        = "mySG"
  description = "Allow all inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.myVPC.id

  tags = {
    Name = "mySG"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_ipv4" {
  security_group_id = aws_security_group.mySG.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_egress_rule" "allow_ipv4" {
  security_group_id = aws_security_group.mySG.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

## 2) AMI Data Source 설정
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

  owners = ["137112412989"] # amazon
}

## 3) SSH Key 생성
### 사용자가 반드시 해야 하는 역할
### $ ssh-keygen -t rsa
#### Enter file in which to save the key (/home/tf/.ssh/id_rsa): /home/tf/.ssh/devkey
#### Enter passphrase (empty for no passphrase): (Enter)
#### Enter same passphrase again: (Enter)
resource "aws_key_pair" "devkeypair" {
  key_name   = "devkeypair"
  public_key = file("~/.ssh/devkey.pub")
}

## 4) EC2 생성
### - AMI: ami
### - SSH Key: key_name
### - vpc_security_group_ids
### - subnet_id
### - User Data(docker 설치)
### - provisioner - local-exec
#### * templatefile() : 동적 파일 생성
resource "aws_instance" "myEC2" {
  ami           = data.aws_ami.amazonLinux2023.id
  instance_type = "t2.micro"

  key_name = aws_key_pair.devkeypair.id

  vpc_security_group_ids = [ aws_security_group.mySG.id ]

  subnet_id = aws_subnet.myPubSN.id

  user_data_replace_on_change = true
  user_data = filebase64("userdata.tpl")

  provisioner "local-exec" {
    command = templatefile("amazon-linux2023-config.tpl", {
        hostname = self.public_ip,
        user = "ec2-user",
        identityfile = "~/.ssh/devkey"
      }
    )
    interpreter = [ "bash", "-c" ]
    # interpreter = [ "Powershell", "-Command" ]
  }

  tags = {
    Name = "myEC2"
  }
}

# 3. PC에서 EC2 연결 설정
