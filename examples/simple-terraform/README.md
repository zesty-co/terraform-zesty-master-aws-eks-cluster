# Terraform Simple Example

This example shows how to onboard one AWS management account to Zesty and deploy the Kompass Helm chart into one Amazon EKS cluster from a single Terraform root.

Use this example when the customer wants the simplest Terraform flow and does not need separate Terraform states for account onboarding and cluster installation.

## What This Example Does

Terraform performs both actions in one apply:

1. Onboards the AWS management account to Zesty by calling the module in the repository root.
2. Uses the generated `kompass_values_yaml` output to install the Kompass Helm chart into the selected EKS cluster.

The Helm release is created in the `zesty-system` namespace.

## Directory Structure

```text
simple-terraform/
├── main.tf        # Zesty module call and Kompass Helm release
├── outputs.tf     # Kompass values output
├── provider.tf    # AWS, Zesty, EKS, and Helm provider configuration
├── variables.tf   # EKS cluster name and AWS region inputs
└── versions.tf    # Terraform and provider version constraints
```

## Prerequisites

Before starting, confirm that the following items are available:

- Terraform version `1.3` or later.
- AWS credentials with permission to manage the target AWS account and read the target EKS cluster.
- Access to the target EKS cluster.
- A Zesty API token.
- Network access to the Zesty provider, AWS APIs, the EKS cluster, and the Kompass Helm chart repository.

Verify AWS access before running Terraform:

```bash
aws sts get-caller-identity
```

The command must return the AWS account where the deployment should run. If it returns a different account, update the local AWS credentials before continuing.

## Values to Replace

This example contains placeholder values. Replace them before running Terraform.

| Location | Placeholder | Required value |
|----------|-------------|----------------|
| `provider.tf` | `your-zesty-api-token` | Customer Zesty API token |
| `variables.tf` | `default = "us-east-1"` | AWS region where the management account and EKS cluster exist |
| Terraform command | `my-eks-cluster` | Exact EKS cluster name |

Do not commit real customer secrets to source control. If this example is adapted for production use, store the Zesty token according to the customer's secret-management policy.

## Deployment Steps

### Step 1: Open the Example Directory

From the repository root, open this example:

```bash
cd examples/simple-terraform
```

Run all commands in the sections below from this directory.

### Step 2: Configure the Zesty Token

Open `provider.tf` and update the Zesty provider:

```hcl
provider "zesty" {
  token = "your-zesty-api-token"
}
```

Replace `your-zesty-api-token` with the customer Zesty API token.

### Step 3: Confirm the AWS Region

Open `variables.tf` and confirm the default AWS region:

```hcl
variable "region" {
  description = "AWS region where the management account and EKS cluster live"
  type        = string
  default     = "us-east-1"
}
```

If the customer's EKS cluster is not in `us-east-1`, replace the default value with the correct AWS region.

The AWS provider uses this value:

```hcl
provider "aws" {
  region = var.region
}
```

### Step 4: Identify the EKS Cluster Name

Find the exact EKS cluster name in AWS. The value must match the cluster name exactly.

You can verify the available clusters with:

```bash
aws eks list-clusters --region us-east-1
```

If the cluster is in a different region, replace `us-east-1` in the command with the correct region.

### Step 5: Initialize Terraform

Run:

```bash
terraform init
```

Terraform downloads the required providers.

This example does not define a remote backend. Terraform will use local state unless the customer adds a backend configuration.

### Step 6: Review the Terraform Plan

Run:

```bash
terraform plan -var="cluster_name=my-eks-cluster"
```

Replace `my-eks-cluster` with the exact EKS cluster name.

Review the plan before applying it. The plan should include:

- Zesty account onboarding resources.
- A Helm release named `kompass`.
- The `zesty-system` Kubernetes namespace, if it does not already exist.

If Terraform cannot find the EKS cluster, confirm that:

- The `cluster_name` value exactly matches the EKS cluster name.
- The AWS region is correct.
- The AWS credentials can read the EKS cluster.

### Step 7: Apply the Terraform Configuration

Run:

```bash
terraform apply -var="cluster_name=my-eks-cluster"
```

Replace `my-eks-cluster` with the exact EKS cluster name.

When Terraform asks for approval, type:

```text
yes
```

Terraform onboards the AWS management account to Zesty and installs Kompass into the selected EKS cluster.

## Validation

After Terraform completes, confirm that the Helm release exists:

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

Use a Kubernetes context that points to the same EKS cluster used in the Terraform command.

## File Reference

| File | Description |
|------|-------------|
| `main.tf` | Calls the Zesty module and creates the Kompass Helm release |
| `outputs.tf` | Exposes `kompass_values_yaml` from the Zesty module |
| `provider.tf` | Configures AWS, Zesty, EKS lookup, and Helm provider access |
| `variables.tf` | Defines the EKS cluster name and AWS region inputs |
| `versions.tf` | Defines Terraform and provider version constraints |
