/*
  *
  * Optional Variables
  *
  */

variable "cluster_id" {
  type        = string
  description = "The name of your HCP Consul cluster"
  default     = "cluster-ec2-demo"
}

variable "vpc_region" {
  type        = string
  description = "The AWS region to create resources in"
  default     = "us-west-2"
}

variable "hvn_region" {
  type        = string
  description = "The AWS region to create HCP resources in"
  default     = "us-west-2"
}

variable "hvn_id" {
  type        = string
  description = "The name of your HCP HVN"
  default     = "cluster-ec2-demo-hvn"
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

variable "ssh" {
  type        = bool
  description = "Enable or disable SSH access via locally created certificate"
  default     = true
}

variable "install_demo_app" {
  type        = bool
  description = "Choose to install HashiCups"
  default     = true
}

