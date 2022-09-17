output "security_group_id" {
  description = "Newly created AWS security group that allow Consul client communication, if 'security_group_ids' was not provided."
  value       = length(var.security_group_ids) == 0 ? aws_security_group.hcp_consul[0].id : ""

  # This is here because so Consul clients wait until the HVN <> VPC peering completes and an HVN to VPC route exists.
  # If Consul clients try to connect before this peering is accepted and configured, clients will not be able to
  # communicate back to the HCP Consul server and Consul client calls will fail.
  depends_on = [hcp_hvn_route.peering_route]
}
