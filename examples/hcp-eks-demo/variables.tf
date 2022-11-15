variable "cluster_id" {
  type        = string
  description = "The name of your HCP Consul cluster"
  default     = "cluster-eks-demo"
}

variable "hvn_cidr_block" {
  type        = string
  description = "The CIDR range to create the HCP HVN with"
  default     = "172.25.32.0/20"
}

variable "hvn_id" {
  type        = string
  description = "The name of your HCP HVN"
  default     = "cluster-eks-demo-hvn"
}

variable "hvn_region" {
  type        = string
  description = "The HCP region to create resources in"
  default     = "us-west-2"
}

variable "install_demo_app" {
  type        = string
  description = "Choose to install HashiCups"
  default     = true
}

variable "install_eks_cluster" {
  type        = string
  description = "Choose if you want an eks cluster to be provisioned"
  default     = true
}

variable "tier" {
  type        = string
  description = "The HCP Consul tier to use when creating a Consul cluster"
  default     = "development"
}

variable "vpc_region" {
  type        = string
  description = "The AWS region to create resources in"
  default     = "us-west-2"
}

variable "fargate_eks" {
  type        = bool
  description = "Use fargate eks containers for consul instead of ec2 instances. Only works for agentless"
  default     = false
}
