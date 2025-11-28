variable "cluster_name" {
  type = string
}

variable "oidc_provider_arn" {
  type = string
}

variable "namespace" {
  type    = string
  default = "kube-system"
}

variable "region" {
  type = string
}

variable "vpc_id" {
  type = string
}
