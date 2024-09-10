variable "web_server_ami" {
  description = "Este es la plantilla utilizada para servidor web"
  type        = string
  default     = "ami-0182f373e66f89c85"
}

variable "instance_type" {
  description = "Tipo de instancia a crear"
  type        = string
  default     = "t2.micro"
}