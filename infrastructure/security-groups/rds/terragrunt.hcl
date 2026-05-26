include "root" {
  path = find_in_parent_folders("root.hcl")
}

dependency "network" {
  config_path = "../../../../tf-aws-core-resources/environments/dev/network"
  
  mock_outputs = {
    vpc_id = "vpc-mock-id"
  }
  mock_outputs_allowed_terraform_commands = ["plan", "destroy"]
}

dependency "ecs_sg" {
  config_path = "../ecs"
  
  mock_outputs = {
    security_group_id = "sg-mock-id"
  }
  mock_outputs_allowed_terraform_commands = ["plan", "destroy"]
}

terraform {
  source = "git::git@github.com:alvimrodrigo-corestack-labs/tf-aws-modules.git//modules/security-group?ref=main"
}

inputs = {
  name        = "app-rds-sg-dev"
  description = "Security Group para o RDS - Acesso vindo do ECS"
  vpc_id      = dependency.network.outputs.vpc_id

  ingress_rules = [
    {
      from_port       = 5432
      to_port         = 5432
      protocol        = "tcp"
      security_groups = [dependency.ecs_sg.outputs.security_group_id]
      description     = "Allow Postgres traffic from ECS"
    }
  ]
}
