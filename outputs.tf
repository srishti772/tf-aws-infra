#Output



output "db_host" {
  description = "DB host"
  value       = "${aws_db_instance.this.endpoint} "
}
