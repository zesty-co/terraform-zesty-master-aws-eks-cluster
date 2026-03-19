# Terraform module to onboard an AWS management account and connect EKS clusters to Zesty Kompass

This module onboards an AWS management account to Zesty and prepares the billing and access resources needed for Kompass.

It creates:

- IAM role and policy for Zesty access
- S3 bucket and CUR configuration
- Glue database, table, crawler, and crawler IAM role
- Athena workgroup for CUR queries
- Zesty account registration and Kompass values output

After the account is onboarded, you can use the generated `kompass_values_yaml` to install the Kompass Helm chart into one or more EKS clusters.

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.3
- AWS credentials for the target management account
- Zesty API token for the `zesty` provider

```terraform
provider "zesty" {
  token = "your-zesty-api-token"
}
```

## Providers

- `aws` ~> 6.0
- `zesty` ~> 0.3.0
- `random` ~> 3.7.2
- `local` ~> 2.5.3

To deploy Kompass as part of the same Terraform root, also include:

- `helm` ~> 3.0

## Example Usage

### Account onboarding only

```terraform
module "zesty" {
  source = "git::https://github.com/HenItzhaki/terraform-zesty-master-aws-eks-cluster.git"

  create_values_local_file = false
}

output "kompass_values_yaml" {
  value       = module.zesty.kompass_values_yaml
  description = "Kompass Helm values YAML"
  sensitive   = true
}
```

### Account onboarding and single-cluster Kompass deployment

```terraform
module "zesty" {
  source = "git::https://github.com/HenItzhaki/terraform-zesty-master-aws-eks-cluster.git"

  create_values_local_file = false
}

resource "helm_release" "kompass" {
  name             = "kompass"
  repository       = "https://zesty-co.github.io/kompass"
  chart            = "kompass"
  namespace        = "zesty-system"
  cleanup_on_fail  = true
  create_namespace = true

  values = [module.zesty.kompass_values_yaml]
}
```

## Examples

### Terraform

- [Simple single-cluster example](./examples/simple/terraform/)
- [Multi-cluster example](./examples/multi_clusters/terraform/)

### Terragrunt

- [Simple single-cluster example](./examples/simple/terragrunt/)
- [Multi-cluster example](./examples/multi_clusters/terragrunt/)

## Kompass Helm Values Reference

The module outputs a `kompass_values_yaml` string containing the credentials and
metadata needed to connect your cluster to Zesty. It is passed directly to the
`helm_release` resource via the `values` argument.

For the full list of configurable chart values, see the
[Kompass `values.yaml`](https://github.com/zesty-co/kompass-insights/blob/main/charts/zesty/values.yaml).
