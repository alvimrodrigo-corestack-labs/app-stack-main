include "root" {
  path = find_in_parent_folders("root.hcl")
}

dependency "network" {
  config_path = "../../../tf-aws-core-resources/environments/dev/network"
  
  mock_outputs = {
    vpc_id = "vpc-mock-id"
  }
  mock_outputs_allowed_terraform_commands = ["plan", "destroy"]
}

dependency "alb" {
  config_path = "../../../tf-aws-core-resources/environments/dev/load-balancer"
  
  mock_outputs = {
    http_listener_arns = {
      "80" = "arn:aws:elasticloadbalancing:us-east-1:123456789012:listener/app/my-load-balancer/50dc6c495c0c9188/f2f7dc8efc522d38"
    }
  }
  mock_outputs_allowed_terraform_commands = ["plan", "destroy"]
}

terraform {
  source = "git::git@github.com:alvimrodrigo-corestack-labs/tf-aws-modules.git//modules/alb-app-link?ref=feat/alb-app-link"
}

inputs = {
  vpc_id       = dependency.network.outputs.vpc_id
  listener_arn = dependency.alb.outputs.http_listener_arns["80"]
  app_name     = "fastapi-app"
  environment  = "dev"

  rules = {
    backend = {
      host_header       = "api.fastapi.corestack.labs"
      container_port    = 8000
      health_check_path = "/api/v1/utils/health-check/"
      priority          = 10
    }
    frontend = {
      host_header       = "dashboard.fastapi.corestack.labs"
      container_port    = 80
      health_check_path = "/"
      priority          = 20
    }
  }
}
