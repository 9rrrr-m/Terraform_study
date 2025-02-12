output "address" {
  value = aws_db_instance.myDB.address
  description = "DB Instance address"
}

output "port" {
  value = aws_db_instance.myDB.port
  description = "DB Instance port"
}

output "username" {
  value = aws_db_instance.myDB.username
  description = "DB Instance username"
  sensitive = true
}

output "password" {
  value = aws_db_instance.myDB.password
  description = "DB Instance password"
  sensitive = true
}

output "dbname" {
  value = aws_db_instance.myDB.db_name
  description = "DB Instance DB name"
}
