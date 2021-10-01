output "security_group_id" {
  description = "Newly created AWS security group that allow Consul client communication, if 'security_group_ids' was not provided."
  value       = length(var.security_group_ids) == 0 ? aws_security_group.hcp_consul[0].id : ""
}
