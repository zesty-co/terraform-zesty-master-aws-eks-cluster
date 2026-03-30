terraform {
  required_version = ">= 1.3"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    zesty = {
      source  = "zesty-co/zesty"
      version = "~> 0.3.0"
    }
  }
}
