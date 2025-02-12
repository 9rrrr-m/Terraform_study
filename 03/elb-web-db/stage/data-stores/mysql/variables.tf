variable "dbuser" {
  type = string
  description = "myDB username"
  sensitive = true
}

variable "dbpassword" {
  type = string
  description = "myDB password"
  sensitive = true
}
