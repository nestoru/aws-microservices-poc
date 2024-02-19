terraform {
  backend "s3" {
    bucket         = "ms-terraform-state1"
    key            = "state/terraform.tfstate"
    region         = "eu-north-1"
    dynamodb_table = "ms-terraform-state1"
    encrypt        = true
  }
}

module "network" {
  source = "./network"
}

module "eks" {
  source = "./eks"
  subnet1_ids      = module.network.subnet1_ids
  vpc1_id = module.network.vpc1_id
}
