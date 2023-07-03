variable "name" {
  type        = string
  description = "Name of redis cluster"
}

variable "ingress_security_groups" {
  type        = list
  description = "Inbound connection whitelist"
}

variable "vpc_id" {
  type        = string
  description = "ID of the VPC for redis"
}

variable "elasticache_subnet_group_name" {
  type        = string
  description = "Subnet group for redis"
}
