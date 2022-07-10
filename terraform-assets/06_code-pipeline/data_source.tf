data "terraform_remote_state" "ecs" {
  backend = "s3"
  config = {
    bucket = "knp-tf-state"
    key    = "laughing-doodle/terraform-assets/ecs/terraform.tfstate"
    region = "ap-southeast-2"
  }
}
