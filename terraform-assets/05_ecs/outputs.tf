output "lb_dns_name" {
  value       = aws_lb.alb.dns_name
  description = "ALB DNS name"
}

