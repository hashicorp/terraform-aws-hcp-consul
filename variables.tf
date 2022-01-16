/*
 *
 * Required Variables
 *
 */

variable "hvn" {
  type = object({
    hvn_id     = string
    self_link  = string
    cidr_block = string
  })
  description = "The HCP HVN to connect to the VPC"
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
  description = "A list of security group IDs which should allow inbound Consul client traffic. If no security groups are provided, one will be generated for use."
  default     = []
}
