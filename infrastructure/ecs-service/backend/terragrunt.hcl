include "root" {
  path = find_in_parent_folders("root.hcl")
}

dependency "network" {
  config_path = "../../../../tf-aws-core-resources/environments/dev/network"
}

dependency "cluster" {
  config_path = "../../../../tf-aws-core-resources/environments/dev/ecs-cluster"
}

dependency "lb_rules" {
  config_path = "../../load-balancer-rules"
}

dependency "ecs_sg" {
  config_path = "../../security-groups/ecs"
}

dependency "ecr" {
  config_path = "../../ecr/backend"
}

dependency "rds" {
  config_path = "../../rds"
}

terraform {
  source = "git::git@github.com:alvimrodrigo-corestack-labs/tf-aws-modules.git//modules/ecs-service?ref=main"
}

inputs = {
  name             = "fastapi-backend"
  cluster_arn      = dependency.cluster.outputs.cluster_arn
  cpu              = 256
  memory           = 512
  desired_count    = 1
  launch_type      = "FARGATE"
  assign_public_ip = false
  
  subnets          = dependency.network.outputs.private_subnet_ids
  security_groups  = [dependency.ecs_sg.outputs.security_group_id]
  
  target_group_arn = dependency.lb_rules.outputs.target_group_arns["backend"]
  container_name   = "backend"
  container_port   = 8000

  container_definitions = jsonencode([
    {
      name      = "backend"
      image     = "${dependency.ecr.outputs.repository_url}:latest"
      essential = true
      # Comando customizado para rodar migrations e depois a app
      # Ref: full-stack-fastapi-template prestart.sh logic
      command   = ["/bin/bash", "-c", "bash backend/scripts/prestart.sh && fastapi run --workers 4 app/main.py"]
      portMappings = [
        {
          containerPort = 8000
          hostPort      = 8000
          protocol      = "tcp"
        }
      ]
      environment = [
        { name = "DOMAIN", value = "fastapi.corestack.labs" },
        { name = "ENVIRONMENT", value = "production" },
        { name = "DATABASE_SECRET_NAME", value = dependency.rds.outputs.db_password_secret_arn },
        { name = "SECRET_KEY", value = "lab-secret-key-change-me" },
        { name = "FIRST_SUPERUSER", value = "admin@example.com" },
        { name = "FIRST_SUPERUSER_PASSWORD", value = "admin123" },
        { name = "BACKEND_CORS_ORIGINS", value = "http://dashboard.fastapi.corestack.labs,https://dashboard.fastapi.corestack.labs" }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/fastapi-backend"
          "awslogs-region"        = "us-east-1"
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}
