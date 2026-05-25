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

terraform {
  source = "git::git@github.com:alvimrodrigo-corestack-labs/tf-aws-modules.git//modules/rds?ref=main"
}

inputs = {
  identifier = "app-stack-db-dev"
  engine     = "postgres"
  engine_version = "15.4"
  instance_class = "db.t3.micro" # FinOps: Menor instância para lab
  
  allocated_storage = 20
  db_name           = "appdb"
  username          = "dbadmin"
  
  vpc_id     = dependency.network.outputs.vpc_id
  subnet_ids = dependency.network.outputs.private_subnet_ids
  
  skip_final_snapshot = true
  publicly_accessible = false
}
