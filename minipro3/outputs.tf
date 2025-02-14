# 출력 설정
output "alb_dns_name" {
  value = aws_lb.web.dns_name
}

output "db_endpoint" {
  value = aws_db_instance.mysql.endpoint
}
