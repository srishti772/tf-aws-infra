#Output
output "ssh_command" {
  description = "SSH command to connect to the EC2 instance and check webapp service status"
  value       = "ssh -i ${var.public_key_path} ubuntu@replace-ip && sudo systemctl status webapp.service && sudo node /opt/csye6225/webapp/server.js"
}

output "db_host" {
  description = "DB host"
  value       = "${aws_db_instance.this.endpoint} "
}
