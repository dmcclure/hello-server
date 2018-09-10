variable "aws_region" {
  description = "The region where AWS operations will take place"
  default     = "us-west-2"
}

variable "az_count" {
  description = "Maximum number of AZs to cover in a given region"
  default     = "2"
}

variable "environment" {
    description = "Should be 'test', 'staging' or 'production'"
}

# variable "app_image" {
#   description = "Docker image to run in the ECS cluster"
#   default     = "bradfordhamilton/crystal_blockchain:latest"
# }

# variable "app_port" {
#   description = "Port exposed by the docker image to redirect traffic to"
#   default     = 9090
# }

# variable "app_count" {
#   description = "Number of docker containers to run"
#   default     = 3
# }

# variable "ecs_autoscale_role" {
#   description = "Role arn for the ecsAutocaleRole"
#   default     = "YOUR_ECS_AUTOSCALE_ROLE_ARN"
# }

# variable "ecs_task_execution_role" {
#   description = "Role arn for the ecsTaskExecutionRole"
#   default     = "YOUR_ECS_TASK_EXECUTION_ROLE_ARN"
# }

# variable "health_check_path" {
#   default = "/"
# }

# variable "fargate_cpu" {
#   description = "Fargate instance CPU units to provision (1 vCPU = 1024 CPU units)"
#   default     = "1024"
# }

# variable "fargate_memory" {
#   description = "Fargate instance memory to provision (in MiB)"
#   default     = "2048"
# }