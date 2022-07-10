output "region_az_used" {
  value       = aws_subnet.public.*.availability_zone
  description = "availability zones to place ec2 instances in"
}

output "aws_private_subnets" {
  value       = aws_subnet.private.*.id
  description = "private subnets ids"
}

output "aws_public_subnets" {
  value       = aws_subnet.public.*.id
  description = "public subnets ids"
}

output "aws_db_subnets" {
  value       = aws_db_subnet_group.rds_private.subnet_ids
  description = "subnets for rds"
}

output "aws_db_subnets_ids" {
  value       = aws_db_subnet_group.rds_private.id
  description = "subnets for rds ID"
}

output "aws_vpc_id" {
  value       = aws_vpc.vpc.id
  description = "vpc id"
}

output "ecs_task_sg_id" {
  value       = aws_security_group.ecs_task_sg.id
  description = "SG for ecs ec2 instances in private zone"
}

output "http_from_internet_sg_id" {
  value       = aws_security_group.http_from_internet.id
  description = "SG for ALB"
}

output "rds_sg_id" {
  value       = aws_security_group.rds_sg.id
  description = "SG for RDS"
}
