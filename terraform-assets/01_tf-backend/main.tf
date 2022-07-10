provider "aws" {
  region = var.region
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = "knp-tf-state"

  lifecycle {
    prevent_destroy = true
  }
  #Prevent automatic deletion by my scripts
  tags = {
    auto-delete = "no"
  }
}

#Enable versioning
resource "aws_s3_bucket_versioning" "versioning_example" {
  bucket = aws_s3_bucket.terraform_state.bucket
  versioning_configuration {
    status = "Enabled"
  }
}


# Enable server-side encryption. Useful for tfstate files.
# See: https://registry.terraform.io/providers/hashicorp%20%20/aws/latest/docs/resources/s3_bucket

resource "aws_kms_key" "tf_key" {
  description             = "This key is used to encrypt terraform_state bucket objects"
  deletion_window_in_days = 28
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tf_encryption" {
  bucket = aws_s3_bucket.terraform_state.bucket

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.tf_key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_dynamodb_table" "terraform_locks" {
  hash_key     = "LockID"
  name         = "terraform-up-and-running-locks"
  billing_mode = "PAY_PER_REQUEST"
  attribute {
    name = "LockID"
    type = "S"
  }
  #Prevent automatic deletion by my scripts
  tags = {
    auto-delete = "no"
  }
}

## Uncomment the terraform block after you run step-1 from SUBMISSION.md

/*
terraform {
  backend "s3" {
    bucket = "knp-tf-state"
    key    = "laughing-doodle/terraform-assets/tf-backend/terraform.tfstate"
    region = "ap-southeast-2" # Variables may not be used here.

    dynamodb_table = "terraform-up-and-running-locks"
    encrypt        = true
  }
}
*/
