terraform {
  required_version = ">= 1.3.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.19.0"
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

module "eks" {
  source = "../../modules/eks"

  cluster_name     = var.name
  region           = var.region
  vpc_id           = module.network.vpc_id
  private_subnets  = module.network.private_subnets
  public_subnets   = module.network.public_subnets

  node_instance_type = "t3.small"
  desired_capacity    = 6
  min_capacity        = 2
  max_capacity        = 10
}

module "rds" {
  source = "../../modules/rds"

  db_name       = "hcm"
  username      = "postgres"
  instance_class = "db.t3.micro"
  engine_version = "14.20"

  subnet_ids     = module.network.private_subnets
  vpc_id         = module.network.vpc_id
  eks_node_sg_id = module.eks.node_security_group_id

  allocated_storage = 20
  publicly_accessible = false
  multi_az           = false
}

module "alb_ingress" {
  source = "../../modules/alb-ingress-controller"

  cluster_name      = module.eks.cluster_name
  oidc_provider_arn = module.eks.oidc_provider_arn
  region            = var.region
  vpc_id            = module.network.vpc_id

  depends_on = [module.eks]
}

module "argo" {
  source = "../../modules/argo"

  cluster_name      = module.eks.cluster_name

  depends_on = [module.eks]
}
