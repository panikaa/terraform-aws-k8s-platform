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
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.19.0"
    }
  }
}

# 6) Deploy Argo
resource "helm_release" "argocd" {
  name       = "${var.cluster_name}-argo-cd"
  namespace  = var.namespace
  create_namespace = true

  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "5.51.2"

  set {
    name  = "configs.cm.syncPolicy"
    value = "automated"
  }
}

# 7) Deploy Project Manifest to Argo
resource "kubectl_manifest" "argocd_project" {
  yaml_body = file("${path.module}/argocd-project.yaml")

  depends_on = [
    helm_release.argocd
  ]
}

# 8) Deploy App Manifest to Argo
resource "kubectl_manifest" "argocd_app" {
  yaml_body = file("${path.module}/argocd-application.yaml")

  depends_on = [
    helm_release.argocd
  ]
}