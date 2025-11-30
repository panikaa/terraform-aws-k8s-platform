terraform {
  required_version = ">= 1.5.7"

  required_providers {
    helm = {
      source = "hashicorp/helm"
      version = "~> 2.11"
    }
  }
}

# 10) Create external secret IRSA roles nad policy
module "external_secrets_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts"
  version = "6.2.3"

  name = "external-secrets"

  attach_external_secrets_policy = true

  external_secrets_secrets_manager_arns = [
    "arn:aws:secretsmanager:*:*:secret:rds-hcm-password-*"
  ]

  oidc_providers = {
    this = {
      provider_arn               = var.oidc_provider_arn
      namespace_service_accounts = ["kube-system:external-secrets"]
    }
  }

  tags = {
    Name = "external-secrets-irsa"
  }
}

# 11) Create service account for external secrets
resource "kubernetes_service_account" "external_secrets" {
  metadata {
    name      = "external-secrets"
    namespace = "kube-system"

    annotations = {
      "eks.amazonaws.com/role-arn" = module.external_secrets_irsa.arn
    }
  }

  depends_on = [module.external_secrets_irsa]
}

# 12) Deploy External Secrets to helm
resource "helm_release" "external_secrets" {
  name       = "external-secrets"
  repository = "https://charts.external-secrets.io"
  chart      = "external-secrets"
  version    = "0.9.13"
  namespace  = var.namespace

  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "serviceAccount.name"
    value = kubernetes_service_account.external_secrets.metadata[0].name
  }

  set {
    name  = "webhook.port"
    value = "9443"
  }

  depends_on = [
    kubernetes_service_account.external_secrets
  ]
}