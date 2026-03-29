include "datacenter" {
  path = find_in_parent_folders("datacenter.hcl")
}

dependency "account" {
  config_path = find_in_parent_folders("account/terragrunt.hcl")

  mock_outputs = {
    kompass_values_yaml = "mock-values"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

locals {
  region_vars  = read_terragrunt_config(find_in_parent_folders("region.hcl")).locals
  region       = local.region_vars.region
  cluster_name = "my-eks-cluster"
}

terraform {
  source = "${get_repo_root()}/examples/simple/terragrunt/modules/kompass"
}

generate "helm_provider" {
  path      = "helm_provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
locals {
  cluster_name = "${local.cluster_name}"
}

data "aws_eks_cluster" "example" {
  name = local.cluster_name
}

data "aws_eks_cluster_auth" "example" {
  name = local.cluster_name
}

provider "helm" {
  kubernetes = {
    host                   = data.aws_eks_cluster.example.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.example.certificate_authority.0.data)
    token                  = data.aws_eks_cluster_auth.example.token
  }
}
EOF
}

inputs = {
  kompass_values_yaml = dependency.account.outputs.kompass_values_yaml
}
