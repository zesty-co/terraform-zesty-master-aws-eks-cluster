locals {
  root_vars        = read_terragrunt_config(find_in_parent_folders("root.hcl")).locals
  organization     = local.root_vars.organization
  account_vars     = read_terragrunt_config(find_in_parent_folders("account.hcl")).locals
  profile          = local.account_vars.profile
  environment_vars = read_terragrunt_config(find_in_parent_folders("environment.hcl")).locals
  environment      = local.environment_vars.environment
  region_vars      = read_terragrunt_config(find_in_parent_folders("region.hcl")).locals
  region           = local.region_vars.region
  datacenter       = basename(dirname(find_in_parent_folders("datacenter.hcl")))
}

remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    bucket  = "terragrunt-${local.organization}-${local.profile}"
    profile = local.profile
    key     = "${path_relative_to_include()}/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}

generate "provider" {
  path      = "${local.datacenter}_provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
provider "aws" {
  region  = "${local.region}"
  profile = "${local.profile}"

  default_tags {
    tags = {
      environment = "${local.environment}"
      region      = "${local.region}"
      managedBy   = "terraform"
    }
  }
}
EOF
}
