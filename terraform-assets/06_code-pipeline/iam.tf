/* This file describes IAM resources needed by AWS CodePipeline and CodeBuild services

For CodePipeline:
- aws_iam_role.tf-codepipeline-role ("sts:AssumeRole" "codepipeline.amazonaws.com") (A)
- data.aws_iam_policy_document.tf-cicd-pipeline-policies (B)
- aws_iam_policy.tf-cicd-pipeline-policy (C) that consumes B
- aws_iam_role_policy_attachment.tf-cicd-pipeline-attachment binds C and A

For CodeBuild:
- aws_iam_role.tf-codebuild-role (A)
- data.aws_iam_policy_document.tf-cicd-build-policies (B)
- aws_iam_policy.tf-cicd-build-policy (C) that consumes B
- aws_iam_role_policy_attachment.tf-cicd-codebuild-attachment1  binds C and A
- aws_iam_role_policy_attachment.tf-cicd-codebuild-attachment1  adds PowerUserAccess
*/

resource "aws_iam_role" "tf-codepipeline-role" {
  name = "tf-codepipeline-role"
  assume_role_policy = jsonencode({  # terraform's "jsonencode" converts a tform expression result to valid JSON syntax.
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "codepipeline.amazonaws.com"
        }
      },
    ]
  })
}

data "aws_iam_policy_document" "tf-cicd-pipeline-policies" {
  statement {
    sid       = ""
    actions   = ["codestar-connections:UseConnection"]
    resources = ["*"]
    effect    = "Allow"
  }
  statement {
    sid       = ""
    actions   = ["cloudwatch:*", "s3:*", "codebuild:*"] # that's a quick hack. ToDo: refine actions list
    resources = ["*"]
    effect    = "Allow"
  }
}

resource "aws_iam_policy" "tf-cicd-pipeline-policy" {
  name        = "tf-cicd-pipeline-policy"
  path        = "/"
  description = "Pipeline Policy"
  policy      = data.aws_iam_policy_document.tf-cicd-pipeline-policies.json
}

resource "aws_iam_role_policy_attachment" "tf-cicd-pipeline-attachment" {
  policy_arn = aws_iam_policy.tf-cicd-pipeline-policy.arn
  role       = aws_iam_role.tf-codepipeline-role.id
}

resource "aws_iam_role" "tf-codebuild-role" {
  name = "tf-codebuild-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
      },
    ]
  })
}

data "aws_iam_policy_document" "tf-cicd-build-policies" {
  statement {
    sid     = ""
    actions = ["logs:*", "s3:*", "codebuild:*", "secretsmanager:*", "iam:*"] # that's a quick hack. ToDo: refine the actions list
    resources = ["*"]
    effect    = "Allow"
  }
}

resource "aws_iam_policy" "tf-cicd-build-policy" {
  name        = "tf-cicd-build-policy"
  path        = "/"
  description = "Codebuild Policy"
  policy      = data.aws_iam_policy_document.tf-cicd-build-policies.json
}

resource "aws_iam_role_policy_attachment" "tf-cicd-codebuild-attachment1" {
  policy_arn = aws_iam_policy.tf-cicd-build-policy.arn
  role       = aws_iam_role.tf-codebuild-role.id
}

resource "aws_iam_role_policy_attachment" "tf-cicd-codebuild-attachment2" {
  policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
  role       = aws_iam_role.tf-codebuild-role.id
}
