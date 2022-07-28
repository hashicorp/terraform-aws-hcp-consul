variable "subnet_id" {
  type        = string
  description = "The subnet ID to create EC2 clients in"
}

variable "allowed_ssh_cidr_blocks" {
  description = "A list of CIDR-formatted IP address ranges from which the EC2 Instances will allow SSH connections"
  type        = list(string)
  default     = []
}
variable "ssh_keyname" {
  description = "key pair name for ssh connection"
  default     = ""
}
variable "allowed_http_cidr_blocks" {
  description = "A list of CIDR-formatted IP address ranges from which the EC2 Instances will allow connections over 8080"
  type        = list(string)
  default     = []
}

variable "client_config_file" {
  type        = string
  description = "The client config file provided by HCP"
}

variable "client_ca_file" {
  type        = string
  description = "The Consul client CA file provided by HCP"
}

variable "root_token" {
  type        = string
  description = "The Consul Secret ID of the Consul root token"
}

variable "consul_version" {
  type        = string
  description = "The Consul version of the HCP servers"
}

variable "security_group_id" {
  type = string
}

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR"
  default     = "10.0.0.0/8"
}

variable "nomad_token" {
  type = string

  description = "Token for nomad"
}
variable "install_demo_app" {
  type        = bool
  default     = true
  description = "Choose to install the demo app"
}

#needed to setup the unique security groups per ec2 instance
variable "vpc_id" {
  type        = string
  description = "VPC ID"
}
