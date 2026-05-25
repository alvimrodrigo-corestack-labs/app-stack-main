include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "git::git@github.com:alvimrodrigo-corestack-labs/tf-aws-modules.git//modules/ecr?ref=main"
}

inputs = {
  name = "app-frontend"
  scan_on_push = true
}
