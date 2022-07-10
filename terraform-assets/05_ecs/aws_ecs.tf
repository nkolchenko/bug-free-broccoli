/* This file describes resources specific to ECS

- aws_ecs_cluster
- aws_ecs_capacity_provider (an ASG from ec2.tf)
- aws_ecs_cluster_capacity_providers that ties aws_ecs_capacity_provider and aws_ecs_cluster
- aws_ecs_task_definition (two containers)
- aws_ecs_service that runs var.settings.desired_count of aws_ecs_task_definition and ties them to LB
*/

resource "aws_ecs_cluster" "knp_ecs" {
  name = var.app_name

  tags = {
    auto-delete = "no"
    Name        = "${var.app_name}-vpc"
    Environment = var.app_environment
  }

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_capacity_provider" "asg_capacity_prov" {
  name = "asg_prov"

  auto_scaling_group_provider {
    auto_scaling_group_arn = aws_autoscaling_group.ecs_cluster_ag.arn
  }
}

resource "aws_ecs_cluster_capacity_providers" "prov_list" {
  cluster_name       = aws_ecs_cluster.knp_ecs.name
  capacity_providers = [aws_ecs_capacity_provider.asg_capacity_prov.name]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = aws_ecs_capacity_provider.asg_capacity_prov.name
  }
}

resource "aws_ecs_task_definition" "web_server" {
  family             = "frontend_task"
  network_mode       = "awsvpc" # We need this to connect from the ALB
  execution_role_arn = aws_iam_role.ecs.arn
  container_definitions = jsonencode([
    {
      name  = var.settings.container_name
      image = var.container_image
      entrypoint : ["./TechChallengeApp", "serve"],
      cpu       = 512
      memory    = 256
      essential = true
      environment : [
        {
          "name" : "VTT_LISTENHOST", # Hardcoded. to be moved to VARS and to SSM Parameterstore later
          "value" : "0.0.0.0"
        },
        {
          "name" : "VTT_DBHOST"
          "value" : data.terraform_remote_state.rds.outputs.endpoint
        },
        {
          "name" : "VTT_DBUSER"
          "value" : var.vtt_user
        },
        {
          "name" : "VTT_DBPASSWORD"
          "value" : var.vtt_password
        },
        {
          "name" : "VTT_DBNAME"
          "value" : "app"
          "value" : var.vtt_dbname
        }
      ]
      portMappings = [
        {
          protocol      = "tcp"
          containerPort = var.container_port
          hostPort      = var.container_port
        }
      ]
    },
    {
      name  = "updatedb-container"
      image = var.container_image
      entrypoint : ["./TechChallengeApp", "updatedb"],
      cpu       = 256
      memory    = 128
      essential = false
      environment : [
        {
          "name" : "VTT_DBHOST"
          "value" : data.terraform_remote_state.rds.outputs.endpoint
        },
        {
          "name" : "VTT_DBUSER"
          "value" : var.vtt_user
        },
        {
          "name" : "VTT_DBPASSWORD"
          "value" : var.vtt_password
        },
        {
          "name" : "VTT_DBNAME"
          "value" : "app"
          "value" : var.vtt_dbname
        }
      ]
    }
  ])
}

resource "aws_ecs_service" "ecs_frontend" {
  name            = "frontend"
  cluster         = aws_ecs_cluster.knp_ecs.arn
  task_definition = aws_ecs_task_definition.web_server.arn

  desired_count                      = var.settings.desired_count
  deployment_maximum_percent         = var.settings.deploy_max
  deployment_minimum_healthy_percent = var.settings.deploy_min_healthy

  propagate_tags = "SERVICE"


  load_balancer {
    target_group_arn = aws_lb_target_group.knp-target.arn
    container_name   = var.settings.container_name
    container_port   = var.container_port
  }

  network_configuration {
    subnets          = data.terraform_remote_state.network.outputs.aws_private_subnets
    security_groups  = [data.terraform_remote_state.network.outputs.ecs_task_sg_id]
    assign_public_ip = false
  }

  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.asg_capacity_prov.name
    weight            = 1
    base              = 0
  }

  deployment_circuit_breaker {
    enable   = false
    rollback = false
  }

  deployment_controller {
    type = "ECS"
  }

  ordered_placement_strategy {
    type  = "binpack"
    field = "cpu"
  }
}

