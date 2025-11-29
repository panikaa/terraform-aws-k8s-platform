variable "cluster_name" {
  type = string
}

variable "namespace" {
  type    = string
  default = "kube-system"
}
