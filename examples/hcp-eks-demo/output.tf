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

output "kubeconfig_filename" {
  value = abspath(one(module.eks[*].kubeconfig_filename))
}

output "helm_values_filename" {
  value = abspath(module.eks_consul_client.helm_values_file)
}

output "hashicups_url" {
  value = "${one(module.demo_app[*].hashicups_url)}:8080"
}

output "next_steps" {
  value = "HashiCups Application will be ready in ~2 minutes. Use 'terraform output consul_root_token' to retrieve the root token."
}

output "howto_connect" {
  value = <<EOF
  ${var.install_demo_app ? "The demo app, HashiCups, Has been installed for you and its components registered in Consul." : ""}
  ${var.install_demo_app ? "To access HashiCups navigate to: ${one(module.demo_app[*].hashicups_url)}:8080" : ""}

  To access Consul from your local client run:
  export CONSUL_HTTP_ADDR="${hcp_consul_cluster.main.consul_public_endpoint_url}"
  export CONSUL_HTTP_TOKEN=$(terraform output -raw consul_root_token)
  
  ${var.install_eks_cluster ? "You can access your provisioned eks cluster by first running following command" : ""}
  ${var.install_eks_cluster ? "export KUBECONFIG=$(terraform output -raw kubeconfig_filename)" : ""}    

  Consul has been installed in the default namespace. To explore what has been installed run:
  
  kubectl get pods

  EOF
}
