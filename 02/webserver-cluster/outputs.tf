output "alb_dns_name" {
  value = "http://${aws_lb.myALB.dns_name}"
  description = "ALB DNS name"
}
