# Terraform Multi-Cluster Example

This example onboards an AWS management account to Zesty once, then deploys the Kompass Helm chart into multiple EKS clusters using separate Terraform states.

## Architecture

```text
account/               -> applied once per AWS management account
kompass-eks-prod/      -> applied once per EKS cluster
kompass-eks-staging/   -> applied once per EKS cluster
kompass-eks-data/      -> applied once per EKS cluster
```

The `account/` stack provisions the management account resources and outputs `kompass_values_yaml`. Each `kompass-eks-*` stack reads that output from remote state and installs the Kompass Helm chart into its target cluster.

## Directory Structure

```text
infrastructure/
├── account/                   # once per AWS management account - own state
├── kompass-eks-prod/          # cluster: eks-prod - own state
├── kompass-eks-staging/       # cluster: eks-staging - own state
└── kompass-eks-data/          # cluster: eks-data - own state
```

Each `kompass-eks-*` directory is a standalone Terraform root with its own backend key, EKS lookup, and Helm release.

## Prerequisites

- Terraform >= 1.3
- AWS credentials configured for the target management account
- Zesty API token configured in `account/provider.tf`
- Access to the target EKS clusters
- An S3 bucket for Terraform remote state

## Usage

### 1. Apply the account layer

```bash
cd account
terraform init
terraform apply
```

This creates the management account resources and stores the generated Kompass values in remote state.

### 2. Apply each cluster layer

For each `kompass-eks-*` directory:

1. Set a unique backend `key` in `main.tf`
2. Set the target EKS cluster name in `provider.tf`
3. Run Terraform in that directory

Example:

```bash
cd kompass-eks-prod
terraform init
terraform apply
```

Repeat for `kompass-eks-staging`, `kompass-eks-data`, or any additional cluster directory you create.

## Adding a New Cluster

1. Copy one of the existing `kompass-eks-*` directories
2. Rename it for the new cluster
3. Update the S3 backend `key` in `main.tf`
4. Update `local.cluster_name` in `provider.tf`
5. Run `terraform init` and `terraform apply`

## Files

### `account/`

| File | Description |
|------|-------------|
| `main.tf` | S3 backend and module call to the repository root |
| `outputs.tf` | Exposes `kompass_values_yaml` for cluster stacks |
| `provider.tf` | AWS and Zesty provider configuration |
| `versions.tf` | Terraform and provider version constraints |

### `kompass-eks-*/`

| File | Description |
|------|-------------|
| `main.tf` | S3 backend, remote state lookup, and `helm_release` |
| `provider.tf` | AWS provider, EKS data sources, and Helm provider |
| `variables.tf` | Region input definition |
| `versions.tf` | Terraform and provider version constraints |
