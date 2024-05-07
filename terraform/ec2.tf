resource "aws_instance" "web-server" {
  ami = "ami-080e1f13689e07408"
  instance_type = "t2.micro"
  key_name = "Avanti"
  security_groups = ["allow_ssh", "allow_http", "allow_egress"]
  user_data = file("script.sh")

  tags = {
    Name = "AWS-Apache"
  }
}