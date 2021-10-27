output "consul_root_token" {
  value     = hcp_consul_cluster_root_token.token.secret_id
  sensitive = true
}

output "consul_url" {
  value = hcp_consul_cluster.main.public_endpoint ? (
    hcp_consul_cluster.main.consul_public_endpoint_url
    ) : (
    hcp_consul_cluster.main.consul_private_endpoint_url
  )
}

output "clients" {
  value = module.aws_ec2_consul_client
}

output "nomad" {
  value = "http://${module.aws_ec2_consul_client.host_dns}:4646"
}

output "hashicups" {
  value = "http://${module.aws_ec2_consul_client.host_dns}:8080"
}
