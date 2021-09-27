output "consul_root_token" {
  value     = hcp_consul_cluster_root_token.token
  sensitive = true
}

output "consul_url" {
  value = hcp_consul_cluster.main.public_endpoint ? (
    hcp_consul_cluster.main.consul_public_endpoint_url
    ) : (
    hcp_consul_cluster.main.consul_private_endpoint_url
  )
}

output "service_instance_ids" {
  value = module.aws_ec2_consul_client
}