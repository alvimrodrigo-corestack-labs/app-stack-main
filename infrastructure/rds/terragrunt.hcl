include "root" {
  path = find_in_parent_folders("root.hcl")
}

# Aqui está a mágica: consumindo o state do repo CORE
dependency "network" {
  config_path = "../../../tf-aws-core-resources/environments/dev/network"
  
  mock_outputs = {
    vpc_id             = "vpc-mock-id"
    private_subnet_ids = ["subnet-mock-1", "subnet-mock-2"]
  }
  mock_outputs_allowed_terraform_commands = ["plan"]
}

dependency "rds_sg" {
  config_path = "../security-groups/rds"
  
  mock_outputs = {
    security_group_id = "sg-mock-id"
  }
  mock_outputs_allowed_terraform_commands = ["plan"]
}

terraform {
  source = "git::git@github.com:alvimrodrigo-corestack-labs/tf-aws-modules.git//modules/rds?ref=main"
}

inputs = {
  identifier = "app-stack-db-dev"
  engine     = "postgres"
  engine_version = "15.4"
  instance_class = "db.t3.micro" 
  
  allocated_storage = 20
  db_name           = "app"
  
  # Removendo username/password fixos para gerar via modulo + random
  # username          = "postgres" 
  # password          = "postgres123"
  
  vpc_id     = dependency.network.outputs.vpc_id
  subnet_ids = dependency.network.outputs.private_subnet_ids
  vpc_security_group_ids = [dependency.rds_sg.outputs.security_group_id]
  
  skip_final_snapshot = true
  publicly_accessible = false
}
