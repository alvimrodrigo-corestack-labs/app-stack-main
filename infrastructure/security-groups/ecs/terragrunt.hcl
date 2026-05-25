include "root" {
  path = find_in_parent_folders("root.hcl")
}

dependency "network" {
  config_path = "../../../../tf-aws-core-resources/environments/dev/network"
}

dependency "alb_sg" {
  config_path = "../../../../tf-aws-core-resources/environments/dev/security-groups"
}

terraform {
  source = "git::git@github.com:alvimrodrigo-corestack-labs/tf-aws-modules.git//modules/security-group?ref=main"
}

inputs = {
  name        = "app-ecs-sg-dev"
  description = "Security Group para os servicos ECS (Backend e Frontend)"
  vpc_id      = dependency.network.outputs.vpc_id

  ingress_rules = [
    {
      from_port       = 8000
      to_port         = 8000
      protocol        = "tcp"
      security_groups = [dependency.alb_sg.outputs.security_group_id]
      description     = "Allow Backend traffic from ALB"
    },
    {
      from_port       = 80
      to_port         = 80
      protocol        = "tcp"
      security_groups = [dependency.alb_sg.outputs.security_group_id]
      description     = "Allow Frontend traffic from ALB"
    }
  ]
}
