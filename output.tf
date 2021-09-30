output "security_group_ids" {
  description = "List of security group IDs that allow Consul client communication"
  value = length(var.security_group_ids) == 0 ? (
    aws_security_group.hcp_consul.*.id
    ) : (
      var.security_group_ids
  )
}
