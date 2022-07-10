output "s3_bucket_arn" {
  value       = aws_s3_bucket.terraform_state.arn
  description = "the ARN of the S3 bucket"
}

output "dynamodb_table_name" {
  value       = aws_dynamodb_table.terraform_locks.name
  description = "DynamoDB table with locks"
}

output "aws_kms_key_arn" {
  value       = aws_kms_key.tf_key.arn
  description = "AWS KMS key ARN"
}