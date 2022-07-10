/* This file describes resources specific to LB used to send traffic to containers on ECS.

- aws_lb for ALB itself
- aws_lb_listener.http that forwards to aws_lb_target_group
- aws_lb_listener.https (commented out as I don't have ssl certs/domain)
- aws_lb_target_group
*/

resource "aws_lb" "alb" {
  name               = "knp-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [data.terraform_remote_state.network.outputs.http_from_internet_sg_id]
  subnets            = data.terraform_remote_state.network.outputs.aws_public_subnets

  /* ToDo: setup logging (as an improvement)

  enable_deletion_protection = true

  access_logs {
    bucket  = aws_s3_bucket.lb_logs.bucket
    prefix  = "test-lb"
    enabled = true
  }

  */
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.knp-target.arn

  }
}

# it is possible to listen for HTTPS if you own a domain name.
/*
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.cert.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.knp-target.arn
  }
}

resource "aws_acm_certificate" "cert" {
  domain_name       = "example.com"
  validation_method = "DNS"

  tags = {
    Environment = "test"
  }

  lifecycle {
    create_before_destroy = true
  }
}

*/

resource "aws_lb_target_group" "knp-target" {
  name_prefix = "knp-"
  port                 = var.container_port # ecs_container_port
  protocol             = "HTTP"
  target_type          = "ip"
  vpc_id               = data.terraform_remote_state.network.outputs.aws_vpc_id
  deregistration_delay = 5 # https://nathanpeck.com/speeding-up-amazon-ecs-container-deployments/

  /* #create new target group before removing the old one.
  lifecycle {
    create_before_destroy = true
  }

  */
}
