/* This file describes:

- aws_launch_template to be used with aws_autoscaling_group
- data.aws_ami
- aws_autoscaling_group as ECS cluster capacity provider
*/
resource "aws_launch_template" "ecs_ec2" {
  name_prefix = "ec2_for_ecs-"
  image_id    = data.aws_ami.ecs.image_id
  #image_id      = "ami-053d0f9f12656ea46"
  #instance_type = "t2.micro"
  instance_type = "t2.medium"
  key_name      = "t_knp"

  user_data = data.template_cloudinit_config.user_data.rendered  # comes from user_data.tf
  iam_instance_profile {
    name = aws_iam_instance_profile.knp_ec2.name
  }

  network_interfaces {
    security_groups = [data.terraform_remote_state.network.outputs.ecs_task_sg_id]
  }
}

data "aws_ami" "ecs" {
  most_recent = true
  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-hvm-2.0.2022*"] # aws ssm get-parameters --names /aws/service/ecs/optimized-ami/amazon-linux-2/recommended
  }
  owners = ["amazon"]
}

resource "aws_autoscaling_group" "ecs_cluster_ag" {
  name_prefix         = "${aws_ecs_cluster.knp_ecs.name}-asg-"
  desired_capacity    = 2
  max_size            = 2
  min_size            = 2
  vpc_zone_identifier = data.terraform_remote_state.network.outputs.aws_private_subnets
  health_check_type   = "EC2"

  launch_template {
    id      = aws_launch_template.ecs_ec2.id
    version = "$Latest"
  }
  # set of tags I need for my ECS and SSM
  tag {
    key                 = "AmazonECSManaged"
    propagate_at_launch = true
    value               = ""
  }
  tag {
    key                 = "knp"
    propagate_at_launch = true
    value               = "ssm_managed"
  }
  tag {
    key                 = "app_environment"
    propagate_at_launch = true
    value               = "knp-test"
  }
}

# asg prereqs
resource "aws_placement_group" "test" {
  name     = "knp_placement_group"
  strategy = "cluster"
}


