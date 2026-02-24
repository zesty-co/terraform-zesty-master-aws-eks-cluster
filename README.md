# Terraform module to connect an AWS EKS cluster to Zesty Kompass

This module onboards an AWS master account to Zesty, creates the nececessry resources for a zesty master account,(Cur report, Athena database, Glue crawler).
Then you can connect an AWS EKS cluster to Zesty Kompass.

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) 0.13+

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
