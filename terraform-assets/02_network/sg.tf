resource "aws_security_group" "http_from_internet" {
  name        = "http_from_internet"
  description = "Allow http inbound traffic"
  vpc_id      = aws_vpc.vpc.id

  # intentionally listening on 3000 instead of common ports.

  ingress {
    description = "http"
    from_port   = 80
    to_port     = 80
    #from_port   = var.container_port
    #to_port     = var.container_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.app_name}-alb"
    Environment = var.app_name
  }
}

resource "aws_security_group" "ecs_task_sg" {
  name        = "for ecs tasks"
  description = "Allow from alb"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description     = "http-${var.container_port}"
    from_port       = var.container_port
    to_port         = var.container_port
    protocol        = "tcp"
    security_groups = [aws_security_group.http_from_internet.id]
    #cidr_blocks = ["10.0.0.0/16"]
    #cidr_blocks = [aws_vpc.vpc.cidr_block]
  }
  ingress {
    description = "vpc-ssh"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.vpc.cidr_block]
  }
  egress {
    description = "allow-all"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    #security_groups = [aws_security_group.http_from_internet.id]
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.app_name}-ecs-ec2"
    Environment = var.app_name
  }
}

resource "aws_security_group" "rds_sg" {
  name        = "rds_access"
  description = "Allow from ecs"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description = "allow-${var.rds_port}"

    from_port       = var.rds_port
    to_port         = var.rds_port
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_task_sg.id] # allows access from ecs ec2
    #cidr_blocks = ["10.0.0.0/16"]
    #cidr_blocks = [aws_vpc.vpc.cidr_block]
  }
  egress {
    description = "allow-all"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.app_name}-rds"
    Environment = var.app_name
  }
}