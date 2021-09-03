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
  version    = "0.33.0"
  chart      = "consul"

  values = [
    templatefile("${path.module}/templates/consul.tpl", {
      datacenter       = var.datacenter
      consul_hosts     = jsonencode(var.consul_hosts)
      cluster_id       = var.cluster_id
      k8s_api_endpoint = var.k8s_api_endpoint
    })
  ]

  # Helm installation relies on the Kuberenetes secret being
  # available.
  depends_on = [kubernetes_secret.consul_secrets]
}
