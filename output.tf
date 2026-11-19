#print public ip on terminal
output "public_ip" {
    value = aws_instance.tf-web-server.public_ip
  
}
# Web Server Public IP

output "web_public_ip" {
  value = aws_instance.tf-web-server.public_ip
}

# App Server Private IP

output "app_private_ip" {
  value = aws_instance.tf-app-server.private_ip
}

# Database Server Private IP

output "db_private_ip" {
  value = aws_instance.tf-db-server.private_ip
}