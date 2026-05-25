locals {
  region      = "us-east-1"
  project     = "CoreStackLabs"
  environment = "dev"
  
  # Nome do bucket de state criado no repositório Core
  state_bucket = "tf-state-corestack-labs-rodrigo"
}

remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    bucket         = local.state_bucket
    key            = "apps/${path_relative_to_include()}/terraform.tfstate"
    region         = local.region
    encrypt        = true
    dynamodb_table = "terraform-lock-table"
  }
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<PROV
provider "aws" {
  region = "${local.region}"
  default_tags {
    tags = {
      Project     = "${local.project}"
      Environment = "${local.environment}"
      ManagedBy   = "Terragrunt"
    }
  }
}
PROV
}
