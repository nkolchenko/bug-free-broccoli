variable "region" {
  description = "Region where Terraform will run deploy"
  default     = "ap-southeast-2"
  type        = string
}
variable "codestar_connector_arn" {
  description = "codestar connector credentials ARN"
  type        = string
}

variable "dockerhub_credentials" {
  description = "Docker hub credentials ARN"
  type        = string
}
