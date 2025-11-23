terraform {
  required_version = ">= 1.3.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

module "network" {
  source   = "../../modules/network"
  name     = var.name
  vpc_cidr = "10.0.0.0/16"
}
