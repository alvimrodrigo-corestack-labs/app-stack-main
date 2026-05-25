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
  config_path = "../../ecr/frontend"
}

terraform {
  source = "git::git@github.com:alvimrodrigo-corestack-labs/tf-aws-modules.git//modules/ecs-service?ref=main"
}

inputs = {
  name             = "fastapi-frontend"
  cluster_arn      = dependency.cluster.outputs.cluster_arn
  cpu              = 256
  memory           = 512
  desired_count    = 1
  launch_type      = "FARGATE"
  assign_public_ip = false
  
  subnets          = dependency.network.outputs.private_subnet_ids
  security_groups  = [dependency.ecs_sg.outputs.security_group_id]
  
  target_group_arn = dependency.lb_rules.outputs.target_group_arns["frontend"]
  container_name   = "frontend"
  container_port   = 80

  container_definitions = jsonencode([
    {
      name      = "frontend"
      image     = "${dependency.ecr.outputs.repository_url}:latest"
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/fastapi-frontend"
          "awslogs-region"        = "us-east-1"
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}
