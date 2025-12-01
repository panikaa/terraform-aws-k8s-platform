terraform {
  required_version = ">= 1.5.7"

  required_providers {
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

# 7) Deploy Argo
resource "helm_release" "argocd" {
  name       = "${var.cluster_name}-argo-cd"
  namespace  = var.namespace

  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "9.1.4"

  set {
    name  = "configs.cm.syncPolicy"
    value = "automated"
  }
}

# 8) Deploy Project Manifest to Argo
resource "kubectl_manifest" "argocd_project" {
  yaml_body = file("${path.module}/argocd-project.yaml")

  depends_on = [
    helm_release.argocd
  ]
}

# 9) Deploy App Manifest to Argo
resource "kubectl_manifest" "argocd_app" {
  yaml_body = file("${path.module}/argocd-application.yaml")

  depends_on = [
    helm_release.argocd
  ]
}

# 10) Deploy Platform Manifest to Argo
resource "kubectl_manifest" "argocd_platform" {
  yaml_body = file("${path.module}/argocd-platform-app.yaml")

  depends_on = [
    helm_release.argocd
  ]
}