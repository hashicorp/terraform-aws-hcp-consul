output "consul_root_token" {
  value     = hcp_consul_cluster_root_token.token.secret_id
  sensitive = true
}

output "consul_url" {
  value = data.hcp_consul_cluster.main.public_endpoint ? (
    data.hcp_consul_cluster.main.consul_public_endpoint_url
    ) : (
    data.hcp_consul_cluster.main.consul_private_endpoint_url
  )
}

output "kubeconfig_filename" {
  value = abspath(module.eks.kubeconfig_filename)
}

output "kubeconfig_filename-2" {
  value = abspath(module.eks-2.kubeconfig_filename)
}

output "hashicups_url" {
  value = module.demo_app.hashicups_url
}
