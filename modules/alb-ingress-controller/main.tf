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

# 3) Create ServiceAccount role
module "load_balancer_controller_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts"
  version = "6.2.3"

  name = "aws-load-balancer-controller"

  attach_load_balancer_controller_policy = true

  oidc_providers = {
    this = {
      provider_arn               = var.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }
}

# 4) Create ServiceAccount role
resource "kubernetes_service_account" "lbc_sa" {
  metadata {
    name      = "aws-load-balancer-controller"
    namespace = var.namespace

    annotations = {
      "eks.amazonaws.com/role-arn" = module.load_balancer_controller_irsa.arn
    }
  }
}

# 5) Install Helm Chart
resource "helm_release" "aws_load_balancer_controller" {
  name = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = var.namespace
  depends_on = [
    kubernetes_service_account.lbc_sa
  ]

  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "replicaCount"
    value = 1
  }

  set {
    name  = "clusterName"
    value = var.cluster_name
  }

  set {
    name  = "vpcId"
    value = var.vpc_id
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  set {
    name  = "region"
    value = var.region
  }
}