output "vpc_id" {
  value = aws_vpc.myvpc.id
  description = "VPC ID"  
}

output "subnet_id" {
  value = aws_subnet.mysubnet.id
  description = "Subnet ID"  
}
