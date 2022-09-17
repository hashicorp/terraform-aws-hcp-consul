variable "allowed_http_cidr_blocks" {
  description = "A list of CIDR-formatted IP address ranges from which the EC2 Instances will allow connections over 8080"
  type        = list(string)
  default     = []
}

variable "allowed_ssh_cidr_blocks" {
  description = "A list of CIDR-formatted IP address ranges from which the EC2 Instances will allow SSH connections"
  type        = list(string)
  default     = []
}

variable "client_ca_file" {
  type        = string
  description = "The Consul client CA file provided by HCP"
}

variable "client_config_file" {
  type        = string
  description = "The client config file provided by HCP"
}

variable "consul_version" {
  type        = string
  description = "The Consul version of the HCP servers"
}

variable "install_demo_app" {
  type        = bool
  default     = true
  description = "Choose to install the demo app"
}

variable "igw_id" {
  type        = string
  description = "The ID of the VPC's Internet Gateway. Here to ensure the instance is deleted and public IP freed before attempting to destroy the Internet Gateway which will otherwise fail"
}

variable "node_id" {
  description = "A value to uniquely identify a node. This value will be added under the node_meta field for the consul agent as node_id"
  type        = string
  default     = ""
}

variable "root_token" {
  type        = string
  description = "The Consul Secret ID of the Consul root token"
}

variable "security_group_id" {
  type = string
}

variable "ssh_keyname" {
  description = "key pair name for ssh connection"
  default     = ""
}

variable "ssm" {
  type        = bool
  description = "Whether to enable SSM on the EC2 host"
  default     = true
}

variable "subnet_id" {
  type        = string
  description = "The subnet ID to create EC2 clients in"
}

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR"
  default     = "10.0.0.0/8"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}
