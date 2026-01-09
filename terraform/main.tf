resource "aws_ecr_repository" "repos" {
  for_each = toset(var.ecr_repositories)

  name = each.value

  image_scanning_configuration {
    scan_on_push = true
  }

  image_tag_mutability = "MUTABLE"
}

resource "aws_ecs_cluster" "APP_CLUSTER" {                    # THE ECS CLUSTER
  name = var.aws_ecs_cluster

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_task_definition" "frontend_task" {
  family                   = "frontend-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name  = "frontend"
      image = "${aws_ecr_repository.repos["frontend/food-ewb"].repository_url}:${var.image_tag}"
      portMappings = [{
        containerPort = 80
      }]

      essential = true
    }
  ])
}


resource "aws_ecs_task_definition" "backend_task" {
  family                   = "backend-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name  = "backend"
      image = "${aws_ecr_repository.repos["backend/food-ewb"].repository_url}:${var.image_tag}"

      portMappings = [{
        containerPort = 4000
      }]

      essential = true
    }
  ])
}

# THE ADMIN TASK DEFINITION

resource "aws_ecs_task_definition" "admin_task" {
  family                   = "admin-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name  = "admin"
      image = "${aws_ecr_repository.repos["admin/food-ewb"].repository_url}:${var.image_tag}"

      portMappings = [{
        containerPort = 80
      }]

      essential = true
    }
  ])
}


# THE ECS SERVICE 

resource "aws_ecs_service" "food-backend-service-app" {   
  name            = var.app_service_backend
  cluster         = aws_ecs_cluster.APP_CLUSTER.id
  task_definition = aws_ecs_task_definition.backend_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = data.aws_subnets.default.ids
    security_groups = [aws_security_group.backend_sg.id]
      assign_public_ip = true
  }
}


resource "aws_ecs_service" "food-frontend-service-app" {   
  name            = var.app_service_frontend
  cluster         = aws_ecs_cluster.APP_CLUSTER.id
  task_definition = aws_ecs_task_definition.frontend_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = data.aws_subnets.default.ids
    security_groups = [aws_security_group.frontend_sg.id]
    assign_public_ip = true
  }
}

resource "aws_ecs_service" "app_service_admin" {   
  name            = var.app_service_admin
  cluster         = aws_ecs_cluster.APP_CLUSTER.id
  task_definition = aws_ecs_task_definition.admin_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = data.aws_subnets.default.ids
    security_groups = [aws_security_group.frontend_sg.id]
    assign_public_ip = true
  }
}

# THE IAM ROLE FOR ECS TASK EXECUTION

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"


  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
    {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
            Service = "ecs-tasks.amazonaws.com"
        }
    },
    ]
  })

  tags = {
    tag-key = "tag-value"
  }
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy_attachment" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

