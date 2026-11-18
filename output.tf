#print public ip on terminal
output "public_ip" {
    value = aws_instance.tf-web-server.public_ip
  
}