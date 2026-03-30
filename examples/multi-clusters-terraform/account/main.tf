terraform {
  backend "s3" {
    bucket  = "my-terraform-state"
    key     = "zesty/account/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}

module "zesty" {
  source = "../../../"

  create_values_local_file = false
}
