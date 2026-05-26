include "root" {
  path = find_in_parent_folders("root.hcl")
}

dependency "network" {
  config_path = "../../../../tf-aws-core-resources/environments/dev/network"
}

dependency "cluster" {
  config_path = "../../../../tf-aws-core-resources/environments/dev/ecs-cluster"
  
  mock_outputs = {
    cluster_arn = "arn:aws:ecs:us-east-1:123456789012:cluster/mock-cluster"
  }
  mock_outputs_allowed_terraform_commands = ["plan", "destroy"]
}

dependency "lb_rules" {
  config_path = "../../load-balancer-rules"
  
  mock_outputs = {
    target_group_arns = {
      backend = "arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/mock-backend/12345"
    }
  }
  mock_outputs_allowed_terraform_commands = ["plan", "destroy"]
}

dependency "ecs_sg" {
  config_path = "../../security-groups/ecs"
  
  mock_outputs = {
    security_group_id = "sg-mock-id"
  }
  mock_outputs_allowed_terraform_commands = ["plan", "destroy"]
}

dependency "ecr" {
  config_path = "../../ecr/backend"
  
  mock_outputs = {
    repository_url = "123456789012.dkr.ecr.us-east-1.amazonaws.com/mock-repo"
  }
  mock_outputs_allowed_terraform_commands = ["plan", "destroy"]
}

dependency "rds" {
  config_path = "../../rds"
  
  mock_outputs = {
    db_instance_address       = "mock-db.cluster-123.us-east-1.rds.amazonaws.com"
    db_password_secret_arn    = "arn:aws:secretsmanager:us-east-1:123456789012:secret:mock-secret"
  }
  mock_outputs_allowed_terraform_commands = ["plan", "destroy"]
}

terraform {
  source = "git::git@github.com:alvimrodrigo-corestack-labs/tf-aws-modules.git//modules/ecs-service?ref=feat/alb-app-link"
}

inputs = {
  name             = "fastapi-backend"
  cluster_arn      = dependency.cluster.outputs.cluster_arn
  cpu              = 512
  memory           = 1024
  desired_count    = 1
  launch_type      = "FARGATE"
  assign_public_ip = false
  health_check_grace_period_seconds = 300
  
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
      # Comando corrigido: Relativo ao WORKDIR /app/backend/
      command   = ["/bin/bash", "-c", "bash scripts/prestart.sh && fastapi run --workers 4 app/main.py"]
      portMappings = [
        {
          containerPort = 8000
          hostPort      = 8000
          protocol      = "tcp"
        }
      ]
      environment = [
        { name = "PROJECT_NAME", value = "FastAPI ECS Lab" },
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
