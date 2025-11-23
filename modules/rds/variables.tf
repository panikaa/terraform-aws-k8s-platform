variable "db_name" {
  type        = string
  default     = "hcm"
  description = "Database name"
}

variable "username" {
  type        = string
  default     = "postgres"
}

variable "instance_class" {
  type        = string
  default     = "db.t3.micro"
}

variable "publicly_accessible" {
  type        = bool
  default     = false
}

variable "multi_az" {
  type        = bool
  default     = false
}

variable "subnet_ids" {
  type = list(string)
}

variable "vpc_id" {
  type = string
}

variable "eks_node_sg_id" {
  type = string
  description = "Security group ID of EKS nodes"
}

variable "allocated_storage" {
  type    = number
  default = 20
}

variable "engine_version" {
  type    = string
  default = "14.11"
}
