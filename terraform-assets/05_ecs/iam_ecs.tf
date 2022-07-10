/* This file describes IAM entities that are needed for correct work of ECS and SSM.

- data.aws_iam_policy_document.ecs_policy for ECS (A)
- data.aws_iam_policy_document.app_role_assume_role_policy (B)
- aws_iam_role.ecs (C) that consumes B
- aws_iam_role_policy.ecs that ties aws_iam_role (C) and ecs_policy A
- aws_iam_instance_profile.knp_ec2 that consumes aws_iam_role C.
*/

data "aws_iam_policy_document" "ecs_policy" {
  statement {
    sid = "EC2"
    actions = [
      "ec2:CreateNetworkInterface",
      "ec2:DeleteNetworkInterface",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSubnets",
      "ec2:DescribeVpcs",
      "ec2:DetachNetworkInterface",
      "ec2:ModifyNetworkInterfaceAttribute",
      "ec2:DescribeTags"
    ]
    resources = ["*"]
  }

  statement {
    sid = "ECR"
    actions = [
      "ecr:*",
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:GetAuthorizationToken",
      "ecr:GetDownloadUrlForLayer",
    ]
    resources = ["*"]
  }

  statement {
    sid = "ECS"
    actions = [
      "ecs:RunTask",
      "ecs:DescribeServices",
      "ecs:UpdateService",
      "ecs:CreateCluster",
      "ecs:DeregisterContainerInstance",
      "ecs:DiscoverPollEndpoint",
      "ecs:Poll",
      "ecs:RegisterContainerInstance",
      "ecs:StartTelemetrySession",
      "ecs:UpdateContainerInstancesState",
      "ecs:Submit*"
    ]
    resources = ["*"]
  }

  statement {
    sid = "CloudWatch"
    actions = [
      "cloudwatch:DescribeAlarms",
      "cloudwatch:PutMetricAlarm",
    ]
    resources = ["*"]
  }

  statement {
    sid = "IAM"
    actions = [
      "iam:PassRole",
    ]
    resources = ["*"]
  }

  statement {
    sid = "Logs"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["*"]
  }

  statement {
    sid = "SSM"
    actions = [
      "ssm:PutParameter",
      "ssm:GetParameter",
      "ssm:GetParameters",
      "ssm:DescribeAssociation",
      "ssm:GetDeployablePatchSnapshotForInstance",
      "ssm:GetDocument",
      "ssm:DescribeDocument",
      "ssm:GetManifest",
      "ssm:GetParameter",
      "ssm:GetParameters",
      "ssm:ListAssociations",
      "ssm:ListInstanceAssociations",
      "ssm:PutInventory",
      "ssm:PutComplianceItems",
      "ssm:PutConfigurePackageResult",
      "ssm:UpdateAssociationStatus",
      "ssm:UpdateInstanceAssociationStatus",
      "ssm:UpdateInstanceInformation"
    ]
    resources = ["*"]
  }

  statement {
    sid = ""
    actions = [
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel"
    ]
    resources = ["*"]
  }

  statement {
    sid = "ec2messages"
    actions = [
      "ec2messages:AcknowledgeMessage",
      "ec2messages:DeleteMessage",
      "ec2messages:FailMessage",
      "ec2messages:GetEndpoint",
      "ec2messages:GetMessages",
      "ec2messages:SendReply"
    ]
    resources = ["*"]
  }

  /*
  statement {
    sid = "SecretsManager"
    actions = [
      "secretsmanager:GetSecretValue"
    ]
    resources = ["arn:${data.aws_partition.current.partition}:secretsmanager:*:*:secret:*"]
  }
  */
}

data "aws_iam_policy_document" "app_role_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"
      identifiers = [
        "application-autoscaling.amazonaws.com",
        "ecs-tasks.amazonaws.com",
        "lambda.amazonaws.com",
        "events.amazonaws.com",
        "ecs.amazonaws.com",
        "ec2.amazonaws.com" #  documentation at https://docs.aws.amazon.com/IAM/latest/UserGuide/troubleshoot_iam-ec2.html#troubleshoot_iam-ec2_errors-info-doc.
      ]
    }
  }
}

resource "aws_iam_role" "ecs" {
  name               = "knp_ecs_role"
  assume_role_policy = data.aws_iam_policy_document.app_role_assume_role_policy.json
}

resource "aws_iam_role_policy" "ecs" {
  name   = "knp_ecs_role_policy"
  role   = aws_iam_role.ecs.id
  policy = data.aws_iam_policy_document.ecs_policy.json
}

resource "aws_iam_instance_profile" "knp_ec2" {
  name = "knp_instance_profile"
  role = aws_iam_role.ecs.name
  #role = "ecsInstanceRole"
}