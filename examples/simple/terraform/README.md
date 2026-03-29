# Terraform Simple Example

This example onboards an AWS management account to Zesty and deploys the Kompass Helm chart into a single EKS cluster from one Terraform root.

## Prerequisites

- Terraform >= 1.3
- AWS credentials configured for the target management account
- Zesty API token set in `provider.tf`
- Access to the target EKS cluster

## Usage

```bash
terraform init
terraform apply -var="cluster_name=my-eks-cluster"
```

## Files

| File | Description |
|------|-------------|
| `main.tf` | Module call, output, and `helm_release` |
| `outputs.tf` | Exposes `kompass_values_yaml` |
| `provider.tf` | AWS, Zesty, and Helm provider configuration |
| `variables.tf` | Cluster and region inputs |
| `versions.tf` | Terraform and provider version constraints |
