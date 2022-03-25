/*
  *
  * Optional Variables
  *
  */

variable "cluster_id" {
  type        = string
  description = "The name of your HCP Consul cluster"
  default     = "cluster-ecs-demo-3"
}

variable "hvn_region" {
  type        = string
  description = "The HCP region to create resources in"
  default     = "us-east-1"
}

variable "vpc_region" {
  type        = string
  description = "The AWS region to create resources in"
  default     = "us-east-1"
}

variable "hvn_id" {
  type        = string
  description = "The name of your HCP HVN"
  default     = "cluster-ecs-demo-hvn-2"
}

variable "hvn_cidr_block" {
  type        = string
  description = "The CIDR range to create the HCP HVN with"
  default     = "172.25.32.0/20"
}

variable "tier" {
  type        = string
  description = "The HCP Consul tier to use when creating a Consul cluster"
  default     = "development"
}
