variable "app_name" {
  description = "App Name"
  default     = "servian-test-app"
  type        = string
}

/*
variable "app_name" {
  description = "App Name"
  default     = "servian-test"
  type        = string
}
*/

variable "cidr_block" {
  description = "VPC CIDR block"
  default     = "10.0.0.0/16"
  type        = string
}

variable "region" {
  description = "Region where Terraform will run deploy"
  default     = "ap-southeast-2"
  type        = string
}

variable "public_nets" {
  description = "Public subnets in VPC CIDR"
  default = [
    "10.0.1.0/24",
    "10.0.2.0/24"
  ]
  type = list(string)
}

variable "private_nets" {
  description = "Private subnets in VPC CIDR"
  default = [
    "10.0.11.0/24",
    "10.0.12.0/24"
  ]
  type = list(string)
}

variable "container_port" {
  description = "ECS Container Port"
  default     = 3000
  type        = number
}

variable "rds_port" {
  description = "default Postgres port"
  default     = 5432
  type        = number
}
