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

## Examples

### Terraform

- [Multi-cluster example](https://github.com/zesty-co/terraform-zesty-master-aws-eks-cluster/tree/main/examples/multi-clusters-terraform)
- [Simple single-cluster example](https://github.com/zesty-co/terraform-zesty-master-aws-eks-cluster/tree/main/examples/simple-terraform)

### Terragrunt

- [Multi-cluster example](https://github.com/zesty-co/terraform-zesty-master-aws-eks-cluster/tree/main/examples/multi-clusters-terragrunt)
- [Simple single-cluster example](https://github.com/zesty-co/terraform-zesty-master-aws-eks-cluster/tree/main/examples/simple-terragrunt)

## Kompass Helm Values Reference

The module outputs a `kompass_values_yaml` string containing the credentials and
metadata needed to connect your cluster to Zesty. It is passed directly to the
`helm_release` resource via the `values` argument.

For the full list of configurable chart values, see the
[Kompass `values.yaml`](https://github.com/zesty-co/kompass-insights/blob/main/charts/zesty/values.yaml).
