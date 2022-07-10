resource "aws_s3_bucket" "codepipeline_artifacts" {
  bucket = "knp-codepipeline-artifacts-bucket"
  acl    = "private"
}