variable "region" {
  description = "Region where Terraform will run deploy"
  default     = "ap-southeast-2"
  type        = string
}

variable "app_name" {
  description = "App Name"
  default     = "knp-webapp"
  type        = string
}

variable "app_environment" {
  description = "App Name"
  default     = "knp-test"
  type        = string
}

variable "cluster_name" {
  description = "ECS Cluster name"
  default     = "knp_ecs"
  type        = string
}

variable "frontend_cpu" {
  description = "CPU limit for ECS task"
  default     = 512
  type        = number
}

variable "frontend_mem" {
  description = "Memory limit for ECS task"
  default     = 512
  type        = number
}

variable "settings" {
  description = "The map of ECS application settings"
  default = {
    container_name       = "web_app"
    "cpu"                = 512
    "mem"                = 512
    "desired_count"      = 2
    "deploy_max"         = 200
    "deploy_min_healthy" = 100
  }
  type = any
}

variable "container_port" {
  description = "ECS Container Port"
  default     = 3000
  type        = number
}

variable "container_image" {
  description = "image to run a container"
  default     = "public.ecr.aws/r6q7k4f1/hello-world-app:latest"
  type        = string
}

variable "vtt_user" {
  description = "vtt_user env var override"  #ToDO: move to secretsmanager
  default     = "postgres"
  type        = string
}

variable "vtt_password" {
  description = "vtt_password env var override"  #ToDO: move to secretsmanager
  default     = "changeme"
  type        = string
}

variable "vtt_dbname" {
  description = "vtt_dbname env var override"  #ToDO: move to secretsmanager
  default     = "app"
  type        = string
}
