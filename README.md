# Terraform module to onboard an AWS management account to Zesty

This module owns the shared AWS management-account connection used by Zesty
products. It can onboard Kompass, Commitment Manager (CM), or both without
creating competing IAM roles or competing `zesty_account` resources for the
same AWS account.

It creates:

- one IAM role and inline policy for Zesty access
- one S3 bucket and CUR report definition
- one Zesty account registration
- Kompass Athena/Glue resources when `kompass_enabled = true`
- Kompass values output when Kompass is enabled

The registry source is still `zesty-co/master-aws-eks-cluster/zesty` for
compatibility with existing Kompass customers. Treat it as the AWS management
account module, not as a product-specific child module.

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
- `time` ~> 0.12

To deploy Kompass as part of the same Terraform root, also include:

- `helm` ~> 3.0

## Product modes

Use `kompass_enabled` and `cm_access_mode` to choose the product state for the
AWS management account.

```terraform
module "zesty" {
  source  = "zesty-co/master-aws-eks-cluster/zesty"
  version = "~> 0.2"

  kompass_enabled = true
  cm_access_mode  = "disabled"
}
```

`cm_access_mode` accepts:

- `disabled`: CM is not included in the account payload.
- `readonly`: CM is included without automation permissions. The account is
  registered for read-only/evaluation usage.
- `full`: CM is included with automation permissions and marked active.

The default behavior remains Kompass-only:

```terraform
kompass_enabled = true
cm_access_mode  = "disabled"
```

### Existing Kompass customer

Existing Kompass customers can upgrade the module version without changing their
module block. The defaults preserve the current Kompass-only behavior.

```terraform
module "zesty" {
  source  = "zesty-co/master-aws-eks-cluster/zesty"
  version = "~> 0.2"
}
```

The upgrade keeps the same shared IAM role, CUR bucket, Athena/Glue resources,
and `zesty_account.result`. Kompass-specific resources now have Terraform
`moved` blocks so existing state can move to the new conditional addresses
without manual `terraform state mv`.

### Add CM to an existing Kompass account

Add CM by changing only `cm_access_mode` on the same module block.

```terraform
module "zesty" {
  source  = "zesty-co/master-aws-eks-cluster/zesty"
  version = "~> 0.2"

  cm_access_mode = "readonly"
}
```

To upgrade CM from read-only to full automation:

```terraform
cm_access_mode = "full"
```

Terraform updates the same IAM policy and the same `zesty_account.result` in
place. It does not create another IAM role or another Zesty account resource.

### CM-only account

For CM-only onboarding, disable Kompass and choose the CM access mode.

```terraform
module "zesty" {
  source  = "zesty-co/master-aws-eks-cluster/zesty"
  version = "~> 0.2"

  kompass_enabled = false
  cm_access_mode  = "readonly"
}
```

CM-only mode creates the shared IAM role, IAM policy, CUR bucket/report, and
`zesty_account.result`. It does not create Athena, Glue, or a Kompass values
file.

### Add Kompass later to a CM-only account

Keep the same module block and turn Kompass on.

```terraform
kompass_enabled = true
cm_access_mode  = "readonly"
```

Terraform creates the Kompass Athena/Glue resources and updates the existing IAM
policy and `zesty_account.result` in place.

## State ownership

Use only one instance of this module per AWS management account. Do not install
separate product modules for Kompass and CM against the same AWS account,
because each Terraform state would try to own the same account-level IAM role,
policy, CUR, and Zesty account registration.

The `products` variable remains available as an advanced compatibility override.
Prefer `kompass_enabled` and `cm_access_mode` for normal use, because they keep
IAM permissions and the Zesty account payload in sync.

## Examples

### Terraform

- [Simple single-cluster example](https://github.com/zesty-co/terraform-zesty-master-aws-eks-cluster/tree/main/examples/simple-terraform)
- [Multi-cluster example](https://github.com/zesty-co/terraform-zesty-master-aws-eks-cluster/tree/main/examples/multi-clusters-terraform)

### Terragrunt

- [Simple single-cluster example](https://github.com/zesty-co/terraform-zesty-master-aws-eks-cluster/tree/main/examples/simple-terragrunt)
- [Multi-cluster example](https://github.com/zesty-co/terraform-zesty-master-aws-eks-cluster/tree/main/examples/multi-clusters-terragrunt)

## Kompass Helm Values Reference

The module outputs a `kompass_values_yaml` string containing the credentials and
metadata needed to connect your cluster to Zesty. It is passed directly to the
`helm_release` resource via the `values` argument.

This output is `null` when `kompass_enabled = false`.

For the full list of configurable chart values, see the
[Kompass `values.yaml`](https://github.com/zesty-co/kompass-insights/blob/main/charts/zesty/values.yaml).
