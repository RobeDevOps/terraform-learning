resource "aws_instance" "web_server" {
  instance_type = var.instance_type
  ami           = var.web_server_ami
}