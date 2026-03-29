provider "aws" {
  region = var.region
}

locals {
  cluster_name = "kompass-eks-prod"
}

data "aws_eks_cluster" "example" {
  name = local.cluster_name
}

data "aws_eks_cluster_auth" "example" {
  name = local.cluster_name
}

provider "helm" {
  kubernetes = {
    host                   = data.aws_eks_cluster.example.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.example.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.example.token
  }
}
