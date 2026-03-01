# Terraform module to connect an AWS EKS cluster to Zesty Kompass

This module onboards an AWS Management (Master/Payer) account to Zesty and provisions all required resources for integration.
It creates and configures the necessary components in the management account, including:

- AWS CUR
- Amazon Athena database and table configuration
- AWS Glue crawler for CUR data

Once the management account setup is complete, you can connect your AWS EKS clusters to Zesty Kompass for cost visibility and optimization.  
## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) 1.3.0 +

## Providers

- aws >= 6.0
- random >= 3.7.2
- local >= 2.5.3

## Optional Provider

To connect a cluster (optional) as part of the installation, include:

- helm >= 3

## Example Usage

```terraform

module "zesty" {
  source = "zesty-co/aws-eks-cluster/zesty"
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
