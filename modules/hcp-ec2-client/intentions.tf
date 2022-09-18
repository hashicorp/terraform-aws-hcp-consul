resource "consul_config_entry" "service_intentions_deny" {
  count = var.install_demo_app ? 1 : 0

  name = "*"
  kind = "service-intentions"

  config_json = jsonencode({
    Sources = [
      {
        Name   = "*"
        Action = "deny"
      }
    ]
  })
}

resource "consul_config_entry" "service_intentions_product_api" {
  count = var.install_demo_app ? 1 : 0

  name = "product-api"
  kind = "service-intentions"

  config_json = jsonencode({
    Sources = [
      {
        Name       = "public-api"
        Action     = "allow"
        Precedence = 9
        Type       = "consul"
      },
    ]
  })
}
resource "consul_config_entry" "service_intentions_frontend_publicapi" {
  count = var.install_demo_app ? 1 : 0

  name = "public-api"
  kind = "service-intentions"

  config_json = jsonencode({
    Sources = [
      {
        Name       = "frontend"
        Action     = "allow"
        Precedence = 9
        Type       = "consul"
      },
    ]
  })
}

resource "consul_config_entry" "service_intentions_ingress_frontend" {
  count = var.install_demo_app ? 1 : 0

  name = "frontend"
  kind = "service-intentions"

  config_json = jsonencode({
    Sources = [
      {
        Name       = "hashicups-ingress"
        Action     = "allow"
        Precedence = 9
        Type       = "consul"
      },
    ]
  })
}

resource "consul_config_entry" "service_intentions_product_db" {
  count = var.install_demo_app ? 1 : 0

  name = "product-db"
  kind = "service-intentions"

  config_json = jsonencode({
    Sources = [
      {
        Name       = "product-api"
        Action     = "allow"
        Precedence = 9
        Type       = "consul"
      },
    ]
  })
}

resource "consul_config_entry" "service_intentions_payment_api" {
  count = var.install_demo_app ? 1 : 0

  name = "payment-api"
  kind = "service-intentions"

  config_json = jsonencode({
    Sources = [
      {
        Name       = "public-api"
        Action     = "allow"
        Precedence = 9
        Type       = "consul"
      },
    ]
  })
}
