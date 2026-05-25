include "root" {
  path = find_in_parent_folders("root.hcl")
}

dependency "network" {
  config_path = "../../../tf-aws-core-resources/environments/dev/network"
}

dependency "alb" {
  config_path = "../../../tf-aws-core-resources/environments/dev/load-balancer"
}

terraform {
  source = "../../..//tf-aws-modules/modules/alb-app-link"
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
