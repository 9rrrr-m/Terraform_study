variable "server_port" {
  description = "The port the server will use for HTTP requests"
  type = number
  default = 80
}

variable "security_group_name" {
  description = "The name of the security group"
  type = string
  default = "allow_80"
}
