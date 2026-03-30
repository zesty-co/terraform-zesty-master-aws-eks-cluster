include "datacenter" {
  path = find_in_parent_folders("datacenter.hcl")
}

terraform {
  source = "${get_repo_root()}"
}

generate "zesty_provider" {
  path      = "zesty_provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
provider "zesty" {
  token = "your-zesty-api-token"
}
EOF
}

inputs = {
  create_values_local_file = false
}
