output "myalb_dns_name" {
  value = aws_lb.myALB.dns_name
  description = "ALB DNS name"
}

