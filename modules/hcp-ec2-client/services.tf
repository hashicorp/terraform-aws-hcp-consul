# This is needed for a tutorial on blue green deployments.
# This helps show the functionality to make it happen and 
# hide some of the complexity like service defaults
resource "consul_config_entry" "proxy_defaults" {
  count = var.install_demo_app ? 1 : 0

  name = "global"
  kind = "proxy-defaults"

  config_json = jsonencode({
    Config = {
      protocol = "http"
    }
  })
}

resource "consul_config_entry" "service_default_frontend" {
  count = var.install_demo_app ? 1 : 0

  name = "frontend"
  kind = "service-defaults"

  config_json = jsonencode({
    Protocol = "http"
  })
}

# Unforunately, we have to pre-register the Ingress Gateway in Consul before
# the Nomad service starts (for now). Otherwise, destroys will fail with:
# "frontend" has protocol "tcp", which does not match defined listener protocol "http")
# https://github.com/hashicorp/nomad/issues/8647#issuecomment-785484553
resource "consul_config_entry" "ingress_gateway" {
  count = var.install_demo_app ? 1 : 0

  kind = "ingress-gateway"
  name = "hashicups-ingress"

  config_json = jsonencode({
    Listeners = [{
      Port     = 80
      Protocol = "http"
      Services = [
        {
          Name  = "frontend"
          Hosts = ["*"]
        }
      ]
    }]
  })

  depends_on = [consul_config_entry.service_default_frontend]
}

# All HashiCups service defaults
# https://github.com/hashicorp/nomad/issues/8647#issuecomment-785484553
resource "consul_config_entry" "service_default_public_api" {
  count = var.install_demo_app ? 1 : 0

  name = "public-api"
  kind = "service-defaults"

  config_json = jsonencode({
    Protocol = "http"
  })
}

resource "consul_config_entry" "service_default_payment_api" {
  count = var.install_demo_app ? 1 : 0

  name = "payment-api"
  kind = "service-defaults"

  config_json = jsonencode({
    Protocol = "http"
  })
}

resource "consul_config_entry" "service_default_product_api" {
  count = var.install_demo_app ? 1 : 0

  name = "product-api"
  kind = "service-defaults"

  config_json = jsonencode({
    Protocol = "http"
  })
}

resource "consul_config_entry" "service_default_product_db" {
  count = var.install_demo_app ? 1 : 0

  name = "product-db"
  kind = "service-defaults"

  config_json = jsonencode({
    Protocol = "http"
  })
}
