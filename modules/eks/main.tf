terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.8.4"

  cluster_name    = var.cluster_name
  cluster_version = "1.30"

  vpc_id          = var.vpc_id
  subnet_ids      = var.private_subnets

  enable_irsa = true

  cluster_endpoint_public_access = true

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
