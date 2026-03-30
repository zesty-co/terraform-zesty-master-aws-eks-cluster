terraform {
  backend "s3" {
    bucket  = "my-terraform-state"
    key     = "zesty/kompass-eks-staging/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}

data "terraform_remote_state" "account" {
  backend = "s3"
  config = {
    bucket = "my-terraform-state"
    key    = "zesty/account/terraform.tfstate"
    region = "us-east-1"
  }
}

resource "helm_release" "kompass" {
  name             = "kompass"
  repository       = "https://zesty-co.github.io/kompass"
  chart            = "kompass"
  namespace        = "zesty-system"
  cleanup_on_fail  = true
  create_namespace = true

  values = [data.terraform_remote_state.account.outputs.kompass_values_yaml]
}
