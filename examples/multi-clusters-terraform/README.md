# Terraform Multi-Cluster Example

This example shows how to onboard one AWS management account to Zesty and then deploy the Kompass Helm chart into multiple Amazon EKS clusters.

The deployment is intentionally split into separate Terraform states:

- The `account/` stack is applied once for the AWS management account.
- Each `kompass-eks-*` stack is applied once for one EKS cluster.

This structure allows the account-level Zesty registration to be managed separately from the individual cluster installations.

## Architecture

```text
account/               -> applied once per AWS management account
kompass-eks-prod/      -> applied once for the production EKS cluster
kompass-eks-staging/   -> applied once for the staging EKS cluster
kompass-eks-data/      -> applied once for the data EKS cluster
```

The `account/` stack provisions the Zesty account-level resources and stores the generated `kompass_values_yaml` output in Terraform remote state.

Each `kompass-eks-*` stack reads `kompass_values_yaml` from the `account/` remote state and uses it to install the Kompass Helm chart into the selected EKS cluster.

## Directory Structure

```text
multi-clusters-terraform/
├── account/                   # account-level Zesty onboarding, own Terraform state
├── kompass-eks-prod/          # Kompass installation for the production EKS cluster
├── kompass-eks-staging/       # Kompass installation for the staging EKS cluster
└── kompass-eks-data/          # Kompass installation for the data EKS cluster
```

Each `kompass-eks-*` directory is a standalone Terraform root. It has its own backend key, EKS cluster lookup, and Helm release.

## Prerequisites

Before starting, confirm that the following items are available:

- Terraform version `1.3` or later.
- AWS credentials with permission to manage the target AWS account and read the target EKS clusters.
- Access to each target EKS cluster.
- A Zesty API token.
- An S3 bucket for Terraform remote state.
- Network access to the Zesty provider, AWS APIs, the EKS clusters, and the Kompass Helm chart repository.

Verify AWS access before running Terraform:

```bash
aws sts get-caller-identity
```

The command must return the AWS account where the deployment should run. If it returns a different account, update the local AWS credentials before continuing.

## Values to Replace

This example contains placeholder values. Replace them before running Terraform.

| Location | Placeholder | Required value |
|----------|-------------|----------------|
| `account/main.tf` | `my-terraform-state` | S3 bucket used for Terraform state |
| `account/main.tf` | `us-east-1` | AWS region for the Terraform state bucket |
| `account/provider.tf` | `us-east-1` | AWS region for the account-level deployment |
| `account/provider.tf` | `your-zesty-api-token` | Customer Zesty API token |
| `kompass-eks-*/main.tf` | `my-terraform-state` | Same S3 bucket used by the `account/` stack |
| `kompass-eks-*/main.tf` | `us-east-1` | AWS region for the Terraform state bucket |
| `kompass-eks-*/provider.tf` | `local.cluster_name` | Exact EKS cluster name |
| `kompass-eks-*/variables.tf` | `default = "us-east-1"` | AWS region where the EKS cluster exists |

Do not commit real customer secrets to source control. If this example is adapted for production use, store the Zesty token according to the customer's secret-management policy.

## Deployment Steps

### Step 1: Open the Example Directory

From the repository root, open this example:

```bash
cd examples/multi-clusters-terraform
```

Run all commands in the sections below from this directory unless another directory is shown.

### Step 2: Configure the Account Stack

Open `account/main.tf` and update the Terraform backend:

```hcl
terraform {
  backend "s3" {
    bucket  = "my-terraform-state"
    key     = "zesty/account/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}
```

Replace:

- `bucket` with the customer's Terraform state bucket.
- `region` with the AWS region where that bucket exists.

The backend `key` must stay unique for the account stack. The default value `zesty/account/terraform.tfstate` is acceptable if no other deployment uses that same key.

Open `account/provider.tf` and update the AWS region and Zesty token:

```hcl
provider "aws" {
  region = "us-east-1"
}

provider "zesty" {
  token = "your-zesty-api-token"
}
```

Replace:

- `region` with the AWS region used for account-level resources.
- `token` with the customer Zesty API token.

### Step 3: Initialize the Account Stack

Run:

```bash
cd account
terraform init
```

Terraform downloads the required providers and configures the S3 backend.

If Terraform reports an S3 backend error, confirm that:

- The S3 bucket exists.
- The AWS credentials can access the bucket.
- The backend region is correct.

### Step 4: Review the Account Plan

Run:

```bash
terraform plan
```

Review the plan before applying it. The plan should show the resources required for Zesty account onboarding.

### Step 5: Apply the Account Stack

Run:

```bash
terraform apply
```

When Terraform asks for approval, type:

```text
yes
```

After this step completes, Terraform stores the generated `kompass_values_yaml` output in the account remote state. The cluster stacks require that output, so the account stack must be applied before any cluster stack.

### Step 6: Return to the Multi-Cluster Directory

Run:

```bash
cd ..
```

You should now be back in:

```text
examples/multi-clusters-terraform
```

### Step 7: Configure One Cluster Stack

Choose one cluster directory, for example:

```text
kompass-eks-prod/
```

Open `kompass-eks-prod/main.tf` and update both S3 state blocks:

```hcl
terraform {
  backend "s3" {
    bucket  = "my-terraform-state"
    key     = "zesty/kompass-eks-prod/terraform.tfstate"
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
```

Replace:

- The backend `bucket` and `region` with the customer's Terraform state bucket and bucket region.
- The remote state `bucket`, `key`, and `region` with the exact values used by the `account/` stack.

The cluster backend `key` must be unique per cluster. For example:

```text
zesty/kompass-eks-prod/terraform.tfstate
zesty/kompass-eks-staging/terraform.tfstate
zesty/kompass-eks-data/terraform.tfstate
```

Open `kompass-eks-prod/provider.tf` and update the EKS cluster name:

```hcl
locals {
  cluster_name = "kompass-eks-prod"
}
```

Replace `kompass-eks-prod` with the exact EKS cluster name in AWS.

Open `kompass-eks-prod/variables.tf` and update the AWS region if required:

```hcl
variable "region" {
  description = "AWS region where the EKS cluster lives"
  type        = string
  default     = "us-east-1"
}
```

The `default` value must match the AWS region where the EKS cluster exists.

### Step 8: Initialize the Cluster Stack

Run:

```bash
cd kompass-eks-prod
terraform init
```

Terraform configures the cluster stack backend and downloads the AWS and Helm providers.

### Step 9: Review the Cluster Plan

Run:

```bash
terraform plan
```

Review the plan before applying it. The plan should show a Helm release named `kompass` in the `zesty-system` namespace.

If Terraform cannot find the EKS cluster, confirm that:

- `local.cluster_name` exactly matches the EKS cluster name.
- `var.region` matches the EKS cluster region.
- The AWS credentials can read the EKS cluster.

If Terraform cannot read the account remote state, confirm that:

- The `account/` stack was already applied.
- The remote state bucket, key, and region match the values in `account/main.tf`.

### Step 10: Apply the Cluster Stack

Run:

```bash
terraform apply
```

When Terraform asks for approval, type:

```text
yes
```

Terraform installs the Kompass Helm chart into the selected EKS cluster.

### Step 11: Repeat for Additional Clusters

Return to the multi-cluster directory:

```bash
cd ..
```

Repeat Steps 7 through 10 for each additional cluster directory:

- `kompass-eks-staging/`
- `kompass-eks-data/`
- Any new `kompass-eks-*` directory created for another EKS cluster.

## Adding a New Cluster

To add another EKS cluster:

1. Copy an existing cluster directory, such as `kompass-eks-prod/`.
2. Rename the copied directory to match the new cluster purpose, for example `kompass-eks-dev/`.
3. Open the new directory's `main.tf`.
4. Set a unique Terraform backend `key`.
5. Confirm the remote state `bucket`, `key`, and `region` point to the existing `account/` state.
6. Open `provider.tf`.
7. Set `local.cluster_name` to the exact EKS cluster name.
8. Open `variables.tf`.
9. Set the default `region` to the EKS cluster region.
10. Run `terraform init`, `terraform plan`, and `terraform apply` from the new cluster directory.

## Validation

After applying a cluster stack, confirm that the Helm release exists:

```bash
helm list --namespace zesty-system
```

Confirm that the namespace exists:

```bash
kubectl get namespace zesty-system
```

Confirm that Kompass resources were created:

```bash
kubectl get all --namespace zesty-system
```

Use a Kubernetes context that points to the same EKS cluster managed by the Terraform stack.

## File Reference

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
| `main.tf` | S3 backend, account remote state lookup, and Kompass Helm release |
| `provider.tf` | AWS provider, EKS data sources, and Helm provider |
| `variables.tf` | AWS region input definition |
| `versions.tf` | Terraform and provider version constraints |
