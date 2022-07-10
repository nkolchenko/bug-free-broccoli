output "lb_dns_name" {
  value       = data.terraform_remote_state.ecs.outputs.lb_dns_name
  description = "ALB DNS name"
}