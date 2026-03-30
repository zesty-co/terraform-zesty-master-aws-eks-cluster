mock_provider "aws" {
  mock_data "aws_eks_cluster" {
    defaults = {
      endpoint = "https://ABCDEF1234567890.gr7.us-east-1.eks.amazonaws.com"
      certificate_authority = [{
        data = "bW9jay1jYS1jZXJ0"
      }]
    }
  }
}

mock_provider "helm" {}

run "kompass_helm_release" {
  command = apply

  variables {
    region = "us-east-1"
  }

  override_data {
    target = data.terraform_remote_state.account
    values = {
      outputs = {
        kompass_values_yaml = "mock-kompass-values"
      }
    }
  }

  assert {
    condition     = helm_release.kompass.namespace == "zesty-system"
    error_message = "helm release should target zesty-system namespace"
  }

  assert {
    condition     = helm_release.kompass.chart == "kompass"
    error_message = "helm release should use the kompass chart"
  }

  assert {
    condition     = helm_release.kompass.cleanup_on_fail == true
    error_message = "helm release should cleanup on fail"
  }
}
