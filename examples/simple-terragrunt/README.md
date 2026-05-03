# Terragrunt Simple Example

This example shows how to onboard one AWS management account to Zesty and deploy the Kompass Helm chart into one Amazon EKS cluster by using Terragrunt.

Use this example when the customer wants a production-style `live/` directory structure, generated Terraform backend configuration, and a separate reusable module for the Kompass Helm release.

## What This Example Does

Terragrunt manages two stacks:

1. `account/` onboards the AWS management account to Zesty.
2. `kompass/` installs the Kompass Helm chart into one EKS cluster.

The `kompass/` stack depends on the `account/` stack and reads the generated `kompass_values_yaml` output from it.

## Directory Structure

```text
simple-terragrunt/
├── modules/
│   └── kompass/                                      # reusable Helm module
│       ├── main.tf
│       ├── variables.tf
│       └── versions.tf
└── live/
    ├── root.hcl                                      # organization and project values
    └── prod/
        ├── environment.hcl                           # environment name, derived from the directory name
        └── aws/
            ├── datacenter.hcl                        # S3 backend and generated AWS provider
            └── us-east-1/
                ├── region.hcl                        # AWS region, derived from the directory name
                └── my-account/
                    ├── account.hcl                   # AWS account ID and AWS profile
                    └── zesty/
                        ├── account/                  # Zesty account onboarding stack
                        └── kompass/                  # Kompass Helm release stack
```

## Prerequisites

Before starting, confirm that the following items are available:

- Terraform version `1.3` or later.
- Terragrunt version `0.45` or later.
- AWS credentials configured for the customer AWS account.
- An AWS CLI profile that can access the target account.
- Access to the target EKS cluster.
- A Zesty API token.
- An S3 bucket for Terraform remote state.
- Network access to the Zesty provider, AWS APIs, the EKS cluster, and the Kompass Helm chart repository.

Verify AWS access before running Terragrunt:

```bash
aws sts get-caller-identity --profile my-aws-profile
```

Replace `my-aws-profile` with the customer AWS profile. The command must return the AWS account where the deployment should run.

## Values to Replace

This example contains placeholder values. Replace them before running Terragrunt.

| Location | Placeholder | Required value |
|----------|-------------|----------------|
| `live/root.hcl` | `my-org` | Customer organization identifier used in the state bucket name |
| `live/root.hcl` | `my-project` | Customer project identifier |
| `live/prod/aws/us-east-1/my-account/account.hcl` | `111122223333` | Customer AWS account ID |
| `live/prod/aws/us-east-1/my-account/account.hcl` | `my-aws-profile` | Local AWS CLI profile for the customer account |
| `live/prod/aws/datacenter.hcl` | `terragrunt-${local.organization}-${local.profile}` | S3 bucket name pattern for Terraform remote state |
| `live/prod/aws/datacenter.hcl` | `region = "us-east-1"` | AWS region where the Terraform state bucket exists |
| `live/prod/aws/us-east-1/my-account/zesty/account/terragrunt.hcl` | `your-zesty-api-token` | Customer Zesty API token |
| `live/prod/aws/us-east-1/my-account/zesty/kompass/terragrunt.hcl` | `my-eks-cluster` | Exact EKS cluster name |
| Directory `live/prod/` | `prod` | Customer environment name, if different |
| Directory `live/prod/aws/us-east-1/` | `us-east-1` | AWS region where the EKS cluster exists |
| Directory `live/prod/aws/us-east-1/my-account/` | `my-account` | Customer account directory name |

Do not commit real customer secrets to source control. If this example is adapted for production use, store the Zesty token according to the customer's secret-management policy.

## Deployment Steps

### Step 1: Open the Example Directory

From the repository root, open this example:

```bash
cd examples/simple-terragrunt
```

Run all commands in the sections below from this directory unless another directory is shown.

### Step 2: Configure Organization and Project Values

Open `live/root.hcl`:

```hcl
locals {
  organization = "my-org"
  project      = "my-project"
}
```

Replace:

- `my-org` with a customer organization identifier.
- `my-project` with a customer project identifier.

The current backend configuration uses `organization` when building the S3 state bucket name.

### Step 3: Configure the AWS Account

Open `live/prod/aws/us-east-1/my-account/account.hcl`:

```hcl
locals {
  account_id = "111122223333"
  profile    = "my-aws-profile"
}
```

Replace:

- `111122223333` with the customer AWS account ID.
- `my-aws-profile` with the AWS CLI profile that should be used for this account.

Verify the profile:

```bash
aws sts get-caller-identity --profile my-aws-profile
```

The returned account ID must match the customer AWS account ID.

### Step 4: Confirm the Environment and Region Directories

The environment value is derived from the `live/prod/` directory name.

If the customer environment is not `prod`, rename the directory before running Terragrunt.

The AWS region value is derived from the `live/prod/aws/us-east-1/` directory name.

If the EKS cluster is not in `us-east-1`, rename the region directory before running Terragrunt.

### Step 5: Configure the Terraform State Bucket

Open `live/prod/aws/datacenter.hcl` and review the remote state configuration:

```hcl
remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    bucket  = "terragrunt-${local.organization}-${local.profile}"
    profile = local.profile
    key     = "${path_relative_to_include()}/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}
```

Confirm that:

- The generated bucket name matches an existing S3 bucket.
- The `profile` can access the S3 bucket.
- The backend `region` matches the S3 bucket region.

The backend `key` is generated from the Terragrunt directory path, so the `account/` and `kompass/` stacks receive separate state files automatically.

### Step 6: Configure the Zesty Token

Open `live/prod/aws/us-east-1/my-account/zesty/account/terragrunt.hcl`:

```hcl
generate "zesty_provider" {
  path      = "zesty_provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
provider "zesty" {
  token = "your-zesty-api-token"
}
EOF
}
```

Replace `your-zesty-api-token` with the customer Zesty API token.

### Step 7: Configure the EKS Cluster Name

Open `live/prod/aws/us-east-1/my-account/zesty/kompass/terragrunt.hcl`:

```hcl
locals {
  region_vars  = read_terragrunt_config(find_in_parent_folders("region.hcl")).locals
  region       = local.region_vars.region
  cluster_name = "my-eks-cluster"
}
```

Replace `my-eks-cluster` with the exact EKS cluster name in AWS.

### Step 8: Plan Both Stacks

Open the Zesty live directory:

```bash
cd live/prod/aws/us-east-1/my-account/zesty
```

Run:

```bash
terragrunt run-all plan
```

Review the plans before applying them. Terragrunt should plan the `account/` stack and the `kompass/` stack.

If Terragrunt reports a remote state error, confirm that the S3 bucket exists and the AWS profile can access it.

If Terragrunt cannot find the EKS cluster, confirm that the cluster name, region directory, and AWS profile are correct.

### Step 9: Apply Both Stacks

Run:

```bash
terragrunt run-all apply
```

When Terragrunt or Terraform asks for approval, type:

```text
yes
```

Terragrunt applies the `account/` stack first. After the account stack completes, Terragrunt applies the `kompass/` stack and installs the Kompass Helm chart into the EKS cluster.

## Applying Stacks Individually

If the customer requires separate approval steps, apply the stacks individually.

Start with the account stack:

```bash
cd live/prod/aws/us-east-1/my-account/zesty/account
terragrunt plan
terragrunt apply
```

Then apply the Kompass stack:

```bash
cd ../kompass
terragrunt plan
terragrunt apply
```

The account stack must be applied before the Kompass stack because the Kompass stack depends on `kompass_values_yaml` from the account stack.

## Validation

After the Kompass stack completes, confirm that the Helm release exists:

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

Use a Kubernetes context that points to the same EKS cluster configured in `kompass/terragrunt.hcl`.

## File Reference

| File or directory | Description |
|-------------------|-------------|
| `live/root.hcl` | Defines organization and project values |
| `live/prod/environment.hcl` | Derives the environment from the directory name |
| `live/prod/aws/datacenter.hcl` | Configures S3 remote state and generates the AWS provider |
| `live/prod/aws/us-east-1/region.hcl` | Derives the AWS region from the directory name |
| `live/prod/aws/us-east-1/my-account/account.hcl` | Defines AWS account ID and AWS profile |
| `live/prod/aws/us-east-1/my-account/zesty/account/terragrunt.hcl` | Calls the root Zesty module and generates the Zesty provider |
| `live/prod/aws/us-east-1/my-account/zesty/kompass/terragrunt.hcl` | Reads the account dependency and configures the EKS cluster Helm provider |
| `modules/kompass/main.tf` | Creates the Kompass Helm release |
