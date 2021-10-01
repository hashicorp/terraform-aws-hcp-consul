/*
 *
 * Required Variables
 *
 */

variable "hvn_id" {
  type        = string
  description = "The ID of your HCP HVN"
}

variable "vpc_id" {
  type        = string
  description = "The ID of your AWS VPC"
}

variable "route_table_ids" {
  type        = list(string)
  description = "A list of route table IDs which should route to the the HVN's CIDR"
}

/*
 *
 * Optional Variables
 *
 */

variable "security_group_ids" {
  type        = list(string)
  description = "A list of security group IDs which should allow inbound Consul client traffic"
  default     = []
}
