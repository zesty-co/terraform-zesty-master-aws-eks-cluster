# Terragrunt Multi-Cluster Example

This example onboards an AWS management account to Zesty once, then deploys the Kompass Helm chart into multiple EKS clusters using Terragrunt and separate states per cluster.

## Architecture

```text
account/              -> applied once per AWS management account
kompass-eks-prod/     -> applied once per EKS cluster
kompass-eks-staging/  -> applied once per EKS cluster
kompass-eks-data/     -> applied once per EKS cluster
```

## Directory Structure

```text
infrastructure/
├── account/                   # once per AWS management account - own state
├── kompass-eks-prod/          # cluster: eks-prod - own state
├── kompass-eks-staging/       # cluster: eks-staging - own state
└── kompass-eks-data/          # cluster: eks-data - own state
```

Each cluster directory depends on the `account/` stack and reads `kompass_values_yaml` from it.

## Prerequisites

- Terraform >= 1.3
- Terragrunt >= 0.45
- AWS credentials configured in `account.hcl`
- Zesty API token set in `account/terragrunt.hcl`
- Access to the target EKS clusters

## Usage

### Apply everything

```bash
cd live/prod/aws/us-east-1/my-account/zesty
terragrunt run-all apply
```

Terragrunt applies `account/` first, then the `kompass-eks-*` directories.

### Apply individually

```bash
cd live/prod/aws/us-east-1/my-account/zesty/account
terragrunt apply

cd ../kompass-eks-prod
terragrunt apply

cd ../kompass-eks-staging
terragrunt apply

cd ../kompass-eks-data
terragrunt apply
```

## Adding a New Cluster

1. Copy any `kompass-eks-*/` directory
2. Rename it for the new cluster
3. Change `cluster_name` in `terragrunt.hcl`
4. Run `terragrunt apply`
