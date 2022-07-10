/* This file describes pipeline:


- commented out aws_codebuild_project.tf-plan (I don't think we benefit from complicated pipeline)
- aws_codebuild_project.tf-apply
- aws_codepipeline.cicd_pipeline (source and tf-apply)
-
-
-
-
-
-


*/
/*
resource "aws_codebuild_project" "tf-plan" {
  name         = "tf-cicd-plan"
  description  = "Plan stage for tform"
  service_role = aws_iam_role.tf-codebuild-role.arn
  artifacts {
    type = "CODEPIPELINE"
  }
  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "hashicorp/terraform:1.0.3" # it's better to push one in ecr.
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "SERVICE_ROLE"
    registry_credential {
      credential          = var.dockerhub_credentials
      credential_provider = "SECRETS_MANAGER"
    }
  }
  source {
    type      = "CODEPIPELINE"
    buildspec = file("buildspec/plan-buildspec.yml")
  }
}
*/

resource "aws_codebuild_project" "tf-apply" {
  name         = "tf-cicd-apply"
  description  = "Apply stage for tform"
  service_role = aws_iam_role.tf-codebuild-role.arn
  artifacts {
    type = "CODEPIPELINE"
  }
  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "hashicorp/terraform:1.0.3" # it's better to push one in ecr.
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "SERVICE_ROLE"
    registry_credential {
      credential          = var.dockerhub_credentials
      credential_provider = "SECRETS_MANAGER"
    }
  }
  source {
    type      = "CODEPIPELINE"
    buildspec = file("buildspec/apply-buildspec.yml")
  }
}

resource "aws_codepipeline" "cicd_pipeline" {
  name     = "tf-cicd"
  role_arn = aws_iam_role.tf-codepipeline-role.arn

  artifact_store {
    location = aws_s3_bucket.codepipeline_artifacts.id
    type     = "S3"
  }
  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["tf-code"]

      configuration = {
        FullRepositoryId     = "nkolchenko/aws-devops-practice" #ToDO: move to vars
        BranchName           = "main"
        ConnectionArn        = var.codestar_connector_arn
        OutputArtifactFormat = "CODE_ZIP"
      }
    }
  }

  stage {
    name = "TForm-Apply"

    action {
      name            = "Apply"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      input_artifacts = ["tf-code"]
      version         = "1"

      configuration = {
        ProjectName = "tf-cicd-apply"
      }
    }
  }
}
