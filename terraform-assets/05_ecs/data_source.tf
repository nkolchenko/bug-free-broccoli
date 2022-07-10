data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = "knp-tf-state"
    key    = "laughing-doodle/terraform-assets/network/terraform.tfstate"
    region = "ap-southeast-2"
  }
}

data "terraform_remote_state" "rds" {
  backend = "s3"
  config = {
    bucket = "knp-tf-state"
    key    = "laughing-doodle/terraform-assets/rds/terraform.tfstate"
    region = "ap-southeast-2"
  }
}