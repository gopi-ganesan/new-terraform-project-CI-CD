variable "app_service_backend" { 
    description = "food-backend-service"
    type = string
}
variable "app_service_frontend" { 
    description = "food-frontend-service"
    type = string
}

variable "aws_ecs_cluster" {
    description = "food-delivery-cluster"
    type = string
}

variable "aws_ecs_task_definition" {
    description = "food-delivery-task"
    type = string
}

variable "admin_task" {
  description = "food-admin-task"
}

variable "ecr_repositories" {
  description = "List of ECR repositories"
  type        = list(string)
  default     = ["frontend", "backend", "admin"]
}
