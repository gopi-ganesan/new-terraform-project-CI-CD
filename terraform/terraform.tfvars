app_service_backend      = "food-backend-service"
app_service_frontend     = "food-frontend-service"
aws_ecs_cluster          = "food-delivery-cluster"
aws_ecs_task_definition  = "food-delivery-task"
ecr_repositories = ["frontend/food-ewb", "backend/food-ewb", "admin/food-ewb"]
image_tag                = "latest"
app_service_admin       = "food-admin-service"