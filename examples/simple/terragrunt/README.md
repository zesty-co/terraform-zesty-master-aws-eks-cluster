# Terragrunt Simple Example

This example onboards an AWS management account to Zesty and deploys the Kompass Helm chart into a single EKS cluster using Terragrunt with a production-style `live/` directory hierarchy.

## Directory Structure

```text
simple/terragrunt/
├── modules/kompass/                            # reusable Helm module
│   ├── main.tf
│   ├── variables.tf
│   └── versions.tf
└── live/
    ├── root.hcl                                # org + project
    └── prod/
        ├── environment.hcl                     # => "prod" (from dirname)
        └── aws/
            ├── datacenter.hcl                  # S3 backend + AWS provider
            └── us-east-1/
                ├── region.hcl                  # => "us-east-1" (from dirname)
                └── my-account/
                    ├── account.hcl             # AWS account ID + profile
                    └── zesty/
                        ├── account/            # management account onboarding
                        └── kompass/            # Helm release (depends on account)
```

## Prerequisites

- Terraform >= 1.3
- Terragrunt >= 0.45
- AWS credentials configured
- Zesty API token set in `account/terragrunt.hcl`
- Access to the target EKS cluster

## Usage

### Apply both at once

```bash
cd live/prod/aws/us-east-1/my-account/zesty
terragrunt run-all apply
```

### Apply individually

```bash
cd live/prod/aws/us-east-1/my-account/zesty

# 1. Account first
cd account && terragrunt apply

# 2. Kompass
cd ../kompass && terragrunt apply
```

## Configuration

- Cluster name: change `cluster_name` in `kompass/terragrunt.hcl`
- Region: rename the `us-east-1/` directory
- Environment: rename the `prod/` directory
- AWS profile: change `profile` in `account.hcl`
- S3 backend: change the bucket pattern in `datacenter.hcl`
