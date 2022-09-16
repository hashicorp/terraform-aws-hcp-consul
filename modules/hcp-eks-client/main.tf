locals {
  helm_vaues = templatefile("${path.module}/templates/consul.tpl", {
    datacenter       = var.datacenter
    consul_hosts     = jsonencode(var.consul_hosts)
    cluster_id       = var.cluster_id
    k8s_api_endpoint = var.k8s_api_endpoint
    consul_version   = substr(var.consul_version, 1, -1)
  })
}
resource "kubernetes_secret" "consul_secrets" {
  metadata {
    name = "${var.cluster_id}-hcp"
  }

  data = {
    caCert              = var.consul_ca_file
    gossipEncryptionKey = var.gossip_encryption_key
    bootstrapToken      = var.boostrap_acl_token
  }

  type = "Opaque"
}

resource "helm_release" "consul" {
  name       = "consul"
  repository = "https://helm.releases.hashicorp.com"
  version    = var.chart_version
  chart      = "consul"

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
