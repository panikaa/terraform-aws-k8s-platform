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
  version    = "9.1.4"

  set {
    name  = "configs.cm.syncPolicy"
    value = "automated"
  }
}

# 7) Deploy External Secrets to helm
resource "helm_release" "external_secrets" {
  name       = "external-secrets"
  repository = "https://charts.external-secrets.io"
  chart      = "external-secrets"
  version    = "0.9.13"
  namespace  = var.namespace

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.name"
    value = "external-secrets"
  }

  set {
    name  = "webhook.port"
    value = "9443"
  }
  depends_on = [
    helm_release.argocd
  ]
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

# 10) Deploy App Manifest to Argo
resource "kubectl_manifest" "argocd_platform" {
  yaml_body = file("${path.module}/argocd-platform-app.yaml")

  depends_on = [
    helm_release.argocd
  ]
}