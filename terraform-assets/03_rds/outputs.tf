output "endpoint" {
  value       = aws_db_instance.default.endpoint
  description = "Postgres RDS connection endpoint"
}