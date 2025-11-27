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

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_name
}

data "aws_eks_cluster_auth" "cluster_auth" {
  name = module.eks.cluster_name
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

  node_instance_type = "t3.micro"
  desired_capacity    = 2
  min_capacity        = 1
  max_capacity        = 4
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

provider "kubernetes" {
  alias                  = "eks"
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster_auth.token
}

provider "helm" {
  alias = "eks"
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.cluster_auth.token
  }
}

module "alb_ingress" {
  source = "../../modules/alb-ingress-controller"

  cluster_name      = module.eks.cluster_name
  oidc_provider_arn = module.eks.oidc_provider_arn
  region            = var.region

  depends_on = [module.eks]
  
  providers = {
    kubernetes = kubernetes.eks
    helm       = helm.eks
  }
}
