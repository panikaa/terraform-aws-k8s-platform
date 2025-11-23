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

module "eks" {
  source = "../../modules/eks"

  cluster_name     = var.name
  region           = var.region
  vpc_id           = module.network.vpc_id
  private_subnets  = module.network.private_subnets
  public_subnets   = module.network.public_subnets

  node_instance_type = "t3.medium"
  desired_capacity    = 2
  min_capacity        = 1
  max_capacity        = 4
}

module "rds" {
  source = "../../modules/rds"

  db_name       = "hcm"
  username      = "postgres"
  instance_class = "db.t3.micro"
  engine_version = "14.11"

  subnet_ids     = module.network.private_subnets
  vpc_id         = module.network.vpc_id
  eks_node_sg_id = module.eks.node_security_group_id

  allocated_storage = 20
  publicly_accessible = false
  multi_az           = false
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority)
  token                  = data.aws_eks_cluster_auth.auth_token.token
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority)
    token                  = data.aws_eks_cluster_auth.auth_token.token
  }
}

data "aws_eks_cluster_auth" "auth_token" {
  name = module.eks.cluster_name
}

module "alb_ingress" {
  source = "../../modules/alb-ingress-controller"

  cluster_name      = module.eks.cluster_name
  oidc_provider_arn = module.eks.oidc_provider_arn
  region            = var.region
}
