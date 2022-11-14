locals {

  // consul client agents will not be installed starting chart version 1.0.0.
  install_consul_client_agent = substr(var.chart_version, 0, 1) == "1" ? "false" : "true"

  helm_vaues = templatefile("${path.module}/templates/consul.tpl", {
    datacenter              = var.datacenter
    consul_hosts            = jsonencode(var.consul_hosts)
    cluster_id              = var.cluster_id
    k8s_api_endpoint        = var.k8s_api_endpoint
    consul_version          = substr(var.consul_version, 1, -1)
    consul_client_agent     = local.install_consul_client_agent
  })

  consul_secrets_common = {
    bootstrapToken      = var.boostrap_acl_token
  }

  consul_secrets_client_agent = {
    client_agent = local.install_consul_client_agent == "false" ? {} :{
      caCert              = var.consul_ca_file
      gossipEncryptionKey = var.gossip_encryption_key
    }
  }

  consul_secrets = merge(
    local.consul_secrets_common,
    local.consul_secrets_client_agent["client_agent"]
  )
}


resource "kubernetes_secret" "consul_secrets" {
  metadata {
    name = "${var.cluster_id}-hcp"
  }

  data = local.consul_secrets

  type = "Opaque"
}

resource "helm_release" "consul" {
  name       = "consul"
  repository = "https://helm.releases.hashicorp.com"
  version    = var.chart_version
  chart      = "consul"
  timeout  = 720

  values = [local.helm_vaues]

  # Helm installation relies on the Kuberenetes secret being
  # available.
  depends_on = [kubernetes_secret.consul_secrets]
}

resource "local_file" "helm_values" {
  content              = local.helm_vaues
  filename             = substr(var.helm_values_path, -1, 1) == "/" ? "${var.helm_values_path}helm_values_${var.datacenter}" : var.helm_values_path
  file_permission      = var.helm_values_file_permission
  directory_permission = "0755"
}
