variable "cluster_name" {
  type = string
}

variable "namespace" {
  type    = string
  default = "kube-system"
}

variable "oidc_provider_arn" {
  type = string
}

variable "oidc_provider_url" {
  type = string
}