terraform {
  required_version = ">= 1.5.7"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0"
    }
    helm = {
      source = "hashicorp/helm"
      version = "~> 2.11"
    }
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name    = var.cluster_name
  kubernetes_version = "1.33"

  vpc_id          = var.vpc_id
  subnet_ids      = var.private_subnets

  endpoint_public_access = true
  endpoint_private_access = true

  enable_cluster_creator_admin_permissions = true

  endpoint_public_access_cidrs = ["84.52.54.66/32"]

  addons = {
    coredns    = {}
    kube-proxy = {}
    vpc-cni = {
      before_compute = true
    }
  }

  eks_managed_node_groups = {
    default = {
      min_size     = var.min_capacity
      max_size     = var.max_capacity
      desired_size = var.desired_capacity

      instance_types = [var.node_instance_type]
      capacity_type  = "ON_DEMAND"

      subnet_ids = var.private_subnets

      tags = {
        Name = "${var.cluster_name}-nodegroup"
      }
    }
  }

  tags = {
    Environment = "dev"
    Terraform   = "true"
    Cluster     = var.cluster_name
  }
}

# Required tags for AWS Load Balancer Controller
resource "aws_ec2_tag" "private_lb_tags" {
  count       = length(var.private_subnets)
  resource_id = var.private_subnets[count.index]
  key         = "kubernetes.io/role/internal-elb"
  value       = "1"
}

resource "aws_ec2_tag" "public_lb_tags" {
  count       = length(var.public_subnets)
  resource_id = var.public_subnets[count.index]
  key         = "kubernetes.io/role/elb"
  value       = "1"
}
